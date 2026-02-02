import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:appinio_swiper/appinio_swiper.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/supabase_service.dart';
import '../theme/app_theme.dart';
import '../utils/distance_formatter.dart';

class FindNearbyTalentScreen extends StatefulWidget {
  const FindNearbyTalentScreen({super.key});

  @override
  State<FindNearbyTalentScreen> createState() => _FindNearbyTalentScreenState();
}

class _FindNearbyTalentScreenState extends State<FindNearbyTalentScreen> {
  final AppinioSwiperController _swiperController = AppinioSwiperController();

  bool _isLoading = true;
  bool _isEndOfDeck = false;
  List<Map<String, dynamic>> _cards = [];
  Set<String> _myKeywordsNorm = <String>{};
  final Map<String, ImageProvider> _imageProviderCache = <String, ImageProvider>{};

  @override
  void initState() {
    super.initState();
    _load();
  }

  String _norm(String s) => s.trim().toLowerCase();

  String? _ageRangeLabel(Map<String, dynamic> p) {
    // Prefer birthdate if present.
    final raw = p['birthdate'] ?? p['birth_date'] ?? p['dob'];
    DateTime? b;
    if (raw is String && raw.trim().isNotEmpty) {
      b = DateTime.tryParse(raw.trim());
    } else if (raw is DateTime) {
      b = raw;
    }
    if (b != null) {
      final now = DateTime.now();
      int age = now.year - b.year;
      final hasHadBirthday = (now.month > b.month) || (now.month == b.month && now.day >= b.day);
      if (!hasHadBirthday) age -= 1;
      age = age.clamp(0, 130);
      final range = (age ~/ 10) * 10;
      return age > 0 ? '${range}s' : null;
    }

    // Fallback: some older schemas store an `age` field.
    final a = p['age'];
    if (a is num) {
      final age = a.toInt();
      final range = (age ~/ 10) * 10;
      return age > 0 ? '${range}s' : null;
    }
    if (a is String) {
      final n = int.tryParse(a.trim());
      if (n != null) {
        final range = (n ~/ 10) * 10;
        return n > 0 ? '${range}s' : null;
      }
    }
    return null;
  }

  String? _lessonLocationLabel(Map<String, dynamic> p) {
    final raw = p['lesson_locations'] ?? p['lesson_location'] ?? p['lesson_methods'];
    final list = _stringListFromDynamic(raw).map(_norm).toList();
    if (list.isEmpty) return null;
    final hasOnline = list.contains('online');
    final hasOnsite = list.contains('onsite') || list.contains('on-site') || list.contains('inperson') || list.contains('in-person');
    if (hasOnline && hasOnsite) return 'Online, Onsite';
    if (hasOnline) return 'Online';
    if (hasOnsite) return 'Onsite';
    return null;
  }

  String? _genderLabel(Map<String, dynamic> p) {
    final raw = (p['gender'] as String?)?.trim();
    if (raw == null || raw.isEmpty) return null;
    final g = raw.toLowerCase();
    if (g == 'prefer not to say' || g == 'prefer_not_to_say' || g == 'unknown') return null;
    if (g == 'man' || g == 'male') return 'Man';
    if (g == 'woman' || g == 'female') return 'Woman';
    if (g == 'non-binary' || g == 'nonbinary') return 'Non-binary';
    return null;
  }

  String? _rateLabel(Map<String, dynamic> p) {
    final raw = p['tutoring_rate'] ?? p['rate'] ?? p['hourly_rate'];
    if (raw == null) return null;
    final s = raw.toString().trim();
    if (s.isEmpty) return null;
    final n = int.tryParse(s.replaceAll(RegExp(r'[^0-9]'), ''));
    if (n == null) return null;
    return '\$$n/hr';
  }

  int _matchCountForTalents(Iterable<String> talents) {
    return talents.where((t) => _myKeywordsNorm.contains(_norm(t))).length;
  }

  int _matchCountForCard(Map<String, dynamic> p) {
    final talents = _stringListFromDynamic(p['talents']);
    return _matchCountForTalents(talents);
  }

  double _distanceMetersForCard(Map<String, dynamic> p) {
    final distMeters = (p['distance_meters'] as num?)?.toDouble();
    // Put unknown distances at the end for sorting.
    return distMeters ?? double.infinity;
  }

  List<String> _stringListFromDynamic(dynamic value) {
    if (value == null) return const [];
    if (value is List) {
      return value.map((e) => e.toString()).where((e) => e.trim().isNotEmpty).toList();
    }
    if (value is String) {
      final trimmed = value.trim();
      if (trimmed.isEmpty) return const [];
      if (trimmed.contains(',')) {
        return trimmed
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();
      }
      return [trimmed];
    }
    return const [];
  }

