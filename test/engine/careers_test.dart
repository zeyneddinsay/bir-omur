import 'dart:convert';

import 'package:bir_omur/content/card_validator.dart';
import 'package:bir_omur/content/content_registry.dart';
import 'package:bir_omur/engine/engine.dart';
import 'package:bir_omur/models/json_reader.dart';
import 'package:bir_omur/models/models.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_cards.dart';
import '../helpers/test_character.dart';

Map<String, dynamic> _careerJson({double variance = 0}) => {
  'id': 'test_meslek',
  'name': 'Test',
  'incomeVariance': variance,
  'tiers': [
    {
      'name': 'Bir',
      'salary': 100000,
      'promotion': {
        'minYears': 2,
        'chance': 1.0,
        'cost': 50000,
        'requires': {
          'min': {'knowledge': 60},
        },
      },
    },
    {
      'name': 'İki',
      'salary': 200000,
      'promotion': {'minYears': 1, 'chance': 1.0},
    },
    {'name': 'Üç', 'salary': 500000},
  ],
};

/// Emekli aylığı hakkını doldurmuş (20 yıl çalışmış) karakter.
Character _veteran(Character c) =>
    c.copyWith(counters: const LifeCounters(yearsWorked: 20));

Career _career({double variance = 0}) =>
    Career.fromJson(_careerJson(variance: variance), file: 'test.json');

CareerBook _book({double variance = 0}) =>
    CareerBook([_career(variance: variance)]);

Job _job(int tier, {int years = 0}) =>
    Job(careerId: 'test_meslek', tier: tier, yearsInTier: years);

