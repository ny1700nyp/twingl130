import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/quote_service.dart';
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
  Future<DailyQuote?>? _dailyQuoteFuture;
  final Map<String, ImageProvider> _avatarProviderCache = <String, ImageProvider>{};

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
      _dailyQuoteFuture = QuoteService.getDailyQuote(userId: user.id);
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

  int _hash32(String s) {
    // FNV-1a 32-bit
    int h = 0x811c9dc5;
    for (final c in s.codeUnits) {
      h ^= c;
      h = (h * 0x01000193) & 0xFFFFFFFF;
    }
    return h;
  }

  ImageProvider? _imageProviderFromPath(String? path) {
    if (path == null || path.isEmpty) return null;
    final key = path.startsWith('data:image') ? 'data:${_hash32(path)}' : path;
    final cached = _avatarProviderCache[key];
    if (cached != null) return cached;

    if (path.startsWith('data:image')) {
      try {
        final provider = MemoryImage(base64Decode(path.split(',').last));
        _avatarProviderCache[key] = provider;
        return provider;
      } catch (_) {
        return null;
      }
    }
    if (path.startsWith('http://') || path.startsWith('https://')) {
      final provider = NetworkImage(path);
      _avatarProviderCache[key] = provider;
      return provider;
    }
    if (!kIsWeb) {
      // Local file path handling could be added if needed.
      return null;
    }
    return null;
  }

  Widget _homeActionRow({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withAlpha(22),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Theme.of(context).colorScheme.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right,
              color: Theme.of(context).colorScheme.onSurface.withAlpha(150),
            ),
          ],
        ),
      ),
    );
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

  Future<void> _openFindNearby(FindNearbySection section) async {
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FindNearbyTalentScreen(section: section),
      ),
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
                      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                      backgroundImage: avatar,
                      child: avatar == null ? const Icon(Icons.person) : null,
                    ),
                    title: Text(name?.isNotEmpty == true ? name! : 'My Profile'),
                    onTap: () => _onSelectSettings('my_profile'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
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

              // Daily quote (between profile and favorites)
              if (_dailyQuoteFuture != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
                  child: FutureBuilder<DailyQuote?>(
                    future: _dailyQuoteFuture,
                    builder: (context, snap) {
                      final q = snap.data;
                      if (q == null) return const SizedBox.shrink();
                      return Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '“${q.quote}”',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontStyle: FontStyle.italic,
                                    height: 1.35,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            Align(
                              alignment: Alignment.centerRight,
                              child: Text(
                                '— ${q.author}',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: Theme.of(context).colorScheme.onSurface.withAlpha(170),
                                    ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),

              // Home actions by user type: Student / Tutor / Stutor
              ValueListenableBuilder<Map<String, dynamic>?>(
                valueListenable: SupabaseService.currentUserProfileCache,
                builder: (context, profile, _) {
                  final userType = (profile?['user_type'] as String?)?.trim().toLowerCase() ?? '';
                  final isStudent = userType == 'student';
                  final isTutor = userType == 'tutor';
                  final isStutor = userType == 'stutor';

                  final actions = <Widget>[];
                  if (isStudent || isStutor) {
                    actions.addAll([
                      _homeActionRow(
                        icon: Icons.search,
                        title: 'Meet Tutors in your area',
                        onTap: () => _openFindNearby(FindNearbySection.meetTutors),
                      ),
                      const SizedBox(height: 10),
                      _homeActionRow(
                        icon: Icons.auto_awesome_outlined,
                        title: 'The Perfect Tutors, Anywhere',
                        onTap: _openTalentMatch,
                      ),
                    ]);
                  }
                  if (isTutor || isStutor) {
                    if (actions.isNotEmpty) actions.add(const SizedBox(height: 10));
                    actions.addAll([
                      _homeActionRow(
                        icon: Icons.groups_outlined,
                        title: 'Other Tutors in the area',
                        onTap: () => _openFindNearby(FindNearbySection.otherTrainers),
                      ),
                      const SizedBox(height: 10),
                      _homeActionRow(
                        icon: Icons.school_outlined,
                        title: 'Student Candidates in the area',
                        onTap: () => _openFindNearby(FindNearbySection.studentCandidates),
                      ),
                    ]);
                  }
                  if (actions.isEmpty) {
                    actions.add(
                      _homeActionRow(
                        icon: Icons.search,
                        title: 'Meet Tutors in your area',
                        onTap: () => _openFindNearby(FindNearbySection.meetTutors),
                      ),
                    );
                  }

                  return Padding(
                    padding: const EdgeInsets.fromLTRB(16, 2, 16, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: actions,
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
                          backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
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
    );
  }
}

