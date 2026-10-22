import 'dart:convert';

import 'package:bir_omur/engine/engine.dart';
import 'package:bir_omur/models/models.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/families.dart';
import '../helpers/test_cards.dart';
import '../helpers/test_character.dart';

/// Kartsız bir hayatı sonuna kadar oynatır; her yılın durumunu döndürür.
List<LifeState> playLife(int seed, FamilyBook families) {
  final engine = LifeEngine(
    deck: EventDeck(const []),
    seed: seed,
    families: families,
  );
  final states = [engine.startLife()];
  while (!engine.state.isOver) {
    states.add(engine.advanceYear());
  }
  return states;
}

void main() {
  final families = realFamilies();
  const lives = 200;
  final allLives = [for (var s = 0; s < lives; s++) playLife(s, families)];

  Iterable<(LifeState prev, LifeState next)> yearPairs() sync* {
    for (final life in allLives) {
      for (var i = 1; i < life.length; i++) {
        if (!life[i].isOver) yield (life[i - 1], life[i]);
      }
    }
  }

  test('aynı tohum aynı çevreyi üretir', () {
    final a = playLife(3, families).last.character.people.toJson();
    final b = playLife(3, families).last.character.people.toJson();
    expect(jsonEncode(a), jsonEncode(b));
  });

  test('küçük kardeş doğduğu yıl haber olur, öncesinde aktif değildir', () {
    var births = 0;
    for (final (prev, next) in yearPairs()) {
      final age = next.character.age;
      final people = next.character.people;
      for (final p in people.withKin(Kinship.kardes)) {
        if (p.bornAt > age) {
          expect(people.active(age), isNot(contains(p)));
        }
        final reported = next.news.any(
          (n) => n.kind == NewsKind.kardesDogdu && n.personId == p.id,
        );
        expect(reported, p.bornAt == age, reason: 'yaş $age, ${p.id}');
        if (reported) births++;
      }
      expect(prev.character.age, age - 1);
    }
    expect(births, greaterThan(20), reason: 'hiç küçük kardeş doğmadı');
  });

  test('aynı evde yaşanırken anne, baba ve kardeşle ilişki soğumaz', () {
    var checked = 0;
    for (final (_, next) in yearPairs()) {
      final c = next.character;
      for (final p in c.people.active(c.age)) {
        if (PeopleTick.livesTogether(c, p)) {
          checked++;
          expect(p.lastContactAt, c.age);
          expect(Relationships.coolingOf(p, c.age), 0);
        }
      }
    }
    expect(checked, greaterThan(1000));
  });

  test('çocukken anne ve baba aynı evde', () {
    for (final (_, next) in yearPairs()) {
      final c = next.character;
      if (c.age >= 18) continue;
      for (final p in c.people.active(c.age)) {
        if (p.kin == Kinship.anne || p.kin == Kinship.baba) {
          expect(PeopleTick.livesTogether(c, p), isTrue, reason: '${c.age}');
        }
      }
    }
  });

  test('vefat kuralları', () {
    var deaths = 0;
    for (final (prev, next) in yearPairs()) {
      final age = next.character.age;
      for (final p in next.character.people.all) {
        final before = prev.character.people[p.id];
        if (before != null && !before.isAlive) {
          expect(p.diedAt, before.diedAt, reason: 'ölen geri gelmez');
        }
        if (p.diedAt != age) continue;
        deaths++;
        expect(p.ageAt(age), greaterThanOrEqualTo(PeopleTick.deathMinAge));
        if (p.kin == Kinship.anne || p.kin == Kinship.baba) {
          expect(age, greaterThanOrEqualTo(PeopleTick.parentsSafeUntil));
        }
        expect(
          next.news,
          contains(PersonNews(NewsKind.vefat, p.id)),
          reason: 'vefat haberi',
        );
      }
    }
    expect(deaths, greaterThan(100));
  });

  test('okul kademelerinde sınıf kurulur', () {
    for (final life in allLives) {
      for (final state in life) {
        final age = state.character.age;
        final stage = PeopleTick.schoolStarts[age];
        if (stage == null || state.isOver) continue;
        expect(state.news.where((n) => n.kind == NewsKind.yeniSinif), [
          isA<PersonNews>().having((n) => n.detail, 'evre', stage),
        ]);
        final active = state.character.people.active(age).toList();
        final classmates = active
            .where((p) => p.hasRole(RoleKind.sinifArkadasi))
            .toList();
        expect(classmates, hasLength(PeopleTick.classmatesPerClass));
        expect(
          active.where((p) => p.hasRole(RoleKind.siraArkadasi)),
          hasLength(1),
        );
        expect(active.where((p) => p.hasRole(RoleKind.ogretmen)), hasLength(1));
        for (final c in classmates) {
          expect(c.ageAt(age) - age, inInclusiveRange(-1, 1));
          expect(c.origin, Origin.okul);
          expect(c.city, state.character.hometown);
        }
        final teacher = active.singleWhere((p) => p.hasRole(RoleKind.ogretmen));
        expect(teacher.occupation, 'ogretmen');
        expect(teacher.ageAt(age), inInclusiveRange(26, 60));
      }
    }
  });

  test('önceki sınıftan kalanlar ve biten roller', () {
    var stayers = 0;
    for (final life in allLives) {
      for (final state in life) {
        final age = state.character.age;
        if (age != 11 && age != 15) continue;
        if (state.isOver) continue;
        final people = state.character.people.all;
        stayers += people
            .where((p) => p.hasRole(RoleKind.sinifArkadasi) && p.metAt < age)
            .length;
        for (final p in people.where((p) => p.metAt < age)) {
          expect(p.hasRole(RoleKind.ogretmen), isFalse);
          expect(p.hasRole(RoleKind.siraArkadasi), isFalse);
        }
      }
    }
    // 200 hayat × 2 geçiş × 5 kişi × %30 ≈ 600.
    expect(stayers, inInclusiveRange(350, 850));
  });

  test('aktif kişi sınırı aşılmaz; çekirdek aile arşive düşmez', () {
    for (final (_, next) in yearPairs()) {
      final age = next.character.age;
      final active = next.character.people.active(age).toList();
      final nonCore = active.where((p) => !PeopleTick.coreKin.contains(p.kin));
      expect(
        active.length <= PeopleTick.maxActive || nonCore.isEmpty,
        isTrue,
        reason: 'yaş $age: ${active.length} aktif',
      );
      for (final p in next.character.people.all.where((p) => p.archived)) {
        expect(PeopleTick.coreKin, isNot(contains(p.kin)));
      }
    }
  });

  test('kişinin kendi yılı çubukları değiştirmez', () {
    for (final (prev, next) in yearPairs()) {
      for (final p in next.character.people.all) {
        final before = prev.character.people[p.id];
        if (before == null) continue;
        expect(p.memories, before.memories);
        expect(p.base, before.base);
        expect(p.traits, before.traits);
        if (!PeopleTick.livesTogether(prev.character, before) &&
            !PeopleTick.livesTogether(next.character, p)) {
          expect(p.lastContactAt, before.lastContactAt);
        }
      }
    }
  });

  test('emeklilik, iş ve haberler', () {
    for (final (_, next) in yearPairs()) {
      final age = next.character.age;
      final people = next.character.people;
      for (final p in people.active(age)) {
        if (p.ageAt(age) >= 65 &&
            p.occupation != null &&
            p.occupation != 'ev_hanimi') {
          expect(p.occupation, 'emekli', reason: '${p.id} ${p.ageAt(age)}');
        }
        if (p.occupation == 'ev_hanimi') expect(p.gender, Gender.kadin);
        if (p.occupation != null) {
          expect(families.occupations, contains(p.occupation));
        }
      }
      for (final n in next.news) {
        expect(people[n.personId], isNotNull);
      }
    }
  });

  test('arşiv önce rolü bitmiş ve en uzun süredir görüşülmeyenleri alır', () {
    var c = testCharacter(age: 30);
    var book = PeopleBook.empty();
    Person make(String id, {int lastContact = 0, bool role = false}) => Person(
      id: id,
      name: 'Ali',
      surname: 'Kaya',
      gender: Gender.erkek,
      bornAt: 0,
      city: 'Samsun',
      origin: Origin.okul,
      metAt: 0,
      base: 10,
      portraitSeed: 1,
      roles: [if (role) const PersonRole(RoleKind.isArkadasi)],
      lastContactAt: lastContact,
    );
    // 43 kişi: 3'ü fazla. p1 rolü sürüyor ama en eski; p2 ve p3 rolsüz ve
    // en eski. Kalanlar yeni.
    final (b1, _) = book.add((id) => make(id, lastContact: 1, role: true));
    final (b2, _) = b1.add((id) => make(id, lastContact: 2));
    final (b3, _) = b2.add((id) => make(id, lastContact: 3));
    book = b3;
    for (var i = 0; i < 40; i++) {
      final (b, _) = book.add((id) => make(id, lastContact: 20 + i));
      book = b;
    }
    c = c.copyWith(people: book);
    final (after, _) = PeopleTick(
      SeededRandom(1),
      families,
      cities: BirthGenerator.hometowns,
    ).apply(c);
    final archived = after.people.all
        .where((p) => p.archived)
        .map((p) => p.id)
        .toList();
    expect(archived, ['p2', 'p3', 'p4']);
    expect(after.people.active(30).length, PeopleTick.maxActive);
  });

  test('haberler kart seçimi ve aksiyon boyunca korunur', () {
    final engine = LifeEngine(
      deck: EventDeck([
        for (var age = 0; age <= 30; age++)
          testCard(
            'kart_$age',
            minAge: age,
            maxAge: age,
            mandatory: true,
            once: true,
          ),
      ]),
      seed: 4,
      families: families,
    );
    engine.startLife();
    var checked = 0;
    while (engine.state.character.age < 30) {
      while (engine.state.phase == YearPhase.cards) {
        final before = engine.state.news;
        engine.choose(ChoiceSide.left);
        expect(engine.state.news, before);
      }
      final before = engine.state.news;
      final requests = engine.possibleInteractions();
      if (requests.isNotEmpty) {
        engine.interact(requests.first);
        expect(engine.state.news, before);
      }
      if (before.isNotEmpty) checked++;
      engine.advanceYear();
    }
    expect(checked, greaterThan(3));
  });

  test('haberler kayda girip çıkar', () {
    final engine = LifeEngine(
      deck: EventDeck(const []),
      seed: 9,
      families: families,
    );
    engine.startLife();
    LifeState state = engine.state;
    while (state.news.isEmpty) {
      state = engine.advanceYear();
    }
    final restored = LifeEngine.restore(
      deck: EventDeck(const []),
      families: families,
      snapshot:
          jsonDecode(jsonEncode(engine.toSnapshot())) as Map<String, dynamic>,
    );
    expect(restored.state.news, state.news);
    expect(
      jsonEncode(restored.advanceYear().character.people.toJson()),
      jsonEncode(engine.advanceYear().character.people.toJson()),
    );
  });
}
