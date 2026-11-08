import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/mood_stage_theme.dart';
import 'home_stage_screen.dart';
import 'onboarding_screen.dart';

/// Animated splash screen with a gentle scale-in icon and fade-in title.
///
/// After 1.5 seconds, checks whether onboarding has been completed and
/// routes the user to either [OnboardingScreen] or [HomeStageScreen].
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.4, 1.0, curve: Curves.easeIn),
    );

    _controller.forward();

    // Navigate after 1.5 seconds
    Future.delayed(const Duration(milliseconds: 1500), _navigateNext);
  }

  Future<void> _navigateNext() async {
    if (!mounted) return;

    final prefs = await SharedPreferences.getInstance();
    final onboardingComplete = prefs.getBool('onboarding_complete') ?? false;

    if (!mounted) return;

    final destination = onboardingComplete
        ? const HomeStageScreen()
        : const OnboardingScreen();

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => destination,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const palette = StagePalette.gloomy;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [palette.bgTop, palette.bgBottom],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Animated spa icon
              ScaleTransition(
                scale: _scaleAnimation,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: palette.cardSurface,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: palette.cardBorder.withValues(alpha: 0.5),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: palette.accent.withValues(alpha: 0.2),
                        blurRadius: 30,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.spa_rounded,
                    size: 40,
                    color: palette.accent,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Fading title
              FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Grace & Growth',
                      style: TextStyle(
                        fontFamily: 'serif',
                        fontSize: 28,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.3,
                        color: palette.primaryText,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Daily Sanctuary',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: palette.secondaryText,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
