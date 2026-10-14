import 'dart:convert';

import 'package:bir_omur/models/models.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_character.dart';

/// docs/GDD.md "Kart veri formatı" bölümündeki örnek, birebir.
const _gddSample = '''
{
  "id": "kira_zammi_01",
  "stage": "genc",
  "minAge": 19,
  "maxAge": 45,
  "rarity": "siradan",
  "cooldown": 3,
  "conditions": { "notFlags": ["ev_sahibi"], "flags": ["kiraci"] },
  "speaker": "ev_sahibi",
  "text": "Ev sahibi kirayı iki katına çıkarmak istiyor. Gerekçesi: 'Piyasa böyle.'",
  "left": {
    "label": "Taşınırım",
    "effects": { "money": -15000, "happiness": -5, "addFlags": ["tasindi"] }
  },
  "right": {
    "label": "Pazarlık ederim",
    "roll": { "stat": "luck", "threshold": 50 },
    "success": { "money": -3000, "happiness": 3 },
    "fail": { "money": -8000, "reputation": -2, "schedule": { "event": "ev_sahibi_ihtar", "inYears": 1 } }
  }
}
''';

Map<String, dynamic> _sample() =>
    jsonDecode(_gddSample) as Map<String, dynamic>;

Map<String, dynamic> _minimal() => {
  'id': 'test_01',
  'stage': 'bebek',
  'minAge': 0,
  'maxAge': 6,
  'text': 'Metin',
  'left': {'label': 'Sol'},
  'right': {'label': 'Sağ'},
};

