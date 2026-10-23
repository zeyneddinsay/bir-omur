import 'package:bir_omur/engine/engine.dart';
import 'package:bir_omur/l10n/generated/app_localizations_tr.dart';
import 'package:bir_omur/main.dart';
import 'package:bir_omur/services/save_store.dart';
import 'package:bir_omur/ui/l10n_names.dart';
import 'package:bir_omur/ui/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/content.dart';
import '../helpers/stores.dart';

final _content = uiTestContent();

Widget _app({int seed = 7, SaveStore? store}) => ProviderScope(
  // Her uygulama açılışı ayrı bir kapsam; aynı [store] verilirse kayıt
  // açılışlar arasında taşınır.
  key: UniqueKey(),
  overrides: [
    contentProvider.overrideWith((ref) async => _content),
    seedGeneratorProvider.overrideWithValue(() => seed),
    saveStoreProvider.overrideWithValue(store ?? answeredStore()),
  ],
  child: const BirOmurApp(),
);

/// Testler telefon boyutunda çalışır; varsayılan 800×600 test ekranı
/// gerçek bir cihaza benzemez.
void _phone(WidgetTester tester, {Size size = const Size(390, 844)}) {
  tester.view.devicePixelRatio = 3;
  tester.view.physicalSize = size * 3;
  addTearDown(tester.view.reset);
}

Future<void> _bornAs(
  WidgetTester tester,
  String name, {
  Size size = const Size(390, 844),
}) async {
  _phone(tester, size: size);
  await tester.pumpWidget(_app());
  await tester.pumpAndSettle();
  await tester.enterText(find.byKey(const Key('birth_name')), name);
  await tester.tap(find.byKey(const Key('gender_kadin')));
  await tester.pump();
  await tester.tap(find.byKey(const Key('birth_button')));
  await tester.pumpAndSettle();
}

/// Yılın kalan kartlarını sola kaydırarak bitirir.
Future<void> _finishCards(WidgetTester tester) async {
  while (find.byKey(const Key('choose_left')).evaluate().isNotEmpty) {
    await tester.tap(find.byKey(const Key('choose_left')));
    await tester.pumpAndSettle();
  }
}

