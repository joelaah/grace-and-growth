import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/mood_stage_theme.dart';
import 'home_stage_screen.dart';

/// A 3-page onboarding flow introducing the app's core features.
///
/// Page 1: Mood selection concept
/// Page 2: Vertical swipe feed concept
/// Page 3: Mystery box concept + "Begin" button
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  static const List<StagePalette> _pagePalettes = [
    StagePalette.gloomy,
    StagePalette.growing,
    StagePalette.gloomy,
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_complete', true);

    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const HomeStageScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = _pagePalettes[_currentPage];
    final mediaQuery = MediaQuery.of(context);
    final isWideScreen = mediaQuery.size.width >= 720;
    final isDark = palette.isDarkPalette;

    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOutCubic,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [palette.bgTop, palette.bgBottom],
          ),
        ),
        child: Stack(
          children: [
            // Top-right luminous candlelight halo (warm amber / golden radiance)
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment(isWideScreen ? 0.30 : 0.65, -0.60),
                      radius: isWideScreen ? 0.75 : 0.95,
                      colors: [
                        palette.accent.withValues(alpha: isDark ? 0.20 : 0.12),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // Bottom-left deep celestial glow (twilight sapphire / sacred radiance)
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment(isWideScreen ? -0.30 : -0.65, 0.60),
                      radius: isWideScreen ? 0.85 : 1.05,
                      colors: [
                        (isDark ? const Color(0xFF1B2433) : const Color(0xFFE8DFC8))
                            .withValues(alpha: isDark ? 0.45 : 0.30),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),
            SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 540),
                  child: Column(
                    children: [
                      // Skip button
                      Align(
                        alignment: Alignment.topRight,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: TextButton(
                            onPressed: _completeOnboarding,
                            child: Text(
                              'Skip',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: palette.secondaryText,
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Pages
                      Expanded(
                        child: PageView(
                          controller: _pageController,
                          onPageChanged: (index) {
                            setState(() => _currentPage = index);
                          },
                          children: [
                            _buildMoodPage(),
                            _buildSwipePage(),
                            _buildMysteryPage(),
                          ],
                        ),
                      ),

                      // Page indicator dots + action button
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Dots
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(3, (i) {
                                final isActive = i == _currentPage;
                                return AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  margin: const EdgeInsets.symmetric(horizontal: 4),
                                  width: isActive ? 24 : 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: isActive
                                        ? palette.accent
                                        : palette.secondaryText.withValues(alpha: 0.3),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                );
                              }),
                            ),

                            const SizedBox(height: 24),

                            // Next / Begin button
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _currentPage < 2
                                    ? () => _pageController.nextPage(
                                          duration: const Duration(milliseconds: 400),
                                          curve: Curves.easeInOutCubic,
                                        )
                                    : _completeOnboarding,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: palette.accent,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  elevation: 0,
                                ),
                                child: Text(
                                  _currentPage < 2 ? 'Next' : 'Begin',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMoodPage() {
    final palette = _pagePalettes[0];
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxHeight < 520 || constraints.maxWidth < 340;
        final iconSize = isCompact ? 44.0 : 64.0;
        final titleSize = isCompact ? 21.0 : 26.0;
        final subtitleSize = isCompact ? 13.5 : 15.0;
        final verticalGap = isCompact ? 14.0 : 28.0;

        return Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.favorite_outline_rounded,
                  size: iconSize,
                  color: palette.accent,
                ),
                SizedBox(height: verticalGap),
                Text(
                  'Choose your mood',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'serif',
                    fontSize: titleSize,
                    fontWeight: FontWeight.w600,
                    color: palette.primaryText,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Tell us where your heart is today.\nNo masks needed here.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: subtitleSize,
                    height: 1.4,
                    color: palette.secondaryText,
                  ),
                ),
                SizedBox(height: verticalGap),
                // Mini mood chips preview
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: MoodStage.values.map((stage) {
                    final sp = stage.palette;
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: palette.cardSurface.withValues(alpha: 0.72),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: sp.accent.withValues(alpha: 0.55),
                              width: 1.1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.08),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: sp.accent,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                sp.stageLabel,
                                style: TextStyle(
                                  fontSize: isCompact ? 11 : 12,
                                  fontWeight: FontWeight.w500,
                                  color: palette.primaryText,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSwipePage() {
    final palette = _pagePalettes[1];
    final isDark = palette.isDarkPalette;
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxHeight < 520 || constraints.maxWidth < 340;
        final iconSize = isCompact ? 44.0 : 64.0;
        final titleSize = isCompact ? 21.0 : 26.0;
        final subtitleSize = isCompact ? 13.5 : 15.0;
        final verticalGap = isCompact ? 14.0 : 28.0;

        return Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.swipe_vertical_rounded,
                  size: iconSize,
                  color: palette.accent,
                ),
                SizedBox(height: verticalGap),
                Text(
                  'Swipe to explore',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'serif',
                    fontSize: titleSize,
                    fontWeight: FontWeight.w600,
                    color: palette.primaryText,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Bible verses and gentle quotes\nblend in a calming vertical feed.\nSwipe up to discover more.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: subtitleSize,
                    height: 1.4,
                    color: palette.secondaryText,
                  ),
                ),
                SizedBox(height: verticalGap),
                // Mini card preview with frosted glass styling
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                    child: Container(
                      padding: EdgeInsets.all(isCompact ? 14 : 20),
                      decoration: BoxDecoration(
                        color: palette.cardSurface.withValues(alpha: isDark ? 0.72 : 0.84),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: palette.cardBorder.withValues(alpha: 0.75),
                          width: 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.16),
                            blurRadius: 22,
                            offset: const Offset(0, 6),
                          ),
                          BoxShadow(
                            color: palette.accent.withValues(alpha: 0.10),
                            blurRadius: 28,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.auto_stories_outlined,
                            size: isCompact ? 22 : 28,
                            color: palette.accent,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '"Be still, and know\nthat I am God."',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'serif',
                              fontSize: isCompact ? 14 : 16,
                              height: 1.35,
                              color: palette.primaryText,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Psalm 46:10',
                            style: TextStyle(
                              fontSize: isCompact ? 11 : 12,
                              fontWeight: FontWeight.w600,
                              color: palette.accent,
                            ),
                          ),
                        ],
                      ),
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

  Widget _buildMysteryPage() {
    final palette = _pagePalettes[2];
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxHeight < 520 || constraints.maxWidth < 340;
        final bubbleSize = isCompact ? 56.0 : 80.0;
        final iconSize = isCompact ? 28.0 : 40.0;
        final titleSize = isCompact ? 21.0 : 26.0;
        final subtitleSize = isCompact ? 13.5 : 15.0;
        final verticalGap = isCompact ? 14.0 : 28.0;

        return Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: bubbleSize,
                  height: bubbleSize,
                  decoration: BoxDecoration(
                    color: palette.accent.withValues(alpha: 0.16),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: palette.accent.withValues(alpha: 0.5),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: palette.accent.withValues(alpha: 0.22),
                        blurRadius: 24,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.inventory_2_outlined,
                    size: iconSize,
                    color: palette.accent,
                  ),
                ),
                SizedBox(height: verticalGap),
                Text(
                  'Your mystery box awaits',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'serif',
                    fontSize: titleSize,
                    fontWeight: FontWeight.w600,
                    color: palette.primaryText,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Each day holds a personal message\nchosen just for your heart.\nTap "For You" to unseal it.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: subtitleSize,
                    height: 1.4,
                    color: palette.secondaryText,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
