import 'dart:math';

import 'package:bir_omur/engine/engine.dart';
import 'package:bir_omur/models/models.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/families.dart';
import '../helpers/test_character.dart';

void main() {
  final factory = PersonFactory(SeededRandom(5), realFamilies());
  final simit = BusinessTypes.require('simit');
  final berber = BusinessTypes.require('berber');
  final yazilim = BusinessTypes.require('yazilim');

  Character opened(BusinessType t, {int money = 10000000}) =>
      BusinessRules.open(testCharacter(age: 30, money: money), t, factory);

  group('açma', () {
    test('sebepler: yaş, şart, para, vakit, askerlik', () {
      BusinessBlocked? blocked(Character c, BusinessType t, {int time = 5}) =>
          BusinessRules.openBlocked(c, t, timeLeft: time);
      expect(blocked(testCharacter(age: 15), simit), BusinessBlocked.yas);
      expect(
        blocked(testCharacter(age: 30, money: 10000000), yazilim),
        BusinessBlocked.sart,
        reason: 'yazılım için yazılımcılık ya da bilgisayar diploması',
      );
      expect(
        blocked(testCharacter(age: 30, money: 1000, reputation: 10), simit),
        BusinessBlocked.para,
      );
      expect(
        blocked(testCharacter(age: 30, money: 10000000), simit, time: 1),
        BusinessBlocked.vakit,
      );
      expect(
        blocked(
          testCharacter(age: 30, money: 10000000, flags: {'askerde'}),
          simit,
        ),
        BusinessBlocked.askerde,
      );
      final coder = testCharacter(
        age: 30,
        money: 10000000,
        job: const Job(careerId: 'yazilimci', tier: 1),
      );
      expect(blocked(coder, yazilim), isNull);
    });

    test('parası yeten peşin açar; yetmeyen %30 peşinat ve krediyle', () {
      final cash = opened(berber);
      expect(cash.stats.money, 10000000 - berber.setupCost);
      expect(cash.businesses.single.loanYearsLeft, 0);
      expect(cash.businesses.single.staff, hasLength(berber.staffPerBranch));

      final loaned = opened(berber, money: 400000);
      expect(
        loaned.stats.money,
        400000 - BusinessRules.downPayment(berber, loan: true),
      );
      expect(loaned.businesses.single.loanYearsLeft, BusinessRules.loanYears);
      expect(loaned.businesses.single.loanPayment, greaterThan(0));
    });

    test('aynı türden ikinci işletme ve üçüncü işletme açılmaz', () {
      final one = opened(simit);
      expect(
        BusinessRules.openBlocked(one, simit, timeLeft: 5),
        BusinessBlocked.zatenVar,
      );
      final two = BusinessRules.open(one, berber, factory);
      expect(
        BusinessRules.openBlocked(
          two,
          BusinessTypes.require('oto_yikama'),
          timeLeft: 5,
        ),
        BusinessBlocked.cokFazla,
      );
    });
  });

  group('yıl', () {
    test('kâr para olarak gelir, son kârlar tutulur', () {
      final c = opened(berber);
      final (next, years) = BusinessRules.yearOf(c, 0.3, SeededRandom(1));
      final y = years.single;
      expect(next.stats.money, c.stats.money + y.ownerShare - y.loanPaid);
      expect(next.businesses.single.profits, [y.profit]);
    });

    test('nakit eksiye düşüp zarar eden işletme batar ve 2 yıl açılamaz', () {
      // Müdüre bırakılmış, itibarı dibe vurmuş simitçi zarar eder.
      var c = opened(simit, money: simit.setupCost);
      c = BusinessRules.setPresent(c, c.businesses.single.id, false, factory);
      c = c.copyWith(
        stats: c.stats.copyWith(money: 0),
        businesses: [c.businesses.single.copyWith(reputation: 0)],
      );
      final (next, years) = BusinessRules.yearOf(c, 0.5, SeededRandom(2));
      expect(years.single.profit, lessThan(0));
      expect(years.single.bankrupt, isTrue);
      expect(next.businesses, isEmpty);
      expect(next.bankruptcies['simit'], c.age);
      expect(
        BusinessRules.openBlocked(
          next.copyWith(stats: next.stats.copyWith(money: 10000000)),
          simit,
          timeLeft: 5,
        ),
        BusinessBlocked.iflas,
      );
      final manager = next.people.all.firstWhere(
        (p) => p.hasRole(RoleKind.mudur, activeOnly: false),
      );
      expect(manager.hasRole(RoleKind.mudur), isFalse);
    });

    test('emek işinde başında durmamak kârı düşürür', () {
      final c = opened(berber);
      final id = c.businesses.single.id;
      final away = BusinessRules.setPresent(c, id, false, factory);
      expect(
        BusinessRules.expectedProfit(away, away.businesses.single),
        lessThan(BusinessRules.expectedProfit(c, c.businesses.single)),
      );
    });
  });

  test('istifa edince işletmenin müdürü kalır', () {
    final c = BusinessRules.setPresent(
      opened(berber).copyWith(job: const Job(careerId: 'plaza', tier: 1)),
      'berber_30',
      false,
      factory,
    );
    final left = Careers.leaveJob(c);
    final manager = left.people[left.businesses.single.managerId!]!;
    expect(manager.hasRole(RoleKind.mudur), isTrue);
  });

  test('yazılımı büyütünce kredi ve reklam yılı korunur', () {
    final coder = testCharacter(
      age: 30,
      money: 300000,
      job: const Job(careerId: 'yazilimci', tier: 1),
    );
    var c = BusinessRules.open(coder, yazilim, factory);
    final b = c.businesses.single;
    expect(b.loanYearsLeft, greaterThan(0));
    c = c.copyWith(
      age: 32,
      stats: c.stats.copyWith(money: 10000000),
      businesses: [
        b.copyWith(profits: [500000], advertisedAt: 32),
      ],
    );
    expect(BusinessRules.canExpand(c, c.businesses.single), isTrue);
    final grown = BusinessRules.expand(c, b.id, factory).businesses.single;
    expect(grown.type, 'yazilim_ekip');
    expect(grown.loanYearsLeft, b.loanYearsLeft);
    expect(grown.loanPayment, b.loanPayment);
    expect(grown.advertisedAt, 32);
  });

  test('satınca ve kapatınca çalışanlar "eski" olur', () {
    final c = opened(berber);
    final b = c.businesses.single;
    final sold = BusinessRules.dispose(c, b.id, sell: true);
    expect(sold.businesses, isEmpty);
    expect(sold.stats.money, c.stats.money + BusinessRules.saleValue(b));
    expect(sold.people[b.staff.single]!.hasRole(RoleKind.calisan), isFalse);
  });

  group('kart', () {
    test('işletme koşulu türe bakar; yazılım ekipli şirketi de kapsar', () {
      const any = Conditions(business: 'any');
      const none = Conditions(business: 'none');
      const soft = Conditions(business: 'yazilim');
      final c = opened(simit);
      expect(any.isMetBy(c), isTrue);
      expect(none.isMetBy(c), isFalse);
      expect(soft.isMetBy(c), isFalse);
      expect(Conditions.matchesBusiness('yazilim_ekip', 'yazilim'), isTrue);
      expect(Conditions.matchesBusiness('yazilim', 'yazilim_ekip'), isFalse);
    });

    test('işletme etkisi yalnızca koşuldaki türün itibarını değiştirir', () {
      final c = BusinessRules.open(opened(simit), berber, factory);
      final next = EffectResolver.applyEffect(
        c,
        const Effect(business: 5),
        conditions: const Conditions(business: 'berber'),
      );
      int rep(Character x, String type) =>
          x.businesses.firstWhere((b) => b.type == type).reputation;
      expect(rep(next, 'berber'), rep(c, 'berber') + 5);
      expect(rep(next, 'simit'), rep(c, 'simit'));
    });

    test('meslek listesi koşulu', () {
      const office = Conditions(careers: ['plaza', 'memur']);
      expect(office.isMetBy(testCharacter()), isFalse);
      expect(
        office.isMetBy(
          testCharacter(job: const Job(careerId: 'garson', tier: 1)),
        ),
        isFalse,
      );
      expect(
        office.isMetBy(
          testCharacter(job: const Job(careerId: 'memur', tier: 1)),
        ),
        isTrue,
      );
    });
  });

  group('denetim düzeltmeleri', () {
    test(
      'zarardaki işletme satılamaz; ortak çıkışta en az sermayesini alır',
      () {
        var c = opened(berber);
        final id = c.businesses.single.id;
        c = BusinessRules.setPrice(c, id, PriceLevel.normal);
        final losing = c.businesses.single.copyWith(profits: [-100000]);
        expect(BusinessRules.canSell(losing), isFalse);
        final b = c.businesses.single.copyWith(
          profits: [400000, 400000],
          partnerId: 'x',
          partnerShare: 0.3,
          partnerCapital: 300000,
        );
        final value = BusinessRules.saleValue(b);
        expect(value, BusinessRules.equipmentValue(b) + 400000);
        expect(
          BusinessRules.exitValue(b, sell: true),
          value - max(300000, (value * 0.3).round()),
        );
      },
    );

    test('satılan tür 2 yıl açılamaz; tek ve ekipli yazılım aynı koldur', () {
      final c = opened(simit);
      final sold = BusinessRules.dispose(
        c,
        c.businesses.single.id,
        sell: false,
      );
      expect(
        BusinessRules.openBlocked(sold, simit, timeLeft: 5),
        BusinessBlocked.yeniKapandi,
      );
      expect(BusinessRules.sameLine('yazilim_ekip', 'yazilim'), isTrue);
    });

    test('yalnızca bir işletmenin başında durulur', () {
      final c = BusinessRules.open(opened(simit), berber, factory);
      expect(c.businesses.where((b) => b.present), hasLength(1));
      expect(
        c.businesses.firstWhere((b) => b.type == 'simit').managerId,
        isNotNull,
      );
    });

    test('vefat eden çalışanın yerine yenisi gelir', () {
      final c = opened(berber);
      final worker = c.people[c.businesses.single.staff.single]!;
      final dead = c.copyWith(
        people: c.people.update(worker.copyWith(diedAt: c.age)),
      );
      final next = BusinessRules.refreshStaff(dead, factory);
      final staff = next.businesses.single.staff.single;
      expect(staff, isNot(worker.id));
      expect(next.people[staff]!.hasRole(RoleKind.calisan), isTrue);
    });

    test('16 yaşında kredi yok; net servet işletmeyi sayar', () {
      expect(
        BusinessRules.loanAllowed(testCharacter(age: 16, reputation: 80)),
        isFalse,
      );
      final c = opened(berber);
      expect(
        Economy.netWorth(c, const Market(goldPrice: 1)),
        c.stats.money +
            BusinessRules.exitValue(c.businesses.single, sell: false),
      );
    });
  });
}
