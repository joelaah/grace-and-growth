import 'package:flutter/material.dart';
import '../models/inshorts_feed_item.dart';
import '../services/journal_storage.dart';
import '../theme/mood_stage_theme.dart';

/// The "Journal" tab screen showing saved/bookmarked cards with reflection notes.
///
/// Users can view saved cards, write personal reflection notes,
/// and manage their saved collection.
class JournalScreen extends StatefulWidget {
  final StagePalette palette;
  final List<InshortsFeedItem> allFeedItems;
  final Set<String> bookmarkedIds;
  final ValueChanged<String>? onBookmarkToggle;
  final JournalStorage? journalStorage;

  const JournalScreen({
    super.key,
    required this.palette,
    required this.allFeedItems,
    this.bookmarkedIds = const {},
    this.onBookmarkToggle,
    this.journalStorage,
  });

  @override
  State<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen> {
  late final JournalStorage _storage;
  Map<String, String> _notes = {};

  @override
  void initState() {
    super.initState();
    _storage = widget.journalStorage ?? JournalStorage();
    _loadNotes();
  }

  Future<void> _loadNotes() async {
    final entries = await _storage.getAllEntries();
    if (mounted) {
      setState(() {
        _notes = {
          for (final e in entries)
            if (e['cardId'] != null && e['note'] != null)
              e['cardId'] as String: e['note'] as String,
        };
      });
    }
  }

  List<InshortsFeedItem> get _savedItems {
    return widget.allFeedItems
        .where((item) => widget.bookmarkedIds.contains(item.id))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final palette = widget.palette;
    final savedItems = _savedItems;

    if (savedItems.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.spa_outlined,
                size: 48,
                color: palette.secondaryText.withValues(alpha: 0.4),
              ),
              const SizedBox(height: 16),
              Text(
                'Your journal is empty',
                style: TextStyle(
                  fontFamily: 'serif',
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: palette.primaryText,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Save verses and quotes from the feed to begin.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: palette.secondaryText,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      itemCount: savedItems.length,
      itemBuilder: (context, index) {
        final item = savedItems[index];
        final note = _notes[item.id];
        return _buildJournalCard(palette, item, note);
      },
    );
  }

  Widget _buildJournalCard(
    StagePalette palette,
    InshortsFeedItem item,
    String? note,
  ) {
    final cardPalette = item.stage.palette;

    return GestureDetector(
      onTap: () => _showDetailSheet(item, note),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardPalette.cardSurface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: cardPalette.cardBorder.withValues(alpha: 0.5),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Source badge + mood dot
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: cardPalette.accent.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        item.isVerse
                            ? Icons.auto_stories_outlined
                            : Icons.format_quote_rounded,
                        size: 11,
                        color: cardPalette.accent,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        item.sourceBadge,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                          color: cardPalette.accent,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: cardPalette.accent,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  cardPalette.stageLabel,
                  style: TextStyle(
                    fontSize: 10,
                    color: cardPalette.secondaryText,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Main text preview (2 lines)
            Text(
              '\u201c${item.mainText}\u201d',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'serif',
                fontSize: 15,
                height: 1.4,
                color: cardPalette.primaryText,
              ),
            ),
            const SizedBox(height: 6),
            // Attribution
            Text(
              item.attribution,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: cardPalette.accent,
              ),
            ),
            // Journal note (if any)
            if (note != null && note.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: cardPalette.bgTop.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.edit_note_outlined,
                      size: 14,
                      color: cardPalette.secondaryText,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        note,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                          height: 1.3,
                          color: cardPalette.secondaryText,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showDetailSheet(InshortsFeedItem item, String? existingNote) {
    final cardPalette = item.stage.palette;
    final noteController = TextEditingController(text: existingNote ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          decoration: BoxDecoration(
            color: cardPalette.cardSurface,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(
              top: BorderSide(
                color: cardPalette.cardBorder.withValues(alpha: 0.5),
              ),
            ),
          ),
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              24,
              16,
              24,
              MediaQuery.of(context).viewInsets.bottom + 24,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle bar
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color:
                            cardPalette.secondaryText.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Source badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: cardPalette.accent.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      item.sourceBadge,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                        color: cardPalette.accent,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Full text
                  Text(
                    '\u201c${item.mainText}\u201d',
                    style: TextStyle(
                      fontFamily: 'serif',
                      fontSize: 18,
                      height: 1.5,
                      color: cardPalette.primaryText,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    item.attribution,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: cardPalette.accent,
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Reflection note
                  Text(
                    'Your reflection',
                    style: TextStyle(
                      fontFamily: 'serif',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: cardPalette.primaryText,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    decoration: BoxDecoration(
                      color:
                          cardPalette.bgTop.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: cardPalette.cardBorder
                            .withValues(alpha: 0.4),
                      ),
                    ),
                    child: TextField(
                      controller: noteController,
                      maxLines: 4,
                      style: TextStyle(
                        fontSize: 14,
                        color: cardPalette.primaryText,
                        height: 1.4,
                      ),
                      decoration: InputDecoration(
                        hintText:
                            'What does this passage mean to you today?',
                        hintStyle: TextStyle(
                          color: cardPalette.secondaryText
                              .withValues(alpha: 0.5),
                          fontSize: 13,
                        ),
                        contentPadding: const EdgeInsets.all(14),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Action buttons
                  Row(
                    children: [
                      // Save
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            final text = noteController.text.trim();
                            if (text.isNotEmpty) {
                              await _storage.saveNote(item.id, text);
                              await _loadNotes();
                            }
                            if (context.mounted) Navigator.pop(context);
                          },
                          icon: const Icon(Icons.check_rounded, size: 18),
                          label: const Text('Save'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: cardPalette.accent,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding:
                                const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Delete
                      ElevatedButton.icon(
                        onPressed: () async {
                          await _storage.deleteEntry(item.id);
                          widget.onBookmarkToggle?.call(item.id);
                          await _loadNotes();
                          if (context.mounted) Navigator.pop(context);
                        },
                        icon: const Icon(Icons.delete_outline, size: 18),
                        label: const Text('Remove'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              cardPalette.secondaryText.withValues(alpha: 0.12),
                          foregroundColor: cardPalette.secondaryText,
                          elevation: 0,
                          padding:
                              const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
