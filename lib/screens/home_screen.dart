import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import '../services/supabase_service.dart';
import '../widgets/avatar_with_type_badge.dart';
import '../widgets/twingl_wordmark.dart';
import 'edit_trainers_screen.dart';
import 'find_nearby_talent_screen.dart';
import 'general_settings_screen.dart';
import 'global_talent_matching_screen.dart';
import 'onboarding_screen.dart';
import 'profile_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isResolvingCity = false;
  late final VoidCallback _locationListener;
  final Map<String, ImageProvider> _avatarProviderCache = <String, ImageProvider>{};
  /// Logical tab index: 0=Tutors, 1=Students, 2=Fellows. Visibility depends on user type.
  int _favoriteLogicalIndex = 0;

  List<Map<String, dynamic>>? _cachedFavoriteTutors;
  List<Map<String, dynamic>>? _cachedFavoriteStudents;
  List<Map<String, dynamic>>? _cachedFavoriteFellows;
  /// One in-flight future per tab so we do not restart fetch on every build (avoids N+1 / server exhaustion).
  Future<List<Map<String, dynamic>>>? _inFlightFavoriteTutors;
  Future<List<Map<String, dynamic>>>? _inFlightFavoriteStudents;
  Future<List<Map<String, dynamic>>>? _inFlightFavoriteFellows;
  void Function()? _favAddedListenerRef;
  void _invalidateFavoriteTabCache() {
    if (mounted) {
      setState(() {
      _cachedFavoriteTutors = null;
      _cachedFavoriteStudents = null;
      _cachedFavoriteFellows = null;
      _inFlightFavoriteTutors = null;
      _inFlightFavoriteStudents = null;
      _inFlightFavoriteFellows = null;
    });
    }
  }

  /// Preload all three Favorite tab lists in background so tab switch is instant.
  void _preloadFavoriteTabCaches(String userId) {
    SupabaseService.getFavoriteTutorsTabList(userId).then((list) {
      if (mounted) setState(() => _cachedFavoriteTutors = list);
    });
    SupabaseService.getFavoriteStudentsTabList(userId).then((list) {
      if (mounted) setState(() => _cachedFavoriteStudents = list);
    });
    SupabaseService.getFavoriteFellowsTabList(userId).then((list) {
      if (mounted) setState(() => _cachedFavoriteFellows = list);
    });
  }

  /// Optimistic: remove one user from all tab caches so UI updates immediately.
  void _removeUserFromFavoriteCaches(String otherUserId) {
    if (!mounted) return;
    setState(() {
      _cachedFavoriteTutors = _cachedFavoriteTutors?.where((p) => (p['user_id'] as String?) != otherUserId).toList();
      _cachedFavoriteStudents = _cachedFavoriteStudents?.where((p) => (p['user_id'] as String?) != otherUserId).toList();
      _cachedFavoriteFellows = _cachedFavoriteFellows?.where((p) => (p['user_id'] as String?) != otherUserId).toList();
    });
  }

  /// Optimistic: add one profile to the given Favorite tab cache (avoids refetch after like).
  void _onFavoriteTabAdded(({String tab, Map<String, dynamic> profile})? payload) {
    if (payload == null || !mounted) return;
    final profile = Map<String, dynamic>.from(payload.profile);
    final userId = (profile['user_id'] as String?)?.trim() ?? '';
    if (userId.isEmpty) return;
    SupabaseService.favoriteTabAdded.value = null;
    setState(() {
      switch (payload.tab) {
        case 'tutor':
          final list = _cachedFavoriteTutors ?? [];
          if (list.any((p) => (p['user_id'] as String?) == userId)) return;
          _cachedFavoriteTutors = [...list, profile]..sort((a, b) => ((a['name'] as String?) ?? '').compareTo((b['name'] as String?) ?? ''));
          break;
        case 'student':
          final list = _cachedFavoriteStudents ?? [];
          if (list.any((p) => (p['user_id'] as String?) == userId)) return;
          _cachedFavoriteStudents = [...list, profile]..sort((a, b) => ((a['name'] as String?) ?? '').compareTo((b['name'] as String?) ?? ''));
          break;
        case 'fellow':
          final list = _cachedFavoriteFellows ?? [];
          if (list.any((p) => (p['user_id'] as String?) == userId)) return;
          _cachedFavoriteFellows = [...list, profile]..sort((a, b) => ((a['name'] as String?) ?? '').compareTo((b['name'] as String?) ?? ''));
          break;
      }
    });
  }

  @override
  void initState() {
    super.initState();
    SupabaseService.favoriteFromChatVersion.addListener(_invalidateFavoriteTabCache);
    void favAddedListener() {
      final payload = SupabaseService.favoriteTabAdded.value;
      if (payload != null) _onFavoriteTabAdded(payload);
    }
    SupabaseService.favoriteTabAdded.addListener(favAddedListener);
    _favAddedListenerRef = favAddedListener;
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      // Ensure disk caches hydrate before running the "only-if-changed" refresh.
      () async {
        await SupabaseService.getCurrentUserProfileCached(user.id);
        await SupabaseService.getFavoriteTrainersCached(user.id);
        await SupabaseService.refreshBootstrapCachesIfChanged(user.id);
      }();
      _preloadFavoriteTabCaches(user.id);
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
    if (_favAddedListenerRef != null) SupabaseService.favoriteTabAdded.removeListener(_favAddedListenerRef!);
    SupabaseService.favoriteFromChatVersion.removeListener(_invalidateFavoriteTabCache);
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

  Widget _buildFavoriteTabList(
    BuildContext context,
    List<Map<String, dynamic>> list,
    int tabIndex,
  ) {
    if (list.isEmpty) {
      final l10n = AppLocalizations.of(context)!;
      final msg = tabIndex == 0
          ? l10n.noTutorsYet
          : tabIndex == 1
              ? l10n.noStudentsYet
              : l10n.noFellowsYet;
      return Padding(
        padding: const EdgeInsets.only(top: 24),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              msg,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  ),
            ),
          ),
        ),
      );
    }
    return ValueListenableBuilder<Map<String, dynamic>?>(
      valueListenable: SupabaseService.currentUserProfileCache,
      builder: (context, myProfile, __) => ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: list.length,
        itemBuilder: (context, i) {
          final p = list[i];
          final name = (p['name'] as String?)?.trim();
          final userId = (p['user_id'] as String?)?.trim() ?? '';
          final avatarPath = p['main_photo_path'] as String?;
          final avatar = _imageProviderFromPath(avatarPath);
          final chips = SupabaseService.getFavoriteMatchingChips(myProfile, p);
          final hasChips = chips.goalTalent.isNotEmpty || chips.talentGoal.isNotEmpty;
          return ListTile(
            key: ValueKey(userId),
            leading: AvatarWithTypeBadge(
              radius: 22,
              backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
              backgroundImage: avatar,
              userType: p['user_type'] as String?,
            ),
            title: Text(name?.isNotEmpty == true ? name! : 'Unknown'),
            subtitle: hasChips ? _buildMatchingChips(context, chips) : null,
            isThreeLine: hasChips,
            onTap: userId.isEmpty
                ? null
                : () => showProfileDetailSheet(
                      context,
                      userId: userId,
                      currentUserProfile: SupabaseService.currentUserProfileCache.value,
                      hideActionButtons: false,
                      hideDistance: true,
                    ),
            onLongPress: userId.isEmpty ? null : () => _showFavoriteItemMenu(context, name: name?.isNotEmpty == true ? name! : AppLocalizations.of(context)!.unknownName, otherUserId: userId),
          );
        },
      ),
    );
  }

  Future<void> _showFavoriteItemMenu(BuildContext context, {required String name, required String otherUserId}) async {
    final currentUser = Supabase.instance.client.auth.currentUser;
    if (currentUser == null) return;
    if (!context.mounted) return;
    final choice = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Text(
                name,
                style: Theme.of(ctx).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: Text(AppLocalizations.of(ctx)!.delete),
              onTap: () => Navigator.of(ctx).pop('delete'),
            ),
            ListTile(
              leading: const Icon(Icons.block),
              title: Text(AppLocalizations.of(ctx)!.block),
              onTap: () => Navigator.of(ctx).pop('block'),
            ),
          ],
        ),
      ),
    );
    if (choice == null || !context.mounted) return;
    if (choice == 'delete') {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) {
          final l10n = AppLocalizations.of(ctx)!;
          return AlertDialog(
            title: Text(l10n.removeFromFavoriteTitle),
            content: Text(l10n.removeFromFavoriteConfirmMessage),
            actions: [
              TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: Text(l10n.cancel)),
              TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: Text(l10n.delete)),
            ],
          );
        },
      );
      if (confirm == true && context.mounted) {
        _removeUserFromFavoriteCaches(otherUserId);
        Future.microtask(() => SupabaseService.removeFavoriteTabAssignment(currentUser.id, otherUserId, bumpVersion: false));
      }
    } else if (choice == 'block') {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) {
          final l10n = AppLocalizations.of(ctx)!;
          return AlertDialog(
            title: Text(l10n.block),
            content: Text(l10n.blockUserConfirmMessage),
            actions: [
              TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: Text(l10n.cancel)),
              TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: Text(l10n.block)),
            ],
          );
        },
      );
      if (confirm == true && context.mounted) {
        _removeUserFromFavoriteCaches(otherUserId);
        Future.microtask(() async {
          await SupabaseService.blockUser(currentUser.id, otherUserId, bumpVersion: false);
          await SupabaseService.getChatConversationsCached(currentUser.id, forceRefresh: true);
        });
      }
    }
  }

  Widget _buildMatchingChips(
    BuildContext context,
    ({List<String> goalTalent, List<String> talentGoal}) chips,
  ) {
    final list = <Widget>[];
    for (final label in chips.goalTalent) {
      list.add(
        Padding(
          padding: const EdgeInsets.only(right: 4, bottom: 2),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppTheme.twinglPurple.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.twinglPurple, width: 1),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: AppTheme.twinglPurple,
              ),
            ),
          ),
        ),
      );
    }
    for (final label in chips.talentGoal) {
      list.add(
        Padding(
          padding: const EdgeInsets.only(right: 4, bottom: 2),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppTheme.twinglMint.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.twinglMint, width: 1),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: AppTheme.twinglMint,
              ),
            ),
          ),
        ),
      );
    }
    if (list.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        children: list,
      ),
    );
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
          return const TwinglWordmark(fontSize: 30, fontWeight: FontWeight.w800);
        }

        // City label is display-only (do not allow tapping).
        return Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const TwinglWordmark(fontSize: 30, fontWeight: FontWeight.w800),
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
                    leading: AvatarWithTypeBadge(
                      radius: 22,
                      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                      backgroundImage: avatar,
                      userType: profile?['user_type'] as String?,
                    ),
                    title: Text(name?.isNotEmpty == true ? name! : 'My Profile'),
                    onTap: () => _onSelectSettings('my_profile'),
                  );
                },
              ),

              // Home actions by user type: Student / Tutor / Twiner
              ValueListenableBuilder<Map<String, dynamic>?>(
                valueListenable: SupabaseService.currentUserProfileCache,
                builder: (context, profile, _) {
                  final userType = (profile?['user_type'] as String?)?.trim().toLowerCase() ?? '';
                  final isStudent = userType == 'student';
                  final isTutor = userType == 'tutor';
                  final isTwiner = userType == 'twiner';

                  final actions = <Widget>[];
                  if (isStudent || isTwiner) {
                    actions.addAll([
                      _homeActionRow(
                        icon: Icons.search,
                        title: AppLocalizations.of(context)!.meetTutorsInArea,
                        onTap: () => _openFindNearby(FindNearbySection.meetTutors),
                      ),
                      const SizedBox(height: 10),
                      _homeActionRow(
                        icon: Icons.auto_awesome_outlined,
                        title: AppLocalizations.of(context)!.perfectTutorsAnywhere,
                        onTap: _openTalentMatch,
                      ),
                    ]);
                  }
                  if (isTutor || isTwiner) {
                    if (actions.isNotEmpty) actions.add(const SizedBox(height: 10));
                    actions.addAll([
                      _homeActionRow(
                        icon: Icons.groups_outlined,
                        title: AppLocalizations.of(context)!.fellowTutorsInArea,
                        onTap: () => _openFindNearby(FindNearbySection.otherTrainers),
                      ),
                      const SizedBox(height: 10),
                      _homeActionRow(
                        icon: Icons.school_outlined,
                        title: AppLocalizations.of(context)!.studentCandidatesInArea,
                        onTap: () => _openFindNearby(FindNearbySection.studentCandidates),
                      ),
                    ]);
                  }
                  if (actions.isEmpty) {
                    actions.add(
                      _homeActionRow(
                        icon: Icons.search,
                        title: AppLocalizations.of(context)!.meetTutorsInArea,
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

              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Text(
                  AppLocalizations.of(context)!.likedSectionTitle,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),

              // Favorite tabs by user type: Student → Tutors only; Tutor → Students + Fellows; Twiner → all three
              ValueListenableBuilder<Map<String, dynamic>?>(
                valueListenable: SupabaseService.currentUserProfileCache,
                builder: (context, profile, _) {
                  final userType = (profile?['user_type'] as String?)?.trim().toLowerCase() ?? '';
                  final isStudent = userType == 'student';
                  final isTutor = userType == 'tutor';
                  final visibleTabIndices = isStudent
                      ? <int>[0]
                      : isTutor
                          ? <int>[1, 2]
                          : <int>[0, 1, 2]; // Twiner or fallback: all
                  final effectiveIndex = visibleTabIndices.contains(_favoriteLogicalIndex)
                      ? _favoriteLogicalIndex
                      : visibleTabIndices.first;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (visibleTabIndices.length > 1)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.6),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: List.generate(visibleTabIndices.length, (i) {
                                final logicalIndex = visibleTabIndices[i];
                                final l10n = AppLocalizations.of(context)!;
                                final label = logicalIndex == 0
                                    ? l10n.tabTutors
                                    : logicalIndex == 1
                                        ? l10n.tabStudents
                                        : l10n.tabFellows;
                                final selected = effectiveIndex == logicalIndex;
                                return Expanded(
                                  child: GestureDetector(
                                    onTap: () => setState(() => _favoriteLogicalIndex = logicalIndex),
                                    behavior: HitTestBehavior.opaque,
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 150),
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(8),
                                        color: selected
                                            ? AppTheme.primaryGreen
                                            : Colors.transparent,
                                        boxShadow: selected
                                            ? [
                                                BoxShadow(
                                                  color: AppTheme.primaryGreen.withOpacity(0.3),
                                                  blurRadius: 4,
                                                  offset: const Offset(0, 1),
                                                ),
                                              ]
                                            : null,
                                      ),
                                      child: Text(
                                        label,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                                          fontSize: 13,
                                          color: selected
                                              ? Colors.white
                                              : Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }),
                            ),
                          ),
                        ),
                      if (visibleTabIndices.length > 1) const SizedBox(height: 6),

                      ValueListenableBuilder<int>(
                        valueListenable: SupabaseService.favoriteFromChatVersion,
                        builder: (context, version, __) {
                          final user = Supabase.instance.client.auth.currentUser;
                          if (user == null) {
                            return const Padding(
                              padding: EdgeInsets.only(top: 24),
                              child: Center(child: Text('Sign in to see liked')),
                            );
                          }
                          final tabIndex = effectiveIndex;
                          final cachedList = tabIndex == 0
                              ? _cachedFavoriteTutors
                              : tabIndex == 1
                                  ? _cachedFavoriteStudents
                                  : _cachedFavoriteFellows;

                          if (cachedList != null) {
                            return _buildFavoriteTabList(context, cachedList, tabIndex);
                          }

                          // Use a single in-flight future per tab so rebuilds do not restart the fetch.
                          Future<List<Map<String, dynamic>>> future;
                          switch (tabIndex) {
                            case 0:
                              future = _inFlightFavoriteTutors ??= SupabaseService.getFavoriteTutorsTabList(user.id);
                              break;
                            case 1:
                              future = _inFlightFavoriteStudents ??= SupabaseService.getFavoriteStudentsTabList(user.id);
                              break;
                            default:
                              future = _inFlightFavoriteFellows ??= SupabaseService.getFavoriteFellowsTabList(user.id);
                          }
                          return FutureBuilder<List<Map<String, dynamic>>>(
                            key: ValueKey('fav_${tabIndex}_$version'),
                            future: future,
                            builder: (context, snap) {
                              if (snap.connectionState == ConnectionState.waiting) {
                                return const Padding(
                                  padding: EdgeInsets.only(top: 24),
                                  child: Center(child: CircularProgressIndicator()),
                                );
                              }
                              final list = snap.data ?? [];
                              if (snap.connectionState == ConnectionState.done) {
                                WidgetsBinding.instance.addPostFrameCallback((_) {
                                  if (!mounted) return;
                                  setState(() {
                                    if (tabIndex == 0) {
                                      if (snap.hasData) _cachedFavoriteTutors = list;
                                      _inFlightFavoriteTutors = null;
                                    } else if (tabIndex == 1) {
                                      if (snap.hasData) _cachedFavoriteStudents = list;
                                      _inFlightFavoriteStudents = null;
                                    } else {
                                      if (snap.hasData) _cachedFavoriteFellows = list;
                                      _inFlightFavoriteFellows = null;
                                    }
                                  });
                                });
                              }
                              return _buildFavoriteTabList(context, list, tabIndex);
                            },
                          );
                        },
                      ),
                    ],
                  );
                },
              ),
            ],
        ),
      ),
    );
  }
}

