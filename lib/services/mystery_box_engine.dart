import 'dart:math' as math;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/inshorts_feed_item.dart';
import '../models/tagged_verse.dart';
import '../theme/mood_stage_theme.dart';
import 'mood_matching_engine.dart';
import 'quote_api_service.dart';

/// Engine responsible for the "Mysterious Personal Message Box".
///
/// Randomly draws an unseen Bible verse or motivational quote tailored
/// exclusively to the user's active [MoodStage], excluding previously
/// opened items recorded in [SharedPreferences] under `unsealed_message_ids`.
///
/// NO rarity tiers, epic/common labels, or game percentages are used.
class MysteryBoxEngine {
  static const String unsealedMessageIdsKey = 'unsealed_message_ids';
  static const String warmPersonalHeader = 'Picked for your heart today';

  final MoodMatchingEngine _moodMatchingEngine;
  final QuoteApiService _quoteApiService;
  final SharedPreferences? _prefs;
  final math.Random _random;

  MysteryBoxEngine({
    MoodMatchingEngine? moodMatchingEngine,
    QuoteApiService? quoteApiService,
    SharedPreferences? prefs,
    math.Random? random,
  })  : _moodMatchingEngine = moodMatchingEngine ??
            MoodMatchingEngine(
              prefs: prefs,
            ),
        _quoteApiService = quoteApiService ?? QuoteApiService(prefs: prefs),
        _prefs = prefs,
        _random = random ?? math.Random();

  Future<SharedPreferences> get _preferences async =>
      _prefs ?? await SharedPreferences.getInstance();

  /// Retrieves the set of message IDs unsealed by the user.
  Future<Set<String>> getUnsealedMessageIds() async {
    final prefs = await _preferences;
    final list = prefs.getStringList(unsealedMessageIdsKey) ?? <String>[];
    return list.toSet();
  }

  /// Clears the unsealed history in [SharedPreferences].
  Future<void> clearUnsealedHistory() async {
    final prefs = await _preferences;
    await prefs.remove(unsealedMessageIdsKey);
  }

  /// Opens a mystery box for the given [activeMood] and [langCode].
  ///
  /// - Filters Bible verses (Supabase/local seed) and quotes ([QuoteApiService])
  ///   to ONLY items matching [activeMood].
  /// - Excludes IDs stored in [SharedPreferences] (`unsealed_message_ids`).
  /// - If all items for this mood have been unsealed, resets tracking for this mood
  ///   so the box continues offering serene contemplation without interruption.
  /// - Performs a weighted random roll (`Random().nextDouble()`) to select between
  ///   a mood-matched Bible verse and a mood-matched motivational quote.
  /// - Attaches the warm personal header ("Picked for your heart today").
  Future<InshortsFeedItem> openMysteryBox(
    MoodStage activeMood, [
    String langCode = 'eng',
  ]) async {
    List<TaggedVerse> verses;
    try {
      verses = await _moodMatchingEngine.loadVerses();
    } catch (_) {
      verses = MoodMatchingEngine.defaultSeedVerses;
    }
    if (verses.isEmpty) {
      verses = MoodMatchingEngine.defaultSeedVerses;
    }

    List<InspirationalQuote> quotes;
    try {
      quotes = await _quoteApiService.getQuotes();
    } catch (_) {
      quotes = QuoteApiService.seedQuotes;
    }
    if (quotes.isEmpty) {
      quotes = QuoteApiService.seedQuotes;
    }

    // 1. Filter combined pool to ONLY items matching activeMood
    final moodVerses = verses.where((v) => v.primaryStage == activeMood).toList();
    final moodQuotes = quotes.where((q) => q.stage == activeMood).toList();

    // Fallback to static seeds if pools are empty
    if (moodVerses.isEmpty) {
      moodVerses.addAll(
        MoodMatchingEngine.defaultSeedVerses.where((v) => v.primaryStage == activeMood),
      );
    }
    if (moodQuotes.isEmpty) {
      moodQuotes.addAll(
        QuoteApiService.seedQuotes.where((q) => q.stage == activeMood),
      );
    }

    final prefs = await _preferences;
    final unsealedList = prefs.getStringList(unsealedMessageIdsKey) ?? <String>[];
    final unsealedIds = unsealedList.toSet();

    // 2. Exclude previously unsealed items
    var unseenVerses = moodVerses
        .where((v) => !unsealedIds.contains(v.id) && !unsealedIds.contains('verse_${v.id}'))
        .toList();
    var unseenQuotes = moodQuotes
        .where((q) => !unsealedIds.contains(q.id) && !unsealedIds.contains('quote_${q.id}'))
        .toList();

    // If all items in this mood have been unsealed, reset this mood's unsealed history
    if (unseenVerses.isEmpty && unseenQuotes.isEmpty) {
      final moodIdsToRemove = <String>{
        ...moodVerses.map((v) => v.id),
        ...moodVerses.map((v) => 'verse_${v.id}'),
        ...moodQuotes.map((q) => q.id),
        ...moodQuotes.map((q) => 'quote_${q.id}'),
      };
      unsealedIds.removeAll(moodIdsToRemove);
      await prefs.setStringList(unsealedMessageIdsKey, unsealedIds.toList());
      unseenVerses = List<TaggedVerse>.from(moodVerses);
      unseenQuotes = List<InspirationalQuote>.from(moodQuotes);
    }

    // 3. Weighted random roll using Random().nextDouble() to pick between verse and quote
    final bool pickVerse;
    if (unseenVerses.isNotEmpty && unseenQuotes.isNotEmpty) {
      pickVerse = _random.nextDouble() < 0.5;
    } else if (unseenVerses.isNotEmpty) {
      pickVerse = true;
    } else {
      pickVerse = false;
    }

    InshortsFeedItem chosenItem;

    if (pickVerse) {
      final verse = unseenVerses[_random.nextInt(unseenVerses.length)];
      unsealedIds.add(verse.id);
      unsealedIds.add('verse_${verse.id}');
      await prefs.setStringList(unsealedMessageIdsKey, unsealedIds.toList());

      final base = InshortsFeedItem.fromVerse(verse, langCode: langCode);
      chosenItem = InshortsFeedItem(
        id: base.id,
        type: base.type,
        stage: base.stage,
        sourceBadge: base.sourceBadge,
        mainText: base.mainText,
        attribution: base.attribution,
        category: warmPersonalHeader,
        subTag: base.subTag,
        reflectionTitle: base.reflectionTitle,
        reflectionContent: base.reflectionContent,
        promptText: base.promptText,
        readingTime: base.readingTime,
        taggedVerse: base.taggedVerse,
        quote: base.quote,
      );
    } else {
      final quote = unseenQuotes[_random.nextInt(unseenQuotes.length)];
      unsealedIds.add(quote.id);
      unsealedIds.add('quote_${quote.id}');
      await prefs.setStringList(unsealedMessageIdsKey, unsealedIds.toList());

      final base = InshortsFeedItem.fromQuote(quote, langCode: langCode);
      chosenItem = InshortsFeedItem(
        id: base.id,
        type: base.type,
        stage: base.stage,
        sourceBadge: base.sourceBadge,
        mainText: base.mainText,
        attribution: base.attribution,
        category: warmPersonalHeader,
        subTag: base.subTag,
        reflectionTitle: base.reflectionTitle,
        reflectionContent: base.reflectionContent,
        promptText: base.promptText,
        readingTime: base.readingTime,
        taggedVerse: base.taggedVerse,
        quote: base.quote,
      );
    }

    return chosenItem;
  }
}
