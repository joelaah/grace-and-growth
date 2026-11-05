import 'package:flutter/material.dart';
import '../models/tagged_verse.dart';
import '../services/bible_api_service.dart';
import '../services/mood_matching_engine.dart';
import '../theme/mood_stage_theme.dart';
import '../widgets/verse_stage_card.dart';

/// The primary home screen embodying the "Grace & Growth" contemplative sanctuary.
///
/// Transitions background gradients dynamically when the selected [MoodStage] changes,
/// and cross-fades Scripture & Reflection cards when either the mood or language switches.
class HomeStageScreen extends StatefulWidget {
  final MoodMatchingEngine? moodMatchingEngine;
  final BibleApiService? bibleApiService;
  final MoodStage initialStage;

  const HomeStageScreen({
    super.key,
    this.moodMatchingEngine,
    this.bibleApiService,
    this.initialStage = MoodStage.gloomy,
  });

  @override
  HomeStageScreenState createState() => HomeStageScreenState();
}

class HomeStageScreenState extends State<HomeStageScreen> {
  /// The active mood stage governing the current UI ambiance and palette.
  late MoodStage activeStage;
  String _selectedLanguage = 'eng';
  final Set<String> _bookmarkedVerseIds = <String>{};
  String? _playingAudioVerseId;
  int _currentNavIndex = 0;

  late final BibleApiService _bibleApiService;
  late final MoodMatchingEngine _moodMatchingEngine;
  MatchedVerse? _currentMatchedVerse;
  bool _isLoading = false;

  bool get isLoading => _isLoading;

  static const List<String> _languages = ['eng', 'lus', 'hin', 'spa'];

  @override
  void initState() {
    super.initState();
    activeStage = widget.initialStage;
    _bibleApiService = widget.bibleApiService ?? BibleApiService();
    _moodMatchingEngine = widget.moodMatchingEngine ??
        MoodMatchingEngine(bibleApiService: _bibleApiService);
    _loadVerseForStage(activeStage);
  }

