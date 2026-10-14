import 'package:bir_omur/content/disk_content_source.dart';

import 'package:bir_omur/content/content_loader.dart';
import 'package:bir_omur/engine/engine.dart';
import 'package:bir_omur/models/models.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/simulation.dart';

/// `assets/` altındaki gerçek içerik. Testler proje kökünden çalışır.
GameContent loadRealContent() => loadContentFromDisk();

void main() {
  final content = loadRealContent();
  final deck = content.deck;

  test('kart dosyaları hatasız ve uyarısız', () {
    expect(content.warnings, isEmpty, reason: content.warnings.join('\n'));
  });

  test('en az 40 kart, her evrede en az 3 kart', () {
    expect(deck.cards.length, greaterThanOrEqualTo(40));
    for (final stage in LifeStage.values) {
      expect(
        deck.cards.where((c) => c.stage == stage).length,
        greaterThanOrEqualTo(3),
        reason: stage.id,
      );
    }
  });

  test('MVP meslekleri var ve her birine giriş kartı var', () {
    for (final id in ['memur', 'esnaf', 'plaza']) {
      final career = content.careers.byId(id);
      expect(career, isNotNull, reason: id);
      expect(career!.maxTier, 5, reason: id);
      final entry = deck.cards.where(
        (card) => card.choices.any(
          (choice) => choice.allEffects.any(
            (e) =>
                e.career is JoinCareer &&
                (e.career as JoinCareer).careerId == id,
          ),
        ),
      );
      expect(entry, isNotEmpty, reason: '$id için giriş kartı yok');
    }
  });

  test('GDD referans kartları var', () {
    const ids = [
      'isim_koyma',
      'karne_gunu',
      'lgs_kursu',
      'tercih_zamani',
      'askerlik_zamani',
      'kira_zammi_01',
      'isteme_gunu',
      'dugun_takilari',
      'komsu_borc_istedi',
      'borc_geldi_mi',
      'torun_story',
    ];
    for (final id in ids) {
      expect(deck.byId(id), isNotNull, reason: id);
    }
  });

  test('zor dönem kartları motor bayraklarına bağlı ve zorunlu', () {
    for (final flag in EngineFlags.all) {
      final support = deck.cards.where(
        (c) => c.mandatory && c.conditions.flags.contains(flag),
      );
      expect(support, isNotEmpty, reason: '$flag için destek kartı yok');
    }
  });

  group('gerçek kartlarla simülasyon', () {
    late List<LifeState> lives;
    setUpAll(
      () => lives = [
        for (var seed = 0; seed < 100; seed++)
          simulateLife(deck, seed, careers: content.careers),
      ],
    );

    test('100 hayat çökmeden ve sonlu biter', () {
      final ages = lives.map((l) => l.summary!.deathAge).toList()..sort();
      final mean = ages.reduce((a, b) => a + b) / ages.length;
      printOnFailure('ölüm yaşları: $ages');
      expect(mean, inInclusiveRange(50, 95));
    });

    test('kartların büyük çoğunluğu en az bir hayatta görülür', () {
      final seen = {
        for (final life in lives)
          for (final record in life.character.history) record.cardId,
      };
      final unseen = deck.cards
          .map((c) => c.id)
          .where((id) => !seen.contains(id))
          .toList();
      printOnFailure('hiç görülmeyen kartlar: $unseen');
      expect(unseen.length, lessThanOrEqualTo(4), reason: '$unseen');
    });
  });
}
