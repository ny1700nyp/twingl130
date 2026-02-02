import 'dart:convert';

import '../utils/time_utils.dart';
import 'quote_loader_stub.dart'
    if (dart.library.io) 'quote_loader_io.dart';

class DailyQuote {
  final String quote;
  final String author;

  const DailyQuote({
    required this.quote,
    required this.author,
  });
}

class QuoteService {
  QuoteService._();

  static const String quotesAssetPath = 'assets/quotes.json';
  static const String quotesFilePath = r'C:\Users\ny170\Downloads\quote.json';

  static List<DailyQuote>? _cachedQuotes;
  static final Map<String, DailyQuote> _cachedDailyByKey = {};

  static Future<List<DailyQuote>> _loadAllQuotes() async {
    if (_cachedQuotes != null) return _cachedQuotes!;

    final raw = await loadQuotesJson(
      assetPath: quotesAssetPath,
      filePath: quotesFilePath,
    );
    if (raw == null || raw.trim().isEmpty) {
      _cachedQuotes = const <DailyQuote>[];
      return _cachedQuotes!;
    }

    try {
      final decoded = jsonDecode(raw);

      final List<dynamic> list;
      if (decoded is List) {
        list = decoded;
      } else if (decoded is Map && decoded['quotes'] is List) {
        list = decoded['quotes'] as List;
      } else {
        _cachedQuotes = const <DailyQuote>[];
        return _cachedQuotes!;
      }

      final out = <DailyQuote>[];
      for (final e in list) {
        if (e is! Map) continue;
        final q = (e['quote'] ?? e['text'] ?? '').toString().trim();
        final a = (e['author'] ?? '').toString().trim();
        if (q.isEmpty) continue;
        out.add(DailyQuote(quote: q, author: a.isEmpty ? 'Unknown' : a));
      }

      _cachedQuotes = out;
      return out;
    } catch (_) {
      _cachedQuotes = const <DailyQuote>[];
      return _cachedQuotes!;
    }
  }

  static int _stableHash32(String s) {
    // FNV-1a 32-bit
    var hash = 0x811c9dc5;
    for (final unit in s.codeUnits) {
      hash ^= unit;
      hash = (hash * 0x01000193) & 0xffffffff;
    }
    return hash & 0x7fffffff;
  }

  static Future<DailyQuote?> getDailyQuote({String? userId}) async {
    final now = TimeUtils.nowLocal();
    final dayKey = '${now.year.toString().padLeft(4, '0')}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
    final salt = (userId ?? 'global').trim();
    final key = '$dayKey|$salt';

    final cached = _cachedDailyByKey[key];
    if (cached != null) return cached;

    final list = await _loadAllQuotes();
    if (list.isEmpty) return null;

    final seed = _stableHash32(key);
    final idx = seed % list.length;
    final chosen = list[idx];
    _cachedDailyByKey[key] = chosen;
    return chosen;
  }
}

