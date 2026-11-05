import 'package:flutter/material.dart';
import '../models/inshorts_feed_item.dart';
import '../models/tagged_verse.dart';
import '../services/bible_api_service.dart';
import '../services/mood_matching_engine.dart';
import '../services/quote_api_service.dart';
import '../theme/mood_stage_theme.dart';
import '../widgets/inshorts_stage_card.dart';

/// Content filter options for the Inshorts vertical swipe feed.
enum ContentFilter {
  all,
  verses,
  quotes,
}

/// The primary home screen embodying the "Grace & Growth" contemplative sanctuary.
///
/// Features an Inshorts-style vertical swipe feed blending Bible verses and inspirational
/// quotes, with ambient background color transitions matching each card's mood.
class HomeStageScreen extends StatefulWidget {
  final MoodMatchingEngine? moodMatchingEngine;
  final BibleApiService? bibleApiService;
  final QuoteApiService? quoteApiService;
  final MoodStage initialStage;

  const HomeStageScreen({
    super.key,
    this.moodMatchingEngine,
    this.bibleApiService,
    this.quoteApiService,
    this.initialStage = MoodStage.gloomy,
  });

  @override
  HomeStageScreenState createState() => HomeStageScreenState();
}

class HomeStageScreenState extends State<HomeStageScreen> {
  /// The active mood stage governing the current UI ambiance and palette.
  late MoodStage activeStage;
  String _selectedLanguage = 'eng';
  ContentFilter _currentFilter = ContentFilter.all;
  final Set<String> _bookmarkedIds = <String>{};
  int _currentNavIndex = 0;

  late final BibleApiService _bibleApiService;
  late final MoodMatchingEngine _moodMatchingEngine;
  late final QuoteApiService _quoteApiService;
  late final PageController _pageController;

  List<TaggedVerse> _allVerses = [];
  List<InspirationalQuote> _allQuotes = [];
  List<InshortsFeedItem> _allFeedItems = [];
  List<InshortsFeedItem> _displayedItems = [];
  bool _isLoading = true;

  bool get isLoading => _isLoading;
  PageController get pageController => _pageController;
  ContentFilter get currentFilter => _currentFilter;
  List<InshortsFeedItem> get displayedItems => _displayedItems;

  static const List<String> _languages = ['eng', 'lus', 'hin', 'spa'];

