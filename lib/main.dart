import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config/supabase_config.dart';
import 'screens/splash_screen.dart';
import 'services/notification_service.dart';
import 'theme/mood_stage_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService().initialize();

  if (SupabaseConfig.isConfigured) {
    try {
      await Supabase.initialize(
        url: SupabaseConfig.url,
        publishableKey: SupabaseConfig.publishableKey,
      );
    } catch (e) {
      debugPrint('Warning: Supabase initialization failed ($e). Operating in offline mode.');
    }
  } else {
    debugPrint('Supabase is not configured. Operating in offline mode.');
  }

  runApp(const GraceAndGrowthApp());
}

class GraceAndGrowthApp extends StatelessWidget {
  const GraceAndGrowthApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Grace & Growth - Daily Sanctuary',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: StagePalette.bibleLight.bgTop,
        cardColor: StagePalette.bibleLight.cardSurface,
        canvasColor: StagePalette.bibleLight.cardSurface,
        colorScheme: ColorScheme.light(
          primary: StagePalette.bibleLight.accent,
          surface: StagePalette.bibleLight.cardSurface,
          onSurface: StagePalette.bibleLight.primaryText,
          outline: StagePalette.bibleLight.cardBorder,
        ),
        dividerColor: StagePalette.bibleLight.cardBorder,
        fontFamily: 'serif',
        fontFamilyFallback: const [
          'Cormorant Garamond',
          'Noto Sans Devanagari',
          'Georgia',
        ],
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: StagePalette.bibleDark.bgTop,
        cardColor: StagePalette.bibleDark.cardSurface,
        canvasColor: StagePalette.bibleDark.cardSurface,
        colorScheme: ColorScheme.dark(
          primary: StagePalette.bibleDark.accent,
          surface: StagePalette.bibleDark.cardSurface,
          onSurface: StagePalette.bibleDark.primaryText,
          outline: StagePalette.bibleDark.cardBorder,
        ),
        dividerColor: StagePalette.bibleDark.cardBorder,
        fontFamily: 'serif',
        fontFamilyFallback: const [
          'Cormorant Garamond',
          'Noto Sans Devanagari',
          'Georgia',
        ],
      ),
      home: const SplashScreen(),
    );
  }
}
