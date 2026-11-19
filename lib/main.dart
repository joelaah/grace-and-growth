import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/splash_screen.dart';
import 'services/notification_service.dart';
import 'theme/mood_stage_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService().initialize();
  await Supabase.initialize(
    url: 'https://cdwkuzqsjyuzonufixji.supabase.co',
    publishableKey: 'sb_publishable_IqnKDG9zDsuGoYiw4bW4vw_sf2Pod-F',
  );
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
        fontFamilyFallback: const ['Noto Sans Devanagari'],
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
        fontFamilyFallback: const ['Noto Sans Devanagari'],
      ),
      home: const SplashScreen(),
    );
  }
}