void main() {
  group('EventCard.fromJson', () {
    test('GDD örnek kartını okur', () {
      final card = EventCard.fromJson(_sample());

      expect(card.id, 'kira_zammi_01');
      expect(card.stage, LifeStage.genc);
      expect(card.minAge, 19);
      expect(card.maxAge, 45);
      expect(card.rarity, Rarity.siradan);
      expect(card.cooldown, 3);
      expect(card.once, isFalse);
      expect(card.speaker, 'ev_sahibi');
      expect(card.conditions.flags, ['kiraci']);
      expect(card.conditions.notFlags, ['ev_sahibi']);

      expect(card.left.label, 'Taşınırım');
      expect(card.left.hasRoll, isFalse);
      expect(card.left.effects.money, -15000);
      expect(card.left.effects.stats, {StatKind.happiness: -5});
      expect(card.left.effects.addFlags, ['tasindi']);

      expect(card.right.hasRoll, isTrue);
      expect(card.right.roll!.stat, RollStat.luck);
      expect(card.right.roll!.threshold, 50);
      expect(card.right.success!.money, -3000);
      expect(card.right.fail!.stats, {StatKind.reputation: -2});
      expect(card.right.fail!.schedule!.cardId, 'ev_sahibi_ihtar');
      expect(card.right.fail!.schedule!.inYears, 1);
      expect(card.up, isNull);
    });

    test('isteğe bağlı alanlar varsayılan değer alır', () {
      final card = EventCard.fromJson(_minimal());
      expect(card.rarity, Rarity.siradan);
      expect(card.cooldown, 0);
      expect(card.mandatory, isFalse);
      expect(card.chainOnly, isFalse);
      expect(card.left.effects.isEmpty, isTrue);
      expect(card.choices, hasLength(2));
    });

    test('yukarı seçeneği okunur', () {
      final json = _minimal()..['up'] = {'label': 'Yukarı'};
      final card = EventCard.fromJson(json);
      expect(card.choices, hasLength(3));
      expect(card.choice(ChoiceSide.up).label, 'Yukarı');
    });

    void expectFormatError(Map<String, dynamic> json, String pathContains) {
      expect(
        () => EventCard.fromJson(json),
        throwsA(
          isA<CardFormatException>().having(
            (e) => e.path,
            'path',
            contains(pathContains),
          ),
        ),
      );
    }

    test('eksik alanı yoluyla bildirir', () {
      expectFormatError(_minimal()..remove('text'), 'test_01.text');
    });

    test('bilinmeyen kart alanını reddeder', () {
      expectFormatError(_minimal()..['weight'] = 5, 'test_01.weight');
    });

    test('bilinmeyen etki adını reddeder', () {
      final json = _sample();
      (json['left'] as Map)['effects']['mony'] = -10;
      expectFormatError(json, 'kira_zammi_01.left.effects.mony');
    });

    test('bilinmeyen evre ve nadirliği reddeder', () {
      expectFormatError(_minimal()..['stage'] = 'universite', 'stage');
      expectFormatError(_minimal()..['rarity'] = 'destansi', 'rarity');
    });

    test('ters yaş aralığını reddeder', () {
      expectFormatError(_minimal()..['minAge'] = 7, 'minAge');
    });

    test('zarsız seçenekte success kullanılamaz', () {
      final json = _minimal()
        ..['left'] = {
          'label': 'Sol',
          'success': {'money': 5},
        };
      expectFormatError(json, 'left.success');
    });

    test('zarlı seçenekte fail eksikse hata verir', () {
      final json = _minimal()
        ..['left'] = {
          'label': 'Sol',
          'roll': {'stat': 'luck', 'threshold': 40},
          'success': {'money': 5},
        };
      expectFormatError(json, 'left.fail');
    });

    test('zar eşiği 0–100 dışındaysa hata verir', () {
      final json = _sample();
      (json['right'] as Map)['roll']['threshold'] = 150;
      expectFormatError(json, 'roll.threshold');
    });

    test('zincir kartı en az 1 yıl sonra olmalı', () {
      final json = _sample();
      (json['right'] as Map)['fail']['schedule']['inYears'] = 0;
      expectFormatError(json, 'schedule.inYears');
    });
  });

  group('Conditions.isMetBy', () {
    test('bayrak koşulları', () {
      const conditions = Conditions(flags: ['kiraci'], notFlags: ['ev_sahibi']);
      expect(conditions.isMetBy(testCharacter()), isFalse);
      expect(conditions.isMetBy(testCharacter(flags: {'kiraci'})), isTrue);
      expect(
        conditions.isMetBy(testCharacter(flags: {'kiraci', 'ev_sahibi'})),
        isFalse,
      );
    });

    test('min dahil, max hariçtir', () {
      const conditions = Conditions(
        min: {'knowledge': 50},
        max: {'money': 5000},
      );
      expect(
        conditions.isMetBy(testCharacter(knowledge: 50, money: 4999)),
        isTrue,
      );
      expect(
        conditions.isMetBy(testCharacter(knowledge: 49, money: 0)),
        isFalse,
      );
      expect(
        conditions.isMetBy(testCharacter(knowledge: 80, money: 5000)),
        isFalse,
      );
    });

    test('şans, cinsiyet ve mizaç', () {
      const conditions = Conditions(
        min: {'luck': 60},
        gender: Gender.kadin,
        temperament: Temperament.hesapci,
      );
      expect(
        conditions.isMetBy(
          testCharacter(
            luck: 60,
            gender: Gender.kadin,
            temperament: Temperament.hesapci,
          ),
        ),
        isTrue,
      );
      expect(
        conditions.isMetBy(
          testCharacter(
            luck: 60,
            gender: Gender.erkek,
            temperament: Temperament.hesapci,
          ),
        ),
        isFalse,
      );
      expect(
        conditions.isMetBy(
          testCharacter(
            luck: 59,
            gender: Gender.kadin,
            temperament: Temperament.hesapci,
          ),
        ),
        isFalse,
      );
    });

    test('JSON koşulunda bilinmeyen eşik adını reddeder', () {
      final json = _minimal()
        ..['conditions'] = {
          'min': {'iq': 50},
        };
      expect(
        () => EventCard.fromJson(json),
        throwsA(isA<CardFormatException>()),
      );
    });
  });
}