  /// Loads a fresh verse matching the requested [stage] using [MoodMatchingEngine],
  /// automatically updating [activeStage] to match the verse's emotional tone.
  Future<void> _loadVerseForStage(MoodStage stage) async {
    setState(() {
      _isLoading = true;
      activeStage = stage;
    });

    try {
      final matched = await _moodMatchingEngine.getVerseForMood(
        stage: stage,
        langCode: _selectedLanguage,
      );
      if (mounted) {
        setState(() {
          _currentMatchedVerse = matched;
          // Requirement 3: Automatically update activeStage = currentVerse.primaryStage
          activeStage = matched.verse.primaryStage;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Loads a random daily verse across all available starter verses,
  /// morphing [activeStage] to match the selected verse's emotional stage.
  Future<void> loadRandomDailyVerse() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final allVerses = await _moodMatchingEngine.loadVerses();
      if (allVerses.isNotEmpty) {
        final shuffled = List<TaggedVerse>.from(allVerses)..shuffle();
        final chosen = shuffled.first;
        final matched = await _moodMatchingEngine.getVerseForMood(
          stage: chosen.primaryStage,
          langCode: _selectedLanguage,
        );
        if (mounted) {
          setState(() {
            _currentMatchedVerse = matched;
            // Requirement 3: Automatically update activeStage = currentVerse.primaryStage
            activeStage = matched.verse.primaryStage;
            _isLoading = false;
          });
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showGentleNotice(String message, StagePalette palette) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.spa_outlined, size: 16.0, color: palette.accent),
            const SizedBox(width: 8.0),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  fontSize: 13.0,
                  fontWeight: FontWeight.w400,
                  color: palette.primaryText,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: palette.cardSurface,
        elevation: 6.0,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.0),
          side: BorderSide(
            color: palette.cardBorder.withValues(alpha: 0.6),
            width: 1.0,
          ),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = activeStage.palette;

    final currentVerse = _currentMatchedVerse != null
        ? StageVerse.fromTaggedVerse(
            _currentMatchedVerse!.verse,
            resolvedText: _currentMatchedVerse!.text,
            langCode: _selectedLanguage,
          )
        : StageVerse.forStage(activeStage);

    final verseId = currentVerse.id;
    final langCode = _selectedLanguage;
    final isBookmarked = _bookmarkedVerseIds.contains(verseId);
    final isPlayingAudio = _playingAudioVerseId == verseId;

    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOutCubic,
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [palette.bgTop, palette.bgBottom],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(
              horizontal: 20.0,
              vertical: 12.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeaderBar(palette),
                const SizedBox(height: 24.0),
                _buildMoodSection(palette),
                const SizedBox(height: 24.0),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 400),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  layoutBuilder: (Widget? currentChild, List<Widget> previousChildren) {
                    return Stack(
                      alignment: Alignment.topCenter,
                      children: <Widget>[
                        ...previousChildren,
                        if (currentChild != null) currentChild,
                      ],
                    );
                  },
                  transitionBuilder: (Widget child, Animation<double> animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: child,
                    );
                  },
                  child: VerseStageCard(
                    key: ValueKey('${verseId}_$langCode'),
                    verse: currentVerse,
                    palette: palette,
                    langCode: langCode,
                    isBookmarked: isBookmarked,
                    isPlayingAudio: isPlayingAudio,
                    onBookmarkToggle: () {
                      final wasSaved = _bookmarkedVerseIds.contains(verseId);
                      setState(() {
                        if (wasSaved) {
                          _bookmarkedVerseIds.remove(verseId);
                        } else {
                          _bookmarkedVerseIds.add(verseId);
                        }
                      });
                      final message = !wasSaved
                          ? 'Saved to your quiet sanctuary'
                          : 'Removed from saved verses';
                      _showGentleNotice(message, palette);
                    },
                    onAudioToggle: () {
                      final wasPlaying = _playingAudioVerseId == verseId;
                      setState(() {
                        if (wasPlaying) {
                          _playingAudioVerseId = null;
                        } else {
                          _playingAudioVerseId = verseId;
                        }
                      });
                      final message = !wasPlaying
                          ? 'Playing gentle audio whisper...'
                          : 'Audio paused quietly';
                      _showGentleNotice(message, palette);
                    },
                    onShare: () {
                      _showGentleNotice(
                        'Verse copied to share gentle comfort',
                        palette,
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20.0),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNav(palette),
    );
  }

  /// Top header bar featuring the "Grace & Growth" title and compact language selector pill.
  Widget _buildHeaderBar(StagePalette palette) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // App title with dignified contemplative tone
        Expanded(
          child: Row(
            children: [
              Container(
                width: 36.0,
                height: 36.0,
                decoration: BoxDecoration(
                  color: palette.cardSurface,
                  borderRadius: BorderRadius.circular(10.0),
                  border: Border.all(
                    color: palette.cardBorder.withValues(alpha: 0.5),
                    width: 1.0,
                  ),
                ),
                child: Icon(
                  Icons.spa_rounded,
                  size: 20.0,
                  color: palette.accent,
                ),
              ),
              const SizedBox(width: 10.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Grace & Growth',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'serif',
                        fontSize: 20.0,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.2,
                        color: palette.primaryText,
                      ),
                    ),
                    Text(
                      'Daily Sanctuary',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w400,
                        color: palette.secondaryText,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8.0),
        // Compact Language Selector pill (eng, lus, hin, spa)
        Container(
          decoration: BoxDecoration(
            color: palette.cardSurface.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(24.0),
            border: Border.all(
              color: palette.cardBorder.withValues(alpha: 0.6),
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10.0,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 3.0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: _languages.map((code) {
              final isSelected = _selectedLanguage == code;
              return GestureDetector(
                onTap: () {
                  if (_selectedLanguage != code) {
                    setState(() {
                      _selectedLanguage = code;
                    });
                    _loadVerseForStage(activeStage);
                  }
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOutCubic,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7.0,
                    vertical: 4.5,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? palette.accent
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(16.0),
                  ),
                  child: Text(
                    code,
                    style: TextStyle(
                      fontSize: 11.0,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected
                          ? Colors.white
                          : palette.secondaryText,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  /// Horizontal "How is your heart today?" chip selector for the 4 [MoodStage] values.
  Widget _buildMoodSection(StagePalette palette) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'How is your heart today?',
                style: TextStyle(
                  fontFamily: 'serif',
                  fontSize: 20.0,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.2,
                  color: palette.primaryText,
                ),
              ),
            ),
            // Gentle random daily pause trigger
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: loadRandomDailyVerse,
                borderRadius: BorderRadius.circular(20.0),
                child: Padding(
                  padding: const EdgeInsets.all(6.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.auto_awesome_outlined,
                        size: 15.0,
                        color: palette.accent,
                      ),
                      const SizedBox(width: 4.0),
                      Text(
                        'Random',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                          color: palette.secondaryText,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 3.0),
        Text(
          'Choose where you find yourself—no need to put on a brave face.',
          style: TextStyle(
            fontSize: 13.0,
            fontWeight: FontWeight.w400,
            color: palette.secondaryText,
          ),
        ),
        const SizedBox(height: 14.0),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: MoodStage.values.map((stage) {
              final isSelected = activeStage == stage;
              final stagePalette = stage.palette;

              return Padding(
                padding: const EdgeInsets.only(right: 10.0),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      _loadVerseForStage(stage);
                    },
                    borderRadius: BorderRadius.circular(24.0),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOutCubic,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 10.0,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? stagePalette.cardSurface
                            : palette.cardSurface.withValues(alpha: 0.45),
                        borderRadius: BorderRadius.circular(24.0),
                        border: Border.all(
                          color: isSelected
                              ? stagePalette.accent
                              : palette.cardBorder.withValues(alpha: 0.5),
                          width: isSelected ? 1.5 : 1.0,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 10.0,
                                  offset: const Offset(0, 3),
                                ),
                              ]
                            : null,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            width: 8.0,
                            height: 8.0,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isSelected
                                  ? stagePalette.accent
                                  : palette.secondaryText.withValues(alpha: 0.45),
                            ),
                          ),
                          const SizedBox(width: 8.0),
                          Text(
                            stagePalette.stageLabel,
                            style: TextStyle(
                              fontSize: 13.0,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                              color: isSelected
                                  ? stagePalette.primaryText
                                  : palette.secondaryText,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  /// Contemplative bottom navigation bar.
  Widget _buildBottomNav(StagePalette palette) {
    return Container(
      decoration: BoxDecoration(
        color: palette.cardSurface.withValues(alpha: 0.96),
        border: Border(
          top: BorderSide(
            color: palette.cardBorder.withValues(alpha: 0.4),
            width: 1.0,
          ),
        ),
      ),
      child: BottomNavigationBar(
        currentIndex: _currentNavIndex,
        onTap: (index) {
          setState(() {
            _currentNavIndex = index;
          });
          if (index == 1) {
            // "Reflect" tab triggers loading a random daily reflection
            loadRandomDailyVerse();
          }
        },
        backgroundColor: Colors.transparent,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: palette.accent,
        unselectedItemColor: palette.secondaryText.withValues(alpha: 0.75),
        selectedFontSize: 11.0,
        unselectedFontSize: 11.0,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w400),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.spa_outlined),
            activeIcon: Icon(Icons.spa),
            label: 'Today',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.menu_book_outlined),
            activeIcon: Icon(Icons.menu_book),
            label: 'Reflect',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.edit_note_outlined),
            activeIcon: Icon(Icons.edit_note),
            label: 'Journal',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.psychology_alt_outlined),
            activeIcon: Icon(Icons.psychology_alt),
            label: 'Feelings',
          ),
        ],
      ),
    );
  }
}
