import 'package:bir_omur/content/content_loader.dart';
import 'package:bir_omur/content/disk_content_source.dart';
import 'package:bir_omur/engine/engine.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/simulation.dart';

/// `assets/` altındaki gerçek içerik. Testler proje kökünden çalışır.
GameContent loadRealContent() => loadContentFromDisk();

void main() {
  final content = loadRealContent();
  final deck = content.deck;

  test('içerik dosyaları hatasız ve uyarısız', () {
    expect(content.warnings, isEmpty, reason: content.warnings.join('\n'));
  });

  test('MVP meslekleri var', () {
    for (final id in ['memur', 'esnaf', 'plaza']) {
      final career = content.careers.byId(id);
      expect(career, isNotNull, reason: id);
      expect(career!.maxTier, 5, reason: id);
    }
  });

  group('gerçek içerikle simülasyon', () {
    late List<LifeState> lives;
    setUpAll(
      () => lives = [
        for (var seed = 0; seed < 100; seed++)
          simulateLife(
            deck,
            seed,
            careers: content.careers,
            families: content.families,
          ),
      ],
    );

    test('100 hayat çökmeden ve sonlu biter', () {
      final ages = lives.map((l) => l.summary!.deathAge).toList()..sort();
      final mean = ages.reduce((a, b) => a + b) / ages.length;
      printOnFailure('ölüm yaşları: $ages');
      expect(mean, inInclusiveRange(50, 95));
    });
  });
}
