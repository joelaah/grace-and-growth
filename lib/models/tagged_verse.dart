import 'package:flutter/foundation.dart';
import '../theme/mood_stage_theme.dart';

/// Represents a Scripture passage tagged for emotional and contemplative mood stages.
///
/// Holds universal reference identifiers (e.g., `PSA.34.18`), metadata,
/// mood categorization, and multilingual devotional reflections.
@immutable
class TaggedVerse {
  /// Universal identifier format: `{BOOK}.{CHAPTER}.{VERSE}` (e.g., `PSA.34.18`).
  final String id;

  /// Standard USFM 3-letter book code (e.g., `PSA`, `2CO`, `NUM`, `MIC`).
  final String book;

  /// Chapter number within the book.
  final int chapter;

  /// Verse number within the chapter.
  final int verse;

  /// The primary contemplative [MoodStage] this passage speaks to.
  final MoodStage primaryStage;

  /// Mood keywords and themes associated with this verse (e.g., `['gloomy', 'brokenhearted', 'comfort']`).
  final List<String> moodTags;

  /// Multilingual devotional reflections keyed by ISO language code (e.g., `eng`, `lus`, `hin`, `spa`).
  final Map<String, String> reflectionsByLang;

  /// Optional pre-cached multilingual scripture text keyed by language code.
  final Map<String, String> textsByLang;

  /// Optional human-readable category title (e.g., 'Comfort in Heavy Seasons').
  final String? category;

  /// Optional contextual sub-tag (e.g., 'Morning Pause').
  final String? subTag;

  const TaggedVerse({
    required this.id,
    required this.book,
    required this.chapter,
    required this.verse,
    required this.primaryStage,
    required this.moodTags,
    required this.reflectionsByLang,
    this.textsByLang = const <String, String>{},
    this.category,
    this.subTag,
  });

  /// Human-friendly reference display string (e.g. "Psalm 34:18" or "PSA 34:18").
  String get reference {
    final bookName = _bookDisplayNames[book.toUpperCase()] ?? book;
    return '$bookName $chapter:$verse';
  }

  /// Retrieves the devotional reflection for the requested language code,
  /// falling back gracefully to English (`eng`) or the first available reflection.
  String reflectionFor(String langCode) {
    return reflectionsByLang[langCode] ??
        reflectionsByLang['eng'] ??
        (reflectionsByLang.isNotEmpty ? reflectionsByLang.values.first : '');
  }

  /// Retrieves the scripture text for the requested language code if cached.
  String? textFor(String langCode) {
    return textsByLang[langCode] ?? textsByLang['eng'];
  }

  /// Parses a [TaggedVerse] from standard JSON (handling both snake_case and camelCase).
  factory TaggedVerse.fromJson(
    Map<String, dynamic> json, {
    Map<String, String>? extraTexts,
    Map<String, String>? extraReflections,
  }) {
    final rawId = json['id']?.toString() ?? '';
    final idParts = rawId.split('.');

    final book = json['book']?.toString() ??
        (idParts.isNotEmpty && idParts[0].isNotEmpty ? idParts[0] : 'PSA');

    final chapter = json['chapter'] is int
        ? json['chapter'] as int
        : (int.tryParse(json['chapter']?.toString() ?? '') ??
            (idParts.length > 1 ? int.tryParse(idParts[1]) ?? 1 : 1));

    final verse = json['verse'] is int
        ? json['verse'] as int
        : (int.tryParse(json['verse']?.toString() ?? '') ??
            (idParts.length > 2 ? int.tryParse(idParts[2]) ?? 1 : 1));

    final stageRaw = json['primary_stage'] ?? json['primaryStage'] ?? json['stage'];
    final stage = _parseMoodStage(stageRaw);

    final rawTags = json['mood_tags'] ?? json['moodTags'];
    final moodTags = rawTags is List
        ? rawTags.map((e) => e.toString()).toList()
        : <String>[];

    final reflections = <String, String>{};
    if (json['reflections_by_lang'] is Map) {
      (json['reflections_by_lang'] as Map).forEach((k, v) {
        reflections[k.toString()] = v.toString();
      });
    } else if (json['reflectionsByLang'] is Map) {
      (json['reflectionsByLang'] as Map).forEach((k, v) {
        reflections[k.toString()] = v.toString();
      });
    } else if (json['reflections'] is Map) {
      (json['reflections'] as Map).forEach((k, v) {
        reflections[k.toString()] = v.toString();
      });
    }
    if (extraReflections != null) {
      reflections.addAll(extraReflections);
    }

    final texts = <String, String>{};
    if (json['texts_by_lang'] is Map) {
      (json['texts_by_lang'] as Map).forEach((k, v) {
        texts[k.toString()] = v.toString();
      });
    } else if (json['textsByLang'] is Map) {
      (json['textsByLang'] as Map).forEach((k, v) {
        texts[k.toString()] = v.toString();
      });
    } else if (json['scripture_text'] is Map) {
      (json['scripture_text'] as Map).forEach((k, v) {
        texts[k.toString()] = v.toString();
      });
    }
    if (extraTexts != null) {
      texts.addAll(extraTexts);
    }

    return TaggedVerse(
      id: rawId.isNotEmpty ? rawId : '$book.$chapter.$verse',
      book: book,
      chapter: chapter,
      verse: verse,
      primaryStage: stage,
      moodTags: moodTags,
      reflectionsByLang: reflections,
      textsByLang: texts,
      category: json['category']?.toString(),
      subTag: json['sub_tag']?.toString() ?? json['subTag']?.toString(),
    );
  }

