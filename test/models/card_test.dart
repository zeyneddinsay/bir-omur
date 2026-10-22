import 'dart:convert';

import 'package:bir_omur/models/models.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_character.dart';

/// assets/cards/README.md içindeki örnek olay, birebir.
const _readmeSample = '''
{
  "id": "teneffus_not",
  "type": "kisi",
  "theme": "okul",
  "minAge": 11,
  "maxAge": 14,
  "repeat": "once",
  "roles": {
    "kerem": { "roles": ["sinifArkadasi"], "minGap": -1, "maxGap": 1 }
  },
  "speaker": "kerem",
  "text": "Teneffüs. {kerem.ad}, sıra arkadaşına yazdığın notu buldu ve sınıfa okuyor.",
  "left": {
    "label": "Ver onu bana!",
    "effects": {
      "reputation": 3,
      "people": {
        "kerem": {
          "memory": {
            "kind": "rezil_etti",
            "label": "Sınıfın ortasında üstüme yürüdü",
            "tone": "olumsuz",
            "severity": 2
          }
        }
      }
    }
  },
  "right": { "label": "Gülüp geçerim", "effects": { "happiness": -2 } }
}
''';

Map<String, dynamic> _sample() =>
    jsonDecode(_readmeSample) as Map<String, dynamic>;

Map<String, dynamic> _minimal() => {
  'id': 'test_01',
  'type': 'genel',
  'theme': 'genel',
  'minAge': 0,
  'maxAge': 6,
  'repeat': 'once',
  'text': 'Metin',
  'left': {'label': 'Sol'},
  'right': {'label': 'Sağ'},
};

void expectFormatError(Map<String, dynamic> json, String path) {
  expect(
    () => EventCard.fromJson(json),
    throwsA(
      isA<CardFormatException>().having((e) => e.path, 'yol', startsWith(path)),
    ),
  );
}

