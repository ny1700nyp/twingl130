import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/supabase_service.dart';
import '../widgets/twingl_wordmark.dart';
import 'edit_trainers_screen.dart';
import 'find_nearby_talent_screen.dart';
import 'onboarding_screen.dart';
import 'profile_detail_screen.dart';

class ProfileHomeScreen extends StatefulWidget {
  const ProfileHomeScreen({super.key});

  @override
  State<ProfileHomeScreen> createState() => _ProfileHomeScreenState();
}

class _ProfileHomeScreenState extends State<ProfileHomeScreen> {
  bool _isResolvingCity = false;
  late final VoidCallback _locationCacheListener;

  @override
  void initState() {
    super.initState();

    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      // Ensure disk caches hydrate before running the "only-if-changed" refresh.
      () async {
        await SupabaseService.getCurrentUserProfileCached(user.id);
        await SupabaseService.getFavoriteTrainersCached(user.id);
        await SupabaseService.refreshBootstrapCachesIfChanged(user.id);
      }();
    }

    _locationCacheListener = () {
      final loc = SupabaseService.lastKnownLocation.value;
      if (loc == null) return;
      _refreshCityFromStoredLocation(loc.lat, loc.lon);
    };
    SupabaseService.lastKnownLocation.addListener(_locationCacheListener);

