@Tags(['uzun'])
library;

import 'dart:math';

import 'package:bir_omur/engine/engine.dart';
import 'package:bir_omur/main.dart';
import 'package:bir_omur/models/models.dart';
import 'package:bir_omur/ui/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../content/real_cards_test.dart' show loadRealContent;
import '../helpers/stores.dart';

/// Son kullanıcı gibi baştan sona oynanan on hayat. Her yıl vaktin tamamı
/// harcanır: aktiviteler, kişilerle her türlü etkileşim (Ara, aşk adımları,
/// ayrılık), iş ilanı ve mülakat, terfi, zam, tempo, istifa, emeklilik,
/// işletme açma, fiyat, reklam, şube, ortak, tanıdık, satma, kapatma, ev,
/// araba, altın ve taşınma. Her adımda: hata ya da taşma yok, ekranda ham
/// şablon yok, oyunun kuralları bozulmamış.
///
/// Uzun sürer; varsayılan `flutter test` çalıştırmaz:
/// `flutter test --run-skipped -t uzun test/ui/full_play_test.dart`
void main() {
  final content = loadRealContent();
  final template = RegExp(r'[{}]');

  // Her hayatın kişiliği: hangi işlere ağırlık verdiği.
  const personas = <String, Map<String, int>>{
    'sosyal': {'social': 6, 'romance': 2, 'activity': 2, 'work': 1},
    'işletmeci': {'business': 6, 'work': 2, 'assets': 2, 'social': 1},
    'kariyerci': {'work': 6, 'activity': 2, 'social': 1, 'assets': 1},
    'göçebe': {'assets': 5, 'work': 2, 'social': 2, 'activity': 1},
    'aşık': {'romance': 6, 'social': 2, 'activity': 2},
    'karışık': {
      'social': 2,
      'romance': 2,
      'activity': 2,
      'work': 2,
      'business': 2,
      'assets': 2,
    },
  };
  const sizes = [Size(390, 844), Size(360, 640), Size(412, 915)];

  for (var life = 0; life < 10; life++) {
    final persona = personas.keys.elementAt(life % personas.length);
    final weights = personas[persona]!;
    final size = sizes[life % sizes.length];
    final gender = life.isEven ? 'kadin' : 'erkek';
    final seed = 9000 + life * 37;

    testWidgets('hayat ${life + 1}: $persona, $gender, '
        '${size.width.toInt()}×${size.height.toInt()}', (tester) async {
      final random = Random(seed);
      final used = <String, int>{};
      void count(String what) => used[what] = (used[what] ?? 0) + 1;

      tester.view.devicePixelRatio = 3;
      tester.view.physicalSize = size * 3;
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
      final container = ProviderScope.containerOf(
        tester.element(find.byType(BirOmurApp)),
      );
      LifeState? state() => container.read(lifeProvider);

      var step = 0;
      String where() {
        final c = state()?.character;
        return 'adım $step, ${c?.age ?? '-'} yaş';
      }

      void expectClean(String what) {
        expect(tester.takeException(), isNull, reason: '${where()} $what');
        final raw = find.textContaining(template).evaluate().map((e) {
          final w = e.widget;
          return w is Text ? w.data ?? w.textSpan?.toPlainText() : '$w';
        }).toList();
        expect(raw, isEmpty, reason: '${where()} $what: $raw');
      }

      Future<void> settle(String what) async {
        await tester.pumpAndSettle();
        expectClean(what);
      }

      /// Düğme, liste satırı ya da bölümlü seçici dokunulabilir mi?
      bool enabled(Element e) {
        bool check(Widget w) => switch (w) {
          ListTile() => w.enabled && w.onTap != null,
          ButtonStyleButton() => w.onPressed != null,
          IconButton() => w.onPressed != null,
          InkWell() => w.onTap != null,
          _ => true,
        };
        final w = e.widget;
        if (w is ListTile ||
            w is ButtonStyleButton ||
            w is IconButton ||
            w is InkWell) {
          return check(w);
        }
        var result = true;
        var found = false;
        void visit(Element child) {
          if (found) return;
          final cw = child.widget;
          if (cw is ListTile ||
              cw is ButtonStyleButton ||
              cw is IconButton ||
              cw is InkWell) {
            found = true;
            result = check(cw);
            return;
          }
          child.visitChildren(visit);
        }

        e.visitChildren(visit);
        return result;
      }

      List<Key> keyed(String prefix, {bool onlyEnabled = true}) => [
        for (final e in find
            .byWidgetPredicate(
              (w) =>
                  w.key is ValueKey<String> &&
                  (w.key! as ValueKey<String>).value.startsWith(prefix),
            )
            .evaluate())
          if (!onlyEnabled || enabled(e)) e.widget.key!,
      ];

      Future<bool> tapKey(Key key, String what) async {
        final f = find.byKey(key);
        if (f.evaluate().isEmpty) return false;
        if (!enabled(f.evaluate().first)) return false;
        await tester.ensureVisible(f.first);
        await tester.pumpAndSettle();
        await tester.tap(f.first, warnIfMissed: false);
        await settle(what);
        return true;
      }

      Future<bool> tapRandom(String prefix, String what) async {
        const panels = {'action_result', 'action_met'};
        final keys = keyed(prefix)
            .where((k) => !panels.contains((k as ValueKey<String>).value))
            .toList();
        if (keys.isEmpty) return false;
        final key = keys[random.nextInt(keys.length)];
        count('$what ${(key as ValueKey<String>).value}');
        return tapKey(key, what);
      }

      /// Açık kalan diyalog ve sayfaları kapatır: onay diyaloglarında çoğu
      /// zaman "evet", sayfalarda bir seçenek ya da kapatma.
      Future<void> resolvePopups() async {
        for (var i = 0; i < 6; i++) {
          if (find.byType(AlertDialog).evaluate().isNotEmpty) {
            const yes = [
              'break_up_yes',
              'business_dispose_yes',
              'job_quit_yes',
              'move_rent',
              'move_with_family',
            ];
            final options = [
              for (final k in yes)
                if (find.byKey(Key(k)).evaluate().isNotEmpty) Key(k),
            ];
            if (options.isNotEmpty && random.nextDouble() < 0.75) {
              final k = options[random.nextInt(options.length)];
              count('onay ${(k as ValueKey<String>).value}');
              await tapKey(k, 'onay');
            } else {
              final buttons = find.descendant(
                of: find.byType(AlertDialog),
                matching: find.byType(TextButton),
              );
              await tester.tap(buttons.first, warnIfMissed: false);
              await settle('vazgeç');
            }
            continue;
          }
          if (find.byType(BottomSheet).evaluate().isNotEmpty) {
            for (final prefix in const [
              'call_memory_',
              'call_tone_',
              'interview_',
              'open_',
              'move_',
              'tercih_',
            ]) {
              final keys = keyed(prefix)
                  .where(
                    (k) => !const [
                      'move_button',
                      'move_rent',
                      'move_with_family',
                      'tercih_button',
                      'tercih_next',
                    ].contains((k as ValueKey<String>).value),
                  )
                  .toList();
              if (keys.isNotEmpty) {
                final k = keys[random.nextInt(keys.length)];
                count('sayfa ${(k as ValueKey<String>).value}');
                await tapKey(k, 'sayfa');
                break;
              }
            }
            if (find.byType(BottomSheet).evaluate().isNotEmpty) {
              // Seçenek kalmadı: kullanıcı gibi geri tuşuyla kapat.
              await tester.binding.handlePopRoute();
              await settle('sayfa kapat');
            }
            continue;
          }
          break;
        }
      }

      /// Ana ekrana dön: kişi ekranı ve açık sayfalar kapanır.
      Future<void> home() async {
        await resolvePopups();
        for (var i = 0;
            i < 3 && find.byKey(const Key('person_screen')).evaluate().isNotEmpty;
            i++) {
          await tester.tap(find.byType(BackButton).first, warnIfMissed: false);
          await settle('geri');
        }
      }

      Future<void> tab(String name) async {
        await home();
        await tapKey(Key('tab_$name'), 'sekme $name');
      }

      /// Kişiler sekmesinde rastgele kaydırıp görünen birini açar.
      Future<bool> openPerson({bool aliveOnly = true}) async {
        await tab('people');
        final list = find.byKey(const Key('people_list'));
        if (list.evaluate().isNotEmpty && random.nextBool()) {
          await tester.drag(list, Offset(0, -300.0 * random.nextInt(6)));
          await settle('kaydır');
        }
        final keys = keyed('person_')
            .where((k) => (k as ValueKey<String>).value != 'person_screen')
            .toList();
        if (keys.isEmpty) return false;
        final key = keys[random.nextInt(keys.length)];
        await tapKey(key, 'kişi');
        return find.byKey(const Key('person_screen')).evaluate().isNotEmpty;
      }

      Future<void> social({bool romance = false}) async {
        if (!await openPerson()) return;
        const romantic = [
          'interaction_acil',
          'interaction_ciddi',
          'interaction_teklif',
          'interaction_cocukIste',
        ];
        var keys = keyed('interaction_')
            .where((k) => (k as ValueKey<String>).value != 'interaction_result')
            .toList();
        if (romance) {
          final love = keys
              .where((k) => romantic.contains((k as ValueKey<String>).value))
              .toList();
          if (love.isNotEmpty) keys = love;
        }
        // Ayrılık ve uzaklaşma seyrek; yoksa her hayat yalnız biter.
        keys = keys.where((k) {
          final v = (k as ValueKey<String>).value;
          if (v == 'interaction_ayril') return random.nextDouble() < 0.08;
          if (v == 'interaction_uzaklas') return random.nextDouble() < 0.15;
          return true;
        }).toList();
        if (keys.isEmpty) return;
        final key = keys[random.nextInt(keys.length)];
        count('etkileşim ${(key as ValueKey<String>).value}');
        await tapKey(key, 'etkileşim');
        await resolvePopups();
      }

      Future<void> activity() async {
        await tab('activities');
        if (random.nextDouble() < 0.5) {
          final list = find.byType(Scrollable);
          if (list.evaluate().isNotEmpty) {
            await tester.drag(list.last, const Offset(0, -400));
            await settle('kaydır');
          }
        }
        await tapRandom('action_', 'aktivite');
        await resolvePopups();
      }

      Future<void> work() async {
        await tab('work');
        final roll = random.nextInt(9);
        switch (roll) {
          case 0 || 1:
            if (await tapRandom('listing_', 'ilan')) await resolvePopups();
          case 2:
            await tapKey(const Key('job_promotion'), 'terfi');
            count('terfi');
          case 3:
            await tapKey(const Key('job_raise'), 'zam');
            count('zam');
          case 4:
            final tempo = find.byKey(const Key('job_tempo'));
            if (tempo.evaluate().isNotEmpty) {
              final segments = find.descendant(
                of: tempo,
                matching: find.byType(InkWell),
              );
              final n = segments.evaluate().length;
              if (n > 0) {
                await tester.ensureVisible(tempo);
                await tester.pumpAndSettle();
                await tester.tap(
                  segments.at(random.nextInt(n)),
                  warnIfMissed: false,
                );
                await settle('tempo');
                count('tempo');
              }
            }
          case 5:
            if (random.nextDouble() < 0.3 &&
                await tapKey(const Key('job_quit'), 'istifa')) {
              count('istifa');
              await resolvePopups();
            }
            if (await tapKey(const Key('job_retire'), 'emeklilik')) {
              count('erken emeklilik');
            }
          default:
            await tapRandom('action_', 'iş aksiyonu');
            await resolvePopups();
        }
      }

      Future<void> business() async {
        await tab('work');
        final existing = keyed('business_present_', onlyEnabled: false);
        if (existing.isEmpty || random.nextDouble() < 0.25) {
          if (await tapKey(const Key('business_open'), 'işletme aç')) {
            count('işletme aç sayfası');
            await resolvePopups();
          }
          return;
        }
        final ops = [
          'business_ad_',
          'business_expand_',
          'business_hire_',
          'business_partner_',
          'business_price_',
          'business_present_',
          if (random.nextDouble() < 0.12) 'business_sell_',
          if (random.nextDouble() < 0.08) 'business_close_',
        ];
        final op = ops[random.nextInt(ops.length)];
        if (op == 'business_price_' || op == 'business_present_') {
          final targets = keyed(op, onlyEnabled: false);
          if (targets.isEmpty) return;
          final target = find.byKey(targets[random.nextInt(targets.length)]);
          final segments = find.descendant(
            of: target,
            matching: find.byType(InkWell),
          );
          final n = segments.evaluate().length;
          if (n == 0) return;
          await tester.ensureVisible(target);
          await tester.pumpAndSettle();
          await tester.tap(segments.at(random.nextInt(n)), warnIfMissed: false);
          await settle(op);
          count(op);
          return;
        }
        if (await tapRandom(op, 'işletme')) await resolvePopups();
      }

      Future<void> assets() async {
        await tab('assets');
        if (random.nextDouble() < 0.25 &&
            await tapKey(const Key('move_button'), 'taşınma')) {
          count('taşınma sayfası');
          await resolvePopups();
          return;
        }
        final list = find.byType(Scrollable);
        if (list.evaluate().isNotEmpty) {
          await tester.drag(list.last, const Offset(0, -500));
          await settle('kaydır');
        }
        await tapRandom('action_', 'varlık');
        await resolvePopups();
      }

      /// Oyunun kuralları her yıl denetlenir.
      void checkRules() {
        final s = state();
        if (s == null) return;
        final c = s.character;
        for (final kind in StatKind.values) {
          expect(c.stats[kind], inInclusiveRange(0, 100), reason: '$kind');
        }
        expect(s.timeLeft, greaterThanOrEqualTo(0), reason: where());
        final alive = c.people.all.where((p) => p.isAlive).toList();
        expect(
          alive.where((p) => p.kin == Kinship.es).length,
          lessThanOrEqualTo(1),
          reason: '${where()} birden çok eş',
        );
        expect(
          alive.where((p) => Romance.romanticBonds.contains(p.bond)).length +
              alive.where((p) => p.kin == Kinship.es).length,
          lessThanOrEqualTo(2),
          reason: '${where()} aşk karmaşası',
        );
        for (final p in alive) {
          expect(p.ageAt(c.age), lessThanOrEqualTo(106), reason: p.name);
          if (Romance.romanticBonds.contains(p.bond)) {
            expect(p.gender, isNot(c.gender), reason: '${where()} ${p.name}');
            expect(c.age, greaterThanOrEqualTo(18), reason: where());
          }
        }
        if (c.job case final job?) {
          final career = content.careers.byId(job.careerId);
          expect(career, isNotNull, reason: job.careerId);
          expect(job.tier, inInclusiveRange(1, career!.maxTier));
          expect(job.yearsInJob, greaterThanOrEqualTo(job.yearsInTier));
        }
        if (c.home == HomeKind.cocukYaninda) {
          expect(
            alive.any(
              (p) => p.kin == Kinship.cocuk && p.hasRole(RoleKind.evSahibi),
            ),
            isTrue,
            reason: '${where()} ev sahibi çocuk yok',
          );
        }
        expect(c.businesses.length, lessThanOrEqualTo(4), reason: where());
        expect(c.wageIndex, greaterThanOrEqualTo(1));
      }

      // Doğum.
      await tester.ensureVisible(find.byKey(Key('gender_$gender')));
      await tester.tap(find.byKey(Key('gender_$gender')));
      await tester.pump();
      await tester.ensureVisible(find.byKey(const Key('birth_button')));
      await tester.tap(find.byKey(const Key('birth_button')));
      await settle('doğum');

      var years = 0;
      var lastAge = -1;
      var sameAge = 0;
      while (find.byKey(const Key('rebirth')).evaluate().isEmpty) {
        expect(++step, lessThan(20000), reason: 'hayat bitmedi');
        final age = state()?.character.age ?? -1;
        sameAge = age == lastAge ? sameAge + 1 : 0;
        lastAge = age;
        if (sameAge > 60) {
          final keys = keyed('', onlyEnabled: false)
              .map((k) => (k as ValueKey<String>).value)
              .toList();
          Object? error;
          try {
            container.read(lifeProvider.notifier).choose(ChoiceSide.left);
          } on Object catch (e) {
            error = e;
          }
          fail(
            'motor: $error; kart ${state()?.currentEvent?.card.id}; '
            '${state()?.pendingCards.map((e) => e.card.id).toList()}; '
            '${where()} takıldı; faz ${state()?.phase}, '
            'ekrandaki anahtarlar: $keys',
          );
        }
        if (find.byKey(const Key('choose_left')).evaluate().isNotEmpty) {
          final sides = [
            'choose_left',
            'choose_right',
            if (find.byKey(const Key('choose_up')).evaluate().isNotEmpty)
              'choose_up',
          ];
          final key = Key(sides[random.nextInt(sides.length)]);
          await tester.ensureVisible(find.byKey(key));
          await tester.tap(find.byKey(key));
          await settle('kart');
          count('kart');
          continue;
        }
        // YKS tercihi: bölüm ve şehir ya da başka yol.
        if (await tapKey(const Key('tercih_button'), 'tercih')) {
          count('tercih');
          await resolvePopups();
          await resolvePopups();
        }
        // Vakit bitene kadar (ya da makul bir denemeye kadar) yaşa.
        var tries = 0;
        while ((state()?.timeLeft ?? 0) > 0 && tries++ < 14) {
          final total = weights.values.reduce((a, b) => a + b);
          var pick = random.nextInt(total);
          final intent = weights.entries.firstWhere((e) {
            pick -= e.value;
            return pick < 0;
          }).key;
          switch (intent) {
            case 'social':
              await social();
            case 'romance':
              if (random.nextDouble() < 0.3) {
                await tab('activities');
                if (await tapKey(const Key('action_tanis'), 'tanış')) {
                  count('tanış');
                }
              } else {
                await social(romance: true);
              }
            case 'activity':
              await activity();
            case 'work':
              await work();
            case 'business':
              await business();
            case 'assets':
              await assets();
          }
        }
        await home();
        // Birkaç yılda bir bütün sekmeler ve varlık paneli gezilir.
        if (++years % 6 == 0) {
          for (final t in const ['me', 'people', 'work', 'assets', 'activities']) {
            await tab(t);
          }
          if (await tapKey(const Key('assets_button'), 'varlık paneli')) {
            await resolvePopups();
          }
          await tab('me');
        }
        checkRules();
        await tapKey(const Key('age_up'), 'yaşlan');
        count('yıl');
      }
      expectClean('ölüm ekranı');
      // Ne denendi: rapor.
      final summary = used.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      // ignore: avoid_print
      print(
        'hayat ${life + 1} ($persona): ${state()?.character.age} yaş; '
        '${summary.map((e) => '${e.key}: ${e.value}').join(', ')}',
      );
    }, timeout: const Timeout(Duration(minutes: 30)));
  }
}
