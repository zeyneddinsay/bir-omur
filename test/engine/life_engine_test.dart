import 'package:bir_omur/engine/engine.dart';
import 'package:bir_omur/models/models.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_cards.dart';

void main() {
  group('LifeEngine', () {
    test('hayat 0 yaşında başlar ve ilk kart gelir', () {
      final engine = LifeEngine(
        deck: EventDeck([testCard('a', maxAge: 6)]),
        seed: 1,
      );
      final state = engine.startLife(name: 'Elif', gender: Gender.kadin);
      expect(state.character.age, 0);
      expect(state.character.name, 'Elif');
      expect(state.character.gender, Gender.kadin);
      expect(state.phase, YearPhase.cards);
      expect(state.currentCard!.id, 'a');
    });

    test('isim boşsa rastgele isim verilir', () {
      final engine = LifeEngine(deck: EventDeck([]), seed: 1);
      expect(engine.startLife(name: '  ').character.name, isNotEmpty);
    });

    test('kart yoksa doğrudan aksiyon aşamasına geçilir', () {
      final engine = LifeEngine(deck: EventDeck([]), seed: 1);
      final state = engine.startLife();
      expect(state.phase, YearPhase.actions);
      expect(state.actionsLeft, 2);
    });

    test('kartlar bitince aksiyonlar, sonra yaşlanma', () {
      final engine = LifeEngine(
        deck: EventDeck([
          testCard(
            'a',
            maxAge: 0,
            left: {
              'label': 'Sol',
              'effects': {
                'addFlags': ['secti'],
              },
            },
          ),
        ]),
        seed: 1,
      );
      engine.startLife();
      expect(() => engine.advanceYear(), throwsStateError);

      var state = engine.choose(ChoiceSide.left);
      expect(state.phase, YearPhase.actions);
      expect(state.character.hasFlag('secti'), isTrue);

      state = engine.doAction('oyun_oyna');
      expect(state.actionsLeft, 1);
      expect(
        () => engine.doAction('oyun_oyna'),
        throwsStateError,
        reason: 'yılda bir kez',
      );

      state = engine.advanceYear();
      expect(state.character.age, 1);
    });

    test('yukarı seçeneği olmayan kartta yukarı kaydırılamaz', () {
      final engine = LifeEngine(
        deck: EventDeck([testCard('a', maxAge: 6)]),
        seed: 1,
      );
      engine.startLife();
      expect(() => engine.choose(ChoiceSide.up), throwsStateError);
    });

    test('para yetmeyen ve yaşı tutmayan aksiyon yapılamaz', () {
      final engine = LifeEngine(deck: EventDeck([]), seed: 1);
      engine.startLife();
      final enabled = {
        for (final (action, ok) in engine.availableActions()) action.id: ok,
      };
      expect(
        enabled.containsKey('tatil'),
        isFalse,
        reason: 'bebek tatile gitmez',
      );
      expect(() => engine.doAction('tatil'), throwsStateError);
    });

    test('zincir kartı planlanan yılda gelir', () {
      final engine = LifeEngine(
        deck: EventDeck([
          testCard(
            'borc_ver',
            maxAge: 0,
            left: {
              'label': 'Ver',
              'effects': {
                'schedule': {'event': 'borc_geri', 'inYears': 2},
              },
            },
          ),
          testCard('borc_geri', chainOnly: true),
        ]),
        seed: 1,
      );
      engine.startLife();
      var state = engine.choose(ChoiceSide.left);
      expect(state.queue.entries.single.atAge, 2);

      state = engine.advanceYear();
      expect(state.character.age, 1);
      expect(state.phase, YearPhase.actions, reason: '1 yaşında kart yok');

      state = engine.advanceYear();
      expect(state.character.age, 2);
      expect(state.currentCard!.id, 'borc_geri');
      expect(state.queue.isEmpty, isTrue);
    });

    test('sağlık 0 olursa yıl sonunda ölünür ve özet çıkar', () {
      final engine = LifeEngine(
        deck: EventDeck([
          testCard(
            'kaza',
            maxAge: 0,
            left: {
              'label': 'Sol',
              'effects': {'health': -100},
            },
          ),
        ]),
        seed: 1,
      );
      engine.startLife();
      engine.choose(ChoiceSide.left);
      final state = engine.advanceYear();
      expect(state.phase, YearPhase.dead);
      expect(state.character.isAlive, isFalse);
      expect(state.summary!.cause, DeathCause.health);
      expect(state.summary!.deathAge, 0);
      expect(() => engine.advanceYear(), throwsStateError);
    });
  });
}
