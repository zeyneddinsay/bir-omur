import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('ARB dosyasında tekrar eden anahtar yok', () {
    final lines = File('lib/l10n/app_tr.arb').readAsLinesSync();
    final key = RegExp(r'^\s*"([^"]+)"\s*:');
    final seen = <String>{};
    final repeated = <String>[];
    for (final line in lines) {
      final m = key.firstMatch(line);
      if (m == null) continue;
      // Yalnızca en üst düzey anahtarlar (iki boşluk girintili).
      if (!line.startsWith('  "') || line.startsWith('   ')) continue;
      if (!seen.add(m.group(1)!)) repeated.add(m.group(1)!);
    }
    expect(repeated, isEmpty);
  });
}
