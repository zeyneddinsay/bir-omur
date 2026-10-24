import 'package:bir_omur/engine/engine.dart';
import 'package:bir_omur/l10n/generated/app_localizations.dart';
import 'package:bir_omur/l10n/generated/app_localizations_tr.dart';
import 'package:bir_omur/models/models.dart';
import 'package:bir_omur/ui/widgets/life_status.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/content.dart';
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
  final content = uiTestContent();
  final l10n = AppLocalizationsTr();

  group('jobLabel', () {
    String label(Character c) => jobLabel(l10n, c, content.careers);

    test('meslek ve kademe adı içerikten gelir', () {
      final c = testCharacter(
        age: 30,
        job: const Job(careerId: 'memur', tier: 2),
      );
      expect(label(c), 'Memur · Şef');
      // 1. kademenin adı meslek adıyla aynı: tekrar yazılmaz.
      expect(
        label(
          testCharacter(age: 25, job: const Job(careerId: 'memur', tier: 1)),
        ),
        'Memur',
      );
    });

    test('işsiz, öğrenci, emekli, çocuk', () {
      expect(label(testCharacter(age: 30)), 'İşsiz');
      expect(
        label(testCharacter(age: 20, flags: {ActionCatalog.studentFlag})),
        'Üniversite öğrencisi',
      );
      expect(label(testCharacter(age: 70, pension: 140000)), 'Emekli');
      expect(label(testCharacter(age: 10)), 'Öğrenci');
      expect(label(testCharacter(age: 3)), isEmpty, reason: 'okul öncesi');
    });

    test('ölüm özeti son işi gösterir; hiç çalışmadıysa yok', () {
      final retired = testCharacter(
        age: 80,
        pension: 200000,
      ).copyWith(lastJob: const Job(careerId: 'plaza', tier: 5));
      expect(
        lastJobLabel(l10n, retired, content.careers),
        'Plaza çalışanı · Direktör',
      );
      expect(lastJobLabel(l10n, testCharacter(), content.careers), isNull);
    });
  });

  testWidgets('varlıklar paneli açılır ve net serveti gösterir', (
    tester,
  ) async {
    final engine = LifeEngine(
      deck: content.deck,
      careers: content.careers,
      seed: 1,
    );
    engine.startLife();
    await tester.pumpWidget(_wrap(AssetsButton(engine: engine)));

    await tester.tap(find.byKey(const Key('assets_button')));
    await tester.pumpAndSettle();
    expect(find.text('Varlıkların'), findsOneWidget);
    expect(find.byKey(const Key('net_worth')), findsOneWidget);
    expect(find.text('Nakit'), findsOneWidget);
    expect(find.byKey(const Key('sheet_background')), findsOneWidget);
  });

  testWidgets('geçen yıl şeridi gelir, giderler, enflasyon ve terfiyi yazar', (
    tester,
  ) async {
    var closed = false;
    await tester.pumpWidget(
      _wrap(
        LastYearBanner(
          economy: const EconomyReport(
            inflation: 0.32,
            cashEroded: 48000,
            rentPaid: 120000,
            livingCost: 150000,
            spouseIncome: 300000,
          ),
          career: const CareerReport(income: 180000, promoted: true),
          scholarship: 42000,
          onClose: () => closed = true,
        ),
      ),
    );
    final text = tester
        .widget<Text>(
          find.descendant(
            of: find.byKey(const Key('last_year_banner')),
            matching: find.byType(Text),
          ),
        )
        .data!;
    // Eşin katkısı ve burs gelire, kira ve yaşam gideri giderlere eklenir.
    expect(text, contains('Gelir +522.000 TL'));
    expect(text, contains('Giderler −270.000 TL'));
    expect(text, contains('Enflasyon %32'));
    expect(text, contains('Terfi aldın!'));

    await tester.tap(find.byKey(const Key('last_year_close')));
    expect(closed, isTrue);
  });

  testWidgets('söylenecek bir şey yoksa şerit görünmez', (tester) async {
    await tester.pumpWidget(
      _wrap(
        LastYearBanner(
          economy: const EconomyReport(inflation: 0.2),
          career: const CareerReport(income: 0),
          onClose: () {},
        ),
      ),
    );
    expect(find.byKey(const Key('last_year_banner')), findsNothing);
  });
}
