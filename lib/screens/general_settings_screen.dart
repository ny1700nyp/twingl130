import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../app_navigation.dart' show navigatorKey;
import '../l10n/app_localizations.dart';
import '../services/supabase_service.dart';

class GeneralSettingsScreen extends StatefulWidget {
  const GeneralSettingsScreen({super.key});

  @override
  State<GeneralSettingsScreen> createState() => _GeneralSettingsScreenState();
}

class _GeneralSettingsScreenState extends State<GeneralSettingsScreen> {
  bool _isDeleting = false;

  Future<void> _onDeleteAccountTap() async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        final l10n = AppLocalizations.of(context)!;
        return AlertDialog(
          title: Text(l10n.leaveTwingl),
          content: Text(l10n.leaveTwinglDialogMessage),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(l10n.no),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
              child: Text(l10n.yes),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    setState(() => _isDeleting = true);
    try {
      await SupabaseService.resetUserDataForReOnboarding();
      if (!mounted) return;
      await SupabaseService.clearDiskCacheForUser(userId);
      SupabaseService.clearInMemoryCaches();
      if (!mounted) return;
      await Supabase.instance.client.auth.signOut();
      if (!mounted) return;
      navigatorKey.currentState?.pushNamedAndRemoveUntil('/login', (_) => false);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.failedToLeaveTwingl(e.toString())),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.generalSettings),
      ),
      body: SafeArea(
        child: ListView(
          children: [
            ListTile(
              leading: Icon(
                Icons.delete_forever_outlined,
                color: Theme.of(context).colorScheme.error,
              ),
              title: Text(
                AppLocalizations.of(context)!.leaveTwingl,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontWeight: FontWeight.w500,
                ),
              ),
              subtitle: Text(AppLocalizations.of(context)!.clearLikedBlockedChatHistory),
              enabled: !_isDeleting,
              onTap: _isDeleting ? null : _onDeleteAccountTap,
              trailing: _isDeleting
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
