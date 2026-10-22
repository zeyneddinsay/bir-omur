import 'dart:math';

import 'package:bir_omur/engine/engine.dart';
import 'package:bir_omur/models/models.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/people.dart';
import '../helpers/test_cards.dart';
import '../helpers/test_character.dart';

CardRecord _seen(String id, int age) =>
    CardRecord(age: age, cardId: id, side: ChoiceSide.left);

RoleSlot _slot(Map<String, dynamic> json) =>
    testCard('x', roles: {'kisi': json}).roles.single;

void main() {
  group('uygunluk ve tekrar', () {
    test('yaş aralığı dışındaki olay gelmez', () {
      final deck = EventDeck([testCard('a', minAge: 30, maxAge: 40)]);
      final card = deck.cards.single;
      expect(deck.isEligible(card, testCharacter(age: 29)), isFalse);
      expect(deck.isEligible(card, testCharacter(age: 30)), isTrue);
      expect(deck.isEligible(card, testCharacter(age: 40)), isTrue);
      expect(deck.isEligible(card, testCharacter(age: 41)), isFalse);
    });

    test('once: hayatta bir kez', () {
      final card = testCard('a', once: true);
      expect(EventDeck.isRepeatAllowed(card, testCharacter()), isTrue);
      expect(
        EventDeck.isRepeatAllowed(
          card,
          testCharacter(age: 60, history: [_seen('a', 20)]),
        ),
        isFalse,
      );
    });

    test('cooldown dolmadan tekrar gelmez; aynı yıl hiç gelmez', () {
      final card = testCard('a', cooldown: 3);
      bool allowedAt(int age) => EventDeck.isRepeatAllowed(
        card,
        testCharacter(age: age, history: [_seen('a', 20)]),
      );
      expect(allowedAt(20), isFalse);
      expect(allowedAt(22), isFalse);
      expect(allowedAt(23), isTrue);
      final yearly = testCard('b');
      expect(
        EventDeck.isRepeatAllowed(
          yearly,
          testCharacter(age: 21, history: [_seen('b', 20)]),
        ),
        isTrue,
      );
    });

    test('iplik desteden çekilmez', () {
      final deck = EventDeck([testCard('a', chainOnly: true)]);
      expect(deck.isEligible(deck.cards.single, testCharacter()), isFalse);
    });

    test('koşul ve aile profili koşulu', () {
      final deck = EventDeck([
        testCard(
          'a',
          conditions: {
            'flags': ['kiraci'],
            'familyProfile': ['isci', 'yalniz'],
          },
        ),
      ]);
      final card = deck.cards.single;
      final c = testCharacter(flags: {'kiraci'});
      expect(deck.isEligible(card, c), isFalse, reason: 'profil yok');
      expect(
        deck.isEligible(
          card,
          Character.fromJson(c.toJson()..['family'] = 'isci'),
        ),
        isTrue,
      );
      expect(
        deck.isEligible(
          card,
          Character.fromJson(c.toJson()..['family'] = 'memur'),
        ),
        isFalse,
      );
    });

    test('tekrar eden kimlik reddedilir', () {
      expect(
        () => EventDeck([testCard('a'), testCard('a')]),
        throwsArgumentError,
      );
    });
  });

  group('rol eşleştirme', () {
    final c = testCharacter(age: 30);
    bool match(Map<String, dynamic> slot, Person p) =>
        RoleMatcher.matches(_slot(slot), p, c);

    test('akrabalık, rol, eski rol, bağ, cinsiyet, taraf', () {
      final mother = testPerson('p1', kin: Kinship.anne, gender: Gender.kadin);
      expect(
        match({
          'kin': ['anne'],
        }, mother),
        isTrue,
      );
      expect(
        match({
          'kin': ['baba'],
        }, mother),
        isFalse,
      );
      final classmate = testPerson(
        'p2',
        roles: const [PersonRole(RoleKind.sinifArkadasi)],
      );
      final former = testPerson(
        'p3',
        roles: const [PersonRole(RoleKind.sinifArkadasi, active: false)],
      );
      expect(
        match({
          'roles': ['sinifArkadasi'],
        }, classmate),
        isTrue,
      );
      expect(
        match({
          'roles': ['sinifArkadasi'],
        }, former),
        isFalse,
      );
      expect(
        match({
          'formerRoles': ['sinifArkadasi'],
        }, former),
        isTrue,
      );
      expect(
        match({
          'formerRoles': ['sinifArkadasi'],
        }, classmate),
        isFalse,
      );
      expect(
        match({
          'bond': ['arkadas'],
        }, testPerson('p4', bond: Bond.arkadas)),
        isTrue,
      );
      expect(match({'gender': 'kadin'}, mother), isTrue);
      expect(match({'gender': 'erkek'}, mother), isFalse);
      final grandma = testPerson('p5', kin: Kinship.nine, side: Side.anne);
      expect(match({'side': 'anne'}, grandma), isTrue);
      expect(match({'side': 'baba'}, grandma), isFalse);
    });

    test('yaş ve yaş farkı sınırları dahil', () {
      final p = testPerson('p1', age: 32);
      expect(match({'minAge': 32, 'maxAge': 32}, p), isTrue);
      expect(match({'minAge': 33}, p), isFalse);
      expect(match({'minGap': 2, 'maxGap': 2}, p), isTrue);
      expect(match({'maxGap': 1}, p), isFalse);
    });

    test('yakınlık ve husumet sınırları', () {
      final p = testPerson(
        'p1',
        base: 50,
        memories: [testMemory('x', severity: 3, age: 30)],
      );
      expect(match({'minCloseness': 50, 'maxCloseness': 50}, p), isTrue);
      expect(match({'minHostility': 50, 'maxHostility': 50}, p), isTrue);
      expect(match({'minHostility': 51}, p), isFalse);
      expect(match({'maxCloseness': 49}, p), isFalse);
    });

    test('özellik, anı, şehir', () {
      final p = testPerson(
        'p1',
        traits: {Trait.kiskanc},
        memories: [testMemory('rezil_etti')],
        city: 'Rize',
      );
      expect(
        match({
          'traits': ['kiskanc'],
        }, p),
        isTrue,
      );
      expect(
        match({
          'notTraits': ['kiskanc'],
        }, p),
        isFalse,
      );
      expect(match({'memory': 'rezil_etti'}, p), isTrue);
      expect(match({'noMemory': 'rezil_etti'}, p), isFalse);
      expect(match({'memory': 'baska'}, p), isFalse);
      expect(match({'sameCity': false}, p), isTrue);
      expect(match({'sameCity': true}, p), isFalse);
    });

    test('vefat etmiş, arşivdeki ve doğmamış kişi eşleşmez', () {
      expect(match({}, testPerson('p1').copyWith(diedAt: 20)), isFalse);
      expect(match({}, testPerson('p1', archived: true)), isFalse);
      expect(match({}, testPerson('p1', age: -1)), isFalse);
    });

    test('vefat yuvası: son bir yılın ölüsüyle, her vefat için bir kez', () {
      final slot = {'deceased': true};
      expect(_slot(slot).offstage, isTrue, reason: 'her zaman sahne dışı');
      expect(match(slot, testPerson('p1')), isFalse, reason: 'yaşıyor');
      expect(match(slot, testPerson('p1').copyWith(diedAt: 30)), isTrue);
      expect(match(slot, testPerson('p1').copyWith(diedAt: 29)), isTrue);
      expect(match(slot, testPerson('p1').copyWith(diedAt: 28)), isFalse);
      expect(
        match(slot, testPerson('p1', archived: true).copyWith(diedAt: 30)),
        isTrue,
        reason: 'arşivdeki akraba da anılır',
      );
      expect(
        match(slot, testPerson('p1', lastEventAt: 30).copyWith(diedAt: 29)),
        isFalse,
        reason: 'vefatından sonra zaten olaya çıktı',
      );
      expect(
        match(slot, testPerson('p1', lastEventAt: 28).copyWith(diedAt: 29)),
        isTrue,
      );
    });

    test('vefat yuvası dinlenme kuralına takılmaz', () {
      final card = testCard(
        'cenaze',
        roles: {
          'merhum': {'deceased': true},
        },
      );
      final c = withPeople(testCharacter(age: 30), [
        testPerson('x', lastEventAt: 28).copyWith(diedAt: 29),
        testPerson('x'),
      ]);
      expect(EventDeck.bind(card, c, Random(1)), {'merhum': 'p1'});
    });

    test('dinlenme: olaydan sonra 2 yıl, aile çekirdeği hariç', () {
      final friend = testPerson('p1', lastEventAt: 28);
      expect(RoleMatcher.isRested(friend, 30), isFalse);
      expect(RoleMatcher.isRested(friend, 31), isTrue);
      final mother = testPerson('p2', kin: Kinship.anne, lastEventAt: 30);
      expect(RoleMatcher.isRested(mother, 30), isTrue);
    });
  });

  group('bağlama', () {
    final card = testCard(
      'a',
      roles: {
        'arkadas': {
          'roles': ['sinifArkadasi'],
        },
        'anne': {
          'kin': ['anne'],
        },
      },
    );

    test('her yuvaya ayrı ve uygun bir kişi', () {
      final c = withPeople(testCharacter(age: 12), [
        testPerson('x', kin: Kinship.anne, gender: Gender.kadin),
        testPerson(
          'x',
          age: 12,
          playerAge: 12,
          roles: const [PersonRole(RoleKind.sinifArkadasi)],
        ),
      ]);
      expect(EventDeck.bind(card, c, Random(1)), {
        'arkadas': 'p2',
        'anne': 'p1',
      });
    });

    test('uygun kişi yoksa olay bağlanamaz', () {
      final c = withPeople(testCharacter(age: 12), [
        testPerson('x', kin: Kinship.anne),
      ]);
      expect(EventDeck.bind(card, c, Random(1)), isNull);
    });

    test('meşgul ve dinlenmedeki kişi seçilmez; sabit kişi korunur', () {
      final c = withPeople(testCharacter(age: 12), [
        testPerson('x', kin: Kinship.anne),
        testPerson(
          'x',
          age: 12,
          playerAge: 12,
          roles: const [PersonRole(RoleKind.sinifArkadasi)],
        ),
        testPerson(
          'x',
          age: 12,
          playerAge: 12,
          roles: const [PersonRole(RoleKind.sinifArkadasi)],
          lastEventAt: 11,
        ),
      ]);
      expect(EventDeck.bind(card, c, Random(1), busy: {'p2'}), isNull);
      expect(EventDeck.bind(card, c, Random(1), fixed: {'arkadas': 'p3'}), {
        'arkadas': 'p3',
        'anne': 'p1',
      });
      expect(
        EventDeck.bind(card, c, Random(1), fixed: {'arkadas': 'p1'}),
        isNull,
        reason: 'sabit kişi yuvaya uymuyor',
      );
    });

    test('ucu yüksek ilişki iki kat seçilir', () {
      final single = testCard('b', roles: {'kisi': <String, dynamic>{}});
      final c = withPeople(testCharacter(age: 30), [
        testPerson('x', base: 20),
        testPerson('x', base: 80),
      ]);
      final counts = <String, int>{};
      for (var s = 0; s < 3000; s++) {
        final id = EventDeck.bind(single, c, Random(s))!['kisi']!;
        counts.update(id, (n) => n + 1, ifAbsent: () => 1);
      }
      expect(counts['p2']! / counts['p1']!, closeTo(2, 0.25));
    });
  });

  group('çekiliş', () {
    test('istenen sayıda, farklı temalı olay', () {
      final deck = EventDeck([
        for (var i = 0; i < 16; i++)
          testCard('k$i', theme: ['aile', 'okul', 'para', 'genel'][i % 4]),
      ]);
      for (var s = 0; s < 50; s++) {
        final drawn = deck.draw(testCharacter(), Random(s), count: 3);
        expect(drawn, hasLength(3));
        expect(drawn.map((e) => e.card.theme).toSet(), hasLength(3));
      }
    });

    test('aynı temadan ikincisi gelmez, verilen tema hiç gelmez', () {
      final deck = EventDeck([
        testCard('a', theme: 'okul'),
        testCard('b', theme: 'okul'),
        testCard('c', theme: 'aile'),
      ]);
      final drawn = deck.draw(testCharacter(), Random(1), count: 3);
      expect(drawn, hasLength(2));
      final noSchool = deck.draw(
        testCharacter(),
        Random(1),
        count: 3,
        themes: {EventTheme.okul},
      );
      expect(noSchool.map((e) => e.card.id), ['c']);
    });

    test('tesadüf yılda en fazla bir', () {
      final deck = EventDeck([
        testCard('t1', type: 'tesaduf', theme: 'genel'),
        testCard('t2', type: 'tesaduf', theme: 'mahalle'),
      ]);
      for (var s = 0; s < 30; s++) {
        expect(deck.draw(testCharacter(), Random(s), count: 2), hasLength(1));
      }
    });

    test('kişisi bulunamayan olay atlanır, yerine başkası gelir', () {
      final deck = EventDeck([
        testCard(
          'kisili',
          theme: 'aile',
          roles: {
            'es': {
              'kin': ['es'],
            },
          },
        ),
        testCard('kisisiz', theme: 'okul'),
      ]);
      final ids = deck
          .draw(testCharacter(), Random(1), count: 2)
          .map((e) => e.card.id);
      expect(ids, ['kisisiz']);
    });

    test('aynı kişi aynı yıl iki olaya çıkmaz', () {
      final deck = EventDeck([
        testCard('a', theme: 'aile', roles: {'k': <String, dynamic>{}}),
        testCard('b', theme: 'okul', roles: {'k': <String, dynamic>{}}),
      ]);
      final c = withPeople(testCharacter(), [testPerson('x')]);
      expect(deck.draw(c, Random(1), count: 2), hasLength(1));
      expect(deck.draw(c, Random(1), count: 2, busy: {'p1'}), isEmpty);
    });

    test('hariç tutulan olay ve dönemeç çekilişe girmez', () {
      final deck = EventDeck([
        testCard('a', theme: 'aile'),
        testCard('b', theme: 'okul'),
        testCard('z', mandatory: true, theme: 'para'),
      ]);
      final ids = deck
          .draw(testCharacter(), Random(1), count: 3, exclude: {'a'})
          .map((e) => e.card.id);
      expect(ids, ['b']);
    });

    test('ağırlık: sıradan olay efsaneden çok daha sık', () {
      final deck = EventDeck([
        testCard('siradan', theme: 'aile'),
        testCard('efsane', rarity: 'efsane', theme: 'okul'),
      ]);
      final counts = <String, int>{};
      for (var seed = 0; seed < 1100; seed++) {
        final id = deck
            .draw(testCharacter(), Random(seed), count: 1)
            .single
            .card
            .id;
        counts[id] = (counts[id] ?? 0) + 1;
      }
      expect(counts['siradan']!, greaterThan(counts['efsane']! * 6));
      expect(counts['efsane']!, greaterThan(40));
    });
  });

  group('dönemeçler', () {
    test('şartı sağlanan her dönemeç kimlik sırasıyla gelir', () {
      final deck = EventDeck([
        testCard('z2', mandatory: true, once: true),
        testCard('z1', mandatory: true, once: true),
        testCard('a'),
        testCard('z3', mandatory: true, once: true, minAge: 90),
      ]);
      expect(
        deck.milestones(testCharacter(), Random(1)).map((e) => e.card.id),
        ['z1', 'z2'],
      );
    });
  });

  group('iplik sırası', () {
    test('zamanı gelenleri sırasıyla, kişileriyle çıkarır', () {
      final queue = const ScheduleQueue()
          .add('b', atAge: 26, people: {'kerem': 'p3'})
          .add('a', atAge: 24)
          .add('c', atAge: 30);
      final (due, rest) = queue.takeDue(26);
      expect(due.map((e) => e.cardId), ['b', 'a']);
      expect(due.first.people, {'kerem': 'p3'});
      expect(rest.entries.map((e) => e.cardId), ['c']);
      expect(queue.entries, hasLength(3), reason: 'asıl sıra değişmez');
    });

    test('JSON gidip gelir', () {
      final queue = const ScheduleQueue()
          .add('b', atAge: 26, people: {'kerem': 'p3'})
          .add('a', atAge: 24);
      final round = ScheduleQueue.fromJson(queue.toJson());
      expect(round.toJson(), queue.toJson());
    });
  });
}
