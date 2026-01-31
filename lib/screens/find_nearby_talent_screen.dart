import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:appinio_swiper/appinio_swiper.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/supabase_service.dart';
import '../utils/distance_formatter.dart';
import 'profile_detail_screen.dart';

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
  Map<String, dynamic>? _myProfile;
  Set<String> _myKeywordsNorm = <String>{};
  final Map<String, ImageProvider> _imageProviderCache = <String, ImageProvider>{};

  @override
  void initState() {
    super.initState();
    _load();
  }

  String _norm(String s) => s.trim().toLowerCase();

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
      _myProfile = profile;
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

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isMatch ? 'Added to favorites!' : 'Next.'),
          duration: const Duration(seconds: 1),
        ),
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
      appBar: AppBar(title: const Text('Find Nearby Talent')),
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
    final matchCount = _matchCountForTalents(talents);

    final distMeters = (p['distance_meters'] as num?)?.toDouble();
    final distanceLabel = distMeters == null ? '' : 'Within ${formatDistanceMeters(distMeters)}';

    final photoPath = _pickMainPhoto(p);
    final imageProvider = _imageProviderFromPath(photoPath);

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ProfileDetailScreen(
              profile: p,
              currentUserProfile: _myProfile,
            ),
          ),
        );
      },
      child: Card(
        key: ValueKey<String>(p['user_id'] as String? ?? photoPath ?? name),
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Positioned.fill(
              child: imageProvider == null
                  ? Container(
                      color: Theme.of(context).colorScheme.surfaceVariant,
                      child: Icon(
                        Icons.person,
                        size: 96,
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
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.0),
                      Colors.black.withOpacity(0.70),
                    ],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        if (distanceLabel.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Text(
                            distanceLabel,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          'Talent matches: ',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          '$matchCount',
                          style: TextStyle(
                            color: Colors.lightGreenAccent.withOpacity(0.95),
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    if (talents.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: talents.take(12).map((k) {
                          final isMatch = _myKeywordsNorm.contains(_norm(k));
                          final bg = isMatch
                              ? Theme.of(context).colorScheme.primary.withOpacity(0.90)
                              : Colors.white.withOpacity(0.14);
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: bg,
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: isMatch
                                    ? Colors.white.withOpacity(0.18)
                                    : Colors.white.withOpacity(0.08),
                              ),
                            ),
                            child: Text(
                              k,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.95),
                                fontSize: 12,
                                fontWeight: isMatch ? FontWeight.w800 : FontWeight.w600,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

