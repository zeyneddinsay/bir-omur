import 'dart:convert';
import 'dart:io';

import 'package:bir_omur/content/event_text.dart';
import 'package:bir_omur/content/interaction_validator.dart';
import 'package:bir_omur/content/person_text.dart';
import 'package:bir_omur/content/turkish.dart';
import 'package:bir_omur/engine/engine.dart';
import 'package:bir_omur/models/models.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/families.dart';
import '../helpers/test_cards.dart';
import '../helpers/test_character.dart';

final InteractionBook _book = InteractionBook.parse(
  File('assets/interactions.json').readAsStringSync(),
);

Person _person({
  String id = 'p1',
  String name = 'Kerem',
  Gender gender = Gender.erkek,
  int age = 30,
  int playerAge = 30,
  String city = 'Konya',
  Kinship? kin,
  Side? side,
  List<PersonRole> roles = const [],
  Set<Trait> traits = const {},
  int base = 40,
  List<Memory> memories = const [],
  int? lastContactAt,
  WealthLevel wealth = WealthLevel.orta,
  int loan = 0,
  bool archived = false,
}) => Person(
  id: id,
  name: name,
  surname: 'Yılmaz',
  gender: gender,
  bornAt: playerAge - age,
  city: city,
  origin: Origin.okul,
  metAt: 0,
  base: base,
  portraitSeed: 1,
  kin: kin,
  side: side,
  roles: roles,
  traits: traits,
  wealth: wealth,
  memories: memories,
  lastContactAt: lastContactAt ?? playerAge,
  loan: loan,
  archived: archived,
);

Character _with(
  Person p, {
  int age = 30,
  int money = 100000,
  HomeKind home = HomeKind.aile,
}) {
  final (book, _) = PeopleBook.empty().add((id) => p);
  return testCharacter(
    age: age,
    money: money,
    home: home,
  ).copyWith(people: book);
}

Memory _memory(
  String kind, {
  MemoryTone tone = MemoryTone.olumsuz,
  int severity = 2,
  int age = 14,
  MemoryOwner owner = MemoryOwner.ikisi,
}) => Memory(
  kind: kind,
  label: kind,
  age: age,
  tone: tone,
  severity: severity,
  owner: owner,
);

