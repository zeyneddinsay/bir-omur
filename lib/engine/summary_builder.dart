import '../models/models.dart';
import 'death_check.dart';
import 'economy.dart';
import 'event_deck.dart';
import 'hard_day.dart';
import 'life_story.dart';

/// Mahallenin karakteri nasıl hatırladığı. Metni arayüzde ARB'den gelir.
enum Nickname {
  asirlikCinar,
  mahalleninZengini,
  evSahibi,
  sozuDinlenen,
  bayramlarinBasKosesi,
  mahalleninProfesoru,
  hepGulen,
  borcYigidinKamcisi,
  bizimBolukte,

  /// Bir işletmeyi 10 yıl yaşattı ya da 3 şubeye çıkardı.
  patron,

  /// Akraba olmayan en az 8 yakın tanıdığı vardı.
  herkesinDostu,

  /// Üç ya da daha fazla şehirde yaşadı.
  gurbetciRuhlu,
  mahalleninBildikYuzu,
}

/// Ölümde gösterilen basit hayat özeti.
class LifeSummary {
  const LifeSummary({
    required this.character,
    required this.cause,
    required this.nickname,
    required this.cardsSeen,
    required this.netWorth,
    this.biggestMoment,
  });

  final Character character;
  final DeathCause cause;
  final Nickname nickname;
  final int cardsSeen;

  /// Nakit, altın, ev ve arabanın toplamından kalan kredi borcu düşülmüş hâli.
  final int netWorth;

  /// Hayatın en büyük anı (bkz. SummaryBuilder); hiç olay yoksa null.
  final CardRecord? biggestMoment;

  int get deathAge => character.age;
}

class SummaryBuilder {
  const SummaryBuilder(this.deck);

  final EventDeck deck;

  LifeSummary build(Character character, DeathCause cause, Market market) {
    return LifeSummary(
      character: character,
      cause: cause,
      nickname: nicknameFor(character, market),
      cardsSeen: character.history.length,
      netWorth: Economy.netWorth(character, market),
      biggestMoment: _biggestMoment(character),
    );
  }

  static const String soldierFlag = 'asker_anilari';

  /// "Mahallenin Zengini" için net servet eşiği (2026 TL). Bir ev tek
  /// başına 5 milyon ettiği için ev sahibi olmak yetmez.
  static const int richThreshold = 33000000;

  /// Lakap kurallarının baktığı bayraklar; card_lint kayıtta olduklarını
  /// denetler.
  static const Set<String> referencedFlags = {soldierFlag};

  /// Göstergeye bağlı lakapların eşiği.
  static const int statThreshold = 80;

  /// Ev sahipliği ve askerlik anıları, eşiği bu kadar aşmış bir gösterge
  /// gibi sayılır: başka belirgin bir özellik yoksa lakap onlardan gelir.
  static const int homeOwnerScore = 5;

  /// Mahalle seni sözünle hatırlar: itibar eşiği aştığında aşılan puan bu
  /// kadar kat sayılır.
  static const int reputationWeight = 2;

  /// İtibar her yıl ortaya kaydığı için lakap eşiği daha düşük.
  static const int reputationThreshold = 70;
  static const int soldierScore = 3;
  static const int bossScore = 8;
  static const int friendScore = 15;
  static const int movesScore = 12;

  /// Önce özel durumlar (asırlık, zengin, borçlu); sonra en belirgin özellik
  /// kazanır: her aday için eşiğin ne kadar aşıldığına bakılır, en büyüğü
  /// seçilir. Eşitlikte listedeki sıra geçerlidir.
  static Nickname nicknameFor(Character c, Market market) {
    final s = c.stats;
    final story = LifeStory(c);
    final worth = Economy.netWorth(c, market);
    if (c.age >= 100) return Nickname.asirlikCinar;
    if (worth >= richThreshold) return Nickname.mahalleninZengini;
    if (worth < 0) return Nickname.borcYigidinKamcisi;

    final candidates = <(Nickname, int)>[
      (
        Nickname.sozuDinlenen,
        (s.reputation - reputationThreshold) * reputationWeight,
      ),
      (Nickname.bayramlarinBasKosesi, s.family - statThreshold),
      (Nickname.mahalleninProfesoru, s.knowledge - statThreshold),
      (Nickname.hepGulen, s.happiness - statThreshold),
      if (c.assets.houses > 0) (Nickname.evSahibi, homeOwnerScore),
      if (c.hasFlag(soldierFlag)) (Nickname.bizimBolukte, soldierScore),
      if (story.boss) (Nickname.patron, bossScore),
      if (story.everyonesFriend) (Nickname.herkesinDostu, friendScore),
      if (c.counters.moves >= 2) (Nickname.gurbetciRuhlu, movesScore),
    ];
    var best = Nickname.mahalleninBildikYuzu;
    var bestScore = -1;
    for (final (nickname, score) in candidates) {
      if (score > bestScore) {
        best = nickname;
        bestScore = score;
      }
    }
    return best;
  }

  /// Hayatın en büyük anı: dönüm noktalarının puanı ([momentScores]) artı
  /// nadirlik; eşitlikte sonraki. Cenazeler ve zor gün araması sayılmaz.
  CardRecord? _biggestMoment(Character c) {
    CardRecord? best;
    var bestScore = 0;
    final seen = <String>{};
    for (final record in c.history) {
      final card = deck.byId(record.cardId);
      if (card == null) continue;
      final first = seen.add(card.id);
      final mourning = card.roles.any((slot) => slot.deceased);
      if (mourning || card.id == HardDay.callCard) continue;
      var score = momentScores[card.id] ?? 0;
      // Bebek ve benzeri tekrar eden anlarda ilki sayılır.
      if (!first) score ~/= 2;
      score += switch (card.rarity) {
        Rarity.efsane => 8,
        Rarity.nadir => 3,
        Rarity.siradan => 0,
      };
      if (card.type == EventType.donemec || card.type == EventType.iplik) {
        score += 1;
      }
      if (score >= bestScore && score > 0) {
        best = record;
        bestScore = score;
      }
    }
    return best;
  }

  /// Hayatın dönüm noktaları: en büyük an seçilirken öne çıkar.
  static const Map<String, int> momentScores = {
    'dugun': 12,
    'bebek_dogdu': 10,
    'girisim_sonucu': 9,
    'fabrikanin_kapisi': 8,
    'teneffus_yillar_sonra': 8,
    'kiz_isteme_damat': 7,
    'kiz_isteme_gelin': 7,
    'aile_tanisma_yemegi': 7,
    'mezuniyet': 6,
    'komsu_genci_doner': 6,
    'kopya_tesekkuru': 6,
    'el_yapimi_kutu': 6,
    'cam_hikayesi': 5,
    'askerlik_celbi': 5,
    'anneye_kim_bakacak': 5,
    'yks': 4,
    'lgs': 3,
    'ilkokul_ilk_gun': 2,
  };
}
