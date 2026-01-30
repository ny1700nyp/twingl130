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
    try {
      await SupabaseService.removeFavorite(
        currentUserId: user.id,
        swipedUserId: otherUserId,
      );
      await SupabaseService.getFavoriteTrainersCached(user.id, forceRefresh: true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to remove: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Favorite Trainer'),
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
                  : ListView.separated(
                      itemCount: _profiles.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
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
                          subtitle: Text(otherUserId),
                          trailing: IconButton(
                            tooltip: 'Remove',
                            icon: const Icon(Icons.delete_outline),
                            onPressed: otherUserId.isEmpty ? null : () => _removeFavorite(otherUserId),
                          ),
                          onTap: otherUserId.isEmpty
                              ? null
                              : () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => PublicProfileScreen(userId: otherUserId),
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

