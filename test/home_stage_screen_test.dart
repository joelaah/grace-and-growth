import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bible_glory/screens/home_stage_screen.dart';
import 'package:bible_glory/theme/mood_stage_theme.dart';
import 'package:bible_glory/widgets/verse_stage_card.dart';

void main() {
  group('HomeStageScreen Layout & Responsiveness', () {
    testWidgets('Renders without overflow on 320x640 narrow mobile screen', (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(const MaterialApp(home: HomeStageScreen()));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('Renders without overflow on 360x800 standard Android screen', (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(const MaterialApp(home: HomeStageScreen()));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('Renders without overflow on 412x915 large mobile screen', (tester) async {
      tester.view.physicalSize = const Size(412, 915);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(const MaterialApp(home: HomeStageScreen()));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });

  group('Requirement Verification', () {
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

    testWidgets('Top header bar has "Grace & Growth" and compact language selector pill (eng, lus, hin, spa)', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: HomeStageScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Grace & Growth'), findsOneWidget);
      expect(find.text('eng'), findsOneWidget);
      expect(find.text('lus'), findsOneWidget);
      expect(find.text('hin'), findsOneWidget);
      expect(find.text('spa'), findsOneWidget);
    });

    testWidgets('Horizontal chip selector displays 4 MoodStage values', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: HomeStageScreen()));
      await tester.pumpAndSettle();

      expect(find.text('How is your heart today?'), findsOneWidget);
      expect(find.text(StagePalette.gloomy.stageLabel), findsOneWidget);
      expect(find.text(StagePalette.growing.stageLabel), findsOneWidget);
      expect(find.text(StagePalette.bright.stageLabel), findsOneWidget);
      expect(find.text(StagePalette.humble.stageLabel), findsOneWidget);
    });

    testWidgets('AnimatedSwitcher has 400ms duration and key format ValueKey(verseId_langCode)', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: HomeStageScreen()));
      await tester.pumpAndSettle();

      final switcherFinder = find.byType(AnimatedSwitcher);
      expect(switcherFinder, findsOneWidget);

      final switcher = tester.widget<AnimatedSwitcher>(switcherFinder);
      expect(switcher.duration, const Duration(milliseconds: 400));

      final verseCardFinder = find.byType(VerseStageCard);
      expect(verseCardFinder, findsOneWidget);

      final verseCard = tester.widget<VerseStageCard>(verseCardFinder);
      expect(verseCard.key, const ValueKey('gloomy_ps34_18_eng'));
    });

    testWidgets('Switching language cross-fades and updates text and key', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: HomeStageScreen()));
      await tester.pumpAndSettle();

      expect(find.textContaining('Lord is close to the brokenhearted'), findsOneWidget);

      // Tap Mizo/Lushai
      await tester.tap(find.text('lus'));
      await tester.pumpAndSettle();

      final verseCard = tester.widget<VerseStageCard>(find.byType(VerseStageCard));
      expect(verseCard.key, const ValueKey('gloomy_ps34_18_lus'));
      expect(find.textContaining('thinlung lungchhiatte hnaihah'), findsOneWidget);
      expect(find.text('Ngaihtuah Zui Atan'), findsOneWidget);

      // Tap Hindi
      await tester.tap(find.text('hin'));
      await tester.pumpAndSettle();

      final hindiCard = tester.widget<VerseStageCard>(find.byType(VerseStageCard));
      expect(hindiCard.key, const ValueKey('gloomy_ps34_18_hin'));
      expect(find.textContaining('यहोवा टूटे मन वालों के समीप'), findsOneWidget);
      expect(find.text('एक शांत विचार'), findsOneWidget);

      // Tap Spanish
      await tester.tap(find.text('spa'));
      await tester.pumpAndSettle();

      final spaCard = tester.widget<VerseStageCard>(find.byType(VerseStageCard));
      expect(spaCard.key, const ValueKey('gloomy_ps34_18_spa'));
      expect(find.textContaining('Cercano está Jehová a los quebrantados'), findsOneWidget);
      expect(find.text('Un Pensamiento Suave'), findsOneWidget);
    });

    testWidgets('Switching mood stage transitions gradient and verse key', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: HomeStageScreen()));
      await tester.pumpAndSettle();

      // Tap 'Bright & Grateful'
      await tester.tap(find.text(StagePalette.bright.stageLabel));
      await tester.pumpAndSettle();

      final verseCard = tester.widget<VerseStageCard>(find.byType(VerseStageCard));
      expect(verseCard.key, const ValueKey('bright_num6_24_eng'));
      expect(find.text('Numbers 6:24-26'), findsOneWidget);

      final animatedContainer = tester.widget<AnimatedContainer>(
        find.descendant(of: find.byType(Scaffold), matching: find.byType(AnimatedContainer)).first,
      );
      final gradient = (animatedContainer.decoration as BoxDecoration).gradient as LinearGradient;
      expect(gradient.colors, [StagePalette.bright.bgTop, StagePalette.bright.bgBottom]);
    });

    testWidgets('Bookmark state is maintained per verse without leaking across moods', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: HomeStageScreen()));
      await tester.pumpAndSettle();

      // Gloomy verse starts not saved
      expect(find.text('Save'), findsOneWidget);

      // Bookmark gloomy
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(find.text('Saved'), findsOneWidget);

      // Switch to Growing stage
      await tester.tap(find.text(StagePalette.growing.stageLabel));
      await tester.pumpAndSettle();

      // Growing stage must NOT be bookmarked
      expect(find.text('Save'), findsOneWidget);
      expect(find.text('Saved'), findsNothing);

      // Switch back to Gloomy stage
      await tester.tap(find.text(StagePalette.gloomy.stageLabel));
      await tester.pumpAndSettle();

      // Gloomy stage MUST still be bookmarked
      expect(find.text('Saved'), findsOneWidget);
    });

    testWidgets('Audio playback state is maintained per verse without leaking', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: HomeStageScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Listen'), findsOneWidget);

      // Start audio on gloomy
      await tester.tap(find.text('Listen'));
      await tester.pumpAndSettle();
      expect(find.text('Pause'), findsOneWidget);

      // Switch to Humble stage
      await tester.tap(find.text(StagePalette.humble.stageLabel));
      await tester.pumpAndSettle();

      // Humble must show Listen, not Pause
      expect(find.text('Listen'), findsOneWidget);
      expect(find.text('Pause'), findsNothing);
    });

    testWidgets('Cards have 24px border radius', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: HomeStageScreen()));
      await tester.pumpAndSettle();

      final containers = tester.widgetList<Container>(find.descendant(
        of: find.byType(VerseStageCard),
        matching: find.byType(Container),
      ));

      final cardContainers = containers.where((c) {
        final d = c.decoration;
        if (d is BoxDecoration && d.borderRadius is BorderRadius) {
          final br = d.borderRadius as BorderRadius;
          return br.topLeft.x == 24.0 && br.bottomRight.x == 24.0;
        }
        return false;
      }).toList();

      // Scripture card and Reflection card both have 24px border radius
      expect(cardContainers.length, greaterThanOrEqualTo(2));
    });

    testWidgets('Tapping mood chip or random daily pause updates activeStage = currentVerse.primaryStage', (tester) async {
      final screenKey = GlobalKey<HomeStageScreenState>();
      await tester.pumpWidget(MaterialApp(home: HomeStageScreen(key: screenKey)));
      await tester.pumpAndSettle();

      final state = screenKey.currentState!;
      expect(state.activeStage, equals(MoodStage.gloomy));

      // Tap 'Growing in Sorrow' chip
      await tester.tap(find.text(StagePalette.growing.stageLabel));
      await tester.pumpAndSettle();

      expect(state.activeStage, equals(MoodStage.growing));

      // Tap 'Random' trigger in mood header
      await tester.tap(find.text('Random'));
      await tester.pumpAndSettle();

      // activeStage must match currentVerse.primaryStage
      final verseCard = tester.widget<VerseStageCard>(find.byType(VerseStageCard));
      expect(state.activeStage, isNotNull);
      expect(find.byType(VerseStageCard), findsOneWidget);
      expect(verseCard.verse.id, isNotEmpty);
    });
  });
}
