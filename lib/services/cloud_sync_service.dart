import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/journal_storage.dart';
import '../theme/mood_stage_theme.dart';
import 'auth_service.dart';

/// Cloud synchronization service connecting local JournalStorage with Supabase.
class CloudSyncService {
  static final CloudSyncService _instance = CloudSyncService._internal();
  factory CloudSyncService() => _instance;
  CloudSyncService._internal();

  final AuthService _auth = AuthService();
  final JournalStorage _storage = JournalStorage();

  SupabaseClient get _client => Supabase.instance.client;

  /// Pushes local bookmarks, journal notes, and mood entries to Supabase.
  Future<void> pushToCloud() async {
    final userId = _auth.currentUserId;
    if (userId == null) return;

    try {
      // 1. Bookmarks
      final savedIds = await _storage.getSavedCardIds();
      if (savedIds.isNotEmpty) {
        final bookmarkRows = savedIds.map((id) => {
          'user_id': userId,
          'card_id': id,
          'updated_at': DateTime.now().toIso8601String(),
        }).toList();

        await _client.from('user_bookmarks').upsert(
          bookmarkRows,
          onConflict: 'user_id,card_id',
        );
      }

      // 2. Journal Entries
      final entries = await _storage.getAllEntries();
      if (entries.isNotEmpty) {
        final journalRows = entries.map((entry) => {
          'user_id': userId,
          'card_id': entry['cardId'],
          'note': entry['note'],
          'created_at': entry['createdAt'],
          'updated_at': entry['updatedAt'] ?? DateTime.now().toIso8601String(),
        }).toList();

        await _client.from('user_journal').upsert(
          journalRows,
          onConflict: 'user_id,card_id',
        );
      }

      // 3. Mood History
      final moodHistory = await _storage.getMoodHistory();
      if (moodHistory.isNotEmpty) {
        final moodRows = moodHistory.entries.map((e) => {
          'user_id': userId,
          'date': e.key,
          'mood_stage': e.value.index,
          'updated_at': DateTime.now().toIso8601String(),
        }).toList();

        await _client.from('user_mood_history').upsert(
          moodRows,
          onConflict: 'user_id,date',
        );
      }
    } catch (e) {
      debugPrint('Cloud sync push warning (tables may be pending setup): $e');
    }
  }

  /// Pulls remote data from Supabase and merges into local storage.
  Future<void> pullFromCloud() async {
    final userId = _auth.currentUserId;
    if (userId == null) return;

    try {
      // 1. Pull Bookmarks
      final List<dynamic> bookmarks = await _client
          .from('user_bookmarks')
          .select('card_id')
          .eq('user_id', userId);

      for (final row in bookmarks) {
        final cardId = row['card_id'] as String?;
        if (cardId != null) {
          await _storage.saveCardId(cardId);
        }
      }

      // 2. Pull Journal
      final List<dynamic> journals = await _client
          .from('user_journal')
          .select('card_id, note')
          .eq('user_id', userId);

      for (final row in journals) {
        final cardId = row['card_id'] as String?;
        final note = row['note'] as String?;
        if (cardId != null && note != null) {
          await _storage.saveNote(cardId, note);
        }
      }

      // 3. Pull Mood History
      final List<dynamic> moods = await _client
          .from('user_mood_history')
          .select('date, mood_stage')
          .eq('user_id', userId);

      for (final row in moods) {
        final moodIndex = row['mood_stage'] as int?;
        if (moodIndex != null && moodIndex >= 0 && moodIndex < MoodStage.values.length) {
          await _storage.recordMoodForToday(MoodStage.values[moodIndex]);
        }
      }
    } catch (e) {
      debugPrint('Cloud sync pull warning (tables may be pending setup): $e');
    }
  }
}
