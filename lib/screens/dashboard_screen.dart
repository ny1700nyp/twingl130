import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/supabase_service.dart';
import 'chat_screen.dart';

class DashboardScreen extends StatefulWidget {
  final int? resetToken;

  const DashboardScreen({super.key, this.resetToken});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int? _lastResetToken;
  final Map<String, ImageProvider> _avatarProviderCache = {};

  @override
  void initState() {
    super.initState();
    _lastResetToken = widget.resetToken;
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      SupabaseService.getChatConversationsCached(user.id);
    }
  }

  @override
  void didUpdateWidget(covariant DashboardScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.resetToken != null && widget.resetToken != _lastResetToken) {
      _lastResetToken = widget.resetToken;
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        SupabaseService.getChatConversationsCached(user.id, forceRefresh: true);
      }
    }
  }

  ImageProvider? _imageProviderForAvatar(String conversationId, String? path) {
    if (path == null || path.isEmpty) return null;
    final cached = _avatarProviderCache[conversationId];
    if (cached != null) return cached;

    ImageProvider? provider;
    if (path.startsWith('data:image')) {
      try {
        provider = MemoryImage(base64Decode(path.split(',').last));
      } catch (_) {}
    } else if (path.startsWith('http://') || path.startsWith('https://')) {
      provider = NetworkImage(path);
    } else if (!kIsWeb) {
      provider = null;
    }

    if (provider != null) {
      _avatarProviderCache[conversationId] = provider;
    }
    return provider;
  }

  String _previewText(Map<String, dynamic>? latest) {
    if (latest == null) return '';
    final type = (latest['type'] as String?) ?? 'text';
    final text = (latest['message_text'] as String?) ?? '';
    if (type == 'request') return 'Request';
    if (type == 'system') return text;
    return text;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chat')),
      body: ValueListenableBuilder<List<Map<String, dynamic>>?>(
        valueListenable: SupabaseService.chatConversationsCache,
        builder: (context, value, _) {
          final user = Supabase.instance.client.auth.currentUser;
          if (user == null) {
            return const Center(child: Text('Please log in.'));
          }
          if (value == null) {
            return const Center(child: CircularProgressIndicator());
          }

          final list = value;
          if (list.isEmpty) {
            return RefreshIndicator(
              onRefresh: () => SupabaseService.getChatConversationsCached(user.id, forceRefresh: true),
              child: ListView(
                children: const [
                  SizedBox(height: 120),
                  Center(child: Text('No conversations yet.')),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => SupabaseService.getChatConversationsCached(user.id, forceRefresh: true),
            child: ListView.separated(
              itemCount: list.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final c = list[i];
                final conversationId = c['id']?.toString() ?? '';
                if (conversationId.isEmpty) return const SizedBox.shrink();

                final otherProfile = c['other_profile'] as Map<String, dynamic>?;
                final otherName = (otherProfile?['name'] as String?) ?? 'Unknown';
                final avatarPath = otherProfile?['main_photo_path'] as String?;
                final avatar = _imageProviderForAvatar(conversationId, avatarPath);

                final unreadCount = (c['unread_count'] as num?)?.toInt() ?? 0;
                final latest = c['latest_message'] as Map<String, dynamic>?;
                final otherUserId = (c['other_user_id'] as String?) ??
                    (otherProfile?['user_id'] as String?) ??
                    '';

                return ListTile(
                  key: ValueKey(conversationId),
                  leading: CircleAvatar(
                    backgroundImage: avatar,
                    child: avatar == null ? const Icon(Icons.person) : null,
                  ),
                  title: Row(
                    children: [
                      Expanded(child: Text(otherName)),
                      if (unreadCount > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade700,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            unreadCount.toString(),
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                          ),
                        ),
                    ],
                  ),
                  subtitle: Text(
                    _previewText(latest),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: otherUserId.isEmpty
                      ? null
                      : () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => ChatScreen(
                                conversationId: conversationId,
                                otherUserId: otherUserId,
                                otherProfile: otherProfile,
                              ),
                            ),
                          );
                          // Background refresh when returning.
                          SupabaseService.refreshChatConversationsIfChanged(user.id);
                        },
                );
              },
            ),
          );
        },
      ),
    );
  }
}

