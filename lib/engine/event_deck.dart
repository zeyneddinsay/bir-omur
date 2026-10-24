import 'dart:math';

import '../models/models.dart';
import 'people_tick.dart';
import 'relationships.dart';

/// Rol yuvaları kişilere bağlanmış, oynanmayı bekleyen bir olay.
class PendingEvent {
  const PendingEvent(this.card, [this.people = const {}]);

  final EventCard card;

  /// Yuva adı → kişi kimliği.
  final Map<String, String> people;

  Map<String, Object> toJson() => {
    'id': card.id,
    if (people.isNotEmpty) 'people': people,
  };
}

/// Bir kişinin rol yuvasına uyup uymadığı.
abstract final class RoleMatcher {
  /// Olaya çıkan kişi bu kadar yıl başka olaya çıkmaz (aile çekirdeği
  /// hariç).
  static const int restYears = 2;

  static bool matches(RoleSlot slot, Person p, Character c) {
    final now = c.age;
    if (slot.deceased) {
      final died = p.diedAt;
      // Her vefat için bir kez: ölümden sonra olaya çıkmışsa eşleşmez.
      if (died == null ||
          now - died > 1 ||
          (p.lastEventAt != null && p.lastEventAt! >= died)) {
        return false;
      }
    } else if (!p.isAlive || (p.archived && slot.memory == null)) {
      // Anı yuvası arşivdeki eski tanıdığı da bulur: geçmiş geri döner.
      return false;
    }
    if (p.bornAt > now) return false;
    if (slot.kin.isNotEmpty && !slot.kin.contains(p.kin)) return false;
    // Akraba istemeyen rol ya da anı yuvası akrabayı, eşi ya da sevgiliyi
    // seçmez: eş "eski sıra arkadaşın" diye karşına çıkmaz.
    final asksStranger =
        slot.kin.isEmpty &&
        (slot.roles.isNotEmpty ||
            slot.formerRoles.isNotEmpty ||
            slot.memory != null);
    if (asksStranger &&
        (p.kin != null ||
            (slot.bonds.isEmpty &&
                const {
                  Bond.flort,
                  Bond.sevgili,
                  Bond.nisanli,
                }.contains(p.bond)))) {
      return false;
    }
    if (slot.roles.isNotEmpty && !slot.roles.any((r) => p.hasRole(r))) {
      return false;
    }
    if (slot.formerRoles.isNotEmpty &&
        !slot.formerRoles.any(
          (r) => p.roles.any((pr) => pr.kind == r && !pr.active),
        )) {
      return false;
    }
    if (slot.bonds.isNotEmpty && !slot.bonds.contains(p.bond)) return false;
    if (slot.gender != null && p.gender != slot.gender) return false;
    if (slot.side != null && p.side != slot.side) return false;
    final age = p.ageAt(now);
    if (slot.minAge != null && age < slot.minAge!) return false;
    if (slot.maxAge != null && age > slot.maxAge!) return false;
    final gap = age - now;
    if (slot.minGap != null && gap < slot.minGap!) return false;
    if (slot.maxGap != null && gap > slot.maxGap!) return false;
    if (slot.minCloseness != null || slot.maxCloseness != null) {
      final v = Relationships.closeness(p, now);
      if (slot.minCloseness != null && v < slot.minCloseness!) return false;
      if (slot.maxCloseness != null && v > slot.maxCloseness!) return false;
    }
    if (slot.minHostility != null || slot.maxHostility != null) {
      final v = Relationships.hostility(p, now);
      if (slot.minHostility != null && v < slot.minHostility!) return false;
      if (slot.maxHostility != null && v > slot.maxHostility!) return false;
    }
    if (!slot.traits.every(p.hasTrait)) return false;
    if (slot.notTraits.any(p.hasTrait)) return false;
    if (slot.marital.isNotEmpty && !slot.marital.contains(p.marital)) {
      return false;
    }
    if (slot.memory != null &&
        !p.memories.any(
          (m) => m.kind == slot.memory && c.age - m.age >= slot.memoryYears,
        )) {
      return false;
    }
    if (slot.noMemory != null &&
        p.memories.any((m) => m.kind == slot.noMemory)) {
      return false;
    }
    if (slot.sameCity != null && (p.city == c.city) != slot.sameCity) {
      return false;
    }
    if (slot.livesTogether case final together?
        when PeopleTick.livesTogether(c, p) != together) {
      return false;
    }
    return true;
  }

