import 'package:bir_omur/l10n/generated/app_localizations.dart';
import 'package:bir_omur/ui/widgets/swipe_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_cards.dart';

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
}
