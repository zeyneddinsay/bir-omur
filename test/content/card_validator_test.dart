import 'dart:convert';
import 'dart:io';

import 'package:bir_omur/content/card_validator.dart';
import 'package:bir_omur/content/content_loader.dart';
import 'package:bir_omur/content/content_registry.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_cards.dart';

final _registry = ContentRegistry(
  flags: {
    'kiraci': '',
    'universite_ogrencisi': '',
    'asker_anilari': '',
    'tasindi': '',
  },
);

Map<String, dynamic> _card(
  String id, {
  Map<String, dynamic> extra = const {},
}) => {
  ...testCardJson(id, minAge: 20, maxAge: 30, theme: 'genel'),
  'text': 'Kısa bir metin.',
  ...extra,
};

CardCheckResult _check(List<Object?> cards, {String file = 'genc.json'}) =>
    CardValidator(
      _registry,
      familyProfiles: const {'isci', 'memur'},
    ).check({file: jsonEncode(cards)});

/// Tek bir hata bekler ve yolunun [pathContains] içerdiğini doğrular.
void _expectSingleError(
  CardCheckResult result,
  String pathContains, {
  String? messageContains,
}) {
  expect(result.errors, hasLength(1), reason: result.issues.join('\n'));
  final error = result.errors.single;
  expect(error.path, contains(pathContains));
  if (messageContains != null) {
    expect(error.message, contains(messageContains));
  }
}

Map<String, dynamic> _memory({String label = 'Bana yardım etti'}) => {
  'kind': 'yardim',
  'label': label,
  'tone': 'olumlu',
  'severity': 1,
};

