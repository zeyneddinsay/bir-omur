import 'card.dart';
import 'effect.dart';
import 'json_reader.dart';

/// Bir meslek: giriş şartları, ilanları, mülakat soruları, kademeleri ve
/// terfi şartları. İçerik olarak `assets/careers/<id>.json` dosyasından gelir
/// (canlı doküman, "Çalışma hayatı").
class Career {
  const Career({
    required this.id,
    required this.name,
    required this.tiers,
    this.incomeVariance = 0,
    this.entry = const JobEntry(),
    this.listing,
    this.interviews = const [],
    this.occupations = const {},
    this.isPublic = false,
    this.boss = 'patron',
  });

  /// Amir rolleri: `patron`, `amir` (kamu, hastane), `usta` (sanayi).
  static const Set<String> bossRoles = {'patron', 'amir', 'usta'};

  final String id;

  /// Ekranda görünen meslek adı (Türkçe içerik, kart metinleri gibi).
  final String name;

  /// 1. kademeden son kademeye.
  final List<CareerTier> tiers;

  /// Gelirin yıldan yıla oynama payı: 0,5 ise maaş ×0,5 ile ×1,5 arası.
  final double incomeVariance;

  /// Kim girebilir.
  final JobEntry entry;

  /// İş ilanları; null ise bu meslek ilana çıkmaz.
  final ListingInfo? listing;

  /// Mülakatta sorulabilecek sorular.
  final List<InterviewQuestion> interviews;

  /// Bu meslekte çalışan sayılan kişi meslekleri (torpil için:
  /// `assets/families.json` → occupations).
  final Set<String> occupations;

  /// Kamu işi: kovulma yok, maaş her şehirde aynı.
  final bool isPublic;

  /// İşe girince gelen amirin rolü ([bossRoles]).
  final String boss;

  int get maxTier => tiers.length;

  /// [tier] 1'den başlar.
  CareerTier tier(int tier) => tiers[tier - 1];

  factory Career.fromJson(Map<String, dynamic> json, {required String file}) {
    final r = JsonReader(json, file);
    r.rejectUnknownKeys(const {
      'id',
      'name',
      'incomeVariance',
      'tiers',
      'entry',
      'listing',
      'interviews',
      'occupations',
      'public',
      'boss',
    });
    final boss = r.optionalString('boss') ?? 'patron';
    if (!bossRoles.contains(boss)) {
      throw CardFormatException('$file.boss', 'bilinmeyen amir rolü "$boss"');
    }
    final rawTiers = json['tiers'];
    if (rawTiers is! List || rawTiers.isEmpty) {
      throw CardFormatException('$file.tiers', 'en az bir kademe olmalı');
    }
    final variance = (json['incomeVariance'] ?? 0) as num;
    if (variance < 0 || variance >= 1) {
      throw CardFormatException(
        '$file.incomeVariance',
        '0 ile 1 arasında olmalı',
      );
    }
    final tiers = <CareerTier>[];
    for (var i = 0; i < rawTiers.length; i++) {
      final raw = rawTiers[i];
      if (raw is! Map<String, dynamic>) {
        throw CardFormatException('$file.tiers[$i]', 'nesne bekleniyordu');
      }
      final isLast = i == rawTiers.length - 1;
      tiers.add(
        CareerTier.fromJson(JsonReader(raw, '$file.tiers[$i]'), isLast: isLast),
      );
    }
    final rawInterviews = json['interviews'] ?? const [];
    if (rawInterviews is! List) {
      throw CardFormatException('$file.interviews', 'liste olmalı');
    }
    return Career(
      id: r.requireString('id'),
      name: r.requireString('name'),
      tiers: List.unmodifiable(tiers),
      incomeVariance: variance.toDouble(),
      entry: switch (r.optionalObject('entry')) {
        final e? => JobEntry.fromJson(e),
        null => const JobEntry(),
      },
      listing: switch (r.optionalObject('listing')) {
        final l? => ListingInfo.fromJson(l),
        null => null,
      },
      interviews: List.unmodifiable([
        for (var i = 0; i < rawInterviews.length; i++)
          InterviewQuestion.fromJson(
            JsonReader(
              rawInterviews[i] as Map<String, dynamic>,
              '$file.interviews[$i]',
            ),
          ),
      ]),
      occupations: {...r.optionalStringList('occupations')},
      isPublic: r.optionalBool('public'),
      boss: boss,
    );
  }
}

