import 'dart:convert';
import 'dart:math';

import 'package:bir_omur/engine/engine.dart';
import 'package:bir_omur/models/models.dart';
import 'package:flutter_test/flutter_test.dart';

import '../content/real_cards_test.dart' show loadRealContent;
import '../helpers/auto_player.dart';
import '../helpers/simulation.dart' show expectMoneyBooked;

/// Kaos oyuncusu: her adımda o an yapılabilecek her şeyin (aksiyon,
/// etkileşim, ilan, tempo, terfi, zam, istifa, emeklilik, işletme açma,
/// fiyat, reklam, şube, ortak, tanıdık, satma, kapatma, taşınma) arasından
/// rastgele birini seçer. Her adımda: motor hata atmaz, para deftere yazılır,
/// göstergeler sınırda kalır, kayıt yazılıp geri açılınca aynı hayat sürer.
void main() {
  final content = loadRealContent();

  const lives = 60;
  final tried = <String, int>{};

  for (var seed = 0; seed < lives; seed++) {
    test('kaos hayatı $seed', () {
      final random = Random(seed * 7919);
      final auto = AutoPlayer(seed);
      var engine = LifeEngine(
        deck: content.deck,
        seed: seed + 50000,
        careers: content.careers,
        families: content.families,
        interactions: content.interactions,
      );
      var state = engine.startLife();
      Character previous = state.character;
      var steps = 0;

      List<(String, LifeState Function())> options() {
        final e = engine;
        final c = e.state.character;
        return [
          for (final (a, ok) in e.availableActions())
            if (ok) ('aksiyon ${a.id}', () => e.doAction(a.id)),
          for (final r in e.possibleInteractions())
            ('etkileşim ${r.kind.name}', () => e.interact(r)),
          for (final (l, blocked) in e.listingOptions())
            if (blocked == null)
              (
                'ilan',
                () {
                  final refs = e.listingReferences(l);
                  return e.applyFor(
                    l,
                    random.nextBool() ? ChoiceSide.left : ChoiceSide.right,
                    referenceId: refs.isNotEmpty && random.nextBool()
                        ? refs.first.id
                        : null,
                  );
                },
              ),
          if (c.job case final job?) ...[
            for (final t in Tempo.values)
              if (t != job.tempo && e.canSetTempo(t))
                ('tempo ${t.name}', () => e.setTempo(t)),
            if (e.canRequest(promotion: true))
              ('terfi', () => e.requestPromotion()),
            if (e.canRequest(promotion: false)) ('zam', () => e.requestRaise()),
            if (random.nextInt(4) == 0) ('istifa', () => e.quitJob()),
            if (JobMarket.canRetireEarly(c))
              ('erken emeklilik', () => e.retireEarly()),
          ],
          for (final (t, blocked) in e.businessOptions())
            if (blocked == null) ('işletme aç ${t.id}', () => e.openBusiness(t.id)),
          for (final b in c.businesses) ...[
            if (e.canSetBusinessPresent(b.id, !b.present))
              ('başında dur', () => e.setBusinessPresent(b.id, !b.present)),
            for (final p in PriceLevel.values)
              if (p != b.price)
                ('fiyat ${p.name}', () => e.setBusinessPrice(b.id, p)),
            if (e.canAdvertise(b.id)) ('reklam', () => e.advertiseBusiness(b.id)),
            if (e.canExpand(b.id)) ('şube', () => e.expandBusiness(b.id)),
            for (final p in e.partnerCandidates(b.id).take(1))
              ('ortak', () => e.takePartner(b.id, p.id)),
            if (e.canHireKnown(b.id))
              for (final p in e.hireCandidates(b.id).take(1))
                ('tanıdık işe al', () => e.hireKnown(b.id, p.id)),
            if (BusinessRules.canSell(b) && random.nextInt(3) == 0)
              ('işletme sat', () => e.disposeBusiness(b.id, sell: true)),
            if (random.nextInt(5) == 0)
              ('işletme kapat', () => e.disposeBusiness(b.id, sell: false)),
          ],
          if (random.nextInt(6) == 0)
            for (final (city, blocked, _) in e.moveOptions().take(2))
              if (blocked == null)
                (
                  'taşın',
                  () => e.moveTo(city, withFamily: random.nextBool()),
                ),
        ];
      }

      while (!state.isOver) {
        expect(++steps, lessThan(30000), reason: 'hayat bitmedi');
        final c = state.character;
        final where = 'tohum $seed, ${c.age} yaş, adım $steps';
        switch (state.phase) {
          case YearPhase.cards:
            state = engine.choose(auto.pickSide(state.currentEvent!.card));
          case YearPhase.actions:
            if (c.hasFlag(EducationRules.pendingFlag)) {
              state = auto.pickTercih(engine);
              break;
            }
            final ops = options();
            // Vakit bitti ya da yapılacak bir şey kalmadı: yaşlan. Arada
            // vakit bitmeden de yaşlanır (her yılı doldurmayan oyuncu).
            if (ops.isEmpty || random.nextInt(12) == 0) {
              state = engine.advanceYear();
              break;
            }
            // Önce tür (aksiyon, etkileşim, iş, işletme…), sonra o türden bir
            // seçenek: kişi başına onlarca "Ara" tonu öbürlerini bastırmasın.
            final groups = <String, List<(String, LifeState Function())>>{};
            for (final op in ops) {
              groups.putIfAbsent(op.$1.split(' ').first, () => []).add(op);
            }
            final group = groups.values.elementAt(
              random.nextInt(groups.length),
            );
            final (name, run) = group[random.nextInt(group.length)];
            tried[name] = (tried[name] ?? 0) + 1;
            try {
              state = run();
            } on Object catch (e) {
              fail('$where: "$name" hata verdi: $e');
            }
          case YearPhase.dead:
            break;
        }
        final next = state.character;
        if (state.phase != YearPhase.dead) {
          expectMoneyBooked(previous, next, reason: where);
          for (final kind in StatKind.values) {
            expect(next.stats[kind], inInclusiveRange(0, 100), reason: where);
          }
          expect(state.timeLeft, greaterThanOrEqualTo(0), reason: where);
          final spouses = next.people.all.where(
            (p) => p.isAlive && p.kin == Kinship.es,
          );
          expect(spouses.length, lessThanOrEqualTo(1), reason: where);
        }
        previous = next;
        // Ara sıra kaydedip geri açılır: aynı hayat aynı yerden sürer.
        if (steps % 25 == 0 && !state.isOver) {
          final snapshot = jsonDecode(jsonEncode(engine.toSnapshot()));
          final restored = LifeEngine.restore(
            deck: content.deck,
            careers: content.careers,
            families: content.families,
            interactions: content.interactions,
            snapshot: snapshot as Map<String, dynamic>,
          );
          expect(
            jsonEncode(restored.toSnapshot()),
            jsonEncode(engine.toSnapshot()),
            reason: '$where: kayıt gidiş-dönüş',
          );
          engine = restored;
          state = engine.state;
        }
      }
      expect(state.summary, isNotNull);
    });
  }

  tearDownAll(() {
    final sorted = tried.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    // ignore: avoid_print
    print('kaos: ${sorted.map((e) => '${e.key} ${e.value}').join(', ')}');
  });
}
