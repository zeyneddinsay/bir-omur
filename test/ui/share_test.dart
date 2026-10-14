import 'dart:typed_data';

import 'package:bir_omur/engine/engine.dart';
import 'package:bir_omur/l10n/generated/app_localizations.dart';
import 'package:bir_omur/l10n/generated/app_localizations_tr.dart';
import 'package:bir_omur/models/models.dart';
import 'package:bir_omur/services/share_service.dart';
import 'package:bir_omur/ui/providers.dart';
import 'package:bir_omur/ui/share/life_share_card.dart';
import 'package:bir_omur/ui/share/share_preview_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../content/real_cards_test.dart' show loadRealContent;
import '../helpers/auto_player.dart';
import '../helpers/test_character.dart';

class _FakeShare implements ShareService {
  Uint8List? png;
  String? fileName;
  String? text;

  @override
  Future<void> shareImage(
    Uint8List png, {
    required String fileName,
    String? text,
    Rect? origin,
  }) async {
    this.png = png;
    this.fileName = fileName;
    this.text = text;
  }
}

Widget _app(Widget home, {List overrides = const []}) => ProviderScope(
  overrides: [...overrides],
  child: MaterialApp(
    locale: const Locale('tr'),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    home: home,
  ),
);

/// Uzun yaşamış, sayıları dolu bir hayat.
LifeSummary _longLife() {
  final content = loadRealContent();
  for (var seed = 0; seed < 50; seed++) {
    final engine = LifeEngine(
      deck: content.deck,
      careers: content.careers,
      seed: seed,
    );
    final end = AutoPlayer(seed).play(engine);
    if (end.summary!.deathAge > 85 && end.summary!.biggestMoment != null) {
      return end.summary!;
    }
  }
  throw StateError('uygun hayat bulunamadı');
}

void main() {
  final l10n = AppLocalizationsTr();
  final content = loadRealContent();

  test('büyük tutarlar okunur yazılır', () {
    expect(compactMoney(l10n, 2854000), '2,9 milyon TL');
    expect(compactMoney(l10n, 1000000), '1 milyon TL');
    expect(compactMoney(l10n, 640400), '640 bin TL');
    expect(compactMoney(l10n, -38000), '−38 bin TL');
    expect(compactMoney(l10n, 500), '500 TL');
  });

  test('kartta en fazla üç sayı ve geride bırakılan servet', () {
    LifeSummary summaryWith(LifeCounters k) => LifeSummary(
      character: testCharacter().copyWith(counters: k),
      cause: DeathCause.natural,
      nickname: Nickname.hepGulen,
      cardsSeen: 10,
      netWorth: 2500000,
    );
    expect(shareNumbers(l10n, summaryWith(LifeCounters.zero)), [
      'Geride 2,5 milyon TL bıraktı',
    ]);
    final full = shareNumbers(
      l10n,
      summaryWith(
        const LifeCounters(
          moves: 1,
          rentPaid: 2854000,
          goldReceived: 62,
          promotions: 3,
          yearsWorked: 40,
          debtSpells: 9,
        ),
      ),
    );
    expect(full, [
      '1 kez taşındı',
      '2,9 milyon TL kira ödedi',
      '62 gram altın takıldı',
      'Geride 2,5 milyon TL bıraktı',
    ]);
  });

  testWidgets('uzun bir hayatın kartı taşmadan çizilir', (tester) async {
    final summary = _longLife();
    await tester.pumpWidget(
      _app(
        FittedBox(
          child: LifeShareCard(summary: summary, content: content),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(find.byKey(const Key('share_nickname')), findsOneWidget);
    expect(tester.getSize(find.byType(LifeShareCard)), LifeShareCard.size);
  });

  testWidgets('Paylaş 1080×1920 PNG üretir ve paylaşıma verir', (tester) async {
    tester.view.devicePixelRatio = 3;
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    addTearDown(tester.view.reset);
    final share = _FakeShare();
    final summary = _longLife();
    await tester.pumpWidget(
      _app(
        SharePreviewScreen(summary: summary, content: content),
        overrides: [shareServiceProvider.overrideWithValue(share)],
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('share_action')));
    // Görsel üretimi gerçek zamanlı çalışır.
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(seconds: 1)),
    );
    await tester.pumpAndSettle();

    final png = share.png!;
    // PNG başlığındaki genişlik ve yükseklik.
    final header = ByteData.sublistView(png, 16, 24);
    expect(header.getUint32(0), 1080);
    expect(header.getUint32(4), 1920);
    expect(share.fileName, 'bir-omur.png');
    expect(share.text, contains('${summary.deathAge} yıllık'));
  });
}
