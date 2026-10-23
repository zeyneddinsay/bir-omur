import 'package:bir_omur/models/models.dart';

/// Testler için olay üretir; verilmeyen alanlar varsayılanla doldurulur.
/// JSON yolundan geçtiği için olay şeması da birlikte denenmiş olur.
///
/// Eski kart testleriyle uyumlu parametreler: [mandatory] dönemeç,
/// [chainOnly] iplik olur; [once] ve [cooldown] tekrar kuralına çevrilir
/// (ikisi de yoksa her yıl gelebilir). [theme] verilmezse her olay kendi
/// teması varmış gibi davranır diye temalar sırayla dağıtılır; aynı yıl
/// birden çok olay bekleyen testler farklı tema verir.
EventCard testCard(
  String id, {
  int minAge = 0,
  int maxAge = 120,
  String rarity = 'siradan',
  bool once = false,
  int cooldown = 0,
  bool mandatory = false,
  bool chainOnly = false,
  String? type,
  String? theme,
  Map<String, dynamic>? conditions,
  Map<String, dynamic>? roles,
  String? speaker,
  String? text,
  Map<String, dynamic>? left,
  Map<String, dynamic>? right,
  Map<String, dynamic>? up,
}) {
  return EventCard.fromJson(
    testCardJson(
      id,
      minAge: minAge,
      maxAge: maxAge,
      rarity: rarity,
      once: once,
      cooldown: cooldown,
      mandatory: mandatory,
      chainOnly: chainOnly,
      type: type,
      theme: theme,
      conditions: conditions,
      roles: roles,
      speaker: speaker,
      text: text,
      left: left,
      right: right,
      up: up,
    ),
  );
}

/// [testCard] ile aynı, ama JSON olarak (denetçi testleri için).
Map<String, dynamic> testCardJson(
  String id, {
  int minAge = 0,
  int maxAge = 120,
  String rarity = 'siradan',
  bool once = false,
  int cooldown = 0,
  bool mandatory = false,
  bool chainOnly = false,
  String? type,
  String? theme,
  Map<String, dynamic>? conditions,
  Map<String, dynamic>? roles,
  String? speaker,
  String? text,
  Map<String, dynamic>? left,
  Map<String, dynamic>? right,
  Map<String, dynamic>? up,
}) => {
  'id': id,
  'type': type ?? (mandatory ? 'donemec' : (chainOnly ? 'iplik' : 'genel')),
  'theme': theme ?? _themeFor(id),
  'minAge': minAge,
  'maxAge': maxAge,
  'rarity': rarity,
  // Denetçi tekrarı yalnızca dönemeç ve iplikte kabul eder.
  'repeat': once || (cooldown == 0 && !mandatory && !chainOnly && type == null)
      ? 'once'
      : {'cooldown': cooldown < 1 ? 1 : cooldown},
  'conditions': ?conditions,
  'roles': ?roles,
  'speaker': ?speaker,
  'text': text ?? 'Test kartı $id',
  'left': withChoiceResult(left ?? {'label': 'Sol'}),
  'right': withChoiceResult(right ?? {'label': 'Sağ'}),
  'up': ?(up == null ? null : withChoiceResult(up)),
};

/// Denetçi her seçenekte sonuç cümlesi ister; yazılmamışsa varsayılanı
/// eklenir. Testler `result: null` vererek eksik cümleyi deneyebilir.
Map<String, dynamic> withChoiceResult(Map<String, dynamic> choice) {
  if (choice.containsKey('roll')) {
    return {'successResult': 'Tuttu.', 'failResult': 'Tutmadı.', ...choice}
      ..removeWhere((_, v) => v == null);
  }
  return {'result': 'Oldu.', ...choice}..removeWhere((_, v) => v == null);
}

const List<String> _themes = [
  'aile',
  'okul',
  'ask',
  'is',
  'para',
  'mahalle',
  'saglik',
  'genel',
];

String _themeFor(String id) =>
    _themes[id.codeUnits.fold(0, (s, c) => s + c) % _themes.length];