  @override
  void initState() {
    super.initState();
    activeStage = widget.initialStage;
    _bibleApiService = widget.bibleApiService ?? BibleApiService();
    _moodMatchingEngine = widget.moodMatchingEngine ??
        MoodMatchingEngine(bibleApiService: _bibleApiService);
    _quoteApiService = widget.quoteApiService ?? QuoteApiService();

    // Immediately seed with curated in-memory verses and quotes so the feed is instantly available
    _allVerses = MoodMatchingEngine.defaultSeedVerses;
    _allQuotes = QuoteApiService.seedQuotes;
    _rebuildFeedItems();

    // Initialize PageController directly to initialStage card to avoid visual flicker
    final initialIndex = _displayedItems.indexWhere((item) => item.stage == activeStage);
    final startPage = initialIndex != -1 ? initialIndex : 0;
    _pageController = PageController(
      viewportFraction: 0.88,
      initialPage: startPage,
    );
    _isLoading = false;

    // Asynchronously fetch fresh quotes from cache/API in background
    _initializeFeed();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /// Initializes Bible verses and inspirational quotes, interleaves them, and prepares the feed.
  Future<void> _initializeFeed() async {
    try {
      final results = await Future.wait([
        _moodMatchingEngine.loadVerses(),
        _quoteApiService.getQuotes(),
      ]);

      final loadedVerses = results[0] as List<TaggedVerse>;
      final loadedQuotes = results[1] as List<InspirationalQuote>;

      if (mounted) {
        setState(() {
          if (loadedVerses.isNotEmpty) _allVerses = loadedVerses;
          if (loadedQuotes.isNotEmpty) _allQuotes = loadedQuotes;
          _rebuildFeedItems();
        });
      }
    } catch (_) {
      // Graceful fallback to default in-memory seed verses and quotes
      if (_allVerses.isEmpty) _allVerses = MoodMatchingEngine.defaultSeedVerses;
      if (_allQuotes.isEmpty) _allQuotes = QuoteApiService.seedQuotes;
      if (mounted) {
        setState(() {
          _rebuildFeedItems();
        });
      }
    }
  }

  /// Rebuilds the interleaved feed and applies the current content filter ("All • Verses • Quotes").
  void _rebuildFeedItems() {
    final verseItems = _allVerses.map((v) {
      return InshortsFeedItem.fromVerse(v, langCode: _selectedLanguage);
    }).toList();

    final quoteItems = _allQuotes.map((q) {
      return InshortsFeedItem.fromQuote(q, langCode: _selectedLanguage);
    }).toList();

    // Interleave verses and quotes (alternating)
    final interleaved = <InshortsFeedItem>[];
    final maxLen = verseItems.length > quoteItems.length
        ? verseItems.length
        : quoteItems.length;

    for (var i = 0; i < maxLen; i++) {
      if (i < verseItems.length) interleaved.add(verseItems[i]);
      if (i < quoteItems.length) interleaved.add(quoteItems[i]);
    }

    _allFeedItems = interleaved;
    _applyFilter(_currentFilter, resetPage: false);
  }

  /// Applies content filter ("All • Verses • Quotes").
  void _applyFilter(ContentFilter filter, {bool resetPage = true}) {
    _currentFilter = filter;
    switch (filter) {
      case ContentFilter.all:
        _displayedItems = List.from(_allFeedItems);
        break;
      case ContentFilter.verses:
        _displayedItems = _allFeedItems.where((item) => item.isVerse).toList();
        break;
      case ContentFilter.quotes:
        _displayedItems = _allFeedItems.where((item) => item.isQuote).toList();
        break;
    }

    if (resetPage && _pageController.hasClients && _displayedItems.isNotEmpty) {
      _pageController.jumpToPage(0);
      setState(() {
        activeStage = _displayedItems[0].stage;
      });
    }
  }

  /// Jumps or smoothly scrolls the feed to the first card matching the selected [stage].
  Future<void> _jumpToStage(MoodStage stage) async {
    setState(() {
      activeStage = stage;
    });

    final targetIndex = _displayedItems.indexWhere((item) => item.stage == stage);
    if (targetIndex != -1 && _pageController.hasClients) {
      await _pageController.animateToPage(
        targetIndex,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  /// Loads/jumps to a random card across the feed, automatically updating [activeStage].
  Future<void> loadRandomDailyVerse() async {
    if (_displayedItems.isEmpty) return;

    final randomIndex = (List<int>.generate(_displayedItems.length, (i) => i)..shuffle()).first;
    if (_pageController.hasClients) {
      await _pageController.animateToPage(
        randomIndex,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOutCubic,
      );
    }

    if (mounted) {
      setState(() {
        activeStage = _displayedItems[randomIndex].stage;
      });
    }
  }

  /// Called on every vertical swipe in the [PageView.builder].
  void _onPageChanged(int index) {
    if (index >= 0 && index < _displayedItems.length) {
      final currentCard = _displayedItems[index];
      if (activeStage != currentCard.stage) {
        setState(() {
          activeStage = currentCard.stage;
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

    final mediaQuery = MediaQuery.of(context);
    final textScale = mediaQuery.textScaler.scale(1.0);
    final screenHeight = mediaQuery.size.height;
    final isShortScreen = screenHeight < 680 || textScale > 1.25;
    final isVeryShortScreen = screenHeight < 500;

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
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isShort = constraints.maxHeight < 600 || textScale > 1.25;
              final isVeryShort = constraints.maxHeight < 460;
              final isNarrow = constraints.maxWidth < 340 || textScale > 1.25;
              final horizontalPadding = isNarrow ? 10.0 : 20.0;

              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 540.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Top Bar with App Title, Filter Toggle, and Language Selector
                      Padding(
                        padding: EdgeInsets.fromLTRB(
                          horizontalPadding,
                          isVeryShort ? 4.0 : (isShort ? 6.0 : 12.0),
                          horizontalPadding,
                          0.0,
                        ),
                        child: _buildHeaderBar(
                          palette,
                          isShort: isShort,
                          isVeryShort: isVeryShort,
                          isNarrow: isNarrow,
                        ),
                      ),
                      SizedBox(height: isVeryShort ? 3.0 : (isShort ? 6.0 : 12.0)),

                      // "How is your heart today?" mood chips
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                        child: _buildMoodSection(
                          palette,
                          isShort: isShort,
                          isVeryShort: isVeryShort,
                          isNarrow: isNarrow,
                          textScale: textScale,
                        ),
                      ),
                      SizedBox(height: isVeryShort ? 3.0 : (isShort ? 6.0 : 10.0)),

                      // Vertical Inshorts-style PageView middle feed
                      Expanded(
                        child: _isLoading
                            ? Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  valueColor: AlwaysStoppedAnimation<Color>(palette.accent),
                                ),
                              )
                            : _displayedItems.isEmpty
                                ? Center(
                                    child: Text(
                                      'No moments found in this section.',
                                      style: TextStyle(
                                        fontSize: 14.0,
                                        color: palette.secondaryText,
                                      ),
                                    ),
                                  )
                                : PageView.builder(
                                    scrollDirection: Axis.vertical,
                                    pageSnapping: true,
                                    physics: const BouncingScrollPhysics(),
                                    controller: _pageController,
                                    onPageChanged: _onPageChanged,
                                    itemCount: _displayedItems.length,
                                    itemBuilder: (context, index) {
                                      final item = _displayedItems[index];
                                      final isBookmarked = _bookmarkedIds.contains(item.id);

                                      return InshortsStageCard(
                                        key: ValueKey('${item.id}_$_selectedLanguage'),
                                        item: item,
                                        palette: item.stage.palette,
                                        isBookmarked: isBookmarked,
                                        langCode: _selectedLanguage,
                                        onBookmarkToggle: () {
                                          final wasSaved = _bookmarkedIds.contains(item.id);
                                          setState(() {
                                            if (wasSaved) {
                                              _bookmarkedIds.remove(item.id);
                                            } else {
                                              _bookmarkedIds.add(item.id);
                                            }
                                          });
                                          final message = !wasSaved
                                              ? 'Saved to your quiet sanctuary'
                                              : 'Removed from saved moments';
                                          _showGentleNotice(message, item.stage.palette);
                                        },
                                        onShare: () {
                                          _showGentleNotice(
                                            'Copied to share gentle comfort',
                                            item.stage.palette,
                                          );
                                        },
                                      );
                                    },
                                  ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNav(
        palette,
        isShort: isShortScreen,
        isVeryShort: isVeryShortScreen,
      ),
    );
  }

  /// Top header bar featuring the "Grace & Growth" title, compact filter toggle, and language selector pill.
  Widget _buildHeaderBar(
    StagePalette palette, {
    bool isShort = false,
    bool isVeryShort = false,
    bool isNarrow = false,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final textScale = MediaQuery.textScalerOf(context).scale(1.0);
        final narrowMode = isNarrow || constraints.maxWidth < 340 || textScale > 1.25;

        if (narrowMode) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Row 1: App title with icon full width (prevents truncation to "Gr...")
              Row(
                children: [
                  Container(
                    width: isVeryShort ? 26.0 : (isShort ? 28.0 : 32.0),
                    height: isVeryShort ? 26.0 : (isShort ? 28.0 : 32.0),
                    decoration: BoxDecoration(
                      color: palette.cardSurface,
                      borderRadius: BorderRadius.circular(isVeryShort ? 8.0 : 10.0),
                      border: Border.all(
                        color: palette.cardBorder.withValues(alpha: 0.5),
                        width: 1.0,
                      ),
                    ),
                    child: Icon(
                      Icons.spa_rounded,
                      size: isVeryShort ? 14.0 : (isShort ? 16.0 : 18.0),
                      color: palette.accent,
                    ),
                  ),
                  const SizedBox(width: 8.0),
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
                            fontSize: isVeryShort ? 15.0 : (isShort ? 16.5 : 18.0),
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
                            fontSize: isVeryShort ? 9.5 : (isShort ? 10.0 : 10.5),
                            fontWeight: FontWeight.w400,
                            color: palette.secondaryText,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: isVeryShort ? 4.0 : 6.0),
              Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: _buildLanguageSelectorPill(palette, isCompact: true),
                ),
              ),
              SizedBox(height: isVeryShort ? 3.0 : 5.0),
              Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: _buildFilterToggle(palette),
                ),
              ),
            ],
          );
        }

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Row 1: App Title & Language Selector
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        width: isShort ? 28.0 : 34.0,
                        height: isShort ? 28.0 : 34.0,
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
                          size: isShort ? 16.0 : 19.0,
                          color: palette.accent,
                        ),
                      ),
                      const SizedBox(width: 9.0),
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
                                fontSize: isShort ? 17.0 : 19.0,
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
                                fontSize: isShort ? 10.0 : 11.0,
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

                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: _buildLanguageSelectorPill(palette),
                  ),
                ),
              ],
            ),

            SizedBox(height: isShort ? 6.0 : 10.0),

            // Row 2: Compact Filter Toggle ("All • Verses • Quotes")
            Center(
              child: _buildFilterToggle(palette),
            ),
          ],
        );
      },
    );
  }

  /// Compact Language Selector pill (eng, lus, hin, spa)
  Widget _buildLanguageSelectorPill(StagePalette palette, {bool isCompact = false}) {
    return Container(
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
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 3.0 : 4.0,
        vertical: isCompact ? 2.5 : 3.0,
      ),
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
                _rebuildFeedItems();
              }
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              padding: EdgeInsets.symmetric(
                horizontal: isCompact ? 6.0 : 7.0,
                vertical: isCompact ? 3.5 : 4.0,
              ),
              decoration: BoxDecoration(
                color: isSelected ? palette.accent : Colors.transparent,
                borderRadius: BorderRadius.circular(16.0),
              ),
              child: Text(
                code,
                style: TextStyle(
                  fontSize: 11.0,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? Colors.white : palette.secondaryText,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  /// Compact Filter Toggle ("All • Verses • Quotes")
  Widget _buildFilterToggle(StagePalette palette) {
    return Container(
      decoration: BoxDecoration(
        color: palette.cardSurface.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(20.0),
        border: Border.all(
          color: palette.cardBorder.withValues(alpha: 0.55),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8.0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.5),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildFilterItem('All', ContentFilter.all, palette),
            _buildFilterDot(palette),
            _buildFilterItem('Verses', ContentFilter.verses, palette),
            _buildFilterDot(palette),
            _buildFilterItem('Quotes', ContentFilter.quotes, palette),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterDot(StagePalette palette) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2.5),
      child: Text(
        '•',
        style: TextStyle(
          fontSize: 11.0,
          color: palette.secondaryText.withValues(alpha: 0.45),
        ),
      ),
    );
  }

  Widget _buildFilterItem(String label, ContentFilter filter, StagePalette palette) {
    final isSelected = _currentFilter == filter;
    return GestureDetector(
      onTap: () {
        if (_currentFilter != filter) {
          setState(() {
            _applyFilter(filter, resetPage: true);
          });
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 3.5),
        decoration: BoxDecoration(
          color: isSelected ? palette.accent : Colors.transparent,
          borderRadius: BorderRadius.circular(16.0),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.0,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? Colors.white : palette.secondaryText,
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }

  /// Horizontal "How is your heart today?" chip selector for the 4 [MoodStage] values.
  Widget _buildMoodSection(
    StagePalette palette, {
    bool isShort = false,
    bool isVeryShort = false,
    bool isNarrow = false,
    double textScale = 1.0,
  }) {
    final hideSubtitle = isShort || isNarrow || textScale > 1.2;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  'How is your heart today?',
                  maxLines: 1,
                  style: TextStyle(
                    fontFamily: 'serif',
                    fontSize: isVeryShort ? 14.0 : (isShort ? 16.0 : 18.5),
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.2,
                    color: palette.primaryText,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8.0),
            // Gentle random daily pause trigger
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: loadRandomDailyVerse,
                borderRadius: BorderRadius.circular(20.0),
                child: Padding(
                  padding: EdgeInsets.all(isVeryShort ? 3.0 : 5.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.auto_awesome_outlined,
                        size: isVeryShort ? 12.0 : 14.0,
                        color: palette.accent,
                      ),
                      const SizedBox(width: 4.0),
                      Text(
                        'Random',
                        style: TextStyle(
                          fontSize: isVeryShort ? 9.5 : 11.0,
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
        if (!hideSubtitle) ...[
          const SizedBox(height: 2.0),
          Text(
            'Choose where you find yourself—no need to put on a brave face.',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12.0,
              fontWeight: FontWeight.w400,
              color: palette.secondaryText,
            ),
          ),
        ],
        SizedBox(height: isVeryShort ? 3.0 : (isShort ? 5.0 : 10.0)),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: MoodStage.values.map((stage) {
              final isSelected = activeStage == stage;
              final stagePalette = stage.palette;

              return Padding(
                padding: const EdgeInsets.only(right: 6.0),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      _jumpToStage(stage);
                    },
                    borderRadius: BorderRadius.circular(24.0),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOutCubic,
                      padding: EdgeInsets.symmetric(
                        horizontal: isVeryShort ? 7.0 : (isShort ? 8.5 : 10.5),
                        vertical: isVeryShort ? 3.5 : (isShort ? 4.5 : 6.5),
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
                                  blurRadius: 8.0,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            width: isVeryShort ? 5.0 : 7.0,
                            height: isVeryShort ? 5.0 : 7.0,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isSelected
                                  ? stagePalette.accent
                                  : palette.secondaryText.withValues(alpha: 0.45),
                            ),
                          ),
                          const SizedBox(width: 5.0),
                          Text(
                            stagePalette.stageLabel,
                            style: TextStyle(
                              fontSize: isVeryShort ? 10.0 : (isShort ? 11.0 : 12.0),
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
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

  /// Contemplative bottom navigation bar, centered with maxWidth constraint on wide viewports.
  Widget _buildBottomNav(
    StagePalette palette, {
    bool isShort = false,
    bool isVeryShort = false,
  }) {
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
      child: SafeArea(
        top: false,
        child: Align(
          alignment: Alignment.center,
          heightFactor: 1.0,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 540.0),
            child: BottomNavigationBar(
              currentIndex: _currentNavIndex,
              onTap: (index) {
                setState(() {
                  _currentNavIndex = index;
                });
                if (index == 1) {
                  loadRandomDailyVerse();
                }
              },
              backgroundColor: Colors.transparent,
              elevation: 0,
              iconSize: isVeryShort ? 18.0 : (isShort ? 20.0 : 24.0),
              type: BottomNavigationBarType.fixed,
              selectedItemColor: palette.accent,
              unselectedItemColor: palette.secondaryText.withValues(alpha: 0.75),
              selectedFontSize: isVeryShort ? 9.0 : (isShort ? 10.0 : 11.0),
              unselectedFontSize: isVeryShort ? 9.0 : (isShort ? 10.0 : 11.0),
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
          ),
        ),
      ),
    );
  }
}
