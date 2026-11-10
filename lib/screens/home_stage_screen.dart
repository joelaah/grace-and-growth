import 'dart:async';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/inshorts_feed_item.dart';
import '../models/tagged_verse.dart';
import '../services/bible_api_service.dart';
import '../services/journal_storage.dart';
import '../services/mood_matching_engine.dart';
import '../services/mystery_box_engine.dart';
import '../services/quote_api_service.dart';
import '../services/tts_service.dart';
import '../theme/mood_stage_theme.dart';
import '../utils/parallax_card_effect.dart';
import '../widgets/inshorts_stage_card.dart';
import '../widgets/mystery_box_modal.dart';
import '../widgets/notification_time_picker.dart';
import 'today_screen.dart';
import 'journal_screen.dart';
import 'feelings_screen.dart';
import 'auth_screen.dart';
import 'community_screen.dart';

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
  final MysteryBoxEngine? mysteryBoxEngine;
  final MoodStage initialStage;

  const HomeStageScreen({
    super.key,
    this.moodMatchingEngine,
    this.bibleApiService,
    this.quoteApiService,
    this.mysteryBoxEngine,
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
  int _currentNavIndex = 1; // Default to Reflect (feed) tab

  /// Single unified Spiritual Bible theme mode: 'dark' (Sanctuary Twilight) or 'light' (Sacred Scripture)
  late String _themeMode;

  late final BibleApiService _bibleApiService;
  late final MoodMatchingEngine _moodMatchingEngine;
  late final QuoteApiService _quoteApiService;
  late final MysteryBoxEngine _mysteryBoxEngine;
  late final PageController _pageController;
  late final JournalStorage _journalStorage;

  List<TaggedVerse> _allVerses = [];
  List<InspirationalQuote> _allQuotes = [];
  List<InshortsFeedItem> _allFeedItems = [];
  List<InshortsFeedItem> _displayedItems = [];
  bool _isLoading = true;

  // State for debouncing mouse wheel / trackpad scroll & keyboard navigation
  bool _isPageAnimating = false;
  bool _isScrollDebounced = false;
  double _accumulatedScrollDelta = 0.0;
  Timer? _scrollResetTimer;
  Timer? _scrollDebounceTimer;
  final FocusNode _focusNode = FocusNode();

  bool get isLoading => _isLoading;
  PageController get pageController => _pageController;
  ContentFilter get currentFilter => _currentFilter;
  List<InshortsFeedItem> get displayedItems => _displayedItems;

  static const List<String> _languages = ['eng', 'lus', 'hin', 'spa'];

  @override
  void initState() {
    super.initState();
    activeStage = widget.initialStage;
    _themeMode = activeStage.palette.isDarkPalette ? 'dark' : 'light';
    _bibleApiService = widget.bibleApiService ?? BibleApiService();
    _moodMatchingEngine = widget.moodMatchingEngine ??
        MoodMatchingEngine(bibleApiService: _bibleApiService);
    _quoteApiService = widget.quoteApiService ?? QuoteApiService();
    _mysteryBoxEngine = widget.mysteryBoxEngine ??
        MysteryBoxEngine(
          moodMatchingEngine: _moodMatchingEngine,
          quoteApiService: _quoteApiService,
        );
    _journalStorage = JournalStorage();

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
    _loadThemePreference();
  }

  @override
  void dispose() {
    TtsService().stop();
    _scrollResetTimer?.cancel();
    _scrollDebounceTimer?.cancel();
    _focusNode.dispose();
    _pageController.dispose();
    super.dispose();
  }

  /// Loads the saved dark/light mode preference with automatic migration of legacy 'auto' values.
  Future<void> _loadThemePreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final mode = prefs.getString('theme_mode');
      if (mounted) {
        if (mode == 'dark' || mode == 'light') {
          setState(() {
            _themeMode = mode!;
            activeStage = mode == 'light' ? MoodStage.bright : MoodStage.gloomy;
          });
        } else if (mode == 'auto') {
          final isDark = WidgetsBinding.instance.platformDispatcher.platformBrightness != Brightness.light;
          final resolvedMode = isDark ? 'dark' : 'light';
          setState(() {
            _themeMode = resolvedMode;
            activeStage = resolvedMode == 'light' ? MoodStage.bright : MoodStage.gloomy;
          });
          await prefs.setString('theme_mode', resolvedMode);
        }
      }
    } catch (_) {
      // Graceful fallback to initial
    }
  }

  /// Toggles between single spiritual Light mode and Dark mode.
  Future<void> _toggleThemeMode() async {
    final nextMode = _themeMode == 'dark' ? 'light' : 'dark';
    setState(() {
      _themeMode = nextMode;
      activeStage = nextMode == 'light' ? MoodStage.bright : MoodStage.gloomy;
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('theme_mode', nextMode);
    } catch (_) {
      // Ignore
    }
  }

  /// Public toggle helper for switching between Light and Dark mode.
  Future<void> toggleThemeMode() => _toggleThemeMode();

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
    }
  }

  /// Jumps or smoothly scrolls the feed to the first card matching the selected [stage].
  Future<void> _jumpToStage(MoodStage stage) async {
    setState(() {
      activeStage = stage;
      _themeMode = stage.palette.isDarkPalette ? 'dark' : 'light';
    });

    // Record mood for today
    _journalStorage.recordMoodForToday(stage);

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
  }

  /// Called on every vertical swipe in the [PageView.builder].
  void _onPageChanged(int index) {
    TtsService().stop();
    // Maintain single unified theme mode during swipe to avoid flashing and eye strain
  }

  /// Intercepts mouse wheel / trackpad scroll events and resolves them before
  /// Flutter's default Scrollable applies erratic fractional offsets.
  void _onPointerSignal(PointerSignalEvent event) {
    if (event is PointerScrollEvent) {
      if (event.scrollDelta.dy.abs() > 0 && event.scrollDelta.dy.abs() >= event.scrollDelta.dx.abs()) {
        GestureBinding.instance.pointerSignalResolver.register(event, (resolvedEvent) {
          if (resolvedEvent is PointerScrollEvent) {
            _handleDebouncedPointerScroll(resolvedEvent.scrollDelta.dy);
          }
        });
      }
    }
  }

  /// Debounces rapid scroll wheel notches and trackpad momentum, smoothly
  /// animating to the target card once threshold is reached without stutter.
  void _handleDebouncedPointerScroll(double dy) {
    if (!_pageController.hasClients || _displayedItems.isEmpty || dy == 0) return;

    // Reset accumulated delta if user pauses scrolling
    _scrollResetTimer?.cancel();
    _scrollResetTimer = Timer(const Duration(milliseconds: 200), () {
      _accumulatedScrollDelta = 0.0;
    });

    // If scrolling direction reverses, reset accumulator so new direction responds immediately
    if ((_accumulatedScrollDelta > 0 && dy < 0) || (_accumulatedScrollDelta < 0 && dy > 0)) {
      _accumulatedScrollDelta = 0.0;
    }

    // Ignore events while animation is active or during debounce cooldown
    if (_isPageAnimating || _isScrollDebounced) {
      return;
    }

    _accumulatedScrollDelta += dy;

    // A threshold of 20dp triggers immediately for discrete wheel clicks (typically 20-50dp),
    // while aggregating continuous trackpad swipes before firing a clean transition.
    const double threshold = 20.0;
    if (_accumulatedScrollDelta.abs() >= threshold) {
      final direction = _accumulatedScrollDelta > 0 ? 1 : -1;
      _accumulatedScrollDelta = 0.0;

      final currentPage = _pageController.page?.round() ?? _pageController.initialPage;
      final targetPage = (currentPage + direction).clamp(0, _displayedItems.length - 1);

      // If already at boundary in this direction, do not lock out scrolls in the valid direction
      if (targetPage == currentPage) {
        return;
      }

      _isScrollDebounced = true;
      _scrollDebounceTimer?.cancel();
      _scrollDebounceTimer = Timer(const Duration(milliseconds: 500), () {
        if (mounted) {
          _isScrollDebounced = false;
        }
      });
      _animateToRelativePage(direction);
    }
  }

  /// Smoothly animates the feed by [offset] pages (e.g. +1 for next, -1 for previous).
  Future<void> _animateToRelativePage(int offset) async {
    if (_isPageAnimating || !_pageController.hasClients || _displayedItems.isEmpty) return;

    final currentPage = _pageController.page?.round() ?? _pageController.initialPage;
    final targetPage = (currentPage + offset).clamp(0, _displayedItems.length - 1);

    if (targetPage == currentPage) return;

    _isPageAnimating = true;
    try {
      await _pageController.animateToPage(
        targetPage,
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeOutCubic,
      );
    } catch (_) {
      // Ignored
    } finally {
      if (mounted) {
        _isPageAnimating = false;
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
              final isWide = constraints.maxWidth >= 720;
              final horizontalPadding = isNarrow ? 10.0 : (isWide ? 24.0 : 20.0);

              return Focus(
                focusNode: _focusNode,
                autofocus: true,
                onKeyEvent: (node, event) {
                  // Only handle keyboard for Reflect tab (feed)
                  if (_currentNavIndex != 1) return KeyEventResult.ignored;
                  if (event is KeyDownEvent || event is KeyRepeatEvent) {
                    if (event.logicalKey == LogicalKeyboardKey.arrowDown ||
                        event.logicalKey == LogicalKeyboardKey.pageDown ||
                        (event.logicalKey == LogicalKeyboardKey.space &&
                            !HardwareKeyboard.instance.isShiftPressed)) {
                      _animateToRelativePage(1);
                      return KeyEventResult.handled;
                    } else if (event.logicalKey == LogicalKeyboardKey.arrowUp ||
                        event.logicalKey == LogicalKeyboardKey.pageUp ||
                        (event.logicalKey == LogicalKeyboardKey.space &&
                            HardwareKeyboard.instance.isShiftPressed)) {
                      _animateToRelativePage(-1);
                      return KeyEventResult.handled;
                    }
                  }
                  return KeyEventResult.ignored;
                },
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

                    // Tab content area
                    Expanded(
                      child: _buildTabContent(palette),
                    ),
                  ],
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
      floatingActionButton: _currentNavIndex == 1
          ? _buildForYouFloatingButton(palette)
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  /// Builds the content for the currently selected tab.
  Widget _buildTabContent(StagePalette palette) {
    switch (_currentNavIndex) {
      case 0:
        return TodayScreen(
          palette: palette,
          verses: _allVerses,
          quotes: _allQuotes,
          langCode: _selectedLanguage,
          bookmarkedIds: _bookmarkedIds,
          onBookmarkToggle: (id) {
            setState(() {
              if (_bookmarkedIds.contains(id)) {
                _bookmarkedIds.remove(id);
              } else {
                _bookmarkedIds.add(id);
              }
            });
          },
        );
      case 2:
        return JournalScreen(
          palette: palette,
          allFeedItems: _allFeedItems,
          bookmarkedIds: _bookmarkedIds,
          journalStorage: _journalStorage,
          onBookmarkToggle: (id) {
            setState(() {
              _bookmarkedIds.remove(id);
            });
          },
        );
      case 3:
        return FeelingsScreen(
          palette: palette,
          journalStorage: _journalStorage,
        );
      default:
        // Reflect tab (index 1) — the vertical swipe feed
        return _buildFeedContent(palette);
    }
  }

  /// The vertical Inshorts-style PageView feed (Reflect tab).
  Widget _buildFeedContent(StagePalette palette) {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          valueColor: AlwaysStoppedAnimation<Color>(palette.accent),
        ),
      );
    }

    if (_displayedItems.isEmpty) {
      return Center(
        child: Text(
          'No moments found in this section.',
          style: TextStyle(
            fontSize: 14.0,
            color: palette.secondaryText,
          ),
        ),
      );
    }

    return Stack(
      children: [
        Positioned.fill(
          child: ScrollConfiguration(
            behavior: ScrollConfiguration.of(context).copyWith(
              dragDevices: {
                PointerDeviceKind.touch,
                PointerDeviceKind.mouse,
                PointerDeviceKind.trackpad,
                PointerDeviceKind.stylus,
              },
            ),
            child: PageView.builder(
              scrollDirection: Axis.vertical,
              pageSnapping: true,
              physics: const BouncingScrollPhysics(),
              controller: _pageController,
              onPageChanged: _onPageChanged,
              itemCount: _displayedItems.length,
              itemBuilder: (context, index) {
                final item = _displayedItems[index];
                final isBookmarked = _bookmarkedIds.contains(item.id);

                return AnimatedBuilder(
                  animation: _pageController,
                  builder: (context, child) {
                    final metrics = ParallaxCardEffect.calculate(
                      pageController: _pageController,
                      index: index,
                    );
                    return Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.identity()
                        ..setEntry(3, 2, 0.001)
                        ..multiply(Matrix4.diagonal3Values(
                            metrics.scale, metrics.scale, 1.0))
                        ..multiply(Matrix4.translationValues(
                            0.0, metrics.translationY, 0.0)),
                      child: Opacity(
                        opacity: metrics.opacity,
                        child: child,
                      ),
                    );
                  },
                  child: InshortsStageCard(
                    key: ValueKey('${item.id}_$_selectedLanguage'),
                    item: item,
                    palette: palette,
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
                      _showGentleNotice(message, palette);
                    },
                    onShare: () {
                      _showGentleNotice(
                        'Copied to share gentle comfort',
                        palette,
                      );
                    },
                    onResearch: item.isVerse
                        ? () => _showBibleResearchModal(item, palette)
                        : null,
                  ),
                );
              },
            ),
          ),
        ),
        Positioned.fill(
          child: Listener(
            behavior: HitTestBehavior.translucent,
            onPointerSignal: _onPointerSignal,
          ),
        ),
      ],
    );
  }

  /// Floating "For You" mystery box button opening the [MysteryBoxModal] for [activeStage].
  Widget _buildForYouFloatingButton(StagePalette palette) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          MysteryBoxModal.show(
            context,
            activeMood: activeStage,
            langCode: _selectedLanguage,
            mysteryBoxEngine: _mysteryBoxEngine,
            isItemBookmarked: (item) => _bookmarkedIds.contains(item.id),
            onBookmarkToggle: (item) {
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
            onShare: (item) {
              _showGentleNotice(
                'Copied to share gentle comfort',
                item.stage.palette,
              );
            },
          );
        },
        borderRadius: BorderRadius.circular(28.0),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 9.0),
          decoration: BoxDecoration(
            color: palette.accent,
            borderRadius: BorderRadius.circular(28.0),
            boxShadow: [
              BoxShadow(
                color: palette.accent.withValues(alpha: 0.35),
                blurRadius: 10.0,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.inventory_2_outlined,
                size: 16.0,
                color: Colors.white,
              ),
              SizedBox(width: 5.0),
              Text(
                'For You',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Top header bar featuring the "Grace & Growth" title, theme toggle, compact filter toggle, and language selector pill.
  Widget _buildHeaderBar(
    StagePalette palette, {
    bool isShort = false,
    bool isVeryShort = false,
    bool isNarrow = false,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final textScale = MediaQuery.textScalerOf(context).scale(1.0);
        final narrowMode = isNarrow || constraints.maxWidth < 430 || textScale > 1.15;

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
                          'Daily Sanctuary • Spreading the Gospel',
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
                  _buildCommunityButton(palette),
                  _buildAccountButton(palette),
                  _buildNotificationButton(palette),
                  _buildThemeToggle(palette),
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
            // Row 1: App Title & Theme Toggle & Language Selector
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
                              'Daily Sanctuary • Spreading the Gospel',
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

                const SizedBox(width: 4.0),
                _buildCommunityButton(palette),
                const SizedBox(width: 2.0),
                _buildAccountButton(palette),
                const SizedBox(width: 2.0),
                _buildNotificationButton(palette),
                const SizedBox(width: 2.0),
                _buildThemeToggle(palette),
                const SizedBox(width: 4.0),

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

  /// Single Light/Dark mode toggle button with clear spiritual mode indications.
  Widget _buildThemeToggle(StagePalette palette) {
    final isDark = _themeMode == 'dark';
    final icon = isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded;
    final tooltip = isDark
        ? 'Switch to Light mode (Sacred Scripture)'
        : 'Switch to Dark mode (Sanctuary Twilight)';

    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _toggleThemeMode,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Icon(
              icon,
              size: 18,
              color: palette.secondaryText,
            ),
          ),
        ),
      ),
    );
  }

  /// Displays the interactive Bible Research & Gospel Spreading modal bottom sheet.
  void _showBibleResearchModal(InshortsFeedItem item, StagePalette palette) {
    final verse = item.taggedVerse;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) {
        final screenHeight = MediaQuery.of(modalContext).size.height;
        final isShort = screenHeight < 680;
        final modalHeight = screenHeight * (isShort ? 0.92 : 0.85);

        return Container(
          height: modalHeight,
          decoration: BoxDecoration(
            color: palette.cardSurface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28.0)),
            border: Border.all(
              color: palette.cardBorder.withValues(alpha: 0.8),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 24.0,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Drag handle
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: 10.0, bottom: 8.0),
                    width: 38.0,
                    height: 4.5,
                    decoration: BoxDecoration(
                      color: palette.secondaryText.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                  ),
                ),

                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8.0),
                        decoration: BoxDecoration(
                          color: palette.accent.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(12.0),
                          border: Border.all(
                            color: palette.accent.withValues(alpha: 0.35),
                            width: 1.0,
                          ),
                        ),
                        child: Icon(
                          Icons.auto_stories_rounded,
                          size: 20.0,
                          color: palette.accent,
                        ),
                      ),
                      const SizedBox(width: 12.0),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Bible Research & Study',
                              style: TextStyle(
                                fontFamily: 'serif',
                                fontSize: 17.0,
                                fontWeight: FontWeight.w600,
                                color: palette.primaryText,
                              ),
                            ),
                            Text(
                              'Spreading the Gospel through Living Word',
                              style: TextStyle(
                                fontSize: 11.0,
                                color: palette.secondaryText,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close_rounded, size: 20.0, color: palette.secondaryText),
                        onPressed: () => Navigator.of(modalContext).pop(),
                      ),
                    ],
                  ),
                ),

                const Divider(height: 1.0),

                // Scrollable content
                Flexible(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Scripture Reference Badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
                          decoration: BoxDecoration(
                            color: palette.accent.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          child: Text(
                            item.attribution,
                            style: TextStyle(
                              fontSize: 13.0,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                              color: palette.accent,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12.0),

                        // Main Scripture Verse
                        Container(
                          padding: const EdgeInsets.all(16.0),
                          decoration: BoxDecoration(
                            color: palette.bgTop.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(16.0),
                            border: Border.all(
                              color: palette.cardBorder.withValues(alpha: 0.5),
                              width: 1.0,
                            ),
                          ),
                          child: Text(
                            '“${item.mainText}”',
                            style: TextStyle(
                              fontFamily: 'serif',
                              fontSize: 16.5,
                              height: 1.5,
                              color: palette.primaryText,
                            ),
                          ),
                        ),

                        const SizedBox(height: 20.0),

                        // Research Details Section
                        Text(
                          'Scripture Context & Details',
                          style: TextStyle(
                            fontFamily: 'serif',
                            fontSize: 14.5,
                            fontWeight: FontWeight.w600,
                            color: palette.primaryText,
                          ),
                        ),
                        const SizedBox(height: 8.0),

                        _buildResearchDetailRow(
                          palette,
                          'Translation',
                          verse != null
                              ? 'Berean Standard Bible (BSB) • Public Domain'
                              : 'Curated Contemplative Devotional',
                          Icons.translate_rounded,
                        ),
                        if (verse != null) ...[
                          _buildResearchDetailRow(
                            palette,
                            'Book & Location',
                            'Book: ${verse.book} • Chapter ${verse.chapter}, Verse ${verse.verse}',
                            Icons.bookmark_added_outlined,
                          ),
                          _buildResearchDetailRow(
                            palette,
                            'Theme & Tags',
                            verse.moodTags.join(' • '),
                            Icons.local_offer_outlined,
                          ),
                        ],
                        _buildResearchDetailRow(
                          palette,
                          'Spiritual Aim',
                          'Spreading the Good News of God’s grace, peace, and eternal love.',
                          Icons.favorite_outline_rounded,
                        ),

                        const SizedBox(height: 18.0),

                        // Devotional Reflection
                        Text(
                          'Quiet Devotional Meditation',
                          style: TextStyle(
                            fontFamily: 'serif',
                            fontSize: 14.5,
                            fontWeight: FontWeight.w600,
                            color: palette.primaryText,
                          ),
                        ),
                        const SizedBox(height: 8.0),
                        Text(
                          item.reflectionContent,
                          style: TextStyle(
                            fontSize: 13.5,
                            height: 1.5,
                            fontStyle: FontStyle.italic,
                            color: palette.secondaryText,
                          ),
                        ),

                        const SizedBox(height: 24.0),

                        // Action: Spread the Gospel
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              final gospelText =
                                  '🕊️ Good News for Your Heart:\n\n“${item.mainText}”\n— ${item.attribution}\n\nShared with love to spread the Gospel • Grace & Growth Daily Sanctuary';
                              Clipboard.setData(ClipboardData(text: gospelText));
                              try {
                                Share.share(
                                  gospelText,
                                  subject: 'Spreading the Gospel: ${item.attribution}',
                                );
                              } catch (_) {
                                // Ignore headless test / unsupported platform errors
                              }
                              _showGentleNotice(
                                'Copied to share gentle comfort',
                                palette,
                              );
                              Navigator.of(modalContext).pop();
                            },
                            icon: const Icon(Icons.send_rounded, size: 16.0),
                            label: const Text(
                              'Spread This Gospel Verse',
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.3,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: palette.accent,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14.0),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16.0),
                              ),
                              elevation: 2.0,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildResearchDetailRow(
    StagePalette palette,
    String label,
    String value,
    IconData icon,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16.0, color: palette.accent),
          const SizedBox(width: 8.0),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: TextStyle(fontSize: 12.5, color: palette.secondaryText),
                children: [
                  TextSpan(
                    text: '$label: ',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: palette.primaryText,
                    ),
                  ),
                  TextSpan(text: value),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Daily reminder notification modal trigger.
  Widget _buildNotificationButton(StagePalette palette) {
    return Tooltip(
      message: 'Daily Reminder',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => NotificationTimePickerModal.show(context, palette),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Icon(
              Icons.notifications_none_rounded,
              size: 18,
              color: palette.secondaryText,
            ),
          ),
        ),
      ),
    );
  }

  /// Cloud sync and account modal trigger.
  Widget _buildAccountButton(StagePalette palette) {
    return Tooltip(
      message: 'Cloud Sync & Account',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => AuthModal.show(context, palette),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Icon(
              Icons.cloud_outlined,
              size: 18,
              color: palette.secondaryText,
            ),
          ),
        ),
      ),
    );
  }

  /// Quiet Solidarity (Community Reflections) modal trigger.
  Widget _buildCommunityButton(StagePalette palette) {
    return Tooltip(
      message: 'Quiet Solidarity (Community)',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => CommunityScreen.show(context, palette),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Icon(
              Icons.diversity_3_outlined,
              size: 18,
              color: palette.secondaryText,
            ),
          ),
        ),
      ),
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

  /// Contemplative bottom navigation bar occupying the full width of the screen.
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
        child: BottomNavigationBar(
          currentIndex: _currentNavIndex,
          onTap: (index) {
            setState(() {
              _currentNavIndex = index;
            });
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
    );
  }
}
