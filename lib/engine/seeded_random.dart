import 'dart:math';

/// Durumu kaydedilebilen tohumlu rastgelelik (splitmix64).
///
/// `dart:math` içindeki `Random(seed)` iç durumunu dışarı vermez; yarıda
/// kaydedilen bir hayat yüklendiğinde rastgelelik aynı yerden devam
/// edemezdi. Bu sınıfın bütün durumu tek bir 64 bitlik sayıdır: [state]
/// kaydedilir, [SeededRandom.fromState] ile kaldığı yerden sürer.
///
/// Mobil (Dart VM) hedefler için yazılmıştır; tam sayılar 64 bit ve taşma
/// sarmalanır. Web'de çalışmaz.
class SeededRandom implements Random {
  SeededRandom(int seed) : _state = seed;

  SeededRandom.fromState(int state) : _state = state;

  int _state;

  int get state => _state;

  static const int _gamma = 0x9E3779B97F4A7C15;
  static const double _twoPow53 = 9007199254740992.0;

  /// Sonraki 64 bitlik değer.
  int _next() {
    _state += _gamma;
    var z = _state;
    z = (z ^ (z >>> 30)) * 0xBF58476D1CE4E5B9;
    z = (z ^ (z >>> 27)) * 0x94D049BB133111EB;
    return z ^ (z >>> 31);
  }

  /// 53 bitlik eşit dağılımlı sayı (0 ≤ x < 2^53).
  int _next53() => _next() >>> 11;

  @override
  int nextInt(int max) {
    if (max <= 0 || max > (1 << 32)) {
      throw RangeError.range(max, 1, 1 << 32, 'max');
    }
    // Reddetme örneklemesi: üst sınır 2^53'ü tam bölmediğinde oluşan
    // küçük kaymayı önler.
    final limit = (1 << 53) - (1 << 53) % max;
    while (true) {
      final x = _next53();
      if (x < limit) return x % max;
    }
  }

  @override
  double nextDouble() => _next53() / _twoPow53;

  @override
  bool nextBool() => _next() < 0;
}
