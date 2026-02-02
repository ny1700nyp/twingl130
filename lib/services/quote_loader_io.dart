import 'dart:io';

import 'package:flutter/services.dart' show rootBundle;

/// IO-capable loader:
/// - prefer bundled asset (works across platforms)
/// - fallback to local file path (dev convenience)
Future<String?> loadQuotesJson({
  required String assetPath,
  required String filePath,
}) async {
  try {
    return await rootBundle.loadString(assetPath);
  } catch (_) {
    // ignore
  }

  try {
    final f = File(filePath);
    if (await f.exists()) {
      return await f.readAsString();
    }
  } catch (_) {
    // ignore
  }

  return null;
}

