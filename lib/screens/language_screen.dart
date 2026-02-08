import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../providers/locale_provider.dart';

/// Language selection screen. Options: System Default, then supported locales
/// (Chinese, English, French, German, Japanese, Korean, Spanish).
/// Shows a checkmark next to the currently selected option.
class LanguageScreen extends StatelessWidget {
  const LanguageScreen({super.key});

  static const List<String> _languageCodes = [
    'zh',
    'en',
    'fr',
    'de',
    'ja',
    'ko',
    'es',
  ];

  String _labelForCode(AppLocalizations l10n, String code) {
    switch (code) {
      case 'zh':
        return l10n.languageChinese;
      case 'en':
        return l10n.languageEnglish;
      case 'fr':
        return l10n.languageFrench;
      case 'de':
        return l10n.languageGerman;
      case 'ja':
        return l10n.languageJapanese;
      case 'ko':
        return l10n.languageKorean;
      case 'es':
        return l10n.languageSpanish;
      default:
        return code;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final localeProvider = context.watch<LocaleProvider>();
    final currentLocale = localeProvider.locale;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.language),
      ),
      body: ListView(
        children: [
          ListTile(
            title: Text(l10n.systemDefault),
            trailing: currentLocale == null
                ? const Icon(Icons.check, color: Colors.green)
                : null,
            onTap: () async {
              await localeProvider.clearLocale();
              if (context.mounted) Navigator.of(context).pop();
            },
          ),
          ..._languageCodes.map((code) {
            final isSelected = currentLocale?.languageCode == code;
            return ListTile(
              title: Text(_labelForCode(l10n, code)),
              trailing: isSelected
                  ? const Icon(Icons.check, color: Colors.green)
                  : null,
              onTap: () async {
                await localeProvider.setLocale(Locale(code));
                if (context.mounted) Navigator.of(context).pop();
              },
            );
          }),
        ],
      ),
    );
  }
}