    if ((SupabaseService.currentCityCache.value ?? '').trim().isEmpty) {
      _refreshCityFromGps();
    }
  }

  @override
  void dispose() {
    SupabaseService.lastKnownLocation.removeListener(_locationCacheListener);
    super.dispose();
  }

  String _extractCity(Map<String, dynamic>? profile) {
    return '';
  }

  String _extractCityFromPlacemark(Placemark p) {
    final c = (p.locality ?? '').trim();
    if (c.isNotEmpty) return c;
    final s = (p.subAdministrativeArea ?? '').trim();
    if (s.isNotEmpty) return s;
    final a = (p.administrativeArea ?? '').trim();
    if (a.isNotEmpty) return a;
    return '';
  }

  Future<String> _reverseGeocodeCityFallback(double lat, double lon) async {
    if (!kIsWeb) return '';
    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lon&zoom=10&addressdetails=1',
      );
      final res = await http.get(url, headers: {'User-Agent': 'TwinglApp/1.0'});
      if (res.statusCode != 200) return '';
      final data = jsonDecode(res.body);
      final address = data['address'] as Map<String, dynamic>?;
      if (address == null) return '';
      return (address['city'] as String?) ??
          (address['town'] as String?) ??
          (address['village'] as String?) ??
          (address['municipality'] as String?) ??
          (address['county'] as String?) ??
          '';
    } catch (_) {
      return '';
    }
  }

  Future<void> _refreshCityFromStoredLocation(double lat, double lon) async {
    if (_isResolvingCity) return;
    setState(() => _isResolvingCity = true);
    try {
      var city = '';
      try {
        final placemarks = await placemarkFromCoordinates(lat, lon);
        if (placemarks.isNotEmpty) {
          city = _extractCityFromPlacemark(placemarks.first);
        }
      } catch (_) {}
      if (city.isEmpty) {
        city = await _reverseGeocodeCityFallback(lat, lon);
      }
      if (city.trim().isNotEmpty) {
        await SupabaseService.setCityForCurrentUser(city: city.trim(), lat: lat, lon: lon);
      }
    } finally {
      if (mounted) setState(() => _isResolvingCity = false);
    }
  }

  Future<void> _refreshCityFromGps() async {
    if (_isResolvingCity) return;
    setState(() => _isResolvingCity = true);
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      final cachedLoc = SupabaseService.lastKnownLocation.value;
      if (cachedLoc != null) {
        await _refreshCityFromStoredLocation(cachedLoc.lat, cachedLoc.lon);
        return;
      }

      final profile = SupabaseService.currentUserProfileCache.value;
      final lat = (profile?['latitude'] as num?)?.toDouble();
      final lon = (profile?['longitude'] as num?)?.toDouble();
      if (lat != null && lon != null) {
        await SupabaseService.setLastKnownLocationForCurrentUser(lat: lat, lon: lon);
        await _refreshCityFromStoredLocation(lat, lon);
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 10),
      );
      await SupabaseService.setLastKnownLocationForCurrentUser(lat: pos.latitude, lon: pos.longitude);
      await _refreshCityFromStoredLocation(pos.latitude, pos.longitude);
    } catch (_) {
      // ignore
    } finally {
      if (mounted) setState(() => _isResolvingCity = false);
    }
  }

  Future<void> _onSelectMenu(String value) async {
    if (value == 'my_profile') {
      final user = Supabase.instance.client.auth.currentUser;
      await showProfileDetailSheet(
        context,
        profile: SupabaseService.currentUserProfileCache.value,
        userId: user?.id,
        isMyProfile: true,
        currentUserProfile: SupabaseService.currentUserProfileCache.value,
        onEditPressed: () async {
          if (user == null || !context.mounted) return;
          final profile = await SupabaseService.getCurrentUserProfileCached(user.id);
          if (profile == null || !context.mounted) return;
          final r = await Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => OnboardingScreen(existingProfile: profile)),
          );
          if (r == true && context.mounted) {
            await SupabaseService.refreshCurrentUserProfileCache(user.id);
          }
        },
      );
    } else if (value == 'nearby') {
      await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const FindNearbyTalentScreen()));
    } else if (value == 'edit_trainers') {
      await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const EditTrainersScreen()));
    } else if (value == 'logout') {
      await Supabase.instance.client.auth.signOut();
      SupabaseService.clearInMemoryCaches();
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = AnimatedBuilder(
      animation: Listenable.merge([
        SupabaseService.currentUserProfileCache,
        SupabaseService.currentCityCache,
      ]),
      builder: (context, _) {
        final profile = SupabaseService.currentUserProfileCache.value;
        final cacheCity = (SupabaseService.currentCityCache.value ?? '').trim();
        final city = cacheCity.isNotEmpty ? cacheCity : _extractCity(profile);
        final cityLabel = city.isNotEmpty ? city : (_isResolvingCity ? 'Locating' : 'Enable location');

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const TwinglWordmark(fontSize: 30, fontWeight: FontWeight.w800),
            const SizedBox(width: 10),
            InkWell(
              onTap: _isResolvingCity ? null : _refreshCityFromGps,
              child: Row(
                children: [
                  const Icon(Icons.location_on, size: 18),
                  const SizedBox(width: 4),
                  Text(cityLabel, style: const TextStyle(fontSize: 13)),
                ],
              ),
            ),
          ],
        );
      },
    );

    return Scaffold(
      appBar: AppBar(
        title: title,
        actions: [
          PopupMenuButton<String>(
            onSelected: _onSelectMenu,
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'my_profile', child: Text('My Profile')),
              PopupMenuItem(value: 'nearby', child: Text('Find Nearby Talent')),
              PopupMenuItem(value: 'edit_trainers', child: Text('My Favorite Trainers')),
              PopupMenuItem(value: 'logout', child: Text('Logout')),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          final user = Supabase.instance.client.auth.currentUser;
          if (user == null) return;
          await SupabaseService.refreshCurrentUserProfileCache(user.id);
          await SupabaseService.getFavoriteTrainersCached(user.id, forceRefresh: true);
          await SupabaseService.refreshBootstrapCachesIfChanged(user.id);
        },
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: ValueListenableBuilder<Map<String, dynamic>?>(
                  valueListenable: SupabaseService.currentUserProfileCache,
                  builder: (context, profile, _) {
                    if (profile == null) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }
                    final name = (profile['name'] as String?) ?? 'Unknown';
                    final type = (profile['user_type'] as String?) ?? '';
                    return Card(
                      child: ListTile(
                        title: Text(name),
                        subtitle: Text(type),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          final userId = profile['user_id'] as String?;
                          if (userId == null) return;
                          showProfileDetailSheet(
                            context,
                            userId: userId,
                            currentUserProfile: SupabaseService.currentUserProfileCache.value,
                            hideActionButtons: false,
                            hideDistance: true,
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ),
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Text('My Favorite Trainers', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
            ValueListenableBuilder<List<Map<String, dynamic>>?>(
              valueListenable: SupabaseService.favoriteTrainersCache,
              builder: (context, favoritesValue, _) {
                if (favoritesValue == null) {
                  return const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  );
                }
                final favorites = favoritesValue;
                if (favorites.isEmpty) {
                  return const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(child: Text('No favorite trainers yet.')),
                    ),
                  );
                }
                return SliverList.separated(
                  itemCount: favorites.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final p = favorites[i];
                    final name = (p['name'] as String?) ?? 'Unknown';
                    final userId = (p['user_id'] as String?) ?? '';
                    return ListTile(
                      title: Text(name),
                      subtitle: Text(userId),
                      onTap: userId.isEmpty
                          ? null
                          : () => showProfileDetailSheet(
                                context,
                                userId: userId,
                                currentUserProfile: SupabaseService.currentUserProfileCache.value,
                                hideActionButtons: false,
                                hideDistance: true,
                              ),
                    );
                  },
                );
              },
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
    );
  }
}

