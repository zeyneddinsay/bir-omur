import 'dart:math';

import '../models/models.dart';

/// Bütün olay kartları ve yıllık kart çekimi.
class EventDeck {
  EventDeck(Iterable<EventCard> cards)
    : cards = List.unmodifiable(cards),
      _byId = {for (final card in cards) card.id: card} {
    if (_byId.length != this.cards.length) {
      throw ArgumentError('Destede tekrar eden kart kimliği var');
    }
  }

  final List<EventCard> cards;
  final Map<String, EventCard> _byId;

  EventCard? byId(String id) => _byId[id];

  /// Kartın bu yıl desteden çekilebilir olup olmadığı. Zincir kartları
  /// (chainOnly) asla çekilmez.
  bool isEligible(EventCard card, Character character) =>
      !card.chainOnly &&
      card.isInAgeRange(character.age) &&
      isRepeatAllowed(card, character) &&
      card.conditions.isMetBy(character);

  /// once ve cooldown kuralları. cooldown 0 olsa bile bir kart aynı yıl
  /// iki kez gelmez.
  static bool isRepeatAllowed(EventCard card, Character character) {
    final lastSeen = character.lastSeenAge(card.id);
    if (lastSeen == null) return true;
    if (card.once) return false;
    return character.age - lastSeen >= max(1, card.cooldown);
  }

  /// Bu yılın kartlarını seçer.
  ///
  /// Önce koşulu sağlanan zorunlu kartlar gelir (sayı sınırına takılmaz),
  /// sonra [count] dolana kadar ağırlıklı rastgele seçim yapılır.
  /// [exclude] içindeki kartlar (bu yılın zincir kartları gibi) atlanır.
  List<EventCard> draw(
    Character character,
    Random random, {
    required int count,
    Set<String> exclude = const {},
  }) {
    final eligible = [
      for (final card in cards)
        if (!exclude.contains(card.id) && isEligible(card, character)) card,
    ];
    final drawn = [
      for (final card in eligible)
        if (card.mandatory) card,
    ];
    final pool = [
      for (final card in eligible)
        if (!card.mandatory) card,
    ];
    while (drawn.length < count && pool.isNotEmpty) {
      drawn.add(pool.removeAt(_weightedIndex(pool, random)));
    }
    return drawn;
  }

  static int _weightedIndex(List<EventCard> pool, Random random) {
    final total = pool.fold(0, (sum, card) => sum + card.rarity.weight);
    var target = random.nextInt(total);
    for (var i = 0; i < pool.length; i++) {
      target -= pool[i].rarity.weight;
      if (target < 0) return i;
    }
    return pool.length - 1;
  }
}
