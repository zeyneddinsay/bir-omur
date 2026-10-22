import 'dart:math';

import '../models/models.dart';

enum DeathCause {
  /// Sağlık 0'a düştü.
  health,

  /// Yaşa ve sağlığa bağlı ihtimal gerçekleşti.
  natural,
}

/// Yıl sonunda ölüm kontrolü. Yalnızca Sağlık 0 ya da yaşa bağlı ihtimal
/// ölüm getirir; Mutluluk ve Para hiçbir zaman öldürmez.
class DeathCheck {
  const DeathCheck(this.random);

  final Random random;

  /// Bu yaşta herkes ölür; sonsuz hayatı engelleyen sigortadır.
  static const int maxAge = 120;

  /// Yaşa bağlı ölüm ihtimali bu yaştan önce sıfırdır.
  static const int adultAge = 18;

  DeathCause? check(Character character) {
    if (character.stats.health <= 0) return DeathCause.health;
    if (random.nextDouble() < probability(character)) return DeathCause.natural;
    return null;
  }

  /// Bir yıl içinde doğal yoldan ölme ihtimali (0–1).
  static double probability(Character character) {
    final age = character.age;
    if (age >= maxAge) return 1;
    // Çocuklar ve gençler yaşa bağlı ihtimalle ölmez; oyunun tonu bunu
    // kaldırmaz. Sağlık 0'a düşerse [check] yine ölüm verir.
    if (age < adultAge) return 0;
    // Askerdeki yıl da öyle: askerde ölüm oyunda yer almaz.
    if (character.hasFlag('askerde')) return 0;
    final health = character.stats.health;
    final lowHealth = health < 20 ? 0.1 * (20 - health) / 20 : 0.0;
    return min(1, _ageBase(age) + lowHealth);
  }

  static double _ageBase(int age) {
    if (age < 50) return 0.0005;
    if (age < 65) return 0.004;
    if (age < 75) return 0.015;
    if (age < 85) return 0.05;
    if (age < 95) return 0.12;
    if (age < 105) return 0.25;
    return 0.4;
  }
}
