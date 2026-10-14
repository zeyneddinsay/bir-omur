import '../models/models.dart';
import 'death_check.dart';
import 'summary_builder.dart';

/// Biten bir hayatın kalıcı kaydı. Hayat Albümü (F2) bunların üzerine
/// kurulur; kart dosyaları değişse de okunabilsin diye yalnızca kimlik ve
/// sayı tutar, kart metni tutmaz.
class LifeRecord {
  const LifeRecord({
    required this.name,
    required this.gender,
    required this.hometown,
    required this.team,
    required this.background,
    required this.deathAge,
    required this.cause,
    required this.nickname,
    required this.netWorth,
    required this.cardsSeen,
    required this.seed,
    required this.endedAt,
    this.careerId,
    this.careerTier,
    this.biggestMomentCardId,
    this.counters = LifeCounters.zero,
  });

  final String name;
  final String gender;
  final String hometown;
  final String team;
  final String background;
  final int deathAge;
  final String cause;
  final String nickname;
  final int netWorth;
  final int cardsSeen;
  final int seed;

  /// Gerçek takvim zamanı; albümü sıralamak için.
  final DateTime endedAt;

  /// Son iş; hiç çalışmadıysa null.
  final String? careerId;
  final int? careerTier;
  final String? biggestMomentCardId;

  /// Hayatın sayıları (taşınma, kira, altın, terfi…).
  final LifeCounters counters;

  factory LifeRecord.fromSummary(
    LifeSummary summary, {
    required int seed,
    required DateTime endedAt,
    String? careerId,
    int? careerTier,
  }) {
    final c = summary.character;
    return LifeRecord(
      name: c.name,
      gender: c.gender.id,
      hometown: c.hometown,
      team: c.team,
      background: c.background.id,
      deathAge: summary.deathAge,
      cause: summary.cause.name,
      nickname: summary.nickname.name,
      netWorth: summary.netWorth,
      cardsSeen: summary.cardsSeen,
      seed: seed,
      endedAt: endedAt,
      careerId: careerId,
      careerTier: careerTier,
      biggestMomentCardId: summary.biggestMoment?.cardId,
      counters: c.counters,
    );
  }

  /// Motor sürümü değişip ad tanınmazsa null döner.
  Nickname? get nicknameValue => Nickname.values.asNameMap()[nickname];
  DeathCause? get causeValue => DeathCause.values.asNameMap()[cause];

  Map<String, Object?> toJson() => {
    'name': name,
    'gender': gender,
    'hometown': hometown,
    'team': team,
    'background': background,
    'deathAge': deathAge,
    'cause': cause,
    'nickname': nickname,
    'netWorth': netWorth,
    'cardsSeen': cardsSeen,
    'seed': seed,
    'endedAt': endedAt.toIso8601String(),
    'career': careerId,
    'tier': careerTier,
    'moment': biggestMomentCardId,
    'counters': counters.toJson(),
  };

  factory LifeRecord.fromJson(Map<String, dynamic> json) => LifeRecord(
    name: json['name'] as String,
    gender: json['gender'] as String,
    hometown: json['hometown'] as String,
    team: json['team'] as String,
    background: json['background'] as String? ?? 'orta',
    deathAge: json['deathAge'] as int,
    cause: json['cause'] as String,
    nickname: json['nickname'] as String,
    netWorth: json['netWorth'] as int,
    cardsSeen: json['cardsSeen'] as int,
    seed: json['seed'] as int,
    endedAt: DateTime.parse(json['endedAt'] as String),
    careerId: json['career'] as String?,
    careerTier: json['tier'] as int?,
    biggestMomentCardId: json['moment'] as String?,
    counters: LifeCounters.fromJson(json['counters'] as Map<String, dynamic>?),
  );
}