void main() {
  test('temiz olay sorunsuz geçer', () {
    final result = _check([_card('a')]);
    expect(result.issues, isEmpty, reason: result.issues.join('\n'));
    expect(result.cards.single.card.id, 'a');
  });

  group('biçim', () {
    test('eksik alan', () {
      _expectSingleError(_check([_card('a')..remove('theme')]), 'a.theme');
    });

    test('bozuk JSON ve dizi olmayan dosya', () {
      final broken = CardValidator(_registry).check({'x.json': '[{'});
      expect(broken.errors.single.message, contains('JSON'));
      final notList = CardValidator(_registry).check({'x.json': '{}'});
      expect(notList.errors.single.message, contains('dizisi'));
    });

    test('bozuk olay diğerlerini engellemez', () {
      final result = _check([_card('a')..remove('text'), _card('b')]);
      expect(result.errors, hasLength(1));
      expect(result.cards.single.card.id, 'b');
    });

    test('dosyalar arasında tekrar eden kimlik', () {
      final result = CardValidator(_registry).check({
        'a.json': jsonEncode([_card('x')]),
        'b.json': jsonEncode([_card('x')]),
      });
      _expectSingleError(result, 'x', messageContains: 'tekrar');
    });
  });

  group('metin', () {
    final roles = {'k': <String, dynamic>{}};

    test('en uzun adla 140 karakter', () {
      // 'Muhammet' 8 harf + boşluk + 131 harf = 140.
      final fits = _card(
        'a',
        extra: {'roles': roles, 'text': '{k.ad} ${'a' * 131}'},
      );
      expect(_check([fits]).errors, isEmpty);
      final tooLong = _card(
        'a',
        extra: {'roles': roles, 'text': '{k.ad} ${'a' * 132}'},
      );
      _expectSingleError(
        _check([tooLong]),
        'a.text',
        messageContains: 'en uzun',
      );
    });

    test('akrabalık sözcüğü en uzun hâliyle sayılır', () {
      final text = '{k.akraba} ${'a' * 126}';
      _expectSingleError(
        _check([
          _card('a', extra: {'roles': roles, 'text': text}),
        ]),
        'a.text',
      );
    });

    test('seçenek en fazla 24 karakter', () {
      final result = _check([
        _card(
          'a',
          extra: {
            'left': {'label': 'x' * 25},
          },
        ),
      ]);
      _expectSingleError(result, 'a.left.label');
    });

    test('tanımsız yuva, bilinmeyen alan, oyuncu alanı', () {
      _expectSingleError(
        _check([
          _card('a', extra: {'text': '{kerem.ad} geldi.'}),
        ]),
        'a.text',
        messageContains: 'rol yuvası yok',
      );
      _expectSingleError(
        _check([
          _card('a', extra: {'roles': roles, 'text': '{k.yas} yaşında.'}),
        ]),
        'a.text',
        messageContains: 'bilinmeyen alan',
      );
      _expectSingleError(
        _check([
          _card('a', extra: {'text': '{oyuncu.soyad} ailesi.'}),
        ]),
        'a.text',
        messageContains: 'oyuncu.ad',
      );
      _expectSingleError(
        _check([
          _card('a', extra: {'text': '{oyuncu.hitap.dayi} geldi.'}),
        ]),
        'a.text',
        messageContains: 'oyuncu.ad',
      );
      expect(
        _check([
          _card(
            'a',
            extra: {
              'text': "{oyuncu.ad|e} bir haber: 'Gel {oyuncu.hitap.evlat}.'",
            },
          ),
        ]).errors,
        isEmpty,
      );
    });

    test('elle yazılmış ek', () {
      _expectSingleError(
        _check([
          _card('a', extra: {'roles': roles, 'text': "{k.ad}'e söyledin."}),
        ]),
        'a.text',
        messageContains: 'elle yazılmış',
      );
    });

    test('anı etiketi de denetlenir', () {
      final result = _check([
        _card(
          'a',
          extra: {
            'roles': roles,
            'left': {
              'label': 'Sol',
              'effects': {
                'people': {
                  'k': {'memory': _memory(label: 'x' * 49)},
                },
              },
            },
          },
        ),
      ]);
      _expectSingleError(result, 'a.left.people.k.memory.label');
    });
  });

  group('kişiler', () {
    test('kişi etkisi tanımsız yuvaya yazılamaz', () {
      final result = _check([
        _card(
          'a',
          extra: {
            'left': {
              'label': 'Sol',
              'effects': {
                'people': {
                  'k': {'memory': _memory()},
                },
              },
            },
          },
        ),
      ]);
      _expectSingleError(
        result,
        'a.left.people.k',
        messageContains: 'yuvası yok',
      );
    });

    test('vefat etmiş kişiye etki yazılmaz', () {
      final result = _check([
        _card(
          'a',
          extra: {
            'roles': {
              'merhum': {'deceased': true},
            },
            'left': {
              'label': 'Sol',
              'effects': {
                'people': {
                  'merhum': {'memory': _memory()},
                },
              },
            },
          },
        ),
      ]);
      _expectSingleError(
        result,
        'a.left.people.merhum',
        messageContains: 'vefat',
      );
    });

    test('kişi olayı en az bir yuva ister', () {
      _expectSingleError(
        _check([
          _card('a', extra: {'type': 'kisi'}),
        ]),
        'a.roles',
      );
    });

    test('Aile Bağı doğrudan değiştirilemez', () {
      final result = _check([
        _card(
          'a',
          extra: {
            'left': {
              'label': 'Sol',
              'effects': {'family': 5},
            },
          },
        ),
      ]);
      _expectSingleError(result, 'a.left', messageContains: 'Aile Bağı');
    });

    test('18 yaş kuralı: romantik yuva', () {
      final result = _check([
        _card(
          'a',
          extra: {
            'minAge': 16,
            'roles': {
              'k': {
                'bond': ['sevgili'],
                'minAge': 16,
              },
            },
          },
        ),
      ]);
      expect(result.errors.map((e) => e.path), [
        'a.minAge',
        'a.roles.k.minAge',
      ], reason: result.issues.join('\n'));
    });

    test('18 yaş kuralı: romantik bağ kuran etki', () {
      Map<String, dynamic> makesRomance(int roleMinAge) => _card(
        'b',
        extra: {
          'minAge': 18,
          'roles': {
            'k': {'minAge': roleMinAge},
          },
          'left': {
            'label': 'Sol',
            'effects': {
              'people': {
                'k': {'bond': 'flort'},
              },
            },
          },
        },
      );
      expect(_check([makesRomance(18)]).errors, isEmpty);
      _expectSingleError(_check([makesRomance(15)]), 'b.roles.k.minAge');
    });
  });

  group('iplikler', () {
    test('olmayan hedef', () {
      final result = _check([
        _card(
          'a',
          extra: {
            'left': {
              'label': 'Sol',
              'effects': {
                'schedule': {'event': 'yok', 'inYears': 1},
              },
            },
          },
        ),
      ]);
      _expectSingleError(result, 'a.left.schedule', messageContains: '"yok"');
    });

    test('taşınan yuva iki olayda da tanımlı olmalı', () {
      Map<String, dynamic> source(Map<String, dynamic> roles) => _card(
        'a',
        extra: {
          'roles': roles,
          'left': {
            'label': 'Sol',
            'effects': {
              'schedule': {
                'event': 'devam',
                'inYears': 1,
                'with': ['k'],
              },
            },
          },
        },
      );
      final target = _card(
        'devam',
        extra: {
          'type': 'iplik',
          'roles': {'k': <String, dynamic>{}},
        },
      );
      expect(
        _check([
          source({'k': <String, dynamic>{}}),
          target,
        ]).errors,
        isEmpty,
      );
      _expectSingleError(
        _check([source(const {}), target]),
        'a.left.schedule.with',
        messageContains: 'bu olayda',
      );
      final bareTarget = _card('devam', extra: {'type': 'iplik'});
      _expectSingleError(
        _check([
          source({'k': <String, dynamic>{}}),
          bareTarget,
        ]),
        'a.left.schedule.with',
        messageContains: 'hedef olay',
      );
    });

    test('planlanmayan iplik uyarı verir', () {
      final result = _check([
        _card('a', extra: {'type': 'iplik'}),
      ]);
      expect(result.errors, isEmpty);
      expect(result.warnings.single.message, contains('hiç gelmez'));
    });
  });

  group('koşullar ve bayraklar', () {
    test('bilinmeyen bayrak (koşulda ve etkide)', () {
      final result = _check([
        _card(
          'a',
          extra: {
            'conditions': {
              'flags': ['yok1'],
            },
            'left': {
              'label': 'Sol',
              'effects': {
                'addFlags': ['yok2'],
              },
            },
          },
        ),
      ]);
      final messages = result.errors.map((e) => e.message).join();
      expect(messages, contains('yok1'));
      expect(messages, contains('yok2'));
    });

    test('olaylar motorun bayraklarını ekleyip kaldıramaz', () {
      final result = _check([
        _card(
          'a',
          extra: {
            'left': {
              'label': 'Sol',
              'effects': {
                'addFlags': ['ev_sahibi'],
              },
            },
          },
        ),
      ]);
      _expectSingleError(result, 'a.left', messageContains: 'motorun');
    });

    test('bilinmeyen aile profili', () {
      final result = _check([
        _card(
          'a',
          extra: {
            'conditions': {
              'familyProfile': ['astronot'],
            },
          },
        ),
      ]);
      _expectSingleError(result, 'a.conditions.familyProfile');
    });

    test('hiçbir olayın açmadığı bayrağa bakan olay uyarı verir', () {
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
      expect(result.warnings.single.message, contains('hiç gelmez'));
    });

    test('yukarı seçeneği sıradan olayda, nadirlik dönemeçte olmaz', () {
      _expectSingleError(
        _check([
          _card(
            'a',
            extra: {
              'up': {'label': 'Yukarı'},
            },
          ),
        ]),
        'a.up',
      );
      _expectSingleError(
        _check([
          _card(
            'a',
            extra: {
              'type': 'donemec',
              'rarity': 'nadir',
              'up': {'label': 'Yukarı'},
            },
          ),
        ]),
        'a.rarity',
      );
    });

    test('motorun baktığı bayrak kayıtta olmalı', () {
      final registry = ContentRegistry(flags: const {});
      final result = CardValidator(registry).check({});
      expect(
        result.errors.map((e) => e.path),
        containsAll(ContentRegistry.engineReferencedFlags),
      );
    });
  });

  test('loadContent hatada durur, temizse desteyi kurar', () {
    final families = File('assets/families.json').readAsStringSync();
    final names = File('assets/names.json').readAsStringSync();
    final interactions = File('assets/interactions.json').readAsStringSync();
    const registry =
        '{"flags": {"universite_ogrencisi": "", "asker_anilari": "", "tasindi": ""}}';
    expect(
      () => loadContent(
        registrySource: registry,
        cardFiles: {
          'x.json': jsonEncode([_card('a')..remove('text')]),
        },
        familiesSource: families,
        namesSource: names,
        interactionsSource: interactions,
      ),
      throwsA(isA<ContentException>()),
    );
    final content = loadContent(
      registrySource: registry,
      cardFiles: {
        'x.json': jsonEncode([_card('a'), _card('b')]),
      },
      familiesSource: families,
      namesSource: names,
      interactionsSource: interactions,
    );
    expect(content.deck.cards.map((c) => c.id), ['a', 'b']);
  });
}