void main() {
  testWidgets('doğum ekranından ilk karta', (tester) async {
    await _bornAs(tester, 'Zeynep');
    expect(find.text('Zeynep'), findsOneWidget);
    expect(find.textContaining('0 yaş'), findsOneWidget);
    // 0 yaşın zorunlu kartı.
    expect(find.textContaining(firstEventText), findsOneWidget);
  });

  testWidgets('cinsiyet etiketleri dar ekranda ve büyük yazıda tek satır', (
    tester,
  ) async {
    _phone(tester, size: const Size(320, 568));
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    final lineHeight = tester.getSize(find.text('Kadın')).height;
    for (final label in ['Erkek']) {
      expect(
        tester.getSize(find.text(label)).height,
        lineHeight,
        reason: label,
      );
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('uygulama kapanıp açılınca yarım hayata devam edilir', (
    tester,
  ) async {
    _phone(tester);
    final store = answeredStore();
    await tester.pumpWidget(_app(store: store));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('resume_button')), findsNothing);
    await tester.enterText(find.byKey(const Key('birth_name')), 'Defne');
    await tester.tap(find.byKey(const Key('gender_kadin')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('birth_button')));
    await tester.pumpAndSettle();
    await _finishCards(tester);
    await tester.tap(find.byKey(const Key('age_up')));
    await tester.pumpAndSettle();
    expect(find.textContaining('1 yaş'), findsOneWidget);

    // Uygulamayı "kapatıp" aynı kayıtla yeniden aç.
    await tester.pumpWidget(_app(store: store));
    await tester.pumpAndSettle();
    expect(find.text('Defne, 1 yaşında'), findsOneWidget);
    await tester.tap(find.byKey(const Key('resume_button')));
    await tester.pumpAndSettle();
    expect(find.text('Defne'), findsOneWidget);
    expect(find.textContaining('1 yaş'), findsOneWidget);
  });

  testWidgets('eski sürümden kalan hayat bildirilir ve silinir', (
    tester,
  ) async {
    _phone(tester);
    final store = answeredStore();
    await store.saveCurrentLife({
      'version': 1,
      'character': {'name': 'Eski', 'age': 30},
    });
    await tester.pumpWidget(_app(store: store));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('resume_button')), findsNothing);
    expect(find.text('Yarım kalan hayat sürdürülemiyor'), findsOneWidget);
    await tester.ensureVisible(find.byKey(const Key('discard_old_save')));
    await tester.tap(find.byKey(const Key('discard_old_save')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('discard_old_save')), findsNothing);
    expect(await store.loadCurrentLife(), isNull);
  });

  testWidgets('cinsiyet seçilmeden doğum düğmesi kapalı', (tester) async {
    _phone(tester);
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();
    expect(find.text('Rastgele'), findsNothing);
    FilledButton button() =>
        tester.widget<FilledButton>(find.byKey(const Key('birth_button')));
    expect(button().onPressed, isNull);
    await tester.tap(find.byKey(const Key('gender_erkek')));
    await tester.pump();
    expect(button().onPressed, isNotNull);
  });

  testWidgets('Ayarlar\'dan yeni hayat başlatılır', (tester) async {
    await _bornAs(tester, 'Zeynep');
    await tester.tap(find.byKey(const Key('settings_button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('setting_new_life')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('new_life_confirm')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('birth_button')), findsOneWidget);
    expect(find.byKey(const Key('resume_button')), findsNothing);
  });

  testWidgets('kart sürüklenerek seçilir', (tester) async {
    await _bornAs(tester, 'Ali');
    await tester.drag(
      find.byKey(const Key('card_text')),
      const Offset(-300, 0),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining(firstEventText), findsNothing);
    await _finishCards(tester);
    expect(find.byKey(const Key('age_up')), findsOneWidget);
  });

  testWidgets('seçimden sonra sonuç paneli görünür ve kapatılır', (
    tester,
  ) async {
    await _bornAs(tester, 'Ali');
    expect(find.byKey(const Key('outcome_panel')), findsNothing);
    await tester.tap(find.byKey(const Key('choose_right')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('outcome_panel')), findsOneWidget);
    await tester.tap(find.byKey(const Key('outcome_close')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('outcome_panel')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('kısa sürükleme kartı geri bırakır', (tester) async {
    await _bornAs(tester, 'Ali');
    await tester.drag(find.byKey(const Key('card_text')), const Offset(-40, 0));
    await tester.pumpAndSettle();
    expect(find.textContaining(firstEventText), findsOneWidget);
  });

  testWidgets('vakit düşer, Yaşlan yaşı artırır', (tester) async {
    await _bornAs(tester, 'Ali');
    await tester.tap(find.byKey(const Key('choose_right')));
    await tester.pumpAndSettle();
    await _finishCards(tester);
    expect(find.text('Bu yılın vakti bitti'), findsOneWidget);
    // 6 yaşına kadar yıllar yalnızca olaylarla geçer.
    var steps = 0;
    while (find.text('Vakit: 2').evaluate().isEmpty) {
      expect(++steps, lessThan(60), reason: '6 yaşına gelinemedi');
      if (find.byKey(const Key('choose_left')).evaluate().isNotEmpty) {
        await tester.tap(find.byKey(const Key('choose_left')));
      } else {
        await tester.tap(find.byKey(const Key('age_up')));
      }
      await tester.pumpAndSettle();
    }
    expect(find.textContaining('6 yaş'), findsOneWidget);
    await tester.tap(find.byKey(const Key('tab_activities')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('action_oyun_oyna')));
    await tester.tap(find.byKey(const Key('action_oyun_oyna')));
    await tester.pumpAndSettle();
    expect(find.text('Vakit: 1'), findsOneWidget);
    await tester.ensureVisible(find.byKey(const Key('age_up')));
    await tester.tap(find.byKey(const Key('age_up')));
    await tester.pumpAndSettle();
    expect(find.textContaining('7 yaş'), findsOneWidget);
  });

  for (final size in const [Size(390, 844), Size(320, 568)]) {
    testWidgets('bir hayat baştan sona oynanır ve yeniden doğulur '
        '(${size.width.toInt()}×${size.height.toInt()})', (tester) async {
      await _bornAs(tester, 'Mehmet', size: size);
      var steps = 0;
      while (find.byKey(const Key('rebirth')).evaluate().isEmpty) {
        expect(++steps, lessThan(2000), reason: 'hayat bitmedi');
        if (find.byKey(const Key('choose_left')).evaluate().isNotEmpty) {
          final side = steps.isEven ? 'choose_left' : 'choose_right';
          await tester.tap(find.byKey(Key(side)));
        } else {
          await tester.tap(find.byKey(const Key('age_up')));
        }
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: 'adım $steps');
      }
      expect(find.text('Mehmet'), findsOneWidget);
      expect(find.byKey(const Key('nickname')), findsOneWidget);
      expect(find.textContaining('Hayat tohumu: 7'), findsOneWidget);

      await tester.ensureVisible(find.byKey(const Key('rebirth')));
      await tester.tap(find.byKey(const Key('rebirth')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('birth_button')), findsOneWidget);

      // Albümde bu hayat ve rozetler görünür.
      await tester.ensureVisible(find.byKey(const Key('album_button')));
      await tester.tap(find.byKey(const Key('album_button')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('album_life_0')), findsOneWidget);
      expect(find.text('Mehmet'), findsOneWidget);
      await tester.tap(find.text('Rozetler'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('badges_summary')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  test('her aksiyonun ARB dosyasında bir adı var', () {
    final l10n = AppLocalizationsTr();
    for (final action in ActionCatalog.all) {
      expect(l10n.actionName(action.id), isNotNull, reason: action.id);
    }
  });

  test('para Türkçe biçimle yazılır', () {
    expect(AppLocalizationsTr().money(25000), '25.000 TL');
  });
}