  /// Kişi bu yıl yeni bir olaya çıkabilir mi (dinlenme kuralı).
  static bool isRested(Person p, int now) =>
      PeopleTick.coreKin.contains(p.kin) ||
      p.lastEventAt == null ||
      now - p.lastEventAt! > restYears;
}

/// Bütün olaylar ve yıllık olay seçimi.
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

  /// Dönemeçler dahil bir yılın en fazla olay sayısı; sığmayan iplik
  /// sonraki yıla kalır.
  static const int maxPerYear = 3;

  EventCard? byId(String id) => _byId[id];

  /// Kartın kişi bağlamadan önceki şartları: yaş, koşul ve tekrar. İplik
  /// olayları desteden çekilmez.
  bool isEligible(EventCard card, Character character) =>
      !card.chainOnly &&
      card.isInAgeRange(character.age) &&
      isRepeatAllowed(card, character) &&
      card.conditions.isMetBy(character);

  /// once ve cooldown kuralları. Bir kart aynı yıl iki kez gelmez.
  static bool isRepeatAllowed(EventCard card, Character character) {
    final lastSeen = character.lastSeenAge(card.id);
    if (lastSeen == null) return true;
    if (card.once) return false;
    if (card.repeat.maxTimes case final limit?
        when timesSeen(card.id, character) >= limit) {
      return false;
    }
    return character.age - lastSeen >= max(1, card.cooldown);
  }

  /// Kart bu hayatta kaç kez geldi.
  static int timesSeen(String cardId, Character c) =>
      c.history.where((r) => r.cardId == cardId).length;

  /// Daha önce gelmiş kart her gelişinde bu oranla daha az çekilir; yeni
  /// olaylar öne geçer, havuz küçükken aynı kart peş peşe gelmez.
  static const double freshness = 0.35;

  static double drawWeight(EventCard card, Character c) =>
      card.rarity.weight * pow(freshness, timesSeen(card.id, c)).toDouble();

  /// Rol yuvalarını kişilere bağlar. [fixed] önceden bağlanmış yuvalar
  /// (iplikten gelen kişiler); [busy] bu yıl başka olayda olan kişiler.
  /// Uygun kişi bulunamayan yuva varsa null.
  static Map<String, String>? bind(
    EventCard card,
    Character c,
    Random random, {
    Map<String, String> fixed = const {},
    Set<String> busy = const {},
  }) {
    final bound = <String, String>{};
    final now = c.age;
    for (final slot in card.roles) {
      final fixedId = fixed[slot.name];
      if (fixedId != null) {
        final p = c.people[fixedId];
        if (p == null || !RoleMatcher.matches(slot, p, c)) return null;
        bound[slot.name] = fixedId;
        continue;
      }
      // Vefat yuvası yalnızca ölmüşlere bakar; dinlenme kuralı ona işlemez.
      // Anı yuvası arşivdeki eski tanıdığa da bakar (geçmiş geri döner).
      final pool = slot.deceased || slot.memory != null
          ? c.people.bornBy(now)
          : c.people.active(now);
      // Aynı olayda aynı adlı iki kişi olmaz ("Elif mi, Elif mi?").
      final names = {for (final id in bound.values) c.people[id]?.name};
      final candidates = [
        for (final p in pool)
          if (!bound.containsValue(p.id) &&
              !names.contains(p.name) &&
              !busy.contains(p.id) &&
              (slot.deceased || RoleMatcher.isRested(p, now)) &&
              // Eşini ya da aynı akrabalıktan birini bu yıl kaybeden akraba
              // neşeli olaylarda rol almaz.
              (card.mandatory ||
                  slot.deceased ||
                  (!Relationships.widowedRecently(c, p) &&
                      !Relationships.namesakeMourned(c, p))) &&
              RoleMatcher.matches(slot, p, c))
            p,
      ];
      if (candidates.isEmpty) return null;
      bound[slot.name] = _pickPerson(candidates, now, random).id;
    }
    return bound;
  }

  /// Ucu yüksek ilişkiler (çok yakın ya da husumetli) iki kat ağırlıkla
  /// seçilir.
  static Person _pickPerson(List<Person> candidates, int now, Random random) {
    final weights = [
      for (final p in candidates)
        Relationships.closeness(p, now) >= 70 ||
                Relationships.hostility(p, now) >= 50
            ? 2
            : 1,
    ];
    final total = weights.fold(0, (s, w) => s + w);
    var roll = random.nextInt(total);
    for (var i = 0; i < candidates.length; i++) {
      roll -= weights[i];
      if (roll < 0) return candidates[i];
    }
    return candidates.last;
  }

  /// Bu yılın dönemeçleri: şartı sağlanan ve rolleri bağlanabilen her
  /// dönemeç, kimlik sırasıyla.
  List<PendingEvent> milestones(
    Character c,
    Random random, {
    Set<String> busy = const {},
  }) {
    final out = <PendingEvent>[];
    final taken = {...busy};
    final sorted = cards.where((card) => card.mandatory).toList()
      ..sort((a, b) => a.id.compareTo(b.id));
    for (final card in sorted) {
      if (!isEligible(card, c)) continue;
      final people = bind(card, c, random, busy: taken);
      if (people == null) continue;
      taken.addAll(people.values);
      out.add(PendingEvent(card, Map.unmodifiable(people)));
    }
    return out;
  }

  /// Bu yılın rastgele olayları: en fazla [count] tane, ağırlıklı.
  ///
  /// [themes] bu yıl zaten gelmiş (dönemeç dışı) temalar; aynı tema ikinci
  /// kez gelmez. Tesadüf yılda en fazla bir kez gelir. [exclude] bu yıl
  /// zaten gelen kartlar, [busy] bu yıl olaya çıkmış kişiler.
  List<PendingEvent> draw(
    Character c,
    Random random, {
    required int count,
    Set<String> exclude = const {},
    Set<EventTheme> themes = const {},
    Set<String> busy = const {},
  }) {
    if (count <= 0) return const [];
    final pool = [
      for (final card in cards)
        if (!card.mandatory &&
            !exclude.contains(card.id) &&
            !themes.contains(card.theme) &&
            isEligible(card, c))
          card,
    ];
    final drawn = <PendingEvent>[];
    final usedThemes = {...themes};
    final taken = {...busy};
    var chanceUsed = false;
    while (drawn.length < count && pool.isNotEmpty) {
      final card = pool.removeAt(_weightedIndex(pool, c, random));
      if (usedThemes.contains(card.theme)) continue;
      if (card.type == EventType.tesaduf && chanceUsed) continue;
      final people = bind(card, c, random, busy: taken);
      if (people == null) continue;
      drawn.add(PendingEvent(card, Map.unmodifiable(people)));
      usedThemes.add(card.theme);
      taken.addAll(people.values);
      if (card.type == EventType.tesaduf) chanceUsed = true;
    }
    return drawn;
  }

  static int _weightedIndex(List<EventCard> pool, Character c, Random random) {
    final weights = [for (final card in pool) drawWeight(card, c)];
    final total = weights.fold(0.0, (sum, w) => sum + w);
    var target = random.nextDouble() * total;
    for (var i = 0; i < pool.length; i++) {
      target -= weights[i];
      if (target < 0) return i;
    }
    return pool.length - 1;
  }
}