/// Mesleğe giriş şartı. [departments], [flags] ve [vocational] verilmişse
/// en az biri tutmalı (yollardan biri yeter); [requires] ve yaş her zaman.
class JobEntry {
  const JobEntry({
    this.departments = const {},
    this.flags = const {},
    this.vocational = false,
    this.requires = Conditions.none,
    this.minAge = 18,
    this.maxAge,
    this.interviewStat = RollStat.knowledge,
    this.interviewThreshold = 45,
  });

  /// Diplomasıyla girilebilen bölümler.
  final Set<String> departments;

  /// Bu bayraklardan biriyle girilebilir (KPSS, yazılım kursu).
  final Set<String> flags;

  /// Meslek lisesi ya da çıraklıkla girilebilir.
  final bool vocational;
  final Conditions requires;
  final int minAge;
  final int? maxAge;

  /// Mülakat zarı: hangi değere bakar, eşik kaç.
  final RollStat interviewStat;
  final int interviewThreshold;

  bool get hasPath => departments.isNotEmpty || flags.isNotEmpty || vocational;

  factory JobEntry.fromJson(JsonReader r) {
    r.rejectUnknownKeys(const {
      'departments',
      'flags',
      'vocational',
      'requires',
      'minAge',
      'maxAge',
      'interview',
    });
    final requires = r.optionalObject('requires');
    final interview = r.optionalObject('interview');
    final roll = interview == null ? null : Roll.fromJson(interview);
    return JobEntry(
      departments: {...r.optionalStringList('departments')},
      flags: {...r.optionalStringList('flags')},
      vocational: r.optionalBool('vocational'),
      requires: requires == null
          ? Conditions.none
          : Conditions.fromJson(requires),
      minAge: r.optionalInt('minAge') ?? 18,
      maxAge: r.optionalInt('maxAge'),
      interviewStat: roll?.stat ?? RollStat.knowledge,
      interviewThreshold: roll?.threshold ?? 45,
    );
  }
}

/// İlanlar: hangi şehir türlerinde, ne sıklıkla, hangi kurgusal şirketler
/// ve hangi bir cümlelik mizahla.
class ListingInfo {
  const ListingInfo({
    required this.cityTypes,
    required this.weight,
    required this.companies,
    required this.ads,
  });

  /// `buyuk`, `orta`, `kucuk`.
  final Set<String> cityTypes;

  /// İlan sıklığı (diğer mesleklere göre ağırlık).
  final int weight;
  final List<String> companies;
  final List<String> ads;

  factory ListingInfo.fromJson(JsonReader r) {
    r.rejectUnknownKeys(const {'cities', 'weight', 'companies', 'ads'});
    final cities = r.optionalStringList('cities');
    for (final city in cities) {
      if (!const {'buyuk', 'orta', 'kucuk'}.contains(city)) {
        throw CardFormatException('${r.path}.cities', 'bilinmeyen tür "$city"');
      }
    }
    final companies = r.requireStringList('companies');
    final ads = r.requireStringList('ads');
    if (companies.isEmpty || ads.isEmpty) {
      throw CardFormatException(r.path, 'şirket ve ilan cümlesi gerekli');
    }
    return ListingInfo(
      cityTypes: cities.isEmpty
          ? const {'buyuk', 'orta', 'kucuk'}
          : {...cities},
      weight: r.optionalInt('weight') ?? 1,
      companies: List.unmodifiable(companies),
      ads: List.unmodifiable(ads),
    );
  }
}

/// Mülakat sorusu ve iki cevap; her cevap başka bir değere zar atar.
class InterviewQuestion {
  const InterviewQuestion({
    required this.question,
    required this.left,
    required this.right,
  });

  final String question;
  final InterviewAnswer left;
  final InterviewAnswer right;

  factory InterviewQuestion.fromJson(JsonReader r) {
    r.rejectUnknownKeys(const {'question', 'left', 'right'});
    return InterviewQuestion(
      question: r.requireString('question'),
      left: InterviewAnswer.fromJson(r.requireObject('left')),
      right: InterviewAnswer.fromJson(r.requireObject('right')),
    );
  }
}

class InterviewAnswer {
  const InterviewAnswer({required this.label, required this.stat});

  final String label;
  final RollStat stat;

  factory InterviewAnswer.fromJson(JsonReader r) {
    r.rejectUnknownKeys(const {'label', 'stat'});
    final key = r.requireString('stat');
    final stat = RollStat.fromKey(key);
    if (stat == null) {
      throw CardFormatException('${r.path}.stat', 'bilinmeyen değer "$key"');
    }
    return InterviewAnswer(label: r.requireString('label'), stat: stat);
  }
}

class CareerTier {
  const CareerTier({required this.name, required this.salary, this.promotion});