  ImageProvider? _imageProviderFromPath(String? path) {
    if (path == null || path.isEmpty) return null;

    final cached = _imageProviderCache[path];
    if (cached != null) return cached;

    if (path.startsWith('data:image')) {
      try {
        final base64String = path.split(',')[1];
        final bytes = base64Decode(base64String);
        final provider = MemoryImage(bytes);
        _imageProviderCache[path] = provider;
        return provider;
      } catch (_) {
        return null;
      }
    }

    if (path.startsWith('http://') || path.startsWith('https://')) {
      final provider = NetworkImage(path);
      _imageProviderCache[path] = provider;
      return provider;
    }
    return null;
  }

  String? _pickMainPhoto(Map<String, dynamic> profile) {
    final main = profile['main_photo_path'] as String?;
    if (main != null && main.isNotEmpty) return main;
    final photos = profile['profile_photos'] as List<dynamic>?;
    if (photos != null && photos.isNotEmpty) return photos.first.toString();
    return null;
  }

  Future<void> _precacheTopImages(List<Map<String, dynamic>> cards) async {
    final toPrecache = cards.take(6).toList(growable: false);
    final futures = <Future<void>>[];
    for (final p in toPrecache) {
      final photoPath = _pickMainPhoto(p);
      final provider = _imageProviderFromPath(photoPath);
      if (provider != null) {
        futures.add(precacheImage(provider, context));
      }
    }
    if (futures.isNotEmpty) {
      try {
        await Future.wait(futures);
      } catch (_) {}
    }
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        setState(() {
          _cards = [];
          _isLoading = false;
        });
        return;
      }

      final profile = await SupabaseService.getCurrentUserProfile();
      final userType = (profile?['user_type'] as String?)?.trim().toLowerCase();
      if (userType == null || userType.isEmpty) {
        setState(() {
          _cards = [];
          _isLoading = false;
        });
        return;
      }

      double? lat = SupabaseService.lastKnownLocation.value?.lat;
      double? lon = SupabaseService.lastKnownLocation.value?.lon;
      lat ??= (profile?['latitude'] as num?)?.toDouble();
      lon ??= (profile?['longitude'] as num?)?.toDouble();

      if (lat == null || lon == null) {
        setState(() {
          _cards = [];
          _isLoading = false;
        });
        return;
      }

      final raw = (profile?['talents'] as List<dynamic>?) ?? <dynamic>[];
      final myTalents = raw.map((e) => e.toString()).toList();
      _myKeywordsNorm = myTalents.map(_norm).where((e) => e.isNotEmpty).toSet();

      final cards = await SupabaseService.getMatchingCards(
        // Product requirement:
        // Find Nearby should show TRAINERS only (match my talents with trainer talents).
        // Some deployed RPC versions choose candidates based on p_user_type; passing 'trainee'
        // makes the function return trainers in those versions. We still filter below as a guard.
        userType: 'trainee',
        currentLatitude: lat,
        currentLongitude: lon,
        userTalentsOrGoals: myTalents,
        currentUserId: user.id,
      );

      // Safety: never show trainees in results.
      cards.removeWhere((p) => (p['user_type'] as String?)?.trim().toLowerCase() == 'trainee');

      // Product requirement:
      // "Meet Tutors in Your Area" should only show tutors within 20km.
      const maxDistanceMeters = 20000.0;
      cards.removeWhere((p) {
        final d = (p['distance_meters'] as num?)?.toDouble();
        if (d == null) return true; // unknown distance => exclude for "in your area"
        return d > maxDistanceMeters;
      });

      // Sort cards:
      // 1) more talent matches first
      // 2) if tie, closer first
      // 3) if tie, name A-Z (stable-ish)
      cards.sort((a, b) {
        final ma = _matchCountForCard(a);
        final mb = _matchCountForCard(b);
        if (ma != mb) return mb.compareTo(ma);

        final da = _distanceMetersForCard(a);
        final db = _distanceMetersForCard(b);
        final dcmp = da.compareTo(db);
        if (dcmp != 0) return dcmp;

        final na = (a['name'] as String? ?? '').toLowerCase();
        final nb = (b['name'] as String? ?? '').toLowerCase();
        return na.compareTo(nb);
      });

      if (!mounted) return;
      await _precacheTopImages(cards);
      if (!mounted) return;

