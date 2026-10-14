import '../models/models.dart';
import 'death_check.dart';
import 'economy.dart';
import 'event_deck.dart';

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

  /// Hayattaki en nadir kart; nadir ya da efsane kart görülmediyse null.
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

  /// "Mahallenin Zengini" için net servet eşiği (TL). Bir ev tek başına
  /// 1,5 milyon ettiği için ev sahibi olmak yetmez.
  static const int richThreshold = 5000000;

  /// Lakap kurallarının baktığı bayraklar; card_lint kayıtta olduklarını
  /// denetler.
  static const Set<String> referencedFlags = {soldierFlag};

  /// Kurallar öncelik sırasıyla denenir; ilk tutan lakap olur.
  static Nickname nicknameFor(Character c, Market market) {
    final s = c.stats;
    final worth = Economy.netWorth(c, market);
    if (c.age >= 95) return Nickname.asirlikCinar;
    if (worth >= richThreshold) return Nickname.mahalleninZengini;
    if (c.assets.houses > 0) return Nickname.evSahibi;
    if (s.reputation >= 80) return Nickname.sozuDinlenen;
    if (s.family >= 80) return Nickname.bayramlarinBasKosesi;
    if (s.knowledge >= 80) return Nickname.mahalleninProfesoru;
    if (s.happiness >= 80) return Nickname.hepGulen;
    if (worth < 0) return Nickname.borcYigidinKamcisi;
    if (c.hasFlag(soldierFlag)) return Nickname.bizimBolukte;
    return Nickname.mahalleninBildikYuzu;
  }

  /// En nadir kart; eşitlikte ilk görülen.
  CardRecord? _biggestMoment(Character c) {
    CardRecord? best;
    var bestWeight = Rarity.siradan.weight;
    for (final record in c.history) {
      final weight = deck.byId(record.cardId)?.rarity.weight;
      if (weight != null && weight < bestWeight) {
        best = record;
        bestWeight = weight;
      }
    }
    return best;
  }
}