  final String name;

  /// Yıllık gelir (TL), kira dışı geçim düşülmüş.
  final int salary;

  /// Bir üst kademeye geçiş; son kademede null.
  final Promotion? promotion;

  factory CareerTier.fromJson(JsonReader r, {required bool isLast}) {
    r.rejectUnknownKeys(const {'name', 'salary', 'promotion'});
    final salary = r.requireInt('salary');
    if (salary < 0) {
      throw CardFormatException('${r.path}.salary', 'eksi olamaz');
    }
    final promotion = r.optionalObject('promotion');
    if (isLast && promotion != null) {
      throw CardFormatException(
        '${r.path}.promotion',
        'son kademede terfi olmaz',
      );
    }
    if (!isLast && promotion == null) {
      throw CardFormatException(
        '${r.path}.promotion',
        'eksik; son kademe değil',
      );
    }
    return CareerTier(
      name: r.requireString('name'),
      salary: salary,
      promotion: promotion == null ? null : Promotion.fromJson(promotion),
    );
  }
}

/// Terfi: kademede en az [minYears] yıl, [requires] koşulları ve her yıl
/// [chance] ihtimal. Terfide [cost] TL ödenir (esnafın yeni dükkânı gibi).
class Promotion {
  const Promotion({
    required this.minYears,
    required this.chance,
    this.requires = Conditions.none,
    this.cost = 0,
    this.minPerformance = 55,
  });

  /// Kademede en az bu kadar yıl.
  final int minYears;

  /// Terfi istendiğinde şartlar tutuyorsa olumlu cevap ihtimali (performans
  /// ve şans ekler).
  final double chance;
  final Conditions requires;
  final int cost;

  /// Bu performansın altında terfi istenemez.
  final int minPerformance;

  factory Promotion.fromJson(JsonReader r) {
    r.rejectUnknownKeys(const {
      'minYears',
      'chance',
      'requires',
      'cost',
      'minPerformance',
    });
    final chance = r.json['chance'];
    if (chance is! num || chance <= 0 || chance > 1) {
      throw CardFormatException('${r.path}.chance', '0 ile 1 arasında olmalı');
    }
    final minYears = r.requireInt('minYears');
    if (minYears < 1) {
      throw CardFormatException('${r.path}.minYears', 'en az 1');
    }
    final requires = r.optionalObject('requires');
    final cost = r.optionalInt('cost') ?? 0;
    if (cost < 0) throw CardFormatException('${r.path}.cost', 'eksi olamaz');
    final minPerformance = r.optionalInt('minPerformance') ?? 55;
    if (minPerformance < 0 || minPerformance > 100) {
      throw CardFormatException('${r.path}.minPerformance', '0–100 olmalı');
    }
    return Promotion(
      minYears: minYears,
      chance: chance.toDouble(),
      requires: requires == null
          ? Conditions.none
          : Conditions.fromJson(requires),
      cost: cost,
      minPerformance: minPerformance,
    );
  }
}

/// Çalışma temposu: performansı, vakti ve sağlığı belirler.
enum Tempo {
  /// Performans yavaşça düşer; mutluluk biraz artar.
  rahat,
  normal,

  /// Performans hızla artar; vakit 1 azalır, sağlık düşer.
  yukle,
}

/// Karakterin o anki işi.
class Job {
  const Job({
    required this.careerId,
    required this.tier,
    this.yearsInTier = 0,
    this.yearsInJob = 0,
    this.company,
    this.performance = 50,
    this.tempo = Tempo.normal,
    this.raise = 0,
    this.raiseAskedAt,
    this.promotionAskedAt,
  }) : assert(tier >= 1);

  final String careerId;

  /// 1'den başlar.
  final int tier;
  final int yearsInTier;

  /// Bu işte (aynı kurumda) geçen yıl; terfide sıfırlanmaz. Kıdem zammı
  /// ve kıdem tazminatı buna bakar.
  final int yearsInJob;

  /// Kurgusal şirket ya da kurum adı; yoksa null (eski kayıt, kartla iş).
  final String? company;

  /// 0–100. Terfiyi, zammı ve kovulmayı belirler.
  final int performance;
  final Tempo tempo;

  /// Kademedeki zam oranı (0,1 = %10); terfide sıfırlanır.
  final double raise;

  /// Bu yaşta zam ya da terfi istendi (yılda bir kez).
  final int? raiseAskedAt;
  final int? promotionAskedAt;

