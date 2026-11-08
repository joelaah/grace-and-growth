import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/mood_stage_theme.dart';

/// Persistent local storage for journal entries and mood history.
///
/// Uses SharedPreferences for simplicity. Each journal entry is stored as
/// a JSON object keyed by the saved card's ID. Mood history is stored
/// as a map of 'YYYY-MM-DD' → MoodStage index.
class JournalStorage {
  static const String _journalEntriesKey = 'journal_entries';
  static const String _moodHistoryKey = 'mood_history';
  static const String _savedCardIdsKey = 'saved_card_ids';

  final SharedPreferences? _prefs;

  JournalStorage({SharedPreferences? prefs}) : _prefs = prefs;

  Future<SharedPreferences> get _preferences async =>
      _prefs ?? await SharedPreferences.getInstance();

  // ─── Journal Entries ───

  /// A journal entry is: { cardId, note, createdAt, updatedAt }
  Future<List<Map<String, dynamic>>> getAllEntries() async {
    final prefs = await _preferences;
    final raw = prefs.getString(_journalEntriesKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list.cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }

  /// Gets the journal note for a specific card ID.
  Future<String?> getNoteForCard(String cardId) async {
    final entries = await getAllEntries();
    for (final entry in entries) {
      if (entry['cardId'] == cardId) {
        return entry['note'] as String?;
      }
    }
    return null;
  }

  /// Saves or updates a journal note for a card.
  Future<void> saveNote(String cardId, String note) async {
    final prefs = await _preferences;
    final entries = await getAllEntries();
    final now = DateTime.now().toIso8601String();

    // Find existing entry or create new
    final existingIndex = entries.indexWhere((e) => e['cardId'] == cardId);
    if (existingIndex >= 0) {
      entries[existingIndex]['note'] = note;
      entries[existingIndex]['updatedAt'] = now;
    } else {
      entries.add({
        'cardId': cardId,
        'note': note,
        'createdAt': now,
        'updatedAt': now,
      });
    }

    await prefs.setString(_journalEntriesKey, jsonEncode(entries));
  }

  /// Deletes a journal entry by card ID.
  Future<void> deleteEntry(String cardId) async {
    final prefs = await _preferences;
    final entries = await getAllEntries();
    entries.removeWhere((e) => e['cardId'] == cardId);
    await prefs.setString(_journalEntriesKey, jsonEncode(entries));
  }

  // ─── Saved Card IDs (Bookmarks) ───

  /// Gets the ordered list of saved/bookmarked card IDs.
  Future<List<String>> getSavedCardIds() async {
    final prefs = await _preferences;
    return prefs.getStringList(_savedCardIdsKey) ?? [];
  }

  /// Adds a card ID to saved list.
  Future<void> saveCardId(String cardId) async {
    final prefs = await _preferences;
    final ids = await getSavedCardIds();
    if (!ids.contains(cardId)) {
      ids.insert(0, cardId); // newest first
      await prefs.setStringList(_savedCardIdsKey, ids);
    }
  }

  /// Removes a card ID from saved list.
  Future<void> unsaveCardId(String cardId) async {
    final prefs = await _preferences;
    final ids = await getSavedCardIds();
    ids.remove(cardId);
    await prefs.setStringList(_savedCardIdsKey, ids);
  }

  /// Checks if a card is saved.
  Future<bool> isCardSaved(String cardId) async {
    final ids = await getSavedCardIds();
    return ids.contains(cardId);
  }

  // ─── Mood History ───

  /// Records the mood for today.
  Future<void> recordMoodForToday(MoodStage stage) async {
    final prefs = await _preferences;
    final raw = prefs.getString(_moodHistoryKey);
    final Map<String, dynamic> rawMap = raw != null && raw.isNotEmpty
        ? (jsonDecode(raw) as Map<String, dynamic>)
        : <String, dynamic>{};
    final today = _todayKey();
    rawMap[today] = stage.index;
    await prefs.setString(_moodHistoryKey, jsonEncode(rawMap));
  }

  /// Gets the full mood history as { 'YYYY-MM-DD': MoodStage }.
  Future<Map<String, MoodStage>> getMoodHistory() async {
    final prefs = await _preferences;
    final raw = prefs.getString(_moodHistoryKey);
    if (raw == null || raw.isEmpty) return {};

    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final result = <String, MoodStage>{};
      for (final entry in map.entries) {
        final index = entry.value as int;
        if (index >= 0 && index < MoodStage.values.length) {
          result[entry.key] = MoodStage.values[index];
        }
      }
      return result;
    } catch (_) {
      return {};
    }
  }

  /// Gets the mood for a specific date.
  Future<MoodStage?> getMoodForDate(DateTime date) async {
    final history = await getMoodHistory();
    return history[_dateKey(date)];
  }

  /// Gets the mood history for a specific month (for the calendar view).
  Future<Map<String, MoodStage>> getMoodHistoryForMonth(
    int year,
    int month,
  ) async {
    final history = await getMoodHistory();
    final prefix = '$year-${month.toString().padLeft(2, '0')}';
    return Map.fromEntries(
      history.entries.where((e) => e.key.startsWith(prefix)),
    );
  }

  String _todayKey() {
    final now = DateTime.now();
    return _dateKey(now);
  }

  String _dateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
