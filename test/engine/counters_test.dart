import 'dart:convert';

import 'package:bir_omur/engine/engine.dart';
import 'package:bir_omur/models/models.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_cards.dart';
import '../helpers/test_character.dart';

void main() {
  group('kart sayaçları', () {
    final move = testCard(
      'tasin',
      left: {
        'label': 'Sol',
        'effects': {
          'addFlags': ['tasindi'],
          'gold': 12,
        },
      },
    );

    test('taşınma ve kartla gelen altın sayılır', () {
      final resolver = EffectResolver(SeededRandom(1));
      var c = testCharacter(flags: {'tasindi'});
      c = resolver.resolve(c, PendingEvent(move), ChoiceSide.left).character;
      c = resolver
          .resolve(c.copyWith(age: 26), PendingEvent(move), ChoiceSide.left)
          .character;
      // Bayrak zaten varken de her taşınma sayılır.
      expect(c.counters.moves, 2);
      expect(c.counters.goldReceived, 24);
    });

    test('aksiyonla alınan altın "takılan altın" sayılmaz', () {
      final engine = LifeEngine(deck: EventDeck([]), seed: 1);
      engine.startLife();
      while (engine.state.character.age < 19) {
        engine.advanceYear();
      }
      final c = engine.doAction('altin_al').character;
      expect(c.assets.goldGrams, 10);
      expect(c.counters.goldReceived, 0);
    });
  });

  test('ödenen kira birikir', () {
    final tick = EconomyTick(SeededRandom(1));
    var c = testCharacter(money: 0, flags: {'kiraci'});
    var market = Market.initial;
    for (var i = 0; i < 3; i++) {
      (c, market, _) = tick.apply(c, market);
    }
    expect(c.counters.rentPaid, 3 * Assets.defaultRent);
  });

  group('meslek sayaçları', () {
    final book = CareerBook([
      Career.fromJson({
        'id': 'is',
        'name': 'İş',
        'tiers': [
          {
            'name': 'Bir',
            'salary': 100000,
            'promotion': {'minYears': 1, 'chance': 1.0},
          },
          {'name': 'İki', 'salary': 200000},
        ],
      }, file: 'is.json'),
    ]);

    test('çalışılan yıl, kazanç ve yıllık terfi', () {
      final tick = CareerTick(SeededRandom(1), book);
      var c = testCharacter(age: 30, job: const Job(careerId: 'is', tier: 1));
      (c, _) = tick.apply(c);
      (c, _) = tick.apply(c);
      expect(c.counters.yearsWorked, 2);
      expect(c.counters.lifetimeIncome, 100000 + 200000);
      expect(c.counters.promotions, 1);
    });

    test('kartla terfi sayılır, kademe düşmesi sayılmaz', () {
      var c = testCharacter(job: const Job(careerId: 'is', tier: 1));
      c = Careers.applyChange(c, const PromoteCareer(1), book);
      expect(c.counters.promotions, 1);
      c = Careers.applyChange(c, const PromoteCareer(-1), book);
      expect(c.counters.promotions, 1);
    });

    test('işsizin harçlığı ömür boyu kazanca girmez', () {
      final (c, _) = CareerTick(
        SeededRandom(1),
        book,
      ).apply(testCharacter(age: 30));
      expect(c.stats.money, greaterThan(0));
      expect(c.counters.lifetimeIncome, 0);
      expect(c.counters.yearsWorked, 0);
    });
  });

  test('her borca düşüş bir kez sayılır', () {
    Character flags(Character c) => YearTick.updateHardshipFlags(c);
    var c = flags(testCharacter(money: -10));
    expect(c.counters.debtSpells, 1);
    c = flags(c.copyWith(stats: c.stats.copyWith(money: -500)));
    expect(c.counters.debtSpells, 1, reason: 'borçta kalmak yeni dönem değil');
    c = flags(c.copyWith(stats: c.stats.copyWith(money: 100)));
    c = flags(c.copyWith(stats: c.stats.copyWith(money: -1)));
    expect(c.counters.debtSpells, 2);
  });

  test('sayaçlar kayda girer; sayaçsız eski kayıt da açılır', () {
    final c = testCharacter().copyWith(
      counters: const LifeCounters(moves: 3, rentPaid: 360000, debtSpells: 1),
    );
    final json = jsonDecode(jsonEncode(c.toJson())) as Map<String, dynamic>;
    expect(Character.fromJson(json).counters, c.counters);

    json.remove('counters');
    expect(Character.fromJson(json).counters, LifeCounters.zero);
  });
}
