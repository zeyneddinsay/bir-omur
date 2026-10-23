import 'package:bir_omur/l10n/generated/app_localizations.dart';
import 'package:bir_omur/models/models.dart';
import 'package:bir_omur/ui/widgets/swipe_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_cards.dart';
import '../helpers/people.dart';
import '../helpers/test_character.dart';

Widget _wrap(Widget child) => MaterialApp(
  locale: const Locale('tr'),
  supportedLocales: AppLocalizations.supportedLocales,
  localizationsDelegates: const [
    AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  home: Scaffold(body: child),
);

void main() {
  testWidgets('zarlı seçenekte zar işareti ve baktığı değer görünür', (
    tester,
  ) async {
    final card = testCard(
      'zarli',
      text: 'Sınav sabahı.',
      left: {'label': 'Sakin kal'},
      right: {
        'label': 'Kolaylardan başla',
        'roll': {'stat': 'knowledge', 'threshold': 50},
        'success': {'happiness': 2},
        'fail': {'happiness': -2},
      },
    );
    await tester.pumpWidget(
      _wrap(SwipeCard(card: card, text: card.text, onChoose: (_) {})),
    );
    await tester.pumpAndSettle();

    final badge = find.byKey(const Key('roll_badge'));
    expect(badge, findsOneWidget, reason: 'yalnızca zarlı seçenekte');
    expect(
      find.descendant(
        of: find.byKey(const Key('choose_right')),
        matching: badge,
      ),
      findsOneWidget,
    );
    expect(find.text('Zar: Bilgi'), findsOneWidget);
    expect(find.byIcon(Icons.casino_outlined), findsOneWidget);
  });

  testWidgets('şans zarı "Zar: Şans" yazar', (tester) async {
    final card = testCard(
      'sansli',
      text: 'Kura çekiliyor.',
      left: {
        'label': 'Kurayı çek',
        'roll': {'stat': 'luck', 'threshold': 50},
        'success': {'happiness': 2},
        'fail': {'happiness': -2},
      },
    );
    await tester.pumpWidget(
      _wrap(SwipeCard(card: card, text: card.text, onChoose: (_) {})),
    );
    await tester.pumpAndSettle();
    expect(find.text('Zar: Şans'), findsOneWidget);
  });

  testWidgets('seçenek neye dokunacağını ve zarın ihtimalini gösterir', (
    tester,
  ) async {
    final card = testCard(
      'salincak',
      text: 'Parkta tek salıncak boş.',
      left: {
        'label': 'Ben de koşarım',
        'roll': {'stat': 'luck', 'threshold': 50},
        'success': {'happiness': 3},
        'fail': {'happiness': -1, 'health': -1},
      },
      right: {
        'label': 'Sıramı beklerim',
        'effects': {'reputation': 1, 'money': -25000},
      },
    );
    ChoiceSide? chosen;
    await tester.pumpWidget(
      _wrap(
        SwipeCard(
          card: card,
          text: card.text,
          character: testCharacter(luck: 90),
          onChoose: (side) => chosen = side,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final left = find.byKey(const Key('choose_left'));
    final right = find.byKey(const Key('choose_right'));
    // Şansı yüksek oyuncuya ihtimal yüksek görünür.
    expect(
      find.descendant(
        of: left,
        matching: find.byKey(const Key('roll_odds_yuksek')),
      ),
      findsOneWidget,
    );
    expect(find.descendant(of: left, matching: find.text('Tutarsa')), findsOne);
    expect(
      find.descendant(of: left, matching: find.text('Tutmazsa')),
      findsOne,
    );
    // Zarsız seçenekte para tutarıyla, gösterge yönüyle görünür.
    expect(
      find.descendant(of: right, matching: find.text('−25 bin TL')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: right, matching: find.byTooltip('İtibar artar')),
      findsOneWidget,
    );

    await tester.tap(right);
    await tester.pumpAndSettle();
    expect(chosen, ChoiceSide.right);
  });

  testWidgets('akraba önizlemede adıyla değil akrabalığıyla anılır', (
    tester,
  ) async {
    final card = testCard(
      'ilk_bayram',
      text: 'İlk bayramın.',
      roles: {
        'buyuk': {
          'kin': ['nine'],
        },
      },
      left: {
        'label': 'Onun kucağında uyu',
        'effects': {
          'people': {
            'buyuk': {
              'memory': {
                'kind': 'kucak',
                'label': 'Kucağımda uyudu',
                'tone': 'olumlu',
                'severity': 1,
              },
            },
          },
        },
      },
    );
    final c = withPeople(testCharacter(age: 1), [
      testPerson(
        'p1',
        name: 'Meral',
        gender: Gender.kadin,
        kin: Kinship.nine,
        side: Side.baba,
        age: 60,
        playerAge: 1,
      ),
    ]);
    await tester.pumpWidget(
      _wrap(
        SwipeCard(
          card: card,
          text: card.text,
          character: c,
          people: const {'buyuk': 'p1'},
          onChoose: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    final left = find.byKey(const Key('choose_left'));
    expect(
      find.descendant(of: left, matching: find.text('Babaannen')),
      findsOne,
    );
    expect(
      find.descendant(of: left, matching: find.text('Meral')),
      findsNothing,
    );
  });

  testWidgets('devamı olan seçenek kaç yıl sonra geleceğini yazar', (
    tester,
  ) async {
    final card = testCard(
      'sinav',
      text: 'Sınav sabahı.',
      left: {
        'label': 'Baştan sona',
        'roll': {'stat': 'knowledge', 'threshold': 50},
        'success': {'happiness': 2},
        'fail': {
          'happiness': -2,
          'schedule': {'event': 'devam', 'inYears': 1},
        },
      },
    );
    await tester.pumpWidget(
      _wrap(SwipeCard(card: card, text: card.text, onChoose: (_) {})),
    );
    await tester.pumpAndSettle();
    expect(find.text('1 yıl sonra devamı var'), findsOneWidget);
    expect(
      find.byTooltip('Bu seçimin devamı 1 yıl sonra karşına çıkacak.'),
      findsOneWidget,
    );
  });
}
