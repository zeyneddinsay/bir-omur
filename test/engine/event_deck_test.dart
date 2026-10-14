import 'dart:math';

import 'package:bir_omur/engine/engine.dart';
import 'package:bir_omur/models/models.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_cards.dart';
import '../helpers/test_character.dart';

CardRecord _seen(String id, int age) =>
    CardRecord(age: age, cardId: id, side: ChoiceSide.left);

void main() {
  group('EventDeck uygunluk', () {
    test('yaş aralığı dışındaki kart gelmez', () {
      final deck = EventDeck([testCard('a', minAge: 30, maxAge: 40)]);
      expect(
        deck.isEligible(deck.cards.single, testCharacter(age: 29)),
        isFalse,
      );
      expect(
        deck.isEligible(deck.cards.single, testCharacter(age: 30)),
        isTrue,
      );
      expect(
        deck.isEligible(deck.cards.single, testCharacter(age: 41)),
        isFalse,
      );
    });

    test('once kartı hayatta bir kez gelir', () {
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

    test('cooldown dolmadan kart tekrar gelmez', () {
      final card = testCard('a', cooldown: 3);
      bool allowedAt(int age) => EventDeck.isRepeatAllowed(
        card,
        testCharacter(age: age, history: [_seen('a', 20)]),
      );
      expect(allowedAt(22), isFalse);
      expect(allowedAt(23), isTrue);
    });

    test('cooldown 0 olsa da aynı yıl iki kez gelmez', () {
      final card = testCard('a');
      expect(
        EventDeck.isRepeatAllowed(
          card,
          testCharacter(age: 20, history: [_seen('a', 20)]),
        ),
        isFalse,
      );
      expect(
        EventDeck.isRepeatAllowed(
          card,
          testCharacter(age: 21, history: [_seen('a', 20)]),
        ),
        isTrue,
      );
    });

    test('zincir kartı desteden çekilmez', () {
      final deck = EventDeck([testCard('a', chainOnly: true)]);
      expect(deck.isEligible(deck.cards.single, testCharacter()), isFalse);
    });

    test('koşulu sağlanmayan kart gelmez', () {
      final deck = EventDeck([
        testCard(
          'a',
          conditions: {
            'flags': ['kiraci'],
          },
        ),
      ]);
      expect(deck.isEligible(deck.cards.single, testCharacter()), isFalse);
      expect(
        deck.isEligible(deck.cards.single, testCharacter(flags: {'kiraci'})),
        isTrue,
      );
    });

    test('tekrar eden kimlik reddedilir', () {
      expect(
        () => EventDeck([testCard('a'), testCard('a')]),
        throwsArgumentError,
      );
    });
  });

  group('EventDeck.draw', () {
    test('istenen sayıda, birbirinden farklı kart çeker', () {
      final deck = EventDeck([for (var i = 0; i < 10; i++) testCard('k$i')]);
      final drawn = deck.draw(testCharacter(), Random(3), count: 3);
      expect(drawn, hasLength(3));
      expect(drawn.map((c) => c.id).toSet(), hasLength(3));
    });

    test('uygun kart azsa olanı verir', () {
      final deck = EventDeck([
        testCard('a'),
        testCard('b', minAge: 90, maxAge: 99),
      ]);
      expect(deck.draw(testCharacter(), Random(1), count: 3).map((c) => c.id), [
        'a',
      ]);
    });

    test('zorunlu kart her zaman gelir ve sınırı aşabilir', () {
      final deck = EventDeck([
        testCard('z1', mandatory: true),
        testCard('z2', mandatory: true),
        testCard('a'),
      ]);
      for (var seed = 0; seed < 20; seed++) {
        final ids = deck
            .draw(testCharacter(), Random(seed), count: 1)
            .map((c) => c.id);
        expect(ids, ['z1', 'z2']);
      }
    });

    test('hariç tutulan kart çekilmez', () {
      final deck = EventDeck([testCard('a'), testCard('b')]);
      final ids = deck
          .draw(testCharacter(), Random(1), count: 2, exclude: {'a'})
          .map((c) => c.id);
      expect(ids, ['b']);
    });

    test('ağırlıklar: sıradan kart efsaneden çok daha sık gelir', () {
      final deck = EventDeck([
        testCard('siradan'),
        testCard('efsane', rarity: 'efsane'),
      ]);
      final counts = <String, int>{};
      for (var seed = 0; seed < 1100; seed++) {
        final id = deck.draw(testCharacter(), Random(seed), count: 1).single.id;
        counts[id] = (counts[id] ?? 0) + 1;
      }
      // Beklenen oran 10'a 1.
      expect(counts['siradan']!, greaterThan(counts['efsane']! * 6));
      expect(counts['efsane']!, greaterThan(40));
    });
  });

  group('ScheduleQueue', () {
    test('zamanı gelen ve kaçırılan kartları sırasıyla çıkarır', () {
      final queue = const ScheduleQueue()
          .add('b', atAge: 26)
          .add('a', atAge: 24)
          .add('c', atAge: 30);
      final (due, rest) = queue.takeDue(26);
      expect(due, ['b', 'a']);
      expect(rest.entries.map((e) => e.cardId), ['c']);
      expect(queue.entries, hasLength(3), reason: 'asıl sıra değişmez');
    });
  });
}