/// Simülasyon testleri için bütün evreleri kapsayan sentetik deste:
/// zarlı, iplikli, dönemeç, yukarı seçenekli, kişili ve zor dönem
/// olayları içerir.
List<EventCard> simulationDeck() {
  final cards = <EventCard>[];
  for (final stage in LifeStage.values) {
    final min = stage.minAge;
    final max = stage.maxAge ?? 120;
    cards
      ..add(
        testCard(
          '${stage.id}_iyi',
          minAge: min,
          maxAge: max,
          theme: 'genel',
          left: {
            'label': 'Sol',
            'effects': {'happiness': 6, 'health': -3, 'money': -2000},
          },
          right: {
            'label': 'Sağ',
            'effects': {'knowledge': 5},
          },
        ),
      )
      ..add(
        testCard(
          '${stage.id}_zar',
          minAge: min,
          maxAge: max,
          cooldown: 2,
          theme: 'para',
          left: {
            'label': 'Sol',
            'effects': {'reputation': -3},
          },
          right: {
            'label': 'Sağ',
            'roll': {'stat': 'luck', 'threshold': 50},
            'success': {'money': 5000, 'happiness': 5},
            'fail': {'money': -5000, 'health': -10},
          },
        ),
      )
      ..add(
        testCard(
          '${stage.id}_aile',
          minAge: min,
          maxAge: max,
          cooldown: 2,
          type: 'kisi',
          theme: 'aile',
          roles: {
            'kisi': {
              'kin': ['anne', 'baba', 'kardes', 'dede', 'nine'],
            },
          },
          speaker: 'kisi',
          text: '{kisi.akraba|in} bir isteği var, {oyuncu.ad}.',
          left: {
            'label': 'Kabul',
            'effects': {
              'happiness': 2,
              'people': {
                'kisi': {
                  'memory': {
                    'kind': 'kabul_etti',
                    'label': 'İsteğimi kabul etti',
                    'tone': 'olumlu',
                    'severity': 1,
                  },
                },
              },
            },
          },
          right: {
            'label': 'Ret',
            'effects': {
              'people': {
                'kisi': {
                  'memory': {
                    'kind': 'reddetti',
                    'label': 'İsteğimi geri çevirdi',
                    'tone': 'olumsuz',
                    'severity': 1,
                  },
                },
              },
            },
          },
        ),
      )
      ..add(
        testCard(
          '${stage.id}_nadir',
          minAge: min,
          maxAge: max,
          rarity: 'nadir',
          once: true,
          theme: 'saglik',
          left: {
            'label': 'Sol',
            'effects': {'health': -20},
          },
          right: {
            'label': 'Sağ',
            'effects': {
              'schedule': {'event': 'zincir_devam', 'inYears': 2},
            },
          },
          up: {
            'label': 'Yukarı',
            'effects': {'happiness': -70, 'money': -50000},
          },
        ),
      );
  }
  cards
    ..add(
      testCard(
        'zincir_devam',
        chainOnly: true,
        theme: 'mahalle',
        left: {
          'label': 'Sol',
          'roll': {'stat': 'reputation', 'threshold': 40},
          'success': {'money': 3000},
          'fail': {
            'reputation': -5,
            'schedule': {'event': 'zincir_devam', 'inYears': 1},
          },
        },
      ),
    )
    ..add(
      testCard(
        'askerlik',
        minAge: 20,
        maxAge: 29,
        once: true,
        mandatory: true,
        theme: 'genel',
        conditions: {
          'gender': 'erkek',
          'notFlags': ['askerligini_yapti'],
        },
        right: {
          'label': 'Sağ',
          'effects': {
            'health': 5,
            'addFlags': ['askerligini_yapti'],
          },
        },
      ),
    )
    ..add(
      testCard(
        'zor_donem_destek',
        minAge: 19,
        mandatory: true,
        cooldown: 3,
        theme: 'saglik',
        conditions: {
          'flags': ['bunalim'],
        },
        left: {
          'label': 'Sol',
          'effects': {'happiness': 25},
        },
      ),
    )
    ..add(
      testCard(
        'icra',
        minAge: 19,
        mandatory: true,
        cooldown: 2,
        theme: 'para',
        conditions: {
          'flags': ['borclu'],
        },
        left: {
          'label': 'Sol',
          'effects': {'money': 20000, 'reputation': -5},
        },
      ),
    );
  return cards;
}
