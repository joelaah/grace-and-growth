import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bible_glory/screens/home_stage_screen.dart';
import 'package:bible_glory/screens/onboarding_screen.dart';
import 'package:bible_glory/screens/today_screen.dart';
import 'package:bible_glory/screens/feelings_screen.dart';
import 'package:bible_glory/screens/journal_screen.dart';
import 'package:bible_glory/theme/mood_stage_theme.dart';
import 'package:bible_glory/widgets/notification_time_picker.dart';

void main() {
  final testSizes = [
    const Size(320, 480), // legacy / small phone
    const Size(360, 640), // compact Android phone
    const Size(375, 667), // iPhone SE / 8
    const Size(390, 844), // iPhone 14 / modern iPhone
    const Size(412, 915), // Pixel 7 / modern Android
    const Size(280, 653), // Galaxy Z Fold narrow outer display
  ];

  group('Cross-Device Screen Constraints & Responsiveness Tests', () {
    for (final size in testSizes) {
      testWidgets('HomeStageScreen layout fits perfectly at ${size.width}x${size.height}', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(const MaterialApp(home: HomeStageScreen()));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
      });

      testWidgets('OnboardingScreen layout fits perfectly at ${size.width}x${size.height}', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(const MaterialApp(home: OnboardingScreen()));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
      });

      testWidgets('Bible Research Modal fits at ${size.width}x${size.height}', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(const MaterialApp(home: HomeStageScreen()));
        await tester.pumpAndSettle();

        final researchFinder = find.text('Research');
        if (researchFinder.evaluate().isNotEmpty) {
          await tester.tap(researchFinder.first);
          await tester.pumpAndSettle();
        }

        expect(tester.takeException(), isNull);
      });

      testWidgets('TodayScreen layout fits at ${size.width}x${size.height}', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(MaterialApp(
          home: Scaffold(
            body: TodayScreen(
              palette: StagePalette.bibleDark,
              verses: const [],
              quotes: const [],
            ),
          ),
        ));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        final ex = tester.takeException();
        if (ex is FlutterError) {
          debugPrint('OVERFLOW DETAIL: ${ex.message}');
          debugPrint('CONTEXT: ${ex.diagnostics.map((d) => d.toString()).join('\n')}');
        }
        expect(ex, isNull);
      });

      testWidgets('FeelingsScreen layout fits at ${size.width}x${size.height}', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(MaterialApp(
          home: Scaffold(
            body: FeelingsScreen(
              palette: StagePalette.bibleDark,
            ),
          ),
        ));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(tester.takeException(), isNull);
      });

      testWidgets('JournalScreen layout fits at ${size.width}x${size.height}', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(MaterialApp(
          home: Scaffold(
            body: JournalScreen(
              palette: StagePalette.bibleDark,
              allFeedItems: const [],
              bookmarkedIds: const {},
            ),
          ),
        ));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(tester.takeException(), isNull);
      });

      testWidgets('NotificationTimePickerModal fits at ${size.width}x${size.height}', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => TextButton(
                onPressed: () => NotificationTimePickerModal.show(ctx, StagePalette.bibleDark),
                child: const Text('Open'),
              ),
            ),
          ),
        ));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Open'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        expect(tester.takeException(), isNull);
      });
    }
  });
}
