import '../models/models.dart';

/// Motorun kendisinin açıp kapattığı bayraklar. Kartlar bunlara koşul
/// olarak bakabilir (örnek: zor dönem destek kartları).
abstract final class EngineFlags {
  /// Mutluluk 0'a düştü; [bunalimExit] değerine çıkana kadar sürer.
  static const String bunalim = 'bunalim';

  /// Para 0 ya da altına düştü; para yeniden artıya geçene kadar sürer.
  static const String borclu = 'borclu';

  static const Set<String> all = {bunalim, borclu};

  static const int bunalimExit = 30;

  /// Zor dönem bayrakları bu yaştan itibaren açılır; çocukların parası
  /// zaten yoktur.
  static const int hardshipMinAge = 19;
}

/// Yaşlanma: yaş 1 artar ve pasif değişimler uygulanır.
///
/// Gençlikte hafif sağlık toparlanması, yaşa bağlı sağlık kaybı ve
/// yetişkinlikte aile bağının yavaşça soğuması. Gelir [CareerTick],
/// enflasyon, kira ve kredi [EconomyTick] içindedir.
class YearTick {
  const YearTick();

  Character apply(Character character) {
    final age = character.age + 1;
    var stats = character.stats.withDelta(
      StatKind.health,
      yearlyHealthChange(age),
    );
    if (age >= EngineFlags.hardshipMinAge) {
      stats = stats.withDelta(StatKind.family, -1);
    }
    return updateHardshipFlags(character.copyWith(age: age, stats: stats));
  }

  /// Gençken beden küçük yaraları kendi sarar; 50'den sonra yaşlanma
  /// sağlığı yavaşça düşürür.
  static int yearlyHealthChange(int age) {
    if (age >= 80) return -3;
    if (age >= 65) return -2;
    if (age >= 50) return -1;
    if (age < 40) return 1;
    return 0;
  }

  /// Zor dönem bayraklarını göstergelere göre açar ya da kapatır. Kart
  /// seçimlerinden sonra da çağrılır.
  static Character updateHardshipFlags(Character character) {
    if (character.age < EngineFlags.hardshipMinAge) return character;
    final flags = {...character.flags};
    final stats = character.stats;

    if (stats.happiness <= 0) {
      flags.add(EngineFlags.bunalim);
    } else if (stats.happiness >= EngineFlags.bunalimExit) {
      flags.remove(EngineFlags.bunalim);
    }

    if (stats.money <= 0) {
      flags.add(EngineFlags.borclu);
    } else {
      flags.remove(EngineFlags.borclu);
    }

    if (flags.length == character.flags.length &&
        flags.containsAll(character.flags)) {
      return character;
    }
    return character.copyWith(flags: flags);
  }
}
