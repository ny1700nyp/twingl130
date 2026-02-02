import 'package:flutter/services.dart' show rootBundle;

/// Stub loader (used when dart:io is not available).
Future<String?> loadQuotesJson({
  required String assetPath,
  required String filePath,
}) async {
  try {
    return await rootBundle.loadString(assetPath);
  } catch (_) {
    return null;
  }
}

