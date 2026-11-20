import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bible_glory/config/supabase_config.dart';
import 'package:bible_glory/screens/auth_screen.dart';
import 'package:bible_glory/screens/community_screen.dart';
import 'package:bible_glory/services/auth_service.dart';
import 'package:bible_glory/services/cloud_sync_service.dart';
import 'package:bible_glory/services/mood_matching_engine.dart';
import 'package:bible_glory/theme/mood_stage_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SupabaseConfig Environment Validation', () {
    test('SupabaseConfig environment state reflects build flags without baked-in defaults', () {
      if (SupabaseConfig.url.isEmpty) {
        expect(SupabaseConfig.publishableKey, isEmpty);
        expect(SupabaseConfig.isConfigured, isFalse);
      } else {
        expect(
          SupabaseConfig.isConfigured,
          equals(SupabaseConfig.isValidConfig(
            SupabaseConfig.url,
            SupabaseConfig.publishableKey,
          )),
        );
      }
    });

    test('isValidConfig correctly validates valid and invalid configurations', () {
      // Empty / whitespace
      expect(SupabaseConfig.isValidConfig('', ''), isFalse);
      expect(SupabaseConfig.isValidConfig('   ', '   '), isFalse);
      expect(SupabaseConfig.isValidConfig('https://example.supabase.co', ''), isFalse);
      expect(SupabaseConfig.isValidConfig('', 'some-key'), isFalse);

      // Template placeholders from .env.example
      expect(
        SupabaseConfig.isValidConfig(
          'https://your-project-id.supabase.co',
          'your-supabase-publishable-or-anon-key',
        ),
        isFalse,
      );

      // Invalid schemes
      expect(SupabaseConfig.isValidConfig('ftp://test.supabase.co', 'valid-key'), isFalse);
      expect(SupabaseConfig.isValidConfig('ws://test.supabase.co', 'valid-key'), isFalse);
      expect(SupabaseConfig.isValidConfig('javascript:void(0)', 'valid-key'), isFalse);

      // Malformed URLs
      expect(SupabaseConfig.isValidConfig('not a url', 'valid-key'), isFalse);
      expect(SupabaseConfig.isValidConfig('https://', 'valid-key'), isFalse);

      // Valid configurations
      expect(
        SupabaseConfig.isValidConfig(
          'https://cdwkuzqsjyuzonufixji.supabase.co',
          'sb_publishable_IqnKDG9zDsuGoYiw4bW4vw_sf2Pod-F',
        ),
        isTrue,
      );
      expect(
        SupabaseConfig.isValidConfig(
          'https://abcdefghijklmnop.supabase.co',
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.dummy',
        ),
        isTrue,
      );
    });
  });

  group('Offline Resilience Without Initialized Supabase', () {
    test('AuthService methods gracefully handle uninitialized Supabase client', () async {
      final auth = AuthService();
      expect(auth.currentUser, isNull);
      expect(auth.isAuthenticated, isFalse);
      expect(auth.currentUserId, isNull);
      expect(auth.currentUserEmail, isNull);

      // authStateChanges returns empty stream without throwing
      final events = await auth.authStateChanges.toList();
      expect(events, isEmpty);

      // Sign-in / sign-up attempts report AuthException rather than crashing
      expect(
        () => auth.signInWithEmail(email: 'test@example.com', password: 'password123'),
        throwsA(isA<Exception>()),
      );
      expect(
        () => auth.signUpWithEmail(email: 'test@example.com', password: 'password123'),
        throwsA(isA<Exception>()),
      );

      // Sign-out & anonymous sign-in do not throw
      await expectLater(auth.signOut(), completes);
      final anon = await auth.signInAnonymously();
      expect(anon, isNull);
    });

    test('CloudSyncService gracefully skips push/pull when uninitialized or unauthenticated', () async {
      final syncService = CloudSyncService();
      await expectLater(syncService.pushToCloud(), completes);
      await expectLater(syncService.pullFromCloud(), completes);
    });

    test('MoodMatchingEngine gracefully falls back to local seed verses when Supabase client is uninitialized', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final engine = MoodMatchingEngine(prefs: prefs);

      final verses = await engine.loadVerses();
      expect(verses, isNotEmpty);
      expect(verses.any((v) => v.book == 'PSA'), isTrue);
    });

    testWidgets('CommunityScreen gracefully renders calm empty state when Supabase client is uninitialized', (tester) async {
      final palette = StagePalette.bibleLight;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CommunityScreen(palette: palette),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Should render without assertion errors and show empty state
      expect(find.byType(CommunityScreen), findsOneWidget);
      expect(find.text('Quiet Sanctuary'), findsOneWidget);
    });

    testWidgets('AuthModal displays offline sanctuary notice when Supabase is unconfigured', (tester) async {
      final palette = StagePalette.bibleLight;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AuthModal(palette: palette),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(AuthModal), findsOneWidget);
      expect(find.textContaining('Running in local sanctuary mode'), findsOneWidget);
    });
  });
}
