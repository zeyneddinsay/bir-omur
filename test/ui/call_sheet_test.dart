import 'package:bir_omur/engine/engine.dart';
import 'package:bir_omur/l10n/generated/app_localizations.dart';
import 'package:bir_omur/models/models.dart';
import 'package:bir_omur/ui/people/person_screen.dart';
import 'package:bir_omur/ui/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/people.dart';
import '../helpers/test_character.dart';

/// Hayat durumu sabit verilen denetleyici; Ara sohbeti ekranı için.
class _FixedLife extends LifeController {
  _FixedLife(this.fixed);

  final LifeState fixed;

  @override
  LifeState? build() => fixed;
}

void main() {
  testWidgets('Ara: aynı türden birden çok anı olsa da anı listesi açılır', (
    tester,
  ) async {
    // Arkadaşla iki kez "eski günleri andık": aynı türden iki anı.
    Memory oldDays(int age) => Memory(
      kind: 'eski_gunler',
      label: 'Eski günleri andık',
      age: age,
      tone: MemoryTone.olumlu,
      severity: 2,
    );
    final c = withPeople(testCharacter(age: 40), [
      testPerson(
        'p1',
        name: 'Ayşe',
        bond: Bond.arkadas,
        age: 40,
        playerAge: 40,
        memories: [oldDays(30), oldDays(35), testMemory('kavga', age: 20)],
      ),
    ]);
    final state = LifeState(character: c, phase: YearPhase.actions);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [lifeProvider.overrideWith(() => _FixedLife(state))],
        child: MaterialApp(
          locale: const Locale('tr'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: const Scaffold(body: CallSheet(personId: 'p1')),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('call_tone_nostalji')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    // Aynı anı listede bir kez görünür.
    expect(find.text('“Eski günleri andık”'), findsOneWidget);
  });
}