void main() {
  group('Career.fromJson', () {
    test('kademeleri ve terfi şartlarını okur', () {
      final c = _career();
      expect(c.maxTier, 3);
      expect(c.tier(1).salary, 100000);
      expect(c.tier(1).promotion!.cost, 50000);
      expect(c.tier(1).promotion!.requires.min, {'knowledge': 60});
      expect(c.tier(3).promotion, isNull);
    });

    test('son kademede terfi, ara kademede terfisizlik hatadır', () {
      final lastWithPromotion = _careerJson();
      (lastWithPromotion['tiers'] as List).last['promotion'] = {
        'minYears': 1,
        'chance': 0.5,
      };
      expect(
        () => Career.fromJson(lastWithPromotion, file: 'x'),
        throwsA(isA<CardFormatException>()),
      );

      final middleWithout = _careerJson();
      ((middleWithout['tiers'] as List)[1] as Map).remove('promotion');
      expect(
        () => Career.fromJson(middleWithout, file: 'x'),
        throwsA(isA<CardFormatException>()),
      );
    });

    test('gelir oynaklığı 0 ile 1 arasında olmalı', () {
      expect(
        () => Career.fromJson(_careerJson(variance: 1.5), file: 'x'),
        throwsA(isA<CardFormatException>()),
      );
    });
  });

  group('CareerChange.fromJson', () {
    CareerChange parse(Map<String, dynamic> json) =>
        CareerChange.fromJson(JsonReader(json, 'test'));

    test('join kademeyle birlikte okunur', () {
      final change = parse({'join': 'esnaf', 'tier': 3}) as JoinCareer;
      expect(change.careerId, 'esnaf');
      expect(change.tier, 3);
      expect((parse({'join': 'memur'}) as JoinCareer).tier, 1);
    });

    test('tam bir eylem olmalı', () {
      expect(
        () => parse({'join': 'memur', 'quit': true}),
        throwsA(isA<CardFormatException>()),
      );
      expect(() => parse({}), throwsA(isA<CardFormatException>()));
      expect(
        () => parse({'promote': 1, 'tier': 2}),
        throwsA(isA<CardFormatException>()),
      );
    });
  });

  group('Careers.applyChange', () {
    final book = _book();

    test('işe girer, kademe meslekteki en üstü aşmaz', () {
      final c = Careers.applyChange(
        testCharacter(),
        const JoinCareer('test_meslek', tier: 9),
        book,
      );
      expect(c.job!.tier, 3);
    });

    test('terfi kademeler içinde kalır ve yılı sıfırlar', () {
      final c = testCharacter(job: _job(2, years: 4));
      final up = Careers.applyChange(c, const PromoteCareer(5), book);
      expect(up.job!.tier, 3);
      expect(up.job!.yearsInTier, 0);
      final down = Careers.applyChange(c, const PromoteCareer(-5), book);
      expect(down.job!.tier, 1);
    });

    test('işsize terfi bir şey yapmaz', () {
      final c = testCharacter();
      expect(
        identical(Careers.applyChange(c, const PromoteCareer(1), book), c),
        isTrue,
      );
    });

    test('istifa işi bırakır, aylık bağlamaz', () {
      final c = Careers.applyChange(
        testCharacter(job: _job(2)),
        const QuitCareer(),
        book,
      );
      expect(c.job, isNull);
      expect(c.isRetired, isFalse);
    });

    test('emeklilik son maaşın %60ı, en az taban aylık', () {
      final high = Careers.applyChange(
        _veteran(testCharacter(job: _job(3))),
        const RetireCareer(),
        book,
      );
      expect(high.job, isNull);
      expect(high.pension, 300000);

      final low = Careers.applyChange(
        _veteran(testCharacter(job: _job(1))),
        const RetireCareer(),
        book,
      );
      expect(low.pension, Careers.minPension);
    });

    test('kart etkisiyle emekli olan emekli bayrağını alır', () {
      final c = EffectResolver.applyEffect(
        _veteran(testCharacter(job: _job(2))),
        const Effect(career: RetireCareer()),
        careers: book,
      );
      expect(c.hasFlag(Careers.retiredFlag), isTrue);
    });
  });

  group('CareerTick', () {
    test('maaş ödenir, kademede geçen yıl artar', () {
      final (c, report) = CareerTick(
        SeededRandom(1),
        _book(),
      ).apply(testCharacter(age: 30, money: 0, knowledge: 10, job: _job(1)));
      expect(report.income, 100000);
      expect(c.stats.money, 100000);
      expect(c.job!.yearsInTier, 1);
      expect(report.promoted, isFalse);
    });

    test('şartlar ve süre dolunca terfi eder, ücretini öder', () {
      final (c, report) = CareerTick(SeededRandom(1), _book()).apply(
        testCharacter(age: 30, money: 0, knowledge: 60, job: _job(1, years: 1)),
      );
      expect(report.promoted, isTrue);
      expect(c.job!.tier, 2);
      expect(c.job!.yearsInTier, 0);
      // Bu yılın maaşı eski kademeden; terfi ücreti düşülür.
      expect(c.stats.money, 100000 - 50000);
    });

    test('şart tutmazsa terfi olmaz', () {
      final (c, report) = CareerTick(SeededRandom(1), _book()).apply(
        testCharacter(age: 30, money: 0, knowledge: 59, job: _job(1, years: 5)),
      );
      expect(report.promoted, isFalse);
      expect(c.job!.tier, 1);
    });

    test('oynak meslekte gelir aralıkta değişir', () {
      final incomes = <int>{};
      for (var seed = 0; seed < 30; seed++) {
        final (_, report) = CareerTick(
          SeededRandom(seed),
          _book(variance: 0.5),
        ).apply(testCharacter(age: 30, job: _job(3)));
        expect(report.income, inInclusiveRange(250000, 750000));
        incomes.add(report.income);
      }
      expect(incomes.length, greaterThan(10));
    });

    test('65 yaşında çalışan emekli olur ve aylık alır', () {
      final (c, report) = CareerTick(
        SeededRandom(1),
        _book(),
      ).apply(_veteran(testCharacter(age: 65, money: 0, job: _job(3))));
      expect(report.retired, isTrue);
      expect(c.job, isNull);
      expect(c.pension, 300000);
      expect(c.stats.money, 300000);
    });

    test('hiç çalışmamış biri emekli olmaz, 65 yaş aylığı alır', () {
      final (c, report) = CareerTick(
        SeededRandom(1),
        _book(),
      ).apply(testCharacter(age: 65, money: 0));
      expect(report.retired, isFalse);
      expect(c.pension, 0);
      expect(report.income, Careers.oldAgeAllowance);
      expect(report.source, MoneySource.yasliAyligi);
    });

    test('15 yıl çalışan 65te emekli olur, en az taban aylık', () {
      final worker = testCharacter(
        age: 65,
        money: 0,
      ).copyWith(counters: LifeCounters.zero.copyWith(yearsWorked: 15));
      final (c, report) = CareerTick(SeededRandom(1), _book()).apply(worker);
      expect(report.retired, isTrue);
      expect(c.pension, Careers.minPension);
      expect(report.source, MoneySource.emekliAyligi);
    });

    test('işsize kendiliğinden gelir yok; lise cep harçlığı; çocuk 0', () {
      int income(Character c) =>
          CareerTick(SeededRandom(1), _book()).apply(c).$2.income;
      expect(income(testCharacter(age: 30)), 0, reason: 'ara işler aksiyondur');
      expect(income(testCharacter(age: 16)), Careers.highSchoolAllowance);
      expect(income(testCharacter(age: 9)), 0);
      // Anne-babasız üniversiteliye aile harçlığı yok.
      expect(
        income(testCharacter(age: 20, flags: {ActionCatalog.studentFlag})),
        0,
      );
    });
  });

  group('meslek koşulları', () {
    test('none, any, meslek kimliği ve en az kademe', () {
      final worker = testCharacter(job: _job(2));
      final idle = testCharacter();
      bool met(Conditions c, Character ch) => c.isMetBy(ch);

      expect(met(const Conditions(career: 'none'), idle), isTrue);
      expect(met(const Conditions(career: 'none'), worker), isFalse);
      expect(met(const Conditions(career: 'any'), worker), isTrue);
      expect(met(const Conditions(career: 'any'), idle), isFalse);
      expect(met(const Conditions(career: 'test_meslek'), worker), isTrue);
      expect(met(const Conditions(career: 'memur'), worker), isFalse);
      expect(met(const Conditions(minTier: 2), worker), isTrue);
      expect(met(const Conditions(minTier: 3), worker), isFalse);
      expect(met(const Conditions(minTier: 1), idle), isFalse);
    });
  });

  group('card_lint meslek denetimi', () {
    final registry = ContentRegistry(
      flags: {'universite_ogrencisi': '', 'asker_anilari': '', 'tasindi': ''},
    );
    final careerFiles = {'test.json': jsonEncode(_careerJson())};

    CardCheckResult check(Map<String, dynamic> extra) =>
        CardValidator(registry).check({
          'x.json': jsonEncode([
            {
              ...testCardJson('a', minAge: 20, maxAge: 30, text: 'Metin.'),
              ...extra,
            },
          ]),
        }, careerFiles: careerFiles);

    test('bilinen meslek ve kademe geçer', () {
      final result = check({
        'conditions': {'career': 'test_meslek', 'minTier': 3},
        'left': {
          'label': 'Sol',
          'effects': {
            'career': {'join': 'test_meslek', 'tier': 2},
          },
        },
      });
      expect(result.issues, isEmpty);
      expect(result.careers.single.id, 'test_meslek');
    });

    test('bilinmeyen meslek ve olmayan kademe hatadır', () {
      final result = check({
        'conditions': {'career': 'doktor'},
        'left': {
          'label': 'Sol',
          'effects': {
            'career': {'join': 'test_meslek', 'tier': 4},
          },
        },
      });
      expect(result.errors.map((e) => e.message), [
        contains('"doktor"'),
        contains('4. kademe yok'),
      ]);
    });

    test('işsiz koşuluyla kademe istenemez', () {
      final result = check({
        'conditions': {'career': 'none', 'minTier': 2},
      });
      expect(result.errors.single.message, contains('işsiz'));
    });

    test('bozuk meslek dosyası yeriyle bildirilir', () {
      final bad = _careerJson()..remove('name');
      final result = CardValidator(registry)
          .check(const {}, careerFiles: {'bozuk.json': jsonEncode(bad)});
      expect(result.errors.single.path, contains('bozuk.json.name'));
    });
  });

  group('İş ara', () {
    Career career(String id, int salary, Map<String, dynamic> jobSearch) =>
        Career.fromJson({
          'id': id,
          'name': id,
          'jobSearch': jobSearch,
          'tiers': [
            {'name': 'Tek', 'salary': salary},
          ],
        }, file: '$id.json');

    final book = CareerBook([
      career('kolay', 100000, {
        'roll': {'stat': 'luck', 'threshold': 0},
        'maxAge': 35,
      }),
      career('iyi', 300000, {
        'roll': {'stat': 'knowledge', 'threshold': 60},
        'requires': {
          'flags': ['universite_mezunu'],
        },
      }),
    ]);
    bool always(Roll _) => true;
    bool never(Roll _) => false;

    test('en yüksek maaşlı açık meslek önce denenir', () {
      final grad = testCharacter(age: 25, flags: {'universite_mezunu'});
      final (hired, result) = searchJob(grad, book, always);
      expect(result.careerId, 'iyi');
      expect(hired.job!.careerId, 'iyi');
      expect(hired.job!.tier, 1);
    });

    test('şartı tutmayan meslek atlanır', () {
      final (hired, result) = searchJob(testCharacter(age: 25), book, always);
      expect(result.careerId, 'kolay');
      expect(hired.job!.careerId, 'kolay');
    });

    test('yaş sınırı ve başarısız zar', () {
      final (_, old) = searchJob(testCharacter(age: 40), book, always);
      expect(old.found, isFalse);
      final (same, none) = searchJob(testCharacter(age: 25), book, never);
      expect(none.found, isFalse);
      expect(same.job, isNull);
    });

    test(
      'aksiyon yalnızca işsiz, emekli ve öğrenci olmayan yetişkine açık',
      () {
        final action = ActionCatalog.byId(ActionCatalog.jobSearchId)!;
        expect(action.isAvailableFor(testCharacter(age: 25)), isTrue);
        expect(action.isAvailableFor(testCharacter(age: 17)), isFalse);
        expect(
          action.isAvailableFor(testCharacter(age: 25, job: _job(1))),
          isFalse,
        );
        expect(
          action.isAvailableFor(testCharacter(age: 50, pension: 140000)),
          isFalse,
        );
        expect(
          action.isAvailableFor(
            testCharacter(age: 20, flags: {ActionCatalog.studentFlag}),
          ),
          isFalse,
        );
      },
    );

    test('motorda iş ara mesleğe sokar, sonuç yıl sonunda silinir', () {
      final engine = LifeEngine(deck: EventDeck([]), seed: 3, careers: book);
      engine.startLife();
      while (engine.state.character.age < 20) {
        engine.advanceYear();
      }
      final state = engine.doAction(ActionCatalog.jobSearchId);
      expect(engine.lastJobSearch!.careerId, 'kolay');
      expect(state.character.job!.careerId, 'kolay');
      engine.advanceYear();
      expect(engine.lastJobSearch, isNull);
      expect(
        engine.availableActions().any(
          (a) => a.$1.id == ActionCatalog.jobSearchId,
        ),
        isFalse,
        reason: 'işi olan iş aramaz',
      );
    });

    test('iş arama bölümü JSON şemasıyla doğrulanır', () {
      expect(
        () => career('x', 1, {
          'roll': {'stat': 'luck', 'threshold': 50},
          'yas': 30,
        }),
        throwsA(isA<CardFormatException>()),
      );
    });
  });
}
