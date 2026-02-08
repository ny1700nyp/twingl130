import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../l10n/app_localizations.dart';
import '../services/supabase_service.dart';
import '../widgets/avatar_with_type_badge.dart';

enum UserManagementMode { deleteFromLiked, block, unblock }

class UserManagementScreen extends StatefulWidget {
  final UserManagementMode mode;

  const UserManagementScreen({super.key, required this.mode});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _profiles = [];
  final Set<String> _selectedIds = {};
  final Map<String, ImageProvider?> _avatarCache = {};

  String _title(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    switch (widget.mode) {
      case UserManagementMode.deleteFromLiked:
        return l10n.deleteUser;
      case UserManagementMode.block:
        return l10n.blockUser;
      case UserManagementMode.unblock:
        return l10n.unblockUser;
    }
  }

  String _emptyMessage(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    switch (widget.mode) {
      case UserManagementMode.deleteFromLiked:
        return l10n.noLikedUsers;
      case UserManagementMode.block:
        return l10n.noUsersToBlockFromLikedList;
      case UserManagementMode.unblock:
        return l10n.noBlockedUsers;
    }
  }

  String _actionButtonLabel(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    switch (widget.mode) {
      case UserManagementMode.deleteFromLiked:
        return l10n.removeFromLiked;
      case UserManagementMode.block:
        return l10n.blockSelected;
      case UserManagementMode.unblock:
        return l10n.unblockSelected;
    }
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      setState(() {
        _profiles = [];
        _isLoading = false;
      });
      return;
    }

    setState(() => _isLoading = true);
    try {
      List<Map<String, dynamic>> list;
      if (widget.mode == UserManagementMode.unblock) {
        list = await SupabaseService.getBlockedProfiles(user.id);
      } else {
        list = await SupabaseService.getLikedProfiles(user.id);
      }
      setState(() {
        _profiles = list;
        _selectedIds.clear();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load: $e')),
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

  Future<void> _performAction() async {
    if (_selectedIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.selectAtLeastOneUser)),
      );
      return;
    }

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    final l10n = AppLocalizations.of(context)!;
    final confirmMessage = switch (widget.mode) {
      UserManagementMode.deleteFromLiked =>
        l10n.removeUsersFromLikedConfirm(_selectedIds.length),
      UserManagementMode.block =>
        l10n.blockUsersConfirm(_selectedIds.length),
      UserManagementMode.unblock =>
        l10n.unblockUsersConfirm(_selectedIds.length),
    };

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(_actionButtonLabel(context)),
        content: Text(confirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.confirm),
          ),
        ],
      ),
    );

    if (ok != true || !mounted) return;

    bool hadError = false;
    for (final id in _selectedIds) {
      try {
        switch (widget.mode) {
          case UserManagementMode.deleteFromLiked:
            await SupabaseService.removeFavorite(
              currentUserId: user.id,
              swipedUserId: id,
            );
            await SupabaseService.removeFavoriteTabAssignment(
              user.id,
              id,
              bumpVersion: false,
            );
            break;
          case UserManagementMode.block:
            await SupabaseService.blockUser(user.id, id, bumpVersion: true);
            break;
          case UserManagementMode.unblock:
            await SupabaseService.unblockUser(user.id, id);
            break;
        }
      } catch (_) {
        hadError = true;
      }
    }

    if (!mounted) return;
    if (hadError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.someActionsFailed)),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.usersUpdated(_selectedIds.length))),
      );
      if (widget.mode == UserManagementMode.deleteFromLiked) {
        await SupabaseService.getFavoriteTrainersCached(user.id, forceRefresh: true);
        SupabaseService.favoriteFromChatVersion.value++;
      } else if (widget.mode == UserManagementMode.block) {
        SupabaseService.favoriteFromChatVersion.value++;
      }
      SupabaseService.refreshBootstrapCachesIfChanged(user.id);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_title(context)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _profiles.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      _emptyMessage(context),
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        itemCount: _profiles.length,
                        itemBuilder: (context, i) {
                          final p = _profiles[i];
                          final userId = (p['user_id'] as String?) ?? '';
                          final name = (p['name'] as String?)?.trim().isEmpty != true
                              ? (p['name'] as String?)!.trim()
                              : 'Unknown';
                          final selected = _selectedIds.contains(userId);
                          final avatar = _avatarProvider(p['main_photo_path'] as String?);
                          return CheckboxListTile(
                            value: selected,
                            onChanged: (v) {
                              setState(() {
                                if (v == true) {
                                  _selectedIds.add(userId);
                                } else {
                                  _selectedIds.remove(userId);
                                }
                              });
                            },
                            secondary: AvatarWithTypeBadge(
                              radius: 22,
                              backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                              backgroundImage: avatar,
                              userType: p['user_type'] as String?,
                            ),
                            title: Text(name),
                            activeColor: Theme.of(context).colorScheme.primary,
                          );
                        },
                      ),
                    ),
                    SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                        child: SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: _selectedIds.isEmpty ? null : _performAction,
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              _actionButtonLabel(context) +
                                  (_selectedIds.isEmpty ? '' : ' (${_selectedIds.length})'),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}