  /// Converts this [TaggedVerse] into a JSON representation.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'book': book,
      'chapter': chapter,
      'verse': verse,
      'primary_stage': primaryStage.name,
      'mood_tags': moodTags,
      'reflections_by_lang': reflectionsByLang,
      'texts_by_lang': textsByLang,
      if (category != null) 'category': category,
      if (subTag != null) 'sub_tag': subTag,
    };
  }

  TaggedVerse copyWith({
    String? id,
    String? book,
    int? chapter,
    int? verse,
    MoodStage? primaryStage,
    List<String>? moodTags,
    Map<String, String>? reflectionsByLang,
    Map<String, String>? textsByLang,
    String? category,
    String? subTag,
  }) {
    return TaggedVerse(
      id: id ?? this.id,
      book: book ?? this.book,
      chapter: chapter ?? this.chapter,
      verse: verse ?? this.verse,
      primaryStage: primaryStage ?? this.primaryStage,
      moodTags: moodTags ?? this.moodTags,
      reflectionsByLang: reflectionsByLang ?? this.reflectionsByLang,
      textsByLang: textsByLang ?? this.textsByLang,
      category: category ?? this.category,
      subTag: subTag ?? this.subTag,
    );
  }

  static MoodStage _parseMoodStage(dynamic value) {
    if (value is MoodStage) return value;
    final str = value?.toString().toLowerCase().trim();
    for (final stage in MoodStage.values) {
      if (stage.name == str) return stage;
    }
    return MoodStage.gloomy;
  }

  static const Map<String, String> _bookDisplayNames = {
    'GEN': 'Genesis',
    'EXO': 'Exodus',
    'LEV': 'Leviticus',
    'NUM': 'Numbers',
    'DEU': 'Deuteronomy',
    'PSA': 'Psalm',
    'PRO': 'Proverbs',
    'ECC': 'Ecclesiastes',
    'ISA': 'Isaiah',
    'JER': 'Jeremiah',
    'LAM': 'Lamentations',
    'MIC': 'Micah',
    'MAT': 'Matthew',
    'MRK': 'Mark',
    'LUK': 'Luke',
    'JHN': 'John',
    'ROM': 'Romans',
    '1CO': '1 Corinthians',
    '2CO': '2 Corinthians',
    'GAL': 'Galatians',
    'EPH': 'Ephesians',
    'PHP': 'Philippians',
    'COL': 'Colossians',
    '1TH': '1 Thessalonians',
    '2TH': '2 Thessalonians',
    '1TI': '1 Timothy',
    '2TI': '2 Timothy',
    'HEB': 'Hebrews',
    'JAS': 'James',
    '1PE': '1 Peter',
    '2PE': '2 Peter',
    '1JN': '1 John',
    'REV': 'Revelation',
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TaggedVerse &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          book == other.book &&
          chapter == other.chapter &&
          verse == other.verse &&
          primaryStage == other.primaryStage &&
          listEquals(moodTags, other.moodTags) &&
          mapEquals(reflectionsByLang, other.reflectionsByLang) &&
          mapEquals(textsByLang, other.textsByLang);

  @override
  int get hashCode => Object.hash(
        id,
        book,
        chapter,
        verse,
        primaryStage,
        Object.hashAll(moodTags),
        Object.hashAll(reflectionsByLang.entries),
        Object.hashAll(textsByLang.entries),
      );

  @override
  String toString() => 'TaggedVerse($id, stage: ${primaryStage.name})';
}
