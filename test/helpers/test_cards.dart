import 'package:bir_omur/models/models.dart';

/// Testler için kart üretir; verilmeyen alanlar varsayılanla doldurulur.
/// JSON yolundan geçtiği için kart şeması da birlikte denenmiş olur.
EventCard testCard(
  String id, {
  int minAge = 0,
  int maxAge = 120,
  String rarity = 'siradan',
  bool once = false,
  int cooldown = 0,
  bool mandatory = false,
  bool chainOnly = false,
  Map<String, dynamic>? conditions,
  Map<String, dynamic>? left,
  Map<String, dynamic>? right,
  Map<String, dynamic>? up,
}) {
  return EventCard.fromJson({
    'id': id,
    'stage': LifeStage.forAge(minAge).id,
    'minAge': minAge,
    'maxAge': maxAge,
    'rarity': rarity,
    'once': once,
    'cooldown': cooldown,
    'mandatory': mandatory,
    'chainOnly': chainOnly,
    'conditions': ?conditions,
    'text': 'Test kartı $id',
    'left': left ?? {'label': 'Sol'},
    'right': right ?? {'label': 'Sağ'},
    'up': ?up,
  });
}

/// Simülasyon testleri için bütün evreleri kapsayan sentetik deste:
/// zarlı, zincirli, zorunlu, yukarı seçenekli ve zor dönem kartları içerir.
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
          left: {
            'label': 'Sol',
            'effects': {'happiness': 6, 'health': -3, 'money': -2000},
          },
          right: {
            'label': 'Sağ',
            'effects': {'knowledge': 5, 'family': -4},
          },
        ),
      )
      ..add(
        testCard(
          '${stage.id}_zar',
          minAge: min,
          maxAge: max,
          cooldown: 2,
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
          '${stage.id}_nadir',
          minAge: min,
          maxAge: max,
          rarity: 'nadir',
          once: true,
          left: {
            'label': 'Sol',
            'effects': {
              'health': -20,
              'addFlags': ['${stage.id}_iz'],
            },
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
        conditions: {
          'flags': ['bunalim'],
        },
        left: {
          'label': 'Sol',
          'effects': {'happiness': 25, 'family': 5},
        },
      ),
    )
    ..add(
      testCard(
        'icra',
        minAge: 19,
        mandatory: true,
        cooldown: 2,
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
