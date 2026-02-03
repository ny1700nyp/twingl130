import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/supabase_service.dart';
import 'public_profile_screen.dart';

class LikedProfilesScreen extends StatefulWidget {
  const LikedProfilesScreen({super.key});

  @override
  State<LikedProfilesScreen> createState() => _LikedProfilesScreenState();
}

class _LikedProfilesScreenState extends State<LikedProfilesScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _profiles = [];
  late final VoidCallback _cacheListener;
  final Set<String> _removing = <String>{};
  final Map<String, ImageProvider?> _avatarCache = {};

  @override
  void initState() {
    super.initState();
    _cacheListener = () {
      final cached = SupabaseService.favoriteTrainersCache.value;
      if (cached == null) return;
      // 동일한 목록(같은 user_id 순서)이면 setState 생략 → 제거 후 돌아올 때 이중 rebuild로 아바타 깜빡임 방지
      if (_profiles.length == cached.length &&
          _profiles.asMap().entries.every((e) =>
              (e.value['user_id'] as String?) == (cached[e.key]['user_id'] as String?))) {
        return;
      }
      setState(() {
        _profiles = cached;
        _isLoading = false;
      });
    };
    SupabaseService.favoriteTrainersCache.addListener(_cacheListener);
    _load();
  }

  @override
  void dispose() {
    SupabaseService.favoriteTrainersCache.removeListener(_cacheListener);
    super.dispose();
  }

  Future<void> _load({bool force = false}) async {
    setState(() => _isLoading = true);
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        setState(() {
          _profiles = [];
          _isLoading = false;
        });
        return;
      }

      final list = await SupabaseService.getFavoriteTrainersCached(user.id, forceRefresh: force);
      setState(() {
        _profiles = list;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load favorites: $e')),
      );
    }
  }

  ImageProvider? _avatarProvider(String? path) {
    if (path == null || path.isEmpty) return null;
    final cacheKey = path.length > 200 ? path.hashCode.toString() : path;
    if (_avatarCache.containsKey(cacheKey)) return _avatarCache[cacheKey];
    ImageProvider? provider;
    if (path.startsWith('data:image')) {
      try {
        final b64 = path.split(',').last;
        provider = MemoryImage(base64Decode(b64));
      } catch (_) {
        provider = null;
      }
    } else if (path.startsWith('http://') || path.startsWith('https://')) {
      provider = NetworkImage(path);
    }
    if (provider != null) _avatarCache[cacheKey] = provider;
    return provider;
  }

  Future<void> _removeFavorite(String otherUserId) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    if (otherUserId.trim().isEmpty) return;
    if (_removing.contains(otherUserId)) return;

    final target = _profiles.firstWhere(
      (p) => (p['user_id'] as String?) == otherUserId,
      orElse: () => <String, dynamic>{},
    );
    final otherName = (target['name'] as String?)?.trim().isNotEmpty == true
        ? (target['name'] as String).trim()
        : 'this user';

    // Confirm before removing
    if (!mounted) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove favorite?'),
        content: Text('Remove $otherName from your favorites?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Yes'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    // Optimistic UI only: 로컬 _profiles만 갱신. 캐시는 API 성공 후 갱신해 리스너 이중 setState로 인한 깜빡임 방지.
    final removed = target;
    final filtered = _profiles.where((p) => (p['user_id'] as String?) != otherUserId).toList();

    setState(() {
      _removing.add(otherUserId);
      _profiles = filtered;
      _isLoading = false;
    });

    // DB delete in background
    () async {
      try {
        await SupabaseService.removeFavorite(
          currentUserId: user.id,
          swipedUserId: otherUserId,
        );
        // API 성공 후 캐시만 동기화 (리스너는 같은 목록이면 setState 생략하므로 깜빡임 없음).
        final cached = SupabaseService.favoriteTrainersCache.value;
        if (cached != null) {
          SupabaseService.favoriteTrainersCache.value =
              cached.where((p) => (p['user_id'] as String?) != otherUserId).toList();
        }
        Future.microtask(() => SupabaseService.refreshBootstrapCachesIfChanged(user.id));
      } catch (e) {
        // 실패 시 DB에서 다시 불러와서 복구
        await SupabaseService.getFavoriteTrainersCached(user.id, forceRefresh: true);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to remove: $e')),
        );
        if (removed.isNotEmpty) {
          final nowCached = SupabaseService.favoriteTrainersCache.value;
          if (nowCached == null || !nowCached.any((p) => (p['user_id'] as String?) == otherUserId)) {
            setState(() {
              _profiles = [..._profiles, Map<String, dynamic>.from(removed)];
            });
          }
        }
      } finally {
        if (mounted) _removing.remove(otherUserId);
        // setState 없이 _removing만 정리 (이미 리스트에서 제거됐으므로 한 번만 rebuild 유지)
      }
    }();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit my Favorite'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => _load(force: true),
              child: _profiles.isEmpty
                  ? ListView(
                      children: const [
                        SizedBox(height: 120),
                        Center(child: Text('No favorite trainers yet.')),
                      ],
                    )
                  : ListView.builder(
                      itemCount: _profiles.length,
                      itemBuilder: (context, i) {
                        final p = _profiles[i];
                        final name = (p['name'] as String?) ?? 'Unknown';
                        final otherUserId = (p['user_id'] as String?) ?? '';
                        final avatar = _avatarProvider(p['main_photo_path'] as String?);
                        return ListTile(
                          key: ValueKey(otherUserId),
                          leading: CircleAvatar(
                            backgroundImage: avatar,
                            child: avatar == null ? const Icon(Icons.person) : null,
                          ),
                          title: Text(name),
                          trailing: IconButton(
                            tooltip: 'Remove',
                            icon: const Icon(Icons.delete_outline),
                            onPressed:
                                (otherUserId.isEmpty || _removing.contains(otherUserId)) ? null : () => _removeFavorite(otherUserId),
                          ),
                          onTap: otherUserId.isEmpty
                              ? null
                              : () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => PublicProfileScreen(
                                        userId: otherUserId,
                                        currentUserProfile: SupabaseService.currentUserProfileCache.value,
                                      ),
                                    ),
                                  );
                                },
                        );
                      },
                    ),
            ),
    );
  }
}