      setState(() {
        _cards = cards;
        _isLoading = false;
        _isEndOfDeck = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load nearby: $e')),
      );
    }
  }

  Future<void> _handleSwipeEnd(int previousIndex, int targetIndex, SwiperActivity activity) async {
    if (previousIndex < 0 || previousIndex >= _cards.length) return;
    if (activity is! Swipe) return;

    final direction = activity.direction;
    if (direction != AxisDirection.left && direction != AxisDirection.right) return;

    final currentUser = Supabase.instance.client.auth.currentUser;
    if (currentUser == null) return;

    final card = _cards[previousIndex];
    final swipedUserId = card['user_id'] as String?;
    if (swipedUserId == null || swipedUserId.isEmpty) return;

    final isMatch = direction == AxisDirection.right;
    try {
      await SupabaseService.saveMatch(
        swipedUserId: swipedUserId,
        currentUserId: currentUser.id,
        isMatch: isMatch,
        swipedProfile: card,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save: $e')),
      );
    }
  }

  Widget _buildCircleActionButton({
    required Color color,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.10),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Center(
          child: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 28,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEndOfDeckCard(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Card(
          elevation: 8,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.location_on,
                  size: 44,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 12),
                const Text(
                  'No more nearby results',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Text(
                  'Tap refresh to search again.',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.65),
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _load,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Refresh'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Meet Tutors in Your Area')),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _cards.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'No nearby talent found.',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                        const SizedBox(height: 12),
                        FilledButton.icon(
                          onPressed: _load,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Refresh'),
                        ),
                      ],
                    ),
                  )
                : Column(
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                          child: _isEndOfDeck
                              ? _buildEndOfDeckCard(context)
                              : AppinioSwiper(
                                  controller: _swiperController,
                                  cardCount: _cards.length,
                                  cardBuilder: (context, index) => _buildCard(context, _cards[index]),
                                  swipeOptions: const SwipeOptions.only(left: true, right: true),
                                  backgroundCardCount: 2,
                                  onSwipeEnd: _handleSwipeEnd,
                                  onEnd: () {
                                    if (!mounted) return;
                                    setState(() => _isEndOfDeck = true);
                                  },
                                ),
                        ),
                      ),
                      if (!_isEndOfDeck)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildCircleActionButton(
                                color: Colors.blueGrey,
                                icon: Icons.skip_next,
                                onTap: () => _swiperController.swipeLeft(),
                              ),
                              const SizedBox(width: 40),
                              _buildCircleActionButton(
                                color: Colors.green,
                                icon: Icons.thumb_up_alt,
                                onTap: () => _swiperController.swipeRight(),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
      ),
    );
  }

  Widget _buildCard(BuildContext context, Map<String, dynamic> p) {
    final name = p['name'] as String? ?? 'Unknown';
    final talents = _stringListFromDynamic(p['talents']);

    final distMeters = (p['distance_meters'] as num?)?.toDouble();
    final distanceLabel = distMeters == null ? null : formatDistanceMeters(distMeters);
    final ageRangeLabel = _ageRangeLabel(p);
    final genderLabel = _genderLabel(p);
    final methodLabel = _lessonLocationLabel(p);
    final rateLabel = _rateLabel(p);

    final photoPath = _pickMainPhoto(p);
    final imageProvider = _imageProviderFromPath(photoPath);
    final aboutMe = (p['about_me'] as String?)?.trim() ?? '';

    final matched = <String>[];
    final rest = <String>[];
    for (final t in talents) {
      if (_myKeywordsNorm.contains(_norm(t))) {
        matched.add(t);
      } else {
        rest.add(t);
      }
    }
    final shownTalents = [...matched, ...rest].take(12).toList(growable: false);

    return Card(
      key: ValueKey<String>(p['user_id'] as String? ?? photoPath ?? name),
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: SizedBox(
                  width: 140,
                  height: 140,
                  child: imageProvider == null
                      ? Container(
                          color: Theme.of(context).colorScheme.surfaceContainerHighest,
                          child: Icon(
                            Icons.person,
                            size: 54,
                            color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.6),
                          ),
                        )
                      : RepaintBoundary(
                          child: Image(
                            image: imageProvider,
                            fit: BoxFit.cover,
                            gaplessPlayback: true,
                            filterQuality: FilterQuality.medium,
                          ),
                        ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: Text(
                [
                  name,
                  if (ageRangeLabel != null) ageRangeLabel,
                  if (genderLabel != null) genderLabel,
                ].join(' • '),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
              ),
            ),
            const SizedBox(height: 8),
            if (distanceLabel != null || methodLabel != null)
              Center(
                child: Text(
                  [
                    if (distanceLabel != null) distanceLabel,
                    if (methodLabel != null) methodLabel,
                  ].join('  •  '),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.70),
                      ),
                ),
              ),
            if (aboutMe.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                aboutMe,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.80),
                      height: 1.25,
                    ),
              ),
            ],
            if (shownTalents.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'I can teach',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: shownTalents.map((k) {
                  final isMatch = _myKeywordsNorm.contains(_norm(k));
                  final bg = isMatch ? AppTheme.twinglGreen : Theme.of(context).colorScheme.surfaceContainerHighest;
                  final fg = isMatch ? Colors.white : Theme.of(context).colorScheme.onSurface;
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                    decoration: BoxDecoration(
                      color: bg,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: isMatch ? Colors.transparent : AppTheme.twinglGreen,
                        width: 1.2,
                      ),
                    ),
                    child: Text(
                      k,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: fg,
                            fontWeight: isMatch ? FontWeight.w900 : FontWeight.w700,
                          ),
                    ),
                  );
                }).toList(),
              ),
            ],
            const SizedBox(height: 14),
            Text(
              'Tutoring rate',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              rateLabel ?? '—',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

