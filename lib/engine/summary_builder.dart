import '../models/models.dart';
import 'death_check.dart';
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
    this.biggestMoment,
  });

  final Character character;
  final DeathCause cause;
  final Nickname nickname;
  final int cardsSeen;

  /// Hayattaki en nadir kart; nadir ya da efsane kart görülmediyse null.
  final CardRecord? biggestMoment;

  int get deathAge => character.age;
}

class SummaryBuilder {
  const SummaryBuilder(this.deck);

  final EventDeck deck;

  LifeSummary build(Character character, DeathCause cause) {
    return LifeSummary(
      character: character,
      cause: cause,
      nickname: nicknameFor(character),
      cardsSeen: character.history.length,
      biggestMoment: _biggestMoment(character),
    );
  }

  static const String homeOwnerFlag = 'ev_sahibi';
  static const String soldierFlag = 'asker_anilari';

  /// Lakap kurallarının baktığı bayraklar; card_lint kayıtta olduklarını
  /// denetler.
  static const Set<String> referencedFlags = {homeOwnerFlag, soldierFlag};

  /// Kurallar öncelik sırasıyla denenir; ilk tutan lakap olur.
  static Nickname nicknameFor(Character c) {
    final s = c.stats;
    if (c.age >= 95) return Nickname.asirlikCinar;
    if (s.money >= 1000000) return Nickname.mahalleninZengini;
    if (c.hasFlag(homeOwnerFlag)) return Nickname.evSahibi;
    if (s.reputation >= 80) return Nickname.sozuDinlenen;
    if (s.family >= 80) return Nickname.bayramlarinBasKosesi;
    if (s.knowledge >= 80) return Nickname.mahalleninProfesoru;
    if (s.happiness >= 80) return Nickname.hepGulen;
    if (s.money < 0) return Nickname.borcYigidinKamcisi;
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