  Job copyWith({
    int? tier,
    int? yearsInTier,
    int? yearsInJob,
    int? performance,
    Tempo? tempo,
    double? raise,
    int? raiseAskedAt,
    int? promotionAskedAt,
  }) => Job(
    careerId: careerId,
    tier: tier ?? this.tier,
    yearsInTier: yearsInTier ?? this.yearsInTier,
    yearsInJob: yearsInJob ?? this.yearsInJob,
    company: company,
    performance: performance ?? this.performance,
    tempo: tempo ?? this.tempo,
    raise: raise ?? this.raise,
    raiseAskedAt: raiseAskedAt ?? this.raiseAskedAt,
    promotionAskedAt: promotionAskedAt ?? this.promotionAskedAt,
  );

  Map<String, Object> toJson() => {
    'career': careerId,
    'tier': tier,
    'years': yearsInTier,
    'seniority': yearsInJob,
    'company': ?company,
    'performance': performance,
    'tempo': tempo.name,
    if (raise != 0) 'raise': raise,
    'raiseAsked': ?raiseAskedAt,
    'promotionAsked': ?promotionAskedAt,
  };

  factory Job.fromJson(Map<String, dynamic> json) => Job(
    careerId: json['career'] as String,
    tier: json['tier'] as int,
    yearsInTier: json['years'] as int,
    yearsInJob: json['seniority'] as int? ?? json['years'] as int,
    company: json['company'] as String?,
    performance: json['performance'] as int? ?? 50,
    tempo: Tempo.values.asNameMap()[json['tempo']] ?? Tempo.normal,
    raise: (json['raise'] as num? ?? 0).toDouble(),
    raiseAskedAt: json['raiseAsked'] as int?,
    promotionAskedAt: json['promotionAsked'] as int?,
  );

  @override
  bool operator ==(Object other) =>
      other is Job &&
      other.careerId == careerId &&
      other.tier == tier &&
      other.yearsInTier == yearsInTier &&
      other.yearsInJob == yearsInJob &&
      other.company == company &&
      other.performance == performance &&
      other.tempo == tempo &&
      other.raise == raise &&
      other.raiseAskedAt == raiseAskedAt &&
      other.promotionAskedAt == promotionAskedAt;

  @override
  int get hashCode => Object.hash(
    careerId,
    tier,
    yearsInTier,
    yearsInJob,
    company,
    performance,
    tempo,
    raise,
    raiseAskedAt,
    promotionAskedAt,
  );
}

/// Bir kart seçeneğinin işe etkisi.
sealed class CareerChange {
  const CareerChange();

  factory CareerChange.fromJson(JsonReader r) {
    r.rejectUnknownKeys(const {'join', 'tier', 'quit', 'promote', 'retire'});
    final actions = ['join', 'quit', 'promote', 'retire'].where(r.has).toList();
    if (actions.length != 1) {
      throw CardFormatException(
        r.path,
        'join, quit, promote ya da retire anahtarlarından tam biri olmalı',
      );
    }
    if (r.has('tier') && actions.single != 'join') {
      throw CardFormatException(
        '${r.path}.tier',
        'yalnızca join ile kullanılır',
      );
    }
    switch (actions.single) {
      case 'join':
        final tier = r.optionalInt('tier') ?? 1;
        if (tier < 1) throw CardFormatException('${r.path}.tier', 'en az 1');
        return JoinCareer(r.requireString('join'), tier: tier);
      case 'promote':
        final steps = r.requireInt('promote');
        if (steps == 0) {
          throw CardFormatException('${r.path}.promote', '0 olamaz');
        }
        return PromoteCareer(steps);
      case 'quit':
        if (r.json['quit'] != true) {
          throw CardFormatException('${r.path}.quit', 'true olmalı');
        }
        return const QuitCareer();
      default:
        if (r.json['retire'] != true) {
          throw CardFormatException('${r.path}.retire', 'true olmalı');
        }
        return const RetireCareer();
    }
  }
}

/// Mesleğe girer. Zaten bir işi varsa eskisi bırakılır.
class JoinCareer extends CareerChange {
  const JoinCareer(this.careerId, {this.tier = 1});

  final String careerId;
  final int tier;
}

/// Kademe atlar (eksi değer kademe düşürür); son ve ilk kademede durur.
class PromoteCareer extends CareerChange {
  const PromoteCareer(this.steps);

  final int steps;
}

/// İşi bırakır; emekli aylığı bağlanmaz.
class QuitCareer extends CareerChange {
  const QuitCareer();
}

/// Emekli olur; işi varsa son maaşa göre aylık bağlanır.
class RetireCareer extends CareerChange {
  const RetireCareer();
}
