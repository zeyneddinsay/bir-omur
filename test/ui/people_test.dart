import 'package:bir_omur/engine/engine.dart';
import 'package:bir_omur/main.dart';
import 'package:bir_omur/models/models.dart';
import 'package:bir_omur/ui/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/content.dart';
import '../helpers/stores.dart';

final _content = uiTestContent();

Future<ProviderContainer> _bornAndGrown(WidgetTester tester, int age) async {
  tester.view.devicePixelRatio = 3;
  tester.view.physicalSize = const Size(390, 844) * 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        contentProvider.overrideWith((ref) async => _content),
        seedGeneratorProvider.overrideWithValue(() => 7),
        saveStoreProvider.overrideWithValue(answeredStore()),
      ],
      child: const BirOmurApp(),
    ),
  );
  await tester.pumpAndSettle();
  await tester.enterText(find.byKey(const Key('birth_name')), 'Elif');
  await tester.tap(find.byKey(const Key('birth_button')));
  await tester.pumpAndSettle();
  final container = ProviderScope.containerOf(
    tester.element(find.byType(Scaffold).first),
  );
  var steps = 0;
  while (true) {
    final state = container.read(lifeProvider)!;
    if (state.character.age >= age && state.phase == YearPhase.actions) break;
    expect(++steps, lessThan(200));
    final key = state.phase == YearPhase.cards ? 'choose_left' : 'age_up';
    await tester.tap(find.byKey(Key(key)));
    await tester.pumpAndSettle();
  }
  return container;
}

void main() {
  testWidgets('İnsanlar sekmesi aileyi gösterir; kişi ekranı açılır', (
    tester,
  ) async {
    final container = await _bornAndGrown(tester, 11);
    final c = container.read(lifeProvider)!.character;
    final parent = c.people.all.firstWhere(
      (p) => p.kin == Kinship.anne || p.kin == Kinship.baba,
    );

    await tester.tap(find.byKey(const Key('tab_people')));
    await tester.pumpAndSettle();
    expect(find.text('Aile'), findsOneWidget);
    await tester.tap(find.byKey(Key('person_${parent.id}')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('person_screen')), findsOneWidget);
    expect(
      find.text(parent.kin == Kinship.anne ? 'Annen' : 'Baban'),
      findsOneWidget,
    );
    expect(find.byKey(const Key('closeness_bar')), findsOneWidget);
    // Aynı evde yaşanan anne ya da baba aranmaz; ev içi etkileşimler var.
    expect(find.byKey(const Key('interaction_ara')), findsNothing);
    expect(find.byKey(const Key('interaction_dertles')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Ara: ton seçilir, sonuç yazılır, vakit düşer', (tester) async {
    final container = await _bornAndGrown(tester, 11);
    final before = container.read(lifeProvider)!;
    // Aynı evde yaşamayan biri: sınıf arkadaşı.
    final parent = before.character.people.all.firstWhere(
      (p) => p.hasRole(RoleKind.sinifArkadasi),
    );

    await tester.tap(find.byKey(const Key('tab_people')));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(Key('person_${parent.id}')),
      200,
      scrollable: find.descendant(
        of: find.byKey(const Key('people_list')),
        matching: find.byType(Scrollable),
      ),
    );
    await tester.tap(find.byKey(Key('person_${parent.id}')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('interaction_ara')));
    await tester.pumpAndSettle();
    expect(find.text('Nasıl konuşacaksın?'), findsOneWidget);
    await tester.tap(find.byKey(const Key('call_tone_halHatir')));
    await tester.pumpAndSettle();

    final after = container.read(lifeProvider)!;
    expect(after.timeLeft, before.timeLeft - 1);
    expect(after.lastInteraction?.personId, parent.id);
    expect(find.byKey(const Key('interaction_result')), findsOneWidget);
    // Aynı yıl ikinci arama kapalı.
    final tile = tester.widget<ListTile>(
      find.byKey(const Key('interaction_ara')),
    );
    expect(tile.enabled, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Ben sekmesinde yılın günlüğü; sekmeler arasında gezinilir', (
    tester,
  ) async {
    await _bornAndGrown(tester, 7);
    expect(find.byKey(const Key('journal')), findsOneWidget);
    // 7 yaşında ilkokul başlar: günlükte haber olarak görünür.
    expect(find.textContaining('İlkokul başladı'), findsOneWidget);
    for (final tab in ['people', 'work', 'assets', 'activities', 'me']) {
      await tester.tap(find.byKey(Key('tab_$tab')));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: tab);
    }
    expect(find.byKey(const Key('age_up')), findsOneWidget);
  });
}