void main() {
  group('EventCard.fromJson', () {
    test('README örneğini okur', () {
      final card = EventCard.fromJson(_sample());
      expect(card.type, EventType.kisi);
      expect(card.theme, EventTheme.okul);
      expect(card.once, isTrue);
      expect(card.speaker, 'kerem');
      final kerem = card.role('kerem')!;
      expect(kerem.roles, {RoleKind.sinifArkadasi});
      expect(kerem.minGap, -1);
      final memory = card.left.effects.people['kerem']!.memory!;
      expect(memory.kind, 'rezil_etti');
      expect(memory.tone, MemoryTone.olumsuz);
      expect(memory.severity, 2);
      expect(memory.owner, MemoryOwner.ikisi);
      expect(card.left.effects.stats[StatKind.reputation], 3);
    });

    test('en küçük geçerli olay', () {
      final card = EventCard.fromJson(_minimal());
      expect(card.roles, isEmpty);
      expect(card.rarity, Rarity.siradan);
      expect(card.conditions.flags, isEmpty);
    });

    test('tür, tema ve tekrar zorunlu', () {
      for (final key in ['type', 'theme', 'repeat', 'minAge', 'text', 'left']) {
        expectFormatError(_minimal()..remove(key), 'test_01.$key');
      }
    });

    test('bilinmeyen alan, tür, tema reddedilir', () {
      expectFormatError(_minimal()..['stage'] = 'bebek', 'test_01.stage');
      expectFormatError(_minimal()..['type'] = 'masal', 'test_01.type');
      expectFormatError(_minimal()..['theme'] = 'uzay', 'test_01.theme');
    });

    test('tekrar: once ya da cooldown', () {
      final every = EventCard.fromJson(
        _minimal()..['repeat'] = {'cooldown': 3},
      );
      expect(every.once, isFalse);
      expect(every.cooldown, 3);
      expectFormatError(_minimal()..['repeat'] = 'sik', 'test_01.repeat');
      expectFormatError(
        _minimal()..['repeat'] = {'cooldown': 0},
        'test_01.repeat',
      );
    });

    test('tür türetilmiş özellikler', () {
      final milestone = EventCard.fromJson(_minimal()..['type'] = 'donemec');
      expect(milestone.mandatory, isTrue);
      final thread = EventCard.fromJson(_minimal()..['type'] = 'iplik');
      expect(thread.chainOnly, isTrue);
      expect(EventTheme.fromId('is'), EventTheme.isHayati);
    });

    test('rol yuvası adı ve oyuncu ayrılmış adı', () {
      expectFormatError(
        _minimal()..['roles'] = {'Kerem': <String, dynamic>{}},
        'test_01.roles.Kerem',
      );
      expectFormatError(
        _minimal()..['roles'] = {'oyuncu': <String, dynamic>{}},
        'test_01.roles.oyuncu',
      );
    });

    test('rol yuvası alanları', () {
      final card = EventCard.fromJson(
        _minimal()
          ..['roles'] = {
            'nine': {
              'kin': ['nine'],
              'side': 'anne',
              'gender': 'kadin',
              'minAge': 60,
              'minCloseness': 50,
              'traits': ['vefali'],
              'noMemory': 'kustu',
              'sameCity': true,
              'offstage': true,
            },
          },
      );
      final nine = card.role('nine')!;
      expect(nine.kin, {Kinship.nine});
      expect(nine.side, Side.anne);
      expect(nine.gender, Gender.kadin);
      expect(nine.traits, {Trait.vefali});
      expect(nine.sameCity, isTrue);
      expect(nine.offstage, isTrue);
    });

    test('bozuk rol yuvası reddedilir', () {
      Map<String, dynamic> withRole(Map<String, dynamic> role) =>
          _minimal()..['roles'] = {'k': role};
      expectFormatError(withRole({'renk': 'mavi'}), 'test_01.roles.k.renk');
      expectFormatError(
        withRole({
          'kin': ['komsu'],
        }),
        'test_01.roles.k.kin',
      );
      expectFormatError(
        withRole({'minCloseness': 120}),
        'test_01.roles.k.minCloseness',
      );
      expectFormatError(
        withRole({'minAge': 40, 'maxAge': 30}),
        'test_01.roles.k',
      );
    });

    test('konuşmacı bir rol yuvası olmalı', () {
      expectFormatError(_minimal()..['speaker'] = 'anne', 'test_01.speaker');
    });

    test('kişi etkisi', () {
      Map<String, dynamic> withPeople(Map<String, dynamic> people) => _minimal()
        ..['roles'] = {'k': <String, dynamic>{}}
        ..['left'] = {
          'label': 'Sol',
          'effects': {'people': people},
        };
      final card = EventCard.fromJson(
        withPeople({
          'k': {'heal': '*', 'bond': 'arkadas', 'archive': true},
        }),
      );
      final effect = card.left.effects.people['k']!;
      expect(effect.heal, PersonEffect.healHeaviest);
      expect(effect.bond, Bond.arkadas);
      expect(effect.archive, isTrue);
      expectFormatError(
        withPeople({'k': <String, dynamic>{}}),
        'test_01.left.effects.people.k',
      );
      expectFormatError(
        withPeople({
          'k': {
            'memory': {
              'kind': 'a',
              'label': 'b',
              'tone': 'olumlu',
              'severity': 4,
            },
          },
        }),
        'test_01.left.effects.people.k.memory.severity',
      );
      expectFormatError(
        withPeople({
          'k': {
            'memory': {'kind': 'a', 'label': 'b', 'tone': 'iyi', 'severity': 1},
          },
        }),
        'test_01.left.effects.people.k.memory.tone',
      );
    });

    test('iplik taşınan yuvaları okur', () {
      final card = EventCard.fromJson(
        _minimal()
          ..['left'] = {
            'label': 'Sol',
            'effects': {
              'schedule': {
                'event': 'devam',
                'inYears': 2,
                'with': ['kerem'],
              },
            },
          },
      );
      final s = card.left.effects.schedule!;
      expect(s.withRoles, ['kerem']);
      expect(s.inYears, 2);
    });

    test('zarsız success ve fail reddedilir', () {
      expectFormatError(
        _minimal()
          ..['left'] = {
            'label': 'Sol',
            'success': {'money': 1},
          },
        'test_01.left.success',
      );
    });

    test('yukarı seçeneği okunur ve choice onu verir', () {
      final card = EventCard.fromJson(_minimal()..['up'] = {'label': 'Yukarı'});
      expect(card.choice(ChoiceSide.up).label, 'Yukarı');
      expect(
        () => EventCard.fromJson(_minimal()).choice(ChoiceSide.up),
        throwsStateError,
      );
    });
  });

  group('Conditions', () {
    test('aile profili koşulu', () {
      final card = EventCard.fromJson(
        _minimal()
          ..['conditions'] = {
            'familyProfile': ['fabrikator'],
          },
      );
      final c = testCharacter();
      expect(card.conditions.isMetBy(c), isFalse);
      expect(
        card.conditions.isMetBy(
          Character.fromJson(c.toJson()..['family'] = 'fabrikator'),
        ),
        isTrue,
      );
    });
  });
}
