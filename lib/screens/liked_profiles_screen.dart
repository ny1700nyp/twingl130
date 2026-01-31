import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
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

  @override
  void initState() {
    super.initState();
    _cacheListener = () {
      final cached = SupabaseService.favoriteTrainersCache.value;
      if (cached == null) return;
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
    if (path.startsWith('data:image')) {
      try {
        final b64 = path.split(',').last;
        return MemoryImage(base64Decode(b64));
      } catch (_) {
        return null;
      }
    }
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return NetworkImage(path);
    }
    if (!kIsWeb) {
      // Avoid importing dart:io here; keep it simple.
      return null;
    }
    return null;
  }

  Future<void> _removeFavorite(String otherUserId) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    if (otherUserId.trim().isEmpty) return;
    if (_removing.contains(otherUserId)) return;

    // Optimistic UI/cache update: remove immediately.
    final removed = _profiles.firstWhere(
      (p) => (p['user_id'] as String?) == otherUserId,
      orElse: () => <String, dynamic>{},
    );

    setState(() {
      _removing.add(otherUserId);
      _profiles = _profiles.where((p) => (p['user_id'] as String?) != otherUserId).toList();
      _isLoading = false;
    });

    final cached = SupabaseService.favoriteTrainersCache.value;
    if (cached != null) {
      SupabaseService.favoriteTrainersCache.value =
          cached.where((p) => (p['user_id'] as String?) != otherUserId).toList();
    }

    // DB delete in background
    () async {
      try {
        await SupabaseService.removeFavorite(
          currentUserId: user.id,
          swipedUserId: otherUserId,
        );

        // Minimal DB touching: only verify if needed (throttled).
        Future.microtask(() => SupabaseService.refreshBootstrapCachesIfChanged(user.id));

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Removed')),
        );
      } catch (e) {
        // If DB delete failed, re-sync from DB (may restore the item).
        await SupabaseService.getFavoriteTrainersCached(user.id, forceRefresh: true);

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to remove: $e')),
        );

        // If cache couldn't restore (e.g. offline), at least re-add locally.
        if (removed.isNotEmpty) {
          final nowCached = SupabaseService.favoriteTrainersCache.value;
          if (nowCached == null || !nowCached.any((p) => (p['user_id'] as String?) == otherUserId)) {
            setState(() {
              _profiles = [..._profiles, Map<String, dynamic>.from(removed)];
            });
          }
        }
      } finally {
        if (mounted) {
          setState(() => _removing.remove(otherUserId));
        }
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