void main() {
  List<InteractionOption> options(
    Person p, {
    int age = 30,
    int timeLeft = 5,
    Set<String> used = const {},
    int money = 100000,
    HomeKind home = HomeKind.aile,
  }) => Interactions.optionsFor(
    _with(p, age: age, money: money, home: home),
    p,
    timeLeft: timeLeft,
    used: used,
  );

  InteractionOption option(Person p, InteractionKind kind, {int age = 30}) =>
      options(p, age: age).singleWhere((o) => o.kind == kind);

  (Character, InteractionResult) run(
    Person p,
    InteractionKind kind, {
    int seed = 1,
    int age = 30,
    int money = 100000,
    CallTone? tone,
    String? memoryKind,
  }) => Interactions.resolve(
    SeededRandom(seed),
    _with(p, age: age, money: money),
    InteractionRequest(kind, p.id, tone: tone, memoryKind: memoryKind),
    timeLeft: 5,
    used: const {},
    memoryLabels: _book.memoryLabels,
  );

  /// [n] tohumla dener, sonuç anahtarlarını sayar.
  Map<String, int> outcomes(
    Person p,
    InteractionKind kind, {
    int n = 2000,
    CallTone? tone,
    String? memoryKind,
    int age = 30,
  }) {
    final counts = <String, int>{};
    for (var s = 0; s < n; s++) {
      final (_, r) = run(
        p,
        kind,
        seed: s,
        tone: tone,
        memoryKind: memoryKind,
        age: age,
      );
      counts.update(r.outcome, (v) => v + 1, ifAbsent: () => 1);
    }
    return counts;
  }

  double share(Map<String, int> counts, String key) =>
      (counts[key] ?? 0) / counts.values.fold(0, (a, b) => a + b);

  group('hangi etkileşim kime', () {
    test('role özel etkileşimler', () {
      Set<InteractionKind> kinds(Person p) =>
          options(p).map((o) => o.kind).toSet();
      expect(
        kinds(_person(kin: Kinship.anne)),
        contains(InteractionKind.yemegiOv),
      );
      expect(
        kinds(_person(kin: Kinship.baba)),
        contains(InteractionKind.macIzle),
      );
      expect(
        kinds(_person(kin: Kinship.dede)),
        contains(InteractionKind.eliniOp),
      );
      expect(
        kinds(_person(kin: Kinship.nine)),
        contains(InteractionKind.eliniOp),
      );
      expect(
        options(
          _person(kin: Kinship.kardes, age: 8, playerAge: 10),
          age: 10,
        ).map((o) => o.kind),
        contains(InteractionKind.kardesleOyna),
      );
      expect(
        kinds(_person(roles: const [PersonRole(RoleKind.komsu)])),
        contains(InteractionKind.cayaGit),
      );
      final stranger = kinds(_person());
      for (final special in const [
        InteractionKind.yemegiOv,
        InteractionKind.macIzle,
        InteractionKind.eliniOp,
        InteractionKind.kardesleOyna,
        InteractionKind.cayaGit,
      ]) {
        expect(stranger, isNot(contains(special)));
      }
    });

    test('çekirdek aileden uzaklaşılamaz', () {
      for (final kin in PeopleTick.coreKin) {
        expect(
          options(_person(kin: kin)).map((o) => o.kind),
          isNot(contains(InteractionKind.uzaklas)),
        );
      }
      expect(
        options(_person(kin: Kinship.teyze)).map((o) => o.kind),
        contains(InteractionKind.uzaklas),
      );
    });

    test('eski tanıdık yalnızca aranabilir', () {
      expect(options(_person(archived: true)).map((o) => o.kind), [
        InteractionKind.ara,
      ]);
    });

    test('vefat etmiş ya da doğmamış kişiyle etkileşim yok', () {
      expect(options(_person().copyWith(diedAt: 20)), isEmpty);
      expect(options(_person(age: -2)), isEmpty);
    });

    test('borcu varsa borç iste yerine borcunu öde', () {
      final kinds = options(_person(loan: 5000)).map((o) => o.kind);
      expect(kinds, contains(InteractionKind.borcOde));
      expect(kinds, isNot(contains(InteractionKind.borcIste)));
      final repay = options(
        _person(loan: 5000),
        money: 1000,
      ).singleWhere((o) => o.kind == InteractionKind.borcOde);
      expect(repay.blocked, Blocked.para);
      expect(repay.moneyCost, 5000);
    });
  });

  group('şartlar', () {
    test('yaş', () {
      expect(
        option(
          _person(age: 40, playerAge: 6),
          InteractionKind.bulus,
          age: 6,
        ).enabled,
        isTrue,
      );
      expect(
        option(
          _person(age: 2, playerAge: 8),
          InteractionKind.bulus,
          age: 8,
        ).blocked,
        Blocked.karsiYas,
        reason: 'bebekle buluşulmaz',
      );
      expect(
        option(_person(), InteractionKind.ara, age: 10).blocked,
        Blocked.yas,
      );
      expect(option(_person(), InteractionKind.ara, age: 11).enabled, isTrue);
      expect(
        option(_person(age: 5, playerAge: 30), InteractionKind.ara).blocked,
        Blocked.karsiYas,
      );
      expect(
        option(_person(), InteractionKind.borcIste, age: 17).blocked,
        Blocked.yas,
      );
      expect(
        options(
          _person(kin: Kinship.kardes, age: 20, playerAge: 10),
          age: 10,
        ).map((o) => o.kind),
        isNot(contains(InteractionKind.kardesleOyna)),
        reason: 'kardeş 14 yaşından büyük: seçenek hiç çıkmaz',
      );
      final sibling = _person(kin: Kinship.kardes, age: 12, playerAge: 15);
      expect(
        options(sibling, age: 15).map((o) => o.kind),
        isNot(
          anyOf(contains(InteractionKind.ara), contains(InteractionKind.bulus)),
        ),
        reason: 'aynı evde yaşanan kardeş aranmaz',
      );
      expect(
        options(sibling, age: 20, home: HomeKind.kira).map((o) => o.kind),
        contains(InteractionKind.ara),
        reason: 'evden çıkınca kardeş aranır',
      );
    });

    test('vakit, para ve bu yıl', () {
      final p = _person();
      expect(
        options(p, timeLeft: 0).every((o) => o.blocked == Blocked.vakit),
        isTrue,
      );
      expect(
        options(
          p,
          money: 100,
        ).singleWhere((o) => o.kind == InteractionKind.hediye).blocked,
        Blocked.para,
      );
      expect(
        options(
          p,
          used: {Interactions.usedKey(p.id, InteractionKind.bulus)},
        ).singleWhere((o) => o.kind == InteractionKind.bulus).blocked,
        Blocked.buYil,
      );
    });

    test('başka şehir: buluşma 2 vakit ve yol parası; ev içi işler kapalı', () {
      final far = _person(city: 'Rize', kin: Kinship.dede);
      final meet = option(far, InteractionKind.bulus);
      expect(meet.timeCost, 2);
      expect(meet.moneyCost, Interactions.travelCost);
      expect(option(far, InteractionKind.eliniOp).blocked, Blocked.uzak);
      expect(option(far, InteractionKind.ara).timeCost, 1);
      expect(
        option(_person(kin: Kinship.dede), InteractionKind.bulus).timeCost,
        1,
      );
    });

    test('aileyle yaşarken anne aynı evde; evden çıkınca aranır', () {
      final mother = _person(kin: Kinship.anne);
      List<InteractionKind> kinds(int age, HomeKind home) => [
        for (final o in options(mother, age: age, home: home)) o.kind,
      ];
      expect(kinds(12, HomeKind.aile), isNot(contains(InteractionKind.ara)));
      expect(kinds(25, HomeKind.aile), isNot(contains(InteractionKind.ara)));
      expect(kinds(25, HomeKind.kira), contains(InteractionKind.ara));
      expect(option(mother, InteractionKind.yemegiOv, age: 12).enabled, isTrue);
      final away = _person(kin: Kinship.anne, city: 'Rize');
      expect(
        options(
          away,
          home: HomeKind.kira,
        ).singleWhere((o) => o.kind == InteractionKind.yemegiOv).blocked,
        Blocked.uzak,
      );
    });

    test('dertleşmek için yakınlık 30', () {
      expect(
        option(_person(base: 29), InteractionKind.dertles).blocked,
        Blocked.yakinlikDusuk,
      );
      expect(
        option(_person(base: 30), InteractionKind.dertles).enabled,
        isTrue,
      );
    });

    test('Ara tonları', () {
      final now = 30;
      final plain = _person();
      expect(Interactions.toneBlocked(plain, CallTone.halHatir, now), isNull);
      expect(
        Interactions.toneBlocked(plain, CallTone.nostalji, now),
        Blocked.aniYok,
      );
      expect(
        Interactions.toneBlocked(plain, CallTone.igne, now),
        Blocked.aniYok,
      );
      expect(
        Interactions.toneBlocked(plain, CallTone.ozur, now),
        Blocked.kirginlikYok,
      );
      final hurt = _person(memories: [_memory('rezil_etti')]);
      for (final tone in CallTone.values) {
        expect(
          Interactions.toneBlocked(hurt, tone, now),
          isNull,
          reason: tone.name,
        );
      }
      final onlyMine = _person(
        memories: [_memory('beni_kirdi', owner: MemoryOwner.oyuncu)],
      );
      expect(
        Interactions.toneBlocked(onlyMine, CallTone.igne, now),
        Blocked.aniYok,
      );
    });

    test('sohbet menüsü en güçlü üç ortak anı', () {
      final p = _person(
        memories: [
          _memory('a', severity: 1),
          _memory('b', severity: 3),
          _memory('c', severity: 2, tone: MemoryTone.olumlu),
          _memory('d', severity: 2),
          _memory('e', owner: MemoryOwner.kisi, severity: 3),
        ],
      );
      expect(Interactions.callMemories(p, 30).map((m) => m.kind), [
        'b',
        'c',
        'd',
      ]);
      expect(
        Interactions.callMemories(
          p,
          30,
          tone: MemoryTone.olumsuz,
        ).map((m) => m.kind),
        ['b', 'd', 'a'],
      );
    });

    test('kapalı etkileşim uygulanamaz', () {
      expect(
        () => run(_person(base: 10), InteractionKind.dertles),
        throwsStateError,
      );
      expect(
        () => run(_person(), InteractionKind.ara, tone: CallTone.nostalji),
        throwsStateError,
      );
      expect(
        () => run(
          _person(memories: [_memory('rezil_etti')]),
          InteractionKind.ara,
          tone: CallTone.nostalji,
          memoryKind: 'baska',
        ),
        throwsStateError,
      );
    });
  });

  group('sonuçlar', () {
    test('buluşma: yakın kişiyle iyi geçme olasılığı', () {
      // 0,6 + 70/250 = 0,88
      final counts = outcomes(_person(base: 70), InteractionKind.bulus);
      expect(share(counts, 'bulus.iyi'), closeTo(0.88, 0.03));
      expect(counts.containsKey('bulus.tartisma'), isFalse);
    });

    test('buluşma: husumetli kişiyle tartışma ve olumsuz anı', () {
      final p = _person(
        base: 10,
        traits: {Trait.kiskanc},
        memories: [_memory('rezil_etti', severity: 3, age: 30)],
      );
      final counts = outcomes(p, InteractionKind.bulus);
      expect(counts['bulus.tartisma'], greaterThan(1000));
      final (c, r) = run(p, InteractionKind.bulus, seed: 3);
      if (r.outcome == 'bulus.tartisma') {
        expect(r.memory!.tone, MemoryTone.olumsuz);
        expect(c.people[p.id]!.memories, hasLength(2));
      }
    });

    test('hediye: Çıkarcı daha çok sever', () {
      final (_, normal) = run(_person(), InteractionKind.hediye);
      final (_, greedy) = run(
        _person(traits: {Trait.cikarci}),
        InteractionKind.hediye,
      );
      expect(normal.memory!.severity, 1);
      expect(greedy.memory!.severity, 2);
      expect(normal.money, -Interactions.giftCost);
    });

    test('dertleşme: Dedikoducu yarı yarıya mahalleye yayar', () {
      final counts = outcomes(
        _person(traits: {Trait.dedikoducu}),
        InteractionKind.dertles,
      );
      expect(share(counts, 'dertles.yayildi'), closeTo(0.5, 0.04));
      expect(outcomes(_person(), InteractionKind.dertles).keys, [
        'dertles.iyi',
      ]);
      for (var s = 0; s < 50; s++) {
        final (_, r) = run(
          _person(traits: {Trait.dedikoducu}),
          InteractionKind.dertles,
          seed: s,
        );
        if (r.outcome == 'dertles.yayildi') {
          expect(r.stats[StatKind.reputation], -3);
          return;
        }
      }
      fail('yayılma hiç olmadı');
    });

    test('borç: kabul edilirse tutar servete göre, borç kişide kalır', () {
      for (final wealth in WealthLevel.values) {
        final p = _person(base: 100, traits: {Trait.comert}, wealth: wealth);
        final (c, r) = run(p, InteractionKind.borcIste);
        expect(r.outcome, 'borc.verdi');
        expect(r.money, Interactions.loanAmount[wealth]);
        expect(c.people[p.id]!.loan, Interactions.loanAmount[wealth]);
        expect(r.memory, isNull);
      }
    });

    test('borç: reddedilince yalnızca oyuncu hatırlar', () {
      final p = _person(
        base: 0,
        traits: {Trait.cikarci},
        wealth: WealthLevel.dar,
      );
      final (c, r) = run(p, InteractionKind.borcIste);
      expect(r.outcome, 'borc.vermedi');
      expect(r.memory!.owner, MemoryOwner.oyuncu);
      final after = c.people[p.id]!;
      expect(Relationships.hostility(after, 30), 0);
      expect(after.loan, 0);
    });

    test('borç ödeme', () {
      final p = _person(loan: 8000);
      final (c, r) = run(p, InteractionKind.borcOde);
      expect(r.money, -8000);
      expect(c.people[p.id]!.loan, 0);
      expect(r.memory!.tone, MemoryTone.olumlu);
    });

    test('laf sokma: Gamsız yüzde 40 güler geçer', () {
      final counts = outcomes(
        _person(traits: {Trait.gamsiz}),
        InteractionKind.lafSok,
      );
      expect(share(counts, 'lafsok.gecti'), closeTo(0.4, 0.04));
      final (_, r) = run(_person(), InteractionKind.lafSok);
      expect(r.outcome, 'lafsok.iyi');
      expect(r.memory!.tone, MemoryTone.olumsuz);
    });

    test('uzaklaşma arşivler, çubukları ve son görüşmeyi değiştirmez', () {
      final p = _person(lastContactAt: 20, memories: [_memory('x', age: 20)]);
      final (c, r) = run(p, InteractionKind.uzaklas);
      final after = c.people[p.id]!;
      expect(after.archived, isTrue);
      expect(after.lastContactAt, 20);
      expect(after.memories, p.memories);
      expect(r.memory, isNull);
    });

    test('etkileşim görüşme sayılır, aranan eski tanıdık arşivden çıkar', () {
      final p = _person(lastContactAt: 10, archived: true);
      final (c, _) = run(p, InteractionKind.ara, tone: CallTone.halHatir);
      final after = c.people[p.id]!;
      expect(after.lastContactAt, 30);
      expect(after.archived, isFalse);
    });

    test('dede ve nine çocuğa harçlık verir', () {
      final p = _person(kin: Kinship.dede, age: 70, playerAge: 8);
      final (_, child) = run(p, InteractionKind.eliniOp, age: 8);
      expect(child.outcome, 'dede.el.harclik');
      expect(child.money, Interactions.pocketMoney);
      final adult = _person(kin: Kinship.dede, age: 80, playerAge: 25);
      final (_, grown) = run(adult, InteractionKind.eliniOp, age: 25);
      expect(grown.outcome, 'dede.el');
      expect(grown.money, 0);
    });

    test('etkileşim Aile Bağı göstergesine doğrudan dokunmaz', () {
      final (_, r) = run(_person(kin: Kinship.anne), InteractionKind.dertles);
      expect(r.stats.containsKey(StatKind.family), isFalse);
    });
  });

  group('Ara', () {
    test('yıllar sonra arama bir kez 1,5 kat', () {
      final p = _person(lastContactAt: 20);
      final (c, r) = run(p, InteractionKind.ara, tone: CallTone.halHatir);
      expect(r.outcome, 'ara.yillarsonra');
      expect(r.memory!.bonus, Interactions.longGapBonus);
      final after = c.people[p.id]!;
      expect(after.reunited, isTrue);
      final again = after.copyWith(lastContactAt: 20);
      final (_, r2) = run(again, InteractionKind.ara, tone: CallTone.halHatir);
      expect(r2.outcome, 'ara.halhatir');
      expect(r2.memory!.bonus, 1.0);
    });

    test('nostalji, olumlu anı', () {
      final p = _person(
        memories: [_memory('maç', tone: MemoryTone.olumlu, age: 29)],
      );
      final (_, r) = run(
        p,
        InteractionKind.ara,
        tone: CallTone.nostalji,
        memoryKind: 'maç',
      );
      expect(r.outcome, 'ara.nostalji.olumlu');
      expect(r.memory!.kind, 'eski_gunler');
    });

    test('nostalji, olumsuz anı: Kıskanç yarı yarıya, Gamsız neredeyse hep affeder', () {
      Person hurt(Set<Trait> traits) =>
          _person(traits: traits, memories: [_memory('rezil_etti', age: 29)]);
      final jealous = outcomes(
        hurt({Trait.kiskanc}),
        InteractionKind.ara,
        tone: CallTone.nostalji,
        memoryKind: 'rezil_etti',
      );
      final easy = outcomes(
        hurt({Trait.gamsiz}),
        InteractionKind.ara,
        tone: CallTone.nostalji,
        memoryKind: 'rezil_etti',
      );
      expect(share(jealous, 'ara.nostalji.baristik'), closeTo(0.5, 0.04));
      expect(share(easy, 'ara.nostalji.baristik'), closeTo(0.95, 0.02));
    });

    test('özür en ağır kırgınlığı yumuşatır', () {
      final p = _person(
        traits: {Trait.gamsiz},
        memories: [
          _memory('kucuk', severity: 1, age: 29),
          _memory('buyuk', severity: 3, age: 29),
        ],
      );
      for (var s = 0; s < 20; s++) {
        final (c, r) = run(
          p,
          InteractionKind.ara,
          tone: CallTone.ozur,
          seed: s,
        );
        if (r.outcome != 'ara.ozur.kabul') continue;
        final kinds = {
          for (final m in c.people[p.id]!.memories)
            if (m.healed) m.kind,
        };
        expect(kinds, {'buyuk'});
        expect(r.healed, isTrue);
        return;
      }
      fail('özür hiç kabul edilmedi');
    });

    test('iğneleme: Kıskanç kişide şiddet 3', () {
      final p = _person(
        traits: {Trait.kiskanc},
        memories: [_memory('rezil_etti', age: 29)],
      );
      final (c, r) = run(
        p,
        InteractionKind.ara,
        tone: CallTone.igne,
        memoryKind: 'rezil_etti',
      );
      expect(r.outcome, 'ara.igne.iyi');
      expect(r.memory!.severity, 3);
      expect(
        Relationships.hostility(c.people[p.id]!, 30),
        greaterThan(Relationships.hostility(p, 30)),
      );
    });

    test('husumetli ve soğuk kişi yarı yarıya açmaz, özür hariç', () {
      final cold = _person(
        base: 0,
        traits: {Trait.kiskanc},
        memories: [_memory('rezil_etti', severity: 3, age: 30)],
      );
      final counts = outcomes(
        cold,
        InteractionKind.ara,
        tone: CallTone.halHatir,
      );
      expect(share(counts, 'ara.acmadi'), closeTo(0.5, 0.04));
      final apology = outcomes(cold, InteractionKind.ara, tone: CallTone.ozur);
      expect(apology.containsKey('ara.acmadi'), isFalse);
    });

    test('Kerem örneği: 21 yaşında "Çocukluk işte" araması', () {
      // 12 yaşında sınıf arkadaşı, Kıskanç; 14 yaşında rezil etti.
      var kerem = Person(
        id: 'p1',
        name: 'Kerem',
        surname: 'Yılmaz',
        gender: Gender.erkek,
        bornAt: 0,
        city: 'Konya',
        origin: Origin.okul,
        metAt: 12,
        base: 10,
        portraitSeed: 1,
        traits: const {Trait.kiskanc},
        lastContactAt: 14,
      );
      kerem = Relationships.addMemory(
        kerem,
        _memory('rezil_etti', age: 14),
        now: 14,
      );
      for (var s = 0; s < 50; s++) {
        final (c, r) = run(
          kerem,
          InteractionKind.ara,
          age: 21,
          seed: s,
          tone: CallTone.nostalji,
          memoryKind: 'rezil_etti',
        );
        if (r.outcome != 'ara.nostalji.baristik') continue;
        final after = c.people['p1']!;
        expect(Relationships.hostility(after, 21), 12);
        expect(Relationships.closeness(after, 21), 55);
        expect(after.reunited, isTrue);
        return;
      }
      fail('barışma hiç gelmedi');
    });
  });

  group('motor', () {
    final families = realFamilies();

    LifeEngine engineAt(int age) {
      final engine = LifeEngine(
        deck: EventDeck(const []),
        seed: 5,
        families: families,
        interactions: _book,
      )..startLife();
      while (engine.state.character.age < age) {
        engine.advanceYear();
      }
      return engine;
    }

    Person mother(LifeEngine e) =>
        e.state.character.people.withKin(Kinship.anne).firstOrNull ??
        e.state.character.people.withKin(Kinship.baba).first;

    test('etkileşim vakit harcar, aynı yıl tekrarlanmaz, sonucu durumda', () {
      final engine = engineAt(12);
      final parent = mother(engine);
      final before = engine.state.timeLeft;
      final state = engine.interact(
        InteractionRequest(InteractionKind.dertles, parent.id),
      );
      expect(state.timeLeft, before - 1);
      expect(state.lastInteraction!.personId, parent.id);
      expect(
        state.interactionsUsed,
        contains(Interactions.usedKey(parent.id, InteractionKind.dertles)),
      );
      expect(
        () => engine.interact(
          InteractionRequest(InteractionKind.dertles, parent.id),
        ),
        throwsStateError,
      );
      // Yeni yılda yeniden açılır.
      engine.advanceYear();
      expect(engine.state.interactionsUsed, isEmpty);
    });

    test('bu yıl yapılanlar kayda girip çıkar', () {
      final engine = engineAt(12);
      final parent = mother(engine);
      engine.interact(InteractionRequest(InteractionKind.dertles, parent.id));
      final restored = LifeEngine.restore(
        deck: EventDeck(const []),
        families: families,
        interactions: _book,
        snapshot:
            jsonDecode(jsonEncode(engine.toSnapshot())) as Map<String, dynamic>,
      );
      expect(restored.state.interactionsUsed, engine.state.interactionsUsed);
      expect(restored.state.timeLeft, engine.state.timeLeft);
    });

    test('kart aşamasında etkileşim yok', () {
      final engine = LifeEngine(
        deck: EventDeck([
          testCard('k', minAge: 12, maxAge: 12, mandatory: true, once: true),
        ]),
        seed: 5,
        families: families,
      )..startLife();
      while (engine.state.character.age < 12) {
        engine.advanceYear();
      }
      expect(engine.state.phase, YearPhase.cards);
      final parent = mother(engine);
      expect(
        engine.interactionsWith(parent.id).every((o) => !o.enabled),
        isTrue,
      );
      expect(
        () => engine.interact(
          InteractionRequest(InteractionKind.dertles, parent.id),
        ),
        throwsStateError,
      );
    });
  });

  group('metinler', () {
    test('her sonuç her kişi için 140 karakteri aşmadan kurulur', () {
      final player = testCharacter().copyWith(name: 'Mustafa');
      // En uzun adlar ve her akrabalık.
      final people = [
        for (final kin in [null, ...Kinship.values])
          for (final gender in Gender.values)
            _person(
              name: gender == Gender.erkek ? 'İbrahim' : 'Yasemin',
              gender: gender,
              kin: kin,
              side: Side.anne,
            ),
      ];
      for (final MapEntry(key: key, value: texts) in _book.texts.entries) {
        for (final text in texts) {
          for (final p in people) {
            final out = PersonText.render(text, p, player);
            expect(out.length, lessThanOrEqualTo(140), reason: '$key: $out');
            expect(out, isNot(contains('{')), reason: key);
            expect(
              out[0],
              upperTr(out[0]),
              reason: 'büyük harfle başlar: $out',
            );
          }
        }
      }
    });

    test('özelliğe özel metin öncelikli', () {
      final special = _book.textFor('hediye.iyi', 0, traits: ['cikarci']);
      expect(special, _book.texts['hediye.iyi.cikarci']!.first);
      final plain = _book.textFor('hediye.iyi', 1, traits: ['kiskanc']);
      expect(plain, _book.texts['hediye.iyi']![1]);
    });

    test('akrabalık sözcüğü ve ek', () {
      final player = testCharacter();
      final grandma = _person(
        kin: Kinship.nine,
        side: Side.anne,
        gender: Gender.kadin,
      );
      expect(
        PersonText.render('{kisi.akraba|in} elini öptün.', grandma, player),
        'Anneannenin elini öptün.',
      );
      final uncle = _person(kin: Kinship.dayi);
      expect(
        PersonText.render('{kisi.akraba|e} sordun.', uncle, player),
        'Dayına sordun.',
      );
      final friend = _person(name: 'Ayşe', gender: Gender.kadin);
      expect(
        PersonText.render('{kisi.akraba|e} sordun.', friend, player),
        "Ayşe'ye sordun.",
      );
    });

    test('büyük kardeş abla ya da ağabey, küçüğü kardeş', () {
      Person sibling(Gender gender, int bornAt) => Person.fromJson({
        ..._person(kin: Kinship.kardes, gender: gender).toJson(),
        'bornAt': bornAt,
      });
      expect(PersonText.kinWord(sibling(Gender.kadin, -3)), 'ablan');
      expect(PersonText.kinWord(sibling(Gender.erkek, -3)), 'ağabeyin');
      expect(PersonText.kinWord(sibling(Gender.kadin, 2)), 'kardeşin');
      expect(PersonText.kinWord(sibling(Gender.erkek, 0)), 'kardeşin');
    });

    test('oyuncunun hitabı oyuncunun, kişininki kişinin cinsiyetine göre', () {
      final daughter = testCharacter(gender: Gender.kadin);
      final mother = _person(kin: Kinship.anne, gender: Gender.kadin);
      expect(
        PersonText.render(
          "{kisi.akraba}: 'Gel {oyuncu.hitap.evlat}.'",
          mother,
          daughter,
        ),
        "Annen: 'Gel kızım.'",
      );
      final son = testCharacter(gender: Gender.erkek);
      expect(
        PersonText.render(
          '{oyuncu.hitap.evlat}, {kisi.hitap.abi}',
          mother,
          son,
        ),
        'Oğlum, abla',
      );
      expect(
        EventText.render(
          "Bir amca: 'Gül Sokak nerede {oyuncu.hitap.evlat}?'",
          const {},
          daughter,
        ),
        "Bir amca: 'Gül Sokak nerede kızım?'",
      );
    });

    test('dosya denetimi eksik ve bilinmeyen anahtarları yakalar', () {
      final json = jsonDecode(
        File('assets/interactions.json').readAsStringSync(),
      ) as Map<String, dynamic>;
      (json['texts'] as Map).remove('bulus.iyi');
      (json['texts'] as Map)['bulus.uydurma'] = ['{kisi.ad} geldi.'];
      (json['memories'] as Map).remove('hediye');
      ((json['texts'] as Map)['hediye.iyi'] as List)[0] = "{kisi.ad}'e hediye.";
      ((json['texts'] as Map)['hediye.reddetti'] as List)[0] =
          '{kisi.yas} geldi.';
      final problems = validateInteractions(
        InteractionBook.parse(jsonEncode(json)),
      );
      expect(problems, contains('texts.bulus.iyi: metin yok'));
      expect(problems, contains('texts.bulus.uydurma: bilinmeyen sonuç'));
      expect(problems, contains('memories.hediye: etiket yok'));
      expect(problems.any((p) => p.contains('elle yazılmış ek')), isTrue);
      expect(problems.any((p) => p.contains('{kisi.yas}')), isTrue);
    });
  });
}
