import 'dart:convert';

import 'package:bir_omur/content/card_validator.dart';
import 'package:bir_omur/content/content_loader.dart';
import 'package:bir_omur/content/content_registry.dart';
import 'package:flutter_test/flutter_test.dart';

final _registry = ContentRegistry(
  flags: {
    'kiraci': '',
    'ev_sahibi': '',
    'universite_ogrencisi': '',
    'asker_anilari': '',
  },
  speakers: {'anne': ''},
);

Map<String, dynamic> _card(
  String id, {
  Map<String, dynamic> extra = const {},
}) => {
  'id': id,
  'stage': 'genc',
  'minAge': 20,
  'maxAge': 30,
  'text': 'Kısa bir metin.',
  'left': {'label': 'Sol'},
  'right': {'label': 'Sağ'},
  ...extra,
};

CardCheckResult _check(List<Object?> cards, {String file = 'genc.json'}) =>
    CardValidator(_registry).check({file: jsonEncode(cards)});

/// Tek bir hata bekler ve yolunun [pathContains] içerdiğini doğrular.
void _expectSingleError(
  CardCheckResult result,
  String pathContains,
  String messageContains,
) {
  expect(result.errors, hasLength(1), reason: result.issues.join('\n'));
  final error = result.errors.single;
  expect(error.path, contains(pathContains));
  expect(error.message, contains(messageContains));
}

