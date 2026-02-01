import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/supabase_service.dart';
import '../widgets/twingl_wordmark.dart';
import 'edit_trainers_screen.dart';
import 'find_nearby_talent_screen.dart';
import 'general_settings_screen.dart';
import 'global_talent_matching_screen.dart';
import 'my_profile_screen.dart';
import 'public_profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isResolvingCity = false;
  late final VoidCallback _locationListener;

  @override
  void initState() {
    super.initState();
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      SupabaseService.getCurrentUserProfileCached(user.id);
      SupabaseService.getFavoriteTrainersCached(user.id);
      SupabaseService.refreshBootstrapCachesIfChanged(user.id);
    }

    _locationListener = () {
      final loc = SupabaseService.lastKnownLocation.value;
      if (loc == null) return;
      _refreshCityFromLatLon(loc.lat, loc.lon);
    };
    SupabaseService.lastKnownLocation.addListener(_locationListener);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _ensureCityResolved();
    });
  }

  @override
  void dispose() {
    SupabaseService.lastKnownLocation.removeListener(_locationListener);
    super.dispose();
  }

  ImageProvider? _imageProviderFromPath(String? path) {
    if (path == null || path.isEmpty) return null;
    if (path.startsWith('data:image')) {
      try {
        return MemoryImage(base64Decode(path.split(',').last));
      } catch (_) {
        return null;
      }
    }
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return NetworkImage(path);
    }
    if (!kIsWeb) {
      // Local file path handling could be added if needed.
      return null;
    }
    return null;
  }

  Future<void> _ensureCityResolved() async {
    final cached = (SupabaseService.currentCityCache.value ?? '').trim();
    if (cached.isNotEmpty) return;

    final loc = SupabaseService.lastKnownLocation.value;
    if (loc != null) {
      await _refreshCityFromLatLon(loc.lat, loc.lon);
      return;
    }

    final profile = SupabaseService.currentUserProfileCache.value;
    final lat = (profile?['latitude'] as num?)?.toDouble();
    final lon = (profile?['longitude'] as num?)?.toDouble();
    if (lat != null && lon != null) {
      await SupabaseService.setLastKnownLocationForCurrentUser(lat: lat, lon: lon);
      await _refreshCityFromLatLon(lat, lon);
      return;
    }
  }

  Future<String> _reverseGeocodeCity(double lat, double lon) async {
    if (kIsWeb) {
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

    try {
      final placemarks = await placemarkFromCoordinates(lat, lon);
      if (placemarks.isEmpty) return '';
      final p = placemarks.first;
      final c = (p.locality ?? '').trim();
      if (c.isNotEmpty) return c;
      final s = (p.subAdministrativeArea ?? '').trim();
      if (s.isNotEmpty) return s;
      final a = (p.administrativeArea ?? '').trim();
      if (a.isNotEmpty) return a;
      return '';
    } catch (_) {
      return '';
    }
  }

  Future<void> _refreshCityFromLatLon(double lat, double lon) async {
    if (_isResolvingCity) return;
    setState(() => _isResolvingCity = true);
    try {
      final city = (await _reverseGeocodeCity(lat, lon)).trim();
      if (city.isNotEmpty) {
        await SupabaseService.setCityForCurrentUser(city: city, lat: lat, lon: lon);
      }
    } finally {
      if (mounted) setState(() => _isResolvingCity = false);
    }
  }

  Future<void> _openNearbyTalent() async {
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const FindNearbyTalentScreen()),
    );
  }

  Future<void> _openTalentMatch() async {
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const GlobalTalentMatchingScreen()),
    );
  }

  Future<void> _onSelectSettings(String value) async {
    if (!mounted) return;
    if (value == 'my_profile') {
      await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MyProfileScreen()));
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        await SupabaseService.refreshCurrentUserProfileCache(user.id);
      }
    } else if (value == 'edit_trainers') {
      await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const EditTrainersScreen()));
      // No forced DB refresh here; Edit screen updates cache optimistically.
    } else if (value == 'general_settings') {
      await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const GeneralSettingsScreen()));
    } else if (value == 'logout') {
      final nav = Navigator.of(context);
      final messenger = ScaffoldMessenger.of(context);
      try {
        await Supabase.instance.client.auth.signOut();
      } catch (e) {
        // Still try to clear caches and return to login.
        if (!mounted) return;
        messenger.showSnackBar(SnackBar(content: Text('Logout failed: $e')));
      }
      SupabaseService.clearInMemoryCaches();
      if (!mounted) return;
      nav.pushReplacementNamed('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = ValueListenableBuilder<String?>(
      valueListenable: SupabaseService.currentCityCache,
      builder: (context, cityValue, _) {
        final city = (cityValue ?? '').trim();
        final showLocation = city.isNotEmpty || _isResolvingCity;
        final cityLabel = city.isNotEmpty ? city : 'Locating';

        if (!showLocation) {
          // If city is not available, do not show "Enable location" at all.
          return const TwinglWordmark(fontSize: 20, fontWeight: FontWeight.w800);
        }

        // City label is display-only (do not allow tapping).
        return Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const TwinglWordmark(fontSize: 20, fontWeight: FontWeight.w800),
            const SizedBox(width: 10),
            Row(
              children: [
                const Icon(Icons.location_on, size: 18),
                const SizedBox(width: 4),
                Text(cityLabel, style: const TextStyle(fontSize: 13)),
              ],
            ),
          ],
        );
      },
    );

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: title,
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            final user = Supabase.instance.client.auth.currentUser;
            if (user == null) return;
            await SupabaseService.refreshCurrentUserProfileCache(user.id);
            await SupabaseService.getFavoriteTrainersCached(user.id, forceRefresh: true);
            await SupabaseService.refreshBootstrapCachesIfChanged(user.id);
            await _ensureCityResolved();
          },
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: [
              // My Profile
              ValueListenableBuilder<Map<String, dynamic>?>(
                valueListenable: SupabaseService.currentUserProfileCache,
                builder: (context, profile, _) {
                  final name = (profile?['name'] as String?)?.trim();
                  final avatarPath = profile?['main_photo_path'] as String?;
                  final avatar = _imageProviderFromPath(avatarPath);

                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    leading: CircleAvatar(
                      radius: 22,
                      backgroundImage: avatar,
                      child: avatar == null ? const Icon(Icons.person) : null,
                    ),
                    title: Text(name?.isNotEmpty == true ? name! : 'My Profile'),
                    onTap: () => _onSelectSettings('my_profile'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: 'Find nearby talent',
                          onPressed: _openNearbyTalent,
                          icon: const Icon(Icons.search),
                          visualDensity: VisualDensity.compact,
                        ),
                        IconButton(
                          tooltip: 'Talent match (any distance)',
                          onPressed: _openTalentMatch,
                          icon: const Icon(Icons.auto_awesome_outlined),
                          visualDensity: VisualDensity.compact,
                        ),
                        PopupMenuButton<String>(
                          tooltip: 'Settings',
                          icon: const Icon(Icons.settings_outlined),
                          onSelected: _onSelectSettings,
                          itemBuilder: (_) => const [
                            PopupMenuItem(value: 'my_profile', child: Text('My Profile')),
                            PopupMenuItem(value: 'edit_trainers', child: Text('Edit my Favorite')),
                            PopupMenuItem(value: 'general_settings', child: Text('General Settings')),
                            PopupMenuItem(value: 'logout', child: Text('Log out')),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),

              const Padding(
                padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Text(
                  'My Favorite',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),

              // Favorites List
              ValueListenableBuilder<List<Map<String, dynamic>>?>(
                valueListenable: SupabaseService.favoriteTrainersCache,
                builder: (context, favoritesValue, _) {
                  if (favoritesValue == null) {
                    return const Padding(
                      padding: EdgeInsets.only(top: 24),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  final favorites = favoritesValue;
                  if (favorites.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.only(top: 24),
                      child: Center(child: Text('No favorite trainers yet.')),
                    );
                  }

                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: favorites.length,
                    itemBuilder: (context, i) {
                      final p = favorites[i];
                      final name = (p['name'] as String?)?.trim();
                      final userId = (p['user_id'] as String?)?.trim() ?? '';
                      final aboutMe = (p['about_me'] as String?)?.trim() ?? '';
                      final avatarPath = p['main_photo_path'] as String?;
                      final avatar = _imageProviderFromPath(avatarPath);

                  return ListTile(
                    key: ValueKey(userId),
                        leading: CircleAvatar(
                          backgroundImage: avatar,
                          child: avatar == null ? const Icon(Icons.person) : null,
                        ),
                        title: Text(name?.isNotEmpty == true ? name! : 'Unknown'),
                        subtitle: aboutMe.isNotEmpty
                            ? Text(
                                aboutMe,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.65),
                                ),
                              )
                            : null,
                        isThreeLine: aboutMe.isNotEmpty,
                        onTap: userId.isEmpty
                            ? null
                            : () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => PublicProfileScreen(
                                      userId: userId,
                                      currentUserProfile: SupabaseService.currentUserProfileCache.value,
                                    ),
                                  ),
                                ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

