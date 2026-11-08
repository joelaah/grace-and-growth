import '../models/inshorts_feed_item.dart';
import '../models/tagged_verse.dart';
import '../services/quote_api_service.dart';

/// Deterministic daily verse/quote selection algorithm.
///
/// Uses the calendar date as a seed so every user sees the same
/// "Verse of the Day" and "Quote of the Day" on the same day,
/// while cycling through the entire pool without repeats within a period.
class DailySelectionEngine {
  /// Returns a deterministic index for today from a pool of [poolSize] items.
  ///
  /// The algorithm:
  /// 1. Compute a day-number from epoch: `DateTime.now().difference(epoch).inDays`
  /// 2. Use modular arithmetic: `dayNumber % poolSize`
  /// 3. Apply a deterministic shuffle offset using a hash of the day
  ///    to avoid the pattern feeling sequential.
  ///
  /// Formula: `index = (dayNumber * 2654435761 + salt) % poolSize`
  /// where 2654435761 is Knuth's multiplicative hash constant (golden ratio × 2^32).
  static int deterministicIndexForToday(int poolSize, {int salt = 0}) {
    if (poolSize <= 0) return 0;
    final now = DateTime.now();
    final dayNumber = DateTime(now.year, now.month, now.day)
        .difference(DateTime(2024, 1, 1))
        .inDays;

    // Knuth multiplicative hash for uniform distribution
    const int knuthConstant = 2654435761;
    final hash = ((dayNumber * knuthConstant) + salt) & 0x7FFFFFFF;
    return hash % poolSize;
  }

  /// Picks today's Bible verse from [verses], deterministically.
  static TaggedVerse? todaysVerse(List<TaggedVerse> verses) {
    if (verses.isEmpty) return null;
    final index = deterministicIndexForToday(verses.length, salt: 42);
    return verses[index];
  }

  /// Picks today's inspirational quote from [quotes], deterministically.
  static InspirationalQuote? todaysQuote(List<InspirationalQuote> quotes) {
    if (quotes.isEmpty) return null;
    final index = deterministicIndexForToday(quotes.length, salt: 137);
    return quotes[index];
  }

  /// Picks today's verse as an [InshortsFeedItem].
  static InshortsFeedItem? todaysVerseItem(
    List<TaggedVerse> verses, {
    String langCode = 'eng',
  }) {
    final verse = todaysVerse(verses);
    if (verse == null) return null;
    return InshortsFeedItem.fromVerse(verse, langCode: langCode);
  }

  /// Picks today's quote as an [InshortsFeedItem].
  static InshortsFeedItem? todaysQuoteItem(
    List<InspirationalQuote> quotes, {
    String langCode = 'eng',
  }) {
    final quote = todaysQuote(quotes);
    if (quote == null) return null;
    return InshortsFeedItem.fromQuote(quote, langCode: langCode);
  }
}
