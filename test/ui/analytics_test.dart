import 'package:bir_omur/main.dart';
import 'package:bir_omur/services/analytics_service.dart';
import 'package:bir_omur/services/feedback_service.dart';
import 'package:bir_omur/services/save_store.dart';
import 'package:bir_omur/ui/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/content.dart';

class _RecordingAnalytics implements AnalyticsService {
  final enabled = <bool>[];
  final events = <(String, Map<String, Object>)>[];

  @override
  Future<void> setCollectionEnabled(bool on) async => enabled.add(on);

  @override
  Future<void> logEvent(String name, [Map<String, Object>? parameters]) async =>
      events.add((name, parameters ?? const {}));
}

void main() {
  final content = uiTestContent();

  Widget app(SaveStore store, AnalyticsService analytics) => ProviderScope(
    key: UniqueKey(),
    overrides: [
      contentProvider.overrideWith((ref) async => content),
      seedGeneratorProvider.overrideWithValue(() => 7),
      saveStoreProvider.overrideWithValue(store),
      analyticsServiceProvider.overrideWithValue(analytics),
      feedbackServiceProvider.overrideWithValue(const SilentFeedbackService()),
    ],
    child: const BirOmurApp(),
  );

  void phone(WidgetTester tester) {
    tester.view.devicePixelRatio = 3;
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    addTearDown(tester.view.reset);
  }

  testWidgets('onay sorulur, karar kaydedilir ve bir daha sorulmaz', (
    tester,
  ) async {
    phone(tester);
    final store = MemorySaveStore();
    final analytics = _RecordingAnalytics();
    await tester.pumpWidget(app(store, analytics));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('consent_card')), findsOneWidget);
    expect(analytics.enabled.last, isFalse, reason: 'onaysız kapalı başlar');

    await tester.tap(find.byKey(const Key('consent_accept')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('consent_card')), findsNothing);
    expect(analytics.enabled.last, isTrue);
    expect((await store.loadSettings()).analyticsConsent, isTrue);

    final second = _RecordingAnalytics();
    await tester.pumpWidget(app(store, second));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('consent_card')), findsNothing);
    expect(second.enabled.last, isTrue, reason: 'kayıttaki onay uygulanır');
  });

  testWidgets('reddedilirse analitik kapalı kalır, ayarlardan açılabilir', (
    tester,
  ) async {
    phone(tester);
    final store = MemorySaveStore();
    final analytics = _RecordingAnalytics();
    await tester.pumpWidget(app(store, analytics));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('consent_decline')));
    await tester.pumpAndSettle();
    expect(analytics.enabled.last, isFalse);
    expect((await store.loadSettings()).analyticsConsent, isFalse);

    await tester.tap(find.byKey(const Key('settings_button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('setting_analytics')));
    await tester.pumpAndSettle();
    expect(analytics.enabled.last, isTrue);
  });

  testWidgets('bir hayatın olayları gönderilir; karakter adı gönderilmez', (
    tester,
  ) async {
    phone(tester);
    final analytics = _RecordingAnalytics();
    await tester.pumpWidget(app(MemorySaveStore(), analytics));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('consent_accept')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('birth_name')), 'Gizliİsim');
    await tester.ensureVisible(find.byKey(const Key('birth_button')));
    await tester.tap(find.byKey(const Key('birth_button')));
    await tester.pumpAndSettle();
    while (find.byKey(const Key('rebirth')).evaluate().isEmpty) {
      if (find.byKey(const Key('choose_left')).evaluate().isNotEmpty) {
        await tester.tap(find.byKey(const Key('choose_left')));
      } else {
        await tester.tap(find.byKey(const Key('age_up')));
      }
      await tester.pumpAndSettle();
    }

    final names = analytics.events.map((e) => e.$1).toList();
    expect(names.first, AnalyticsEvents.lifeStart);
    expect(names.where((n) => n == AnalyticsEvents.lifeEnd), hasLength(1));
    final end = analytics.events
        .firstWhere((e) => e.$1 == AnalyticsEvents.lifeEnd)
        .$2;
    expect(
      end.keys,
      containsAll([
        'age',
        'cause',
        'nickname',
        'career',
        'cards',
        'session_minutes',
      ]),
    );
    expect(end['age'], isA<int>());
    for (final (_, params) in analytics.events) {
      for (final value in params.values) {
        expect(
          '$value',
          isNot(contains('Gizli')),
          reason: 'karakter adı gitmemeli',
        );
      }
    }

    // Albüm olayı.
    await tester.ensureVisible(find.byKey(const Key('rebirth')));
    await tester.tap(find.byKey(const Key('rebirth')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('album_button')));
    await tester.tap(find.byKey(const Key('album_button')));
    await tester.pumpAndSettle();
    expect(analytics.events.last.$1, AnalyticsEvents.albumOpen);
  });
}