void main() {
  test('temiz kart sorunsuz geçer', () {
    final result = _check([_card('a')]);
    expect(result.issues, isEmpty);
    expect(result.cards.single.card.id, 'a');
    expect(result.cards.single.file, 'genc.json');
  });

  group('eksik ve bozuk alanlar', () {
    test('eksik alan', () {
      _expectSingleError(
        _check([_card('a')..remove('left')]),
        'a.left',
        'nesne bekleniyordu',
      );
    });

    test('bozuk JSON', () {
      final result = CardValidator(_registry).check({'x.json': '[{"id": '});
      _expectSingleError(result, '-', 'JSON okunamadı');
    });

    test('dosya dizi değilse', () {
      final result = CardValidator(_registry).check({'x.json': '{}'});
      _expectSingleError(result, '-', 'kart dizisi');
    });

    test('bozuk kart diğerlerini engellemez', () {
      final result = _check([_card('a')..remove('text'), _card('b')]);
      expect(result.errors, hasLength(1));
      expect(result.cards.map((c) => c.card.id), ['b']);
    });
  });

  group('bilinmeyen adlar', () {
    test('bilinmeyen etki adı', () {
      final card = _card(
        'a',
        extra: {
          'left': {
            'label': 'Sol',
            'effects': {'mutluluk': 5},
          },
        },
      );
      _expectSingleError(
        _check([card]),
        'a.left.effects.mutluluk',
        'bilinmeyen alan',
      );
    });

    test('bilinmeyen bayrak (koşulda ve etkide)', () {
      final card = _card(
        'a',
        extra: {
          'conditions': {
            'flags': ['kirci'],
          },
          'right': {
            'label': 'Sağ',
            'effects': {
              'addFlags': ['evsahibi'],
            },
          },
        },
      );
      final result = _check([card]);
      expect(result.errors.map((e) => e.message), [
        contains('"kirci"'),
        contains('"evsahibi"'),
      ]);
    });

    test('kartlar motorun bayraklarını ekleyip kaldıramaz', () {
      final card = _card(
        'a',
        extra: {
          'left': {
            'label': 'Sol',
            'effects': {
              'addFlags': ['ev_sahibi'],
            },
          },
          'right': {
            'label': 'Sağ',
            'effects': {
              'removeFlags': ['borclu'],
            },
          },
        },
      );
      final result = _check([card]);
      expect(result.errors, hasLength(2));
      expect(
        result.errors.map((e) => e.message),
        everyElement(contains('motorun bayrağı')),
      );
    });

    test('motor bayrakları kayıtta olmadan da bilinir', () {
      final card = _card(
        'a',
        extra: {
          'mandatory': true,
          'cooldown': 2,
          'conditions': {
            'flags': ['bunalim', 'borclu'],
          },
        },
      );
      expect(_check([card]).issues, isEmpty);
    });

    test('bilinmeyen konuşmacı', () {
      _expectSingleError(
        _check([
          _card('a', extra: {'speaker': 'kaynana'}),
        ]),
        'a.speaker',
        '"kaynana"',
      );
    });
  });

  group('uzunluklar', () {
    test('kart metni en fazla 140 karakter', () {
      expect(
        _check([
          _card('a', extra: {'text': 'ç' * 140}),
        ]).issues,
        isEmpty,
      );
      _expectSingleError(
        _check([
          _card('a', extra: {'text': 'ç' * 141}),
        ]),
        'a.text',
        '141 karakter',
      );
    });

    test('seçenek metni en fazla 24 karakter', () {
      final ok = _card(
        'a',
        extra: {
          'left': {'label': 'Hafta sonu dahil giderim'},
        },
      );
      expect(_check([ok]).issues, isEmpty);
      final tooLong = _card(
        'a',
        extra: {
          'right': {'label': 'Hafta sonu dahil gideriz!'},
        },
      );
      _expectSingleError(_check([tooLong]), 'a.right.label', '25 karakter');
    });
  });

  group('tutarlılık', () {
    test('dosyalar arasında tekrar eden kimlik', () {
      final result = CardValidator(_registry).check({
        'a.json': jsonEncode([_card('ayni')]),
        'b.json': jsonEncode([_card('ayni')]),
      });
      _expectSingleError(result, 'ayni', 'ilki: a.json');
      expect(result.errors.single.file, 'b.json');
    });

    test('olmayan zincir hedefi', () {
      final card = _card(
        'a',
        extra: {
          'left': {
            'label': 'Sol',
            'effects': {
              'schedule': {'event': 'yok_boyle_kart', 'inYears': 1},
            },
          },
        },
      );
      _expectSingleError(_check([card]), 'a.left.schedule', '"yok_boyle_kart"');
    });

    test('evre minAge ile uyuşmalı', () {
      _expectSingleError(
        _check([
          _card('a', extra: {'stage': 'lise'}),
        ]),
        'a.stage',
        'genc',
      );
    });

    test('yukarı seçeneği sıradan kartta olmaz', () {
      final card = _card(
        'a',
        extra: {
          'up': {'label': 'Yukarı'},
        },
      );
      _expectSingleError(_check([card]), 'a.up', 'nadir');
      card['rarity'] = 'nadir';
      expect(_check([card]).issues, isEmpty);
    });

    test('zorunlu kart tekrar sınırı ister', () {
      _expectSingleError(
        _check([
          _card('a', extra: {'mandatory': true}),
        ]),
        'a.mandatory',
        'her yıl',
      );
    });

    test('planlanmayan zincir kartı uyarı verir', () {
      final result = _check([
        _card('a', extra: {'chainOnly': true}),
      ]);
      expect(result.errors, isEmpty);
      expect(result.warnings.single.message, contains('hiç gelmez'));
    });

    test('hiçbir kartın açmadığı bayrağa bakan kart uyarı verir', () {
      final result = _check([
        _card(
          'a',
          extra: {
            'conditions': {
              'flags': ['kiraci'],
            },
          },
        ),
      ]);
      expect(result.errors, isEmpty);
      expect(result.warnings.single.message, contains('"kiraci"'));
    });

    test('motorun baktığı bayrak kayıtta olmalı', () {
      final registry = ContentRegistry(flags: const {}, speakers: const {});
      final result = CardValidator(registry).check({'x.json': '[]'});
      expect(
        result.errors.map((e) => e.path),
        containsAll(ContentRegistry.engineReferencedFlags),
      );
    });
  });

  test('loadContent hatada durur, temizse desteyi kurar', () {
    const registry =
        '{"flags": {"universite_ogrencisi": "", "ev_sahibi": "", "asker_anilari": ""}, "speakers": {}}';
    expect(
      () => loadContent(
        registrySource: registry,
        cardFiles: {
          'x.json': jsonEncode([_card('a')..remove('text')]),
        },
      ),
      throwsA(isA<ContentException>()),
    );
    final content = loadContent(
      registrySource: registry,
      cardFiles: {
        'x.json': jsonEncode([_card('a'), _card('b')]),
      },
    );
    expect(content.deck.cards.map((c) => c.id), ['a', 'b']);
  });
}
