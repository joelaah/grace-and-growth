import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Service responsible for fetching Scripture text from the free, static,
/// no-API-key Free Use Bible API (https://bible.helloao.org).
///
/// Automatically caches fetched chapters in [SharedPreferences] so that the app
/// works 100% offline after the initial read and incurs $0 ongoing costs.
class BibleApiService {
  static const String baseUrl = 'https://bible.helloao.org/api';

  /// Default translation mappings for supported app language codes.
  static const Map<String, String> defaultTranslations = {
    'eng': 'BSB',       // Berean Standard Bible (English, Public Domain)
    'spa': 'spa_r09',   // Reina Valera 1909 (Spanish, Public Domain)
    'hin': 'HINIRV',    // Indian Revised Version (Hindi)
    'lus': 'BSB',       // Lushai/Mizo fallback to English when offline/remote unavailable
  };

  final SharedPreferences? _prefs;
  final http.Client? _httpClient;

  BibleApiService({
    SharedPreferences? prefs,
    http.Client? httpClient,
  })  : _prefs = prefs,
        _httpClient = httpClient;

  http.Client get _client => _httpClient ?? http.Client();

  Future<SharedPreferences> get _preferences async =>
      _prefs ?? await SharedPreferences.getInstance();

  /// Resolves a language or translation code to a helloao-compatible translation ID.
  String resolveTranslation(String langOrTranslation) {
    final lower = langOrTranslation.toLowerCase().trim();
    if (defaultTranslations.containsKey(lower)) {
      return defaultTranslations[lower]!;
    }
    return langOrTranslation;
  }

  /// Cache key generator for storing complete chapters locally.
  String chapterCacheKey(String translation, String book, int chapter) {
    return 'bible_chapter_${translation.toUpperCase()}_${book.toUpperCase()}_$chapter';
  }

  /// Fetches verse text by universal ID (e.g. `PSA.34.18`) and language/translation code.
  ///
  /// Checks local [SharedPreferences] first; if not present, downloads the chapter,
  /// saves it to local cache, and extracts the target verse text.
  Future<String?> getVerseText({
    required String universalId,
    String langOrTranslation = 'eng',
  }) async {
    final parsed = parseUniversalId(universalId);
    if (parsed == null) return null;

    final translation = resolveTranslation(langOrTranslation);
    final book = parsed.book.toUpperCase();
    final chapter = parsed.chapter;
    final verse = parsed.verse;

    final chapterData = await getChapterJson(
      book: book,
      chapter: chapter,
      translation: translation,
    );

    if (chapterData == null) return null;
    return extractVerseFromChapter(chapterData, verse);
  }

  /// Retrieves chapter JSON either from local cache or via HTTP.
  Future<Map<String, dynamic>?> getChapterJson({
    required String book,
    required int chapter,
    required String translation,
  }) async {
    final prefs = await _preferences;
    final cacheKey = chapterCacheKey(translation, book, chapter);

    // 1. Check local offline cache
    final cached = prefs.getString(cacheKey);
    if (cached != null && cached.isNotEmpty) {
      try {
        final decoded = jsonDecode(cached);
        if (decoded is Map<String, dynamic>) {
          return decoded;
        }
      } catch (_) {
        // Corrupted cache entry; proceed to fetch
      }
    }

    // 2. Fetch from static remote API
    final url = Uri.parse('$baseUrl/$translation/$book/$chapter.json');
    try {
      final response = await _client.get(url);
      if (response.statusCode == 200) {
        final body = response.body;
        // Cache immediately in local storage for offline use
        await prefs.setString(cacheKey, body);
        final decoded = jsonDecode(body);
        if (decoded is Map<String, dynamic>) {
          return decoded;
        }
      }
    } catch (_) {
      // Offline or network error: return null so caller can use bundled seed fallback
      return null;
    }
    return null;
  }

  /// Extracts text for a given verse number from helloao chapter JSON.
  String? extractVerseFromChapter(Map<String, dynamic> chapterData, int targetVerse) {
    final chapterObj = chapterData['chapter'];
    if (chapterObj is! Map) return null;

    // Structure format: chapter.content -> list of items
    final content = chapterObj['content'];
    if (content is List) {
      for (final item in content) {
        if (item is Map && item['type'] == 'verse') {
          final verseNum = item['number'];
          final isMatch = (verseNum is int && verseNum == targetVerse) ||
              (verseNum?.toString() == targetVerse.toString());
          if (isMatch) {
            return _extractTextFromContent(item['content']);
          }
        }
      }
    }

    // Alternative simple structure: chapter.verses -> map or list
    final verses = chapterObj['verses'];
    if (verses is Map && verses.containsKey(targetVerse.toString())) {
      final v = verses[targetVerse.toString()];
      if (v is String) return v.trim();
      if (v is Map && v['text'] != null) return v['text'].toString().trim();
    }

    return null;
  }

  /// Helper to concatenate text fragments from a verse content list.
  String _extractTextFromContent(dynamic verseContent) {
    if (verseContent is String) return verseContent.trim();
    if (verseContent is! List) return '';

    final buffer = StringBuffer();
    for (final piece in verseContent) {
      if (piece is String) {
        _appendWithSpacing(buffer, piece);
      } else if (piece is Map) {
        if (piece.containsKey('text')) {
          final text = piece['text']?.toString() ?? '';
          _appendWithSpacing(buffer, text);
        }
      }
    }
    return buffer.toString().trim();
  }

  void _appendWithSpacing(StringBuffer buffer, String text) {
    if (text.isEmpty) return;
    if (buffer.isNotEmpty &&
        !buffer.toString().endsWith(' ') &&
        !text.startsWith(' ') &&
        !RegExp(r'^[.,!?;:]').hasMatch(text)) {
      buffer.write(' ');
    }
    buffer.write(text);
  }

  /// Checks if a chapter is cached locally in SharedPreferences.
  Future<bool> isChapterCached({
    required String book,
    required int chapter,
    String langOrTranslation = 'eng',
  }) async {
    final prefs = await _preferences;
    final translation = resolveTranslation(langOrTranslation);
    final cacheKey = chapterCacheKey(translation, book, chapter);
    return prefs.containsKey(cacheKey);
  }

  /// Clears cached Bible chapters.
  Future<void> clearCache() async {
    final prefs = await _preferences;
    final keys = prefs.getKeys();
    for (final key in keys) {
      if (key.startsWith('bible_chapter_')) {
        await prefs.remove(key);
      }
    }
  }

  /// Parses a universal ID string like `PSA.34.18` into its components.
  static ({String book, int chapter, int verse})? parseUniversalId(String id) {
    final parts = id.trim().split('.');
    if (parts.length >= 3) {
      final book = parts[0].trim();
      final chapter = int.tryParse(parts[1].trim());
      final verse = int.tryParse(parts[2].trim());
      if (book.isNotEmpty && chapter != null && verse != null) {
        return (book: book, chapter: chapter, verse: verse);
      }
    }
    return null;
  }
}
