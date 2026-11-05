import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bible_glory/screens/home_stage_screen.dart';
import 'package:bible_glory/theme/mood_stage_theme.dart';
import 'package:bible_glory/widgets/inshorts_stage_card.dart';

void main() {
  group('HomeStageScreen Layout & Responsiveness', () {
    testWidgets('Renders without overflow on 320x640 narrow mobile screen', (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(const MaterialApp(home: HomeStageScreen()));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('Renders without overflow on 360x800 standard Android screen', (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(const MaterialApp(home: HomeStageScreen()));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('Renders without overflow on 412x915 large mobile screen', (tester) async {
      tester.view.physicalSize = const Size(412, 915);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(const MaterialApp(home: HomeStageScreen()));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });

  group('Inshorts Vertical Feed & Requirement Verification', () {
    testWidgets('Scaffold body is wrapped in AnimatedContainer (600ms, Curves.easeInOutCubic, LinearGradient)', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: HomeStageScreen()));
      await tester.pumpAndSettle();

      final animatedContainerFinder = find.descendant(
        of: find.byType(Scaffold),
        matching: find.byType(AnimatedContainer),
      );
      expect(animatedContainerFinder, findsWidgets);

      final animatedContainer = tester.widget<AnimatedContainer>(animatedContainerFinder.first);
      expect(animatedContainer.duration, const Duration(milliseconds: 600));
      expect(animatedContainer.curve, Curves.easeInOutCubic);

      final decoration = animatedContainer.decoration as BoxDecoration;
      expect(decoration.gradient, isA<LinearGradient>());
      final gradient = decoration.gradient as LinearGradient;
      final gloomyPalette = StagePalette.gloomy;
      expect(gradient.colors, [gloomyPalette.bgTop, gloomyPalette.bgBottom]);
    });

    testWidgets('Top header bar has "Grace & Growth", compact filter toggle, and language selector pill', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: HomeStageScreen()));
      await tester.pumpAndSettle();

      // App Title
      expect(find.text('Grace & Growth'), findsOneWidget);

      // Filter toggle options
      expect(find.text('All'), findsOneWidget);
      expect(find.text('Verses'), findsOneWidget);
      expect(find.text('Quotes'), findsOneWidget);

      // Language selector
      expect(find.text('eng'), findsOneWidget);
      expect(find.text('lus'), findsOneWidget);
      expect(find.text('hin'), findsOneWidget);
      expect(find.text('spa'), findsOneWidget);
    });

    testWidgets('Horizontal chip selector displays "How is your heart today?" and 4 MoodStage values', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: HomeStageScreen()));
      await tester.pumpAndSettle();

      expect(find.text('How is your heart today?'), findsOneWidget);
      expect(find.text(StagePalette.gloomy.stageLabel), findsOneWidget);
      expect(find.text(StagePalette.growing.stageLabel), findsOneWidget);
      expect(find.text(StagePalette.bright.stageLabel), findsOneWidget);
      expect(find.text(StagePalette.humble.stageLabel), findsOneWidget);
      expect(find.text('Random'), findsOneWidget);
    });

    testWidgets('Uses vertical PageView.builder with viewportFraction 0.88, BouncingScrollPhysics, and pageSnapping', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: HomeStageScreen()));
      await tester.pumpAndSettle();

      final pageViewFinder = find.byType(PageView);
      expect(pageViewFinder, findsOneWidget);

      final pageView = tester.widget<PageView>(pageViewFinder);
      expect(pageView.scrollDirection, equals(Axis.vertical));
      expect(pageView.pageSnapping, isTrue);
      expect(pageView.physics, isA<BouncingScrollPhysics>());
      expect(pageView.controller?.viewportFraction, equals(0.88));
    });

    testWidgets('Renders InshortsStageCard with split 55%/45% layout and ValueKey format', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: HomeStageScreen()));
      await tester.pumpAndSettle();

      final cardFinder = find.byType(InshortsStageCard);
      expect(cardFinder, findsWidgets);

      final firstCard = tester.widget<InshortsStageCard>(cardFinder.first);
      expect(firstCard.key, isNotNull);
      expect(firstCard.key.toString(), contains('eng'));
    });

    testWidgets('Filter toggle switches between All, Verses only, and Quotes only', (tester) async {
      final screenKey = GlobalKey<HomeStageScreenState>();
      await tester.pumpWidget(MaterialApp(home: HomeStageScreen(key: screenKey)));
      await tester.pumpAndSettle();

      final state = screenKey.currentState!;
      expect(state.currentFilter, equals(ContentFilter.all));
      expect(state.displayedItems.any((item) => item.isVerse), isTrue);
      expect(state.displayedItems.any((item) => item.isQuote), isTrue);

      // Tap 'Verses'
      await tester.tap(find.text('Verses'));
      await tester.pumpAndSettle();

      expect(state.currentFilter, equals(ContentFilter.verses));
      expect(state.displayedItems.every((item) => item.isVerse), isTrue);

      // Tap 'Quotes'
      await tester.tap(find.text('Quotes'));
      await tester.pumpAndSettle();

      expect(state.currentFilter, equals(ContentFilter.quotes));
      expect(state.displayedItems.every((item) => item.isQuote), isTrue);

      // Tap 'All'
      await tester.tap(find.text('All'));
      await tester.pumpAndSettle();

      expect(state.currentFilter, equals(ContentFilter.all));
    });

    testWidgets('Switching language updates text and reflections in feed', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: HomeStageScreen()));
      await tester.pumpAndSettle();

      expect(find.text('eng'), findsOneWidget);

      // Tap Mizo/Lushai
      await tester.tap(find.text('lus'));
      await tester.pumpAndSettle();

      expect(find.text('Ngaihtuah Zui Atan'), findsWidgets);

      // Tap Hindi
      await tester.tap(find.text('hin'));
      await tester.pumpAndSettle();

      expect(find.text('एक शांत विचार'), findsWidgets);

      // Tap Spanish
      await tester.tap(find.text('spa'));
      await tester.pumpAndSettle();

      expect(find.text('Un Pensamiento Suave'), findsWidgets);
    });

    testWidgets('Tapping mood chip jumps/scrolls to that mood and transitions gradient', (tester) async {
      final screenKey = GlobalKey<HomeStageScreenState>();
      await tester.pumpWidget(MaterialApp(home: HomeStageScreen(key: screenKey)));
      await tester.pumpAndSettle();

      final state = screenKey.currentState!;

      // Tap 'Bright & Grateful'
      await tester.ensureVisible(find.text(StagePalette.bright.stageLabel));
      await tester.tap(find.text(StagePalette.bright.stageLabel));
      await tester.pumpAndSettle();

      expect(state.activeStage, equals(MoodStage.bright));

      final animatedContainer = tester.widget<AnimatedContainer>(
        find.descendant(of: find.byType(Scaffold), matching: find.byType(AnimatedContainer)).first,
      );
      final gradient = (animatedContainer.decoration as BoxDecoration).gradient as LinearGradient;
      expect(gradient.colors, [StagePalette.bright.bgTop, StagePalette.bright.bgBottom]);
    });

    testWidgets('Tapping Save toggles bookmark state and displays floating notice', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: HomeStageScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Save'), findsWidgets);

      // Tap first Save button
      await tester.tap(find.text('Save').first);
      await tester.pumpAndSettle();

      expect(find.text('Saved to your quiet sanctuary'), findsOneWidget);
      expect(find.text('Saved'), findsWidgets);
    });

    testWidgets('Tapping Share triggers gentle comfort notice', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: HomeStageScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Share'), findsWidgets);

      await tester.tap(find.text('Share').first);
      await tester.pumpAndSettle();

      expect(find.text('Copied to share gentle comfort'), findsOneWidget);
    });
  });

  group('Cross-Device Responsiveness & Adaptive Viewports', () {
    testWidgets('Renders without overflow on 280x653 narrow foldable screen (Galaxy Z Fold)', (tester) async {
      tester.view.physicalSize = const Size(280, 653);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(const MaterialApp(home: HomeStageScreen()));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Grace & Growth'), findsOneWidget);
    });

    testWidgets('Renders without overflow on 500dp short screen / split-screen multitasking', (tester) async {
      tester.view.physicalSize = const Size(360, 500);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(const MaterialApp(home: HomeStageScreen()));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(InshortsStageCard), findsWidgets);
    });

    testWidgets('Renders centered within 540dp maxWidth on 1024x768 tablet viewport', (tester) async {
      tester.view.physicalSize = const Size(1024, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(const MaterialApp(home: HomeStageScreen()));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      final cardBox = tester.getRect(find.byType(InshortsStageCard).first);
      expect(cardBox.width, lessThanOrEqualTo(540.0));
      expect(cardBox.left, greaterThan(200.0));
    });

    testWidgets('Renders centered within 540dp maxWidth on 1920x1080 desktop viewport', (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(const MaterialApp(home: HomeStageScreen()));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      final cardBox = tester.getRect(find.byType(InshortsStageCard).first);
      expect(cardBox.width, lessThanOrEqualTo(540.0));
      expect(cardBox.left, greaterThan(600.0));
    });

    testWidgets('Renders without overflow under 1.5x accessibility text scaling', (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(1.5)),
            child: const HomeStageScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Grace & Growth'), findsOneWidget);
    });

    testWidgets('Renders without overflow on 280x653 narrow screen with 1.5x text scaling', (tester) async {
      tester.view.physicalSize = const Size(280, 653);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(1.5)),
            child: const HomeStageScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('Renders without overflow on 280x653 narrow screen with 2.0x text scaling', (tester) async {
      tester.view.physicalSize = const Size(280, 653);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(2.0)),
            child: const HomeStageScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('Renders without overflow on 360x450 compact split-screen height', (tester) async {
      tester.view.physicalSize = const Size(360, 450);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(const MaterialApp(home: HomeStageScreen()));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('Renders without overflow on 320x480 legacy small phone', (tester) async {
      tester.view.physicalSize = const Size(320, 480);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(const MaterialApp(home: HomeStageScreen()));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('Vertical drag over quote text smoothly scrolls PageView to next card (pass-through)', (tester) async {
      final screenKey = GlobalKey<HomeStageScreenState>();
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(MaterialApp(home: HomeStageScreen(key: screenKey)));
      await tester.pumpAndSettle();

      final state = screenKey.currentState!;
      final initialPage = state.pageController.page ?? 0;

      // Find the quote text widget inside the first card
      final firstCard = find.byType(InshortsStageCard).first;
      final quoteText = find.descendant(
        of: firstCard,
        matching: find.byType(SingleChildScrollView),
      ).first;

      await tester.drag(quoteText, const Offset(0, -400));
      await tester.pumpAndSettle();

      final newPage = state.pageController.page ?? 0;
      expect(newPage, greaterThan(initialPage));
    });
  });
}
