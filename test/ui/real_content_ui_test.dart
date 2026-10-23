import 'package:bir_omur/main.dart';
import 'package:bir_omur/ui/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../content/real_cards_test.dart' show loadRealContent;
import '../helpers/stores.dart';

/// Gerçek kartlarla, arayüzden baştan sona oynanan hayatlar. Her adımda
/// ekrandaki hiçbir yazıda kurulmamış şablon (`{a.ad}`) kalmamalı: kart
/// metni, seçenek etiketleri, sonuç paneli, sekmeler ve ölüm ekranı dahil.
void main() {
  final content = loadRealContent();
  final template = RegExp(r'[{}]');

  for (final seed in const [3, 15, 42]) {
    testWidgets(
      'gerçek kartlarla hayat: ekranda ham şablon yok (tohum $seed)',
      (tester) async {
        tester.view.devicePixelRatio = 3;
        tester.view.physicalSize = const Size(390, 844) * 3;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              contentProvider.overrideWith((ref) async => content),
              seedGeneratorProvider.overrideWithValue(() => seed),
              saveStoreProvider.overrideWithValue(answeredStore()),
            ],
            child: const BirOmurApp(),
          ),
        );
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.byKey(const Key('gender_erkek')));
        await tester.tap(find.byKey(const Key('gender_erkek')));
        await tester.pump();
        await tester.ensureVisible(find.byKey(const Key('birth_button')));
        await tester.tap(find.byKey(const Key('birth_button')));
        await tester.pumpAndSettle();

        void expectNoTemplate(String where) {
          final raw = find.textContaining(template).evaluate().map((e) {
            final w = e.widget;
            return w is Text ? w.data ?? w.textSpan?.toPlainText() : '$w';
          }).toList();
          expect(raw, isEmpty, reason: 'adım $where: $raw');
        }

        const tabs = ['people', 'work', 'assets', 'activities', 'me'];
        var steps = 0;
        var years = 0;
        while (find.byKey(const Key('rebirth')).evaluate().isEmpty) {
          expect(++steps, lessThan(3000), reason: 'hayat bitmedi');
          expectNoTemplate('$steps');
          final sides = [
            'choose_left',
            'choose_right',
            if (find.byKey(const Key('choose_up')).evaluate().isNotEmpty)
              'choose_up',
          ];
          if (find.byKey(const Key('choose_left')).evaluate().isNotEmpty) {
            final key = Key(sides[steps % sides.length]);
            await tester.ensureVisible(find.byKey(key));
            await tester.tap(find.byKey(key));
          } else {
            // Birkaç yılda bir bütün sekmeler gezilir.
            if (++years % 7 == 0) {
              for (final tab in tabs) {
                await tester.tap(find.byKey(Key('tab_$tab')));
                await tester.pumpAndSettle();
                expectNoTemplate('$steps sekme $tab');
                // İnsanlar sekmesinde ilk iki kişinin ekranı da açılır.
                if (tab == 'people') {
                  final people = find.byWidgetPredicate(
                    (w) => '${w.key}'.contains("'person_"),
                  );
                  expect(people, findsWidgets);
                  for (final p in people.evaluate().take(2).toList()) {
                    final key = p.widget.key!;
                    await tester.ensureVisible(find.byKey(key));
                    await tester.tap(find.byKey(key));
                    await tester.pumpAndSettle();
                    expectNoTemplate('$steps kişi $key');
                    final back = find.byType(BackButton);
                    if (back.evaluate().isNotEmpty) {
                      await tester.tap(back.first);
                    }
                    await tester.pumpAndSettle();
                  }
                }
              }
            }
            await tester.ensureVisible(find.byKey(const Key('age_up')));
            await tester.tap(find.byKey(const Key('age_up')));
          }
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull, reason: 'adım $steps');
        }
        expectNoTemplate('ölüm ekranı');
      },
    );
  }
}
