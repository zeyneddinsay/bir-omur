import 'package:bir_omur/engine/engine.dart';
import 'package:flutter_test/flutter_test.dart';

List<int> _draw(SeededRandom r, int n) => [
  for (var i = 0; i < n; i++) r.nextInt(1000),
];

void main() {
  test('aynı tohum aynı diziyi üretir, farklı tohum farklı', () {
    expect(_draw(SeededRandom(42), 50), _draw(SeededRandom(42), 50));
    expect(_draw(SeededRandom(42), 50), isNot(_draw(SeededRandom(43), 50)));
  });

  test('kaydedilen durumdan dizi kaldığı yerden sürer', () {
    final a = SeededRandom(2026);
    _draw(a, 37);
    final b = SeededRandom.fromState(a.state);
    expect(_draw(b, 100), _draw(a, 100));
  });

  test('splitmix64 referans değeri tutar', () {
    // Tohum 0 için ilk 64 bitlik çıktı 0xE220A8397B1DCDAF olmalı.
    expect(
      SeededRandom(0).nextDouble(),
      (0xE220A8397B1DCDAF >>> 11) / 9007199254740992.0,
    );
  });

  test('bilinen ilk değerler sabit kalır', () {
    // Bu değerler değişirse eski kayıtlar ve tohumlar başka hayat üretir.
    final r = SeededRandom(1);
    expect(_draw(r, 5), [651, 29, 442, 41, 902]);
  });

  test('nextInt sınırların içinde ve kabaca eşit dağılır', () {
    final r = SeededRandom(7);
    final counts = List.filled(6, 0);
    for (var i = 0; i < 60000; i++) {
      counts[r.nextInt(6)]++;
    }
    for (final c in counts) {
      expect(c, inInclusiveRange(9500, 10500));
    }
    expect(SeededRandom(1).nextInt(1), 0);
  });

  test('nextDouble 0 ile 1 arasında', () {
    final r = SeededRandom(9);
    for (var i = 0; i < 10000; i++) {
      expect(r.nextDouble(), allOf(greaterThanOrEqualTo(0), lessThan(1)));
    }
  });

  test('geçersiz üst sınır reddedilir', () {
    expect(() => SeededRandom(1).nextInt(0), throwsRangeError);
  });
}
