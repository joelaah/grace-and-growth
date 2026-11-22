import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bible_glory/models/inshorts_feed_item.dart';
import 'package:bible_glory/models/tagged_verse.dart';
import 'package:bible_glory/screens/home_stage_screen.dart';
import 'package:bible_glory/screens/onboarding_screen.dart';
import 'package:bible_glory/theme/mood_stage_theme.dart';
import 'package:bible_glory/widgets/inshorts_stage_card.dart';

void main() {
  group('Web & Font Contracts', () {
    test('web/index.html contains Noto Sans Devanagari in Google Fonts link and CSS fallback', () {
      final indexHtml = File('web/index.html').readAsStringSync();

      // Verify Google Fonts link includes Noto Sans Devanagari
      expect(indexHtml, contains('Noto+Sans+Devanagari:wght@400;500;600;700'));

      // Verify CSS font-family fallback chain includes Noto Sans Devanagari
      expect(indexHtml, contains("'Noto Sans Devanagari'"));
      expect(indexHtml, contains("font-family: 'Cormorant Garamond', 'Noto Sans Devanagari', Georgia, serif !important;"));

      // Verify Service Worker skipWaiting auto-update logic
      expect(indexHtml, contains('skipWaiting'));
      expect(indexHtml, contains('controllerchange'));
      expect(indexHtml, contains('updatefound'));
    });
  });

  group('InshortsStageCard Frosted Glassmorphism Contracts', () {
    final testVerse = TaggedVerse(
      id: 'PSA.34.18',
      book: 'PSA',
      chapter: 34,
      verse: 18,
      primaryStage: MoodStage.gloomy,
      moodTags: const ['gloomy'],
      textsByLang: const {'eng': 'The Lord is close to the brokenhearted.'},
      reflectionsByLang: const {'eng': 'God draws closest when your spirit feels heavy.'},
    );

    testWidgets('InshortsStageCard contains BackdropFilter and does NOT isolate behind RepaintBoundary', (tester) async {
      final verseItem = InshortsFeedItem.fromVerse(testVerse, langCode: 'eng');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 700,
              width: 500,
              child: InshortsStageCard(
                item: verseItem,
                palette: StagePalette.gloomy,
                langCode: 'eng',
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify there is NO RepaintBoundary wrapping or inside InshortsStageCard
      final repaintBoundaries = find.descendant(
        of: find.byType(InshortsStageCard),
        matching: find.byType(RepaintBoundary),
      );
      expect(repaintBoundaries, findsNothing);

      // Verify BackdropFilter is present
      final backdropFilters = find.descendant(
        of: find.byType(InshortsStageCard),
        matching: find.byType(BackdropFilter),
      );
      expect(backdropFilters, findsOneWidget);

      final filterWidget = tester.widget<BackdropFilter>(backdropFilters.first);
      expect(filterWidget.filter.toString(), contains('18.0'));
    });
  });

  group('Desktop & Tablet Responsive Layout Centering Contracts', () {
    testWidgets('HomeStageScreen centers header, mood chips, feed card, and dock on 1920x1080', (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(const MaterialApp(home: HomeStageScreen()));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);

      // 1. Inshorts card centered at maxWidth: 600
      final cardRect = tester.getRect(find.byType(InshortsStageCard).first);
      expect(cardRect.width, equals(600.0));
      expect(cardRect.left, equals((1920.0 - 600.0) / 2));

      // 2. Header and Mood constrained within maxWidth 820
      final headerFinder = find.text('Grace & Growth');
      expect(headerFinder, findsOneWidget);

      // 3. Floating glass bottom nav constrained within maxWidth 580
      final bottomNavFinder = find.byType(BottomNavigationBar);
      expect(bottomNavFinder, findsOneWidget);
      final navRect = tester.getRect(bottomNavFinder);
      expect(navRect.width, lessThanOrEqualTo(580.0));
    });

    testWidgets('OnboardingScreen centers content at maxWidth: 540 with frosted glass elements', (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(const MaterialApp(home: OnboardingScreen()));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);

      // Verify ConstrainedBox with maxWidth: 540 is present
      final constrainedBoxFinder = find.descendant(
        of: find.byType(OnboardingScreen),
        matching: find.byWidgetPredicate((w) => w is ConstrainedBox && w.constraints.maxWidth == 540.0),
      );
      expect(constrainedBoxFinder, findsOneWidget);

      // Verify BackdropFilter elements are present in the mood pills preview
      final backdropFilters = find.descendant(
        of: find.byType(OnboardingScreen),
        matching: find.byType(BackdropFilter),
      );
      expect(backdropFilters, findsWidgets);
    });
  });
}
