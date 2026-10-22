import 'dart:math';

import '../models/models.dart';
import 'people_tick.dart';
import 'relationships.dart';

/// Zor gün yılını başlatan olay (canlı doküman, "Dünyanın tepkisi").
enum HardDayCause {
  /// Net servet 0'ın altına düştü.
  borc,
  kovuldun,

  /// İşletme battı.
  iflas,

  /// Yakın biri vefat etti.
  vefat,

  /// Mutluluk 0'a düştü.
  bunalim,
}

/// Zor gün testi: kimin arayıp kimin aramadığı unutulmaz.
///
/// Zor gün yılında seni arayan her kişi (en fazla 3) için kısa bir olay
/// gelir ([callCard]); aramayı açıp dertleşirsen o kişi "gerçek dost" olur.
/// Arkadaşın olup aramayanlara "Zor günümde aramadı" anısı yazılır; bu anı
/// sonradan olaylara döner.
abstract final class HardDay {
  /// Zor gün yılı boyunca açık kalan motor bayrağı.
  static const String flag = 'zor_gun';

  /// Arayan kişinin olayı (iplik; motor planlar, `arayan` yuvasıyla).
  static const String callCard = 'zor_gun_aradi';
  static const String callerSlot = 'arayan';

  /// Anı türleri.
  static const String talkedMemory = 'zor_gunde_dertlesti';
  static const String missedMemory = 'zor_gunde_aramadi';

  static const int maxCallers = 3;

  /// Çekirdek aile: vefatları her zaman zor gündür, aramaları beklenir.
  static const Set<Kinship> core = {
    Kinship.anne,
    Kinship.baba,
    Kinship.kardes,
    Kinship.es,
    Kinship.cocuk,
  };

  /// Yılın sebebi; yoksa null. [before] yaşlanmadan önceki, [after] yılın
  /// sonundaki karakter; servetler aynı piyasayla hesaplanmış olmalı.
  static (HardDayCause, String?)? causeOf({
    required Character before,
    required Character after,
    required int worthBefore,
    required int worthAfter,
    required bool fired,
    required bool bankrupt,
    required Iterable<String> deaths,
  }) {
    if (after.age < 19) return null;
    if (bankrupt) return (HardDayCause.iflas, null);
    if (fired) return (HardDayCause.kovuldun, null);
    for (final id in deaths) {
      final p = after.people[id];
      if (p == null) continue;
      if (core.contains(p.kin) || Relationships.closeness(p, after.age) >= 60) {
        return (HardDayCause.vefat, id);
      }
    }
    if (worthBefore >= 0 && worthAfter < 0) return (HardDayCause.borc, null);
    if (!before.hasFlag('bunalim') && after.hasFlag('bunalim')) {
      return (HardDayCause.bunalim, null);
    }
    return null;
  }

  /// Arayanlar: sevenler arar (yakınlık), vefalılar daha çok; para
  /// derdinde çıkarcılar aramaz. Aynı evdekiler zaten yanındadır.
  static List<Person> callers(Character c, Random random, HardDayCause cause) {
    final picked = <Person>[];
    for (final p in c.people.active(c.age)) {
      if (!p.isAlive || p.ageAt(c.age) < 12) continue;
      if (PeopleTick.livesTogether(c, p)) continue;
      final closeness = Relationships.closeness(p, c.age);
      if (closeness < 40) continue;
      var chance = closeness / 100;
      if (p.hasTrait(Trait.vefali)) chance *= 1.4;
      if (p.hasTrait(Trait.cikarci) &&
          (cause == HardDayCause.borc || cause == HardDayCause.iflas)) {
        chance *= 0.2;
      }
      if (random.nextDouble() < chance) picked.add(p);
    }
    picked.sort(
      (a, b) => Relationships.closeness(
        b,
        c.age,
      ).compareTo(Relationships.closeness(a, c.age)),
    );
    return picked.take(maxCallers).toList();
  }

  /// Arkadaşın (akraba olmayan, arkadaş ya da yakın arkadaş bağıyla) olup
  /// aramayanlara "Zor günümde aramadı" anısı yazılır.
  static Character markMissed(Character c, Set<String> callerIds) {
    var book = c.people;
    for (final p in c.people.active(c.age)) {
      if (!p.isAlive || p.kin != null || callerIds.contains(p.id)) continue;
      if (p.bond != Bond.arkadas && p.bond != Bond.yakinArkadas) continue;
      if (PeopleTick.livesTogether(c, p)) continue;
      book = book.update(
        Relationships.addMemory(
          p,
          Memory(
            kind: missedMemory,
            label: 'Zor günümde aramadı',
            age: c.age,
            tone: MemoryTone.olumsuz,
            severity: 2,
            owner: MemoryOwner.oyuncu,
          ),
          now: c.age,
        ),
      );
    }
    return c.copyWith(people: book);
  }

  /// Zor günde arayıp dertleştiğin kişiler: hayat özetinin "gerçek
  /// dost"ları.
  static List<Person> trueFriends(Character c) => [
    for (final p in c.people.all)
      if (p.memories.any((m) => m.kind == talkedMemory)) p,
  ];
}
