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

  /// Aynı yıl gelebilecek arama olayı (dönemeçlere yer kalsın diye 2).
  static const int maxCallers = 2;

  /// "Dipten Döndü": en az bir kez borca düşmüş oyuncunun net serveti bu
  /// tutara ulaşınca açılan motor bayrağı.
  static const String comebackFlag = 'dipten_dondu';
  static const int comebackWorth = 10000000;

  /// Borç zor günü: net servet bu değerin altına inince (küçük eksiler
  /// sayılmaz).
  static const int debtThreshold = -100000;

  /// Akraba olmayanın vefatı bu yakınlıktan itibaren zor gündür.
  static const int griefCloseness = 80;

  /// "Aramadı" anısı yalnızca bu yakınlıktaki arkadaşlara, ve aynı kişiye
  /// bu kadar yılda bir.
  static const int missedMinCloseness = 40;
  static const int missedRepeatYears = 5;

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
      // Çekirdek aile; akraba olmayan çok yakın biri. Dede, nine ve uzak
      // akraba cenazesi zor gün sayılmaz.
      if (core.contains(p.kin) ||
          (p.kin == null &&
              Relationships.closeness(p, after.age) >= griefCloseness)) {
        return (HardDayCause.vefat, id);
      }
    }
    // Borç: öğrenci ve aileyle yaşayan sayılmaz; küçük eksiler sayılmaz.
    final dependent =
        after.hasFlag('universite_ogrencisi') || after.home == HomeKind.aile;
    if (!dependent && worthBefore >= 0 && worthAfter < debtThreshold) {
      return (HardDayCause.borc, null);
    }
    if (!before.hasFlag('bunalim') && after.hasFlag('bunalim')) {
      return (HardDayCause.bunalim, null);
    }
    return null;
  }

  /// Aramak isteyenler: sevenler arar (yakınlık), vefalılar daha çok; para
  /// derdinde çıkarcılar aramaz. Aynı evdekiler zaten yanındadır. En
  /// yakından başlayarak sıralı; olay olarak ilk [maxCallers] gelir, öteki
  /// arayanlar "aramadı" sayılmaz.
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
    return picked;
  }

  /// Arkadaşın (akraba olmayan, arkadaş ya da yakın arkadaş bağıyla) olup
  /// aramayanlara "Zor günümde aramadı" anısı yazılır.
  static Character markMissed(Character c, Set<String> callerIds) {
    var book = c.people;
    for (final p in c.people.active(c.age)) {
      if (!p.isAlive || p.kin != null || callerIds.contains(p.id)) continue;
      if (p.bond != Bond.arkadas && p.bond != Bond.yakinArkadas) continue;
      if (PeopleTick.livesTogether(c, p)) continue;
      if (Relationships.closeness(p, c.age) < missedMinCloseness) continue;
      final recent = p.memories.any(
        (m) => m.kind == missedMemory && c.age - m.age < missedRepeatYears,
      );
      if (recent) continue;
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
