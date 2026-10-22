import 'character.dart' show Gender;

/// Oyuncunun hayatındaki bir insan. Değişmezdir; her değişiklik [copyWith]
/// ile yeni bir kopya üretir. Yakınlık ve husumet burada saklanmaz,
/// anılardan hesaplanır (bkz. `engine/relationships.dart`).
class Person {
  Person({
    required this.id,
    required this.name,
    required this.surname,
    required this.gender,
    required this.bornAt,
    required this.city,
    required this.origin,
    required this.metAt,
    required this.base,
    required this.portraitSeed,
    this.kin,
    this.side,
    this.bond,
    List<PersonRole> roles = const [],
    Set<Trait> traits = const {},
    this.wealth = WealthLevel.orta,
    this.marital = MaritalStatus.bekar,
    this.occupation,
    this.health = 80,
    this.diedAt,
    List<Memory> memories = const [],
    this.impression = Impression.none,
    int? lastContactAt,
    this.archived = false,
    this.loan = 0,
    this.reunited = false,
    this.lastEventAt,
  }) : assert(base >= 0 && base <= 100),
       assert(health >= 0 && health <= 100),
       roles = List.unmodifiable(roles),
       traits = Set.unmodifiable(traits),
       memories = List.unmodifiable(memories),
       lastContactAt = lastContactAt ?? metAt;

  /// Hayat içinde benzersiz kimlik: `p1`, `p2`…
  final String id;
  final String name;
  final String surname;
  final Gender gender;

  /// Bu kişinin doğduğu yıl oyuncunun yaşı. Oyuncudan büyükler için eksidir
  /// (28 yaş büyük anne: −28).
  final int bornAt;

  /// Yaşadığı şehir.
  final String city;

  /// Oyuncuyla nerede tanıştı.
  final Origin origin;

  /// Tanıştıklarında oyuncunun yaşı.
  final int metAt;

  /// Akrabalık; akraba değilse null.
  final Kinship? kin;

  /// Akrabanın hangi taraftan olduğu: babaanne mi anneanne mi. Anne, baba
  /// ve kardeşte null.
  final Side? side;

  /// Akraba olmayanlarla bağın basamağı; akrabalarda null.
  final Bond? bond;

  /// Okul, iş ve mahalledeki rolleri. Bitenler [PersonRole.active] false
  /// olarak kalır ("eski sınıf arkadaşı").
  final List<PersonRole> roles;

  final Set<Trait> traits;
  final WealthLevel wealth;
  final MaritalStatus marital;

  /// Mesleğinin kimliği (`memur`, `ogretmen`); yoksa null.
  final String? occupation;

  /// 0–100. Ebeveynin bakım ihtiyacı ve vefatı buna bakar.
  final int health;

  /// Vefat ettiyse o yıl oyuncunun yaşı; hayattaysa null.
  final int? diedAt;

  /// Yakınlığın tabanı: anne yüksek, yabancı düşük (0–100).
  final int base;

  /// Portre bu tohumla üretilir; kişi ömür boyu aynı yüzü taşır.
  final int portraitSeed;

  /// Seninle ilgili anılar; en fazla [maxMemories]. Fazlası [impression]
  /// içinde birleşir.
  final List<Memory> memories;

  /// Ayrı ayrı tutulmayan küçük anıların toplamı.
  final Impression impression;

  /// En son görüştüğünüz yıl oyuncunun yaşı.
  final int lastContactAt;

  /// "Eski tanıdıklar" listesinde mi. Arşivdeki kişinin yılı işlemez.
  final bool archived;

  /// Oyuncunun bu kişiye borcu (TL); yoksa 0.
  final int loan;

  /// Yıllar sonra arandı mı. "Uzun aradan sonra arama" çarpanı kişi başına
  /// bir kez uygulanır.
  final bool reunited;

  /// Son olayına çıktığı yıl oyuncunun yaşı; olaydan sonra 2 yıl dinlenir
  /// (aile çekirdeği hariç).
  final int? lastEventAt;

  static const int maxMemories = 8;

  bool get isAlive => diedAt == null;

  /// Oyuncu [playerAge] yaşındayken bu kişinin yaşı.
  int ageAt(int playerAge) => playerAge - bornAt;

  String get fullName => '$name $surname';

  bool hasTrait(Trait t) => traits.contains(t);

  bool hasRole(RoleKind kind, {bool activeOnly = true}) =>
      roles.any((r) => r.kind == kind && (!activeOnly || r.active));

  Person copyWith({
    String? city,
    Bond? bond,
    bool clearBond = false,
    List<PersonRole>? roles,
    WealthLevel? wealth,
    MaritalStatus? marital,
    String? occupation,
    bool clearOccupation = false,
    int? health,
    int? diedAt,
    List<Memory>? memories,
    Impression? impression,
    int? lastContactAt,
    bool? archived,
    int? loan,
    bool? reunited,
    int? lastEventAt,
  }) => Person(
    id: id,
    name: name,
    surname: surname,
    gender: gender,
    bornAt: bornAt,
    city: city ?? this.city,
    origin: origin,
    metAt: metAt,
    base: base,
    portraitSeed: portraitSeed,
    kin: kin,
    side: side,
    bond: clearBond ? null : (bond ?? this.bond),
    roles: roles ?? this.roles,
    traits: traits,
    wealth: wealth ?? this.wealth,
    marital: marital ?? this.marital,
    occupation: clearOccupation ? null : (occupation ?? this.occupation),
    health: health ?? this.health,
    diedAt: diedAt ?? this.diedAt,
    memories: memories ?? this.memories,
    impression: impression ?? this.impression,
    lastContactAt: lastContactAt ?? this.lastContactAt,
    archived: archived ?? this.archived,
    loan: loan ?? this.loan,
    reunited: reunited ?? this.reunited,
    lastEventAt: lastEventAt ?? this.lastEventAt,
  );

  Map<String, Object> toJson() => {
    'id': id,
    'name': name,
    'surname': surname,
    'gender': gender.id,
    'bornAt': bornAt,
    'city': city,
    'origin': origin.name,
    'metAt': metAt,
    'base': base,
    'seed': portraitSeed,
    'kin': ?kin?.name,
    'side': ?side?.name,
    'bond': ?bond?.name,
    'roles': [for (final r in roles) r.toJson()],
    'traits': [
      for (final t in Trait.values)
        if (traits.contains(t)) t.name,
    ],
    'wealth': wealth.name,
    'marital': marital.name,
    'occupation': ?occupation,
    'health': health,
    'diedAt': ?diedAt,
    'memories': [for (final m in memories) m.toJson()],
    'impression': impression.toJson(),
    'lastContactAt': lastContactAt,
    'archived': archived,
    if (loan != 0) 'loan': loan,
    if (reunited) 'reunited': true,
    'lastEventAt': ?lastEventAt,
  };

  factory Person.fromJson(Map<String, dynamic> json) => Person(
    id: json['id'] as String,
    name: json['name'] as String,
    surname: json['surname'] as String,
    gender:
        Gender.fromId(json['gender'] as String) ??
        (throw FormatException('bilinmeyen cinsiyet: ${json['gender']}')),
    bornAt: json['bornAt'] as int,
    city: json['city'] as String,
    origin: Origin.values.byName(json['origin'] as String),
    metAt: json['metAt'] as int,
    base: json['base'] as int,
    portraitSeed: json['seed'] as int,
    kin: json['kin'] == null
        ? null
        : Kinship.values.byName(json['kin'] as String),
    side: json['side'] == null
        ? null
        : Side.values.byName(json['side'] as String),
    bond: json['bond'] == null
        ? null
        : Bond.values.byName(json['bond'] as String),
    roles: [
      for (final r in json['roles'] as List)
        PersonRole.fromJson(r as Map<String, dynamic>),
    ],
    traits: {
      for (final t in json['traits'] as List) Trait.values.byName(t as String),
    },
    wealth: WealthLevel.values.byName(json['wealth'] as String),
    marital: MaritalStatus.values.byName(json['marital'] as String),
    occupation: json['occupation'] as String?,
    health: json['health'] as int,
    diedAt: json['diedAt'] as int?,
    memories: [
      for (final m in json['memories'] as List)
        Memory.fromJson(m as Map<String, dynamic>),
    ],
    impression: Impression.fromJson(json['impression'] as Map<String, dynamic>),
    lastContactAt: json['lastContactAt'] as int,
    archived: json['archived'] as bool,
    loan: json['loan'] as int? ?? 0,
    reunited: json['reunited'] as bool? ?? false,
    lastEventAt: json['lastEventAt'] as int?,
  );
}

/// Kişinin oyuncuyla tanıştığı yer.
enum Origin {
  aile,
  okul,
  universite,
  askerlik,
  isYeri,
  mahalle,
  tesaduf,
  araci,
  kendin,
}

/// Akrabalık. "Eş" de burada: evlilikle akraba olunur.
enum Kinship {
  anne,
  baba,
  kardes,
  dede,
  nine,
  amca,
  hala,
  dayi,
  teyze,
  kuzen,
  yegen,
  es,
  cocuk,
  gelin,
  damat,
  torun,
  kayinvalide,
  kayinpeder,
  gorumce,
  baldiz,
  kayinbirader,
  bacanak,
  elti,
}

/// Akrabanın tarafı.
enum Side { anne, baba }

/// Akraba olmayanla bağın basamağı. Husumet ayrı bir basamak değil,
/// çubuklardan okunan bir etikettir.
enum Bond {
  tanidik,
  arkadas,
  yakinArkadas,
  flort,
  sevgili,
  nisanli,
  eskiSevgili,
  eskiEs,
}

/// Okul, iş ve mahalle rolleri.
enum RoleKind {
  siraArkadasi,
  sinifArkadasi,
  ogretmen,
  odaArkadasi,
  bolukArkadasi,
  patron,
  mudur,
  isArkadasi,
  calisan,
  musteri,
  ortak,
  rakip,
  komsu,
  bakkal,
  muhtar,
  evSahibi,
  kiraci,
  doktor,
}

/// Bir rol ve hâlâ sürüp sürmediği. Biten rol "eski" olarak kalır.
class PersonRole {
  const PersonRole(this.kind, {this.active = true});

  final RoleKind kind;
  final bool active;

  PersonRole ended() => PersonRole(kind, active: false);

  Map<String, Object> toJson() => {'kind': kind.name, 'active': active};

  factory PersonRole.fromJson(Map<String, dynamic> json) => PersonRole(
    RoleKind.values.byName(json['kind'] as String),
    active: json['active'] as bool,
  );

  @override
  bool operator ==(Object other) =>
      other is PersonRole && other.kind == kind && other.active == active;

  @override
  int get hashCode => Object.hash(kind, active);
}

/// Kişilik özellikleri. Çubuğu değil davranışı değiştirir; anıların ağırlığı
/// ve solma hızı da bunlara bağlıdır. İlk sürümde 6 özellik var.
enum Trait {
  kiskanc,
  comert,
  cikarci,
  vefali,
  dedikoducu,
  gamsiz;

  /// Birlikte çıkmayan çiftler.
  static const List<(Trait, Trait)> conflicts = [
    (Trait.comert, Trait.cikarci),
    (Trait.vefali, Trait.gamsiz),
  ];

  static bool compatible(Trait a, Trait b) =>
      a != b &&
      !conflicts.any(
        (c) => (c.$1 == a && c.$2 == b) || (c.$1 == b && c.$2 == a),
      );
}

enum WealthLevel { dar, orta, rahat, zengin }

enum MaritalStatus { bekar, evli, bosanmis, dul }

/// Anının olumlu mu olumsuz mu olduğu.
enum MemoryTone { olumlu, olumsuz }

/// Anı kimin hafızasında. Yalnızca [kisi] ve [ikisi] çubukları etkiler;
/// [oyuncu] anıları yalnızca olaylarda yeni seçenek açar.
enum MemoryOwner { kisi, oyuncu, ikisi }

/// Bir kişiyle yaşanmış, hatırlanan bir an.
class Memory {
  const Memory({
    required this.kind,
    required this.label,
    required this.age,
    required this.tone,
    required this.severity,
    this.owner = MemoryOwner.ikisi,
    this.bonus = 1.0,
    this.healed = false,
  }) : assert(severity >= 1 && severity <= 3),
       assert(bonus > 0);

  /// Olayların aradığı kimlik: `rezil_etti`, `zor_gunde_aradi`.
  final String kind;

  /// Sohbette ve kişi ekranında görünen kısa metin, kişinin gözünden:
  /// "Sınıfın ortasında rezil etti".
  final String label;

  /// Oyuncunun o yılki yaşı.
  final int age;
  final MemoryTone tone;

  /// 1 küçük, 2 önemli, 3 unutulmaz.
  final int severity;
  final MemoryOwner owner;

  /// Anının yazıldığı andaki çarpan (örnek: uzun aradan sonra arama 1,5).
  final double bonus;

  /// Olumsuz anı özür ya da barışmayla yumuşadıysa true; ağırlığı yarıya
  /// iner ama anı silinmez.
  final bool healed;

  bool get affectsBars => owner != MemoryOwner.oyuncu;

  Memory heal() => Memory(
    kind: kind,
    label: label,
    age: age,
    tone: tone,
    severity: severity,
    owner: owner,
    bonus: bonus,
    healed: true,
  );

  Map<String, Object> toJson() => {
    'kind': kind,
    'label': label,
    'age': age,
    'tone': tone.name,
    'severity': severity,
    'owner': owner.name,
    if (bonus != 1.0) 'bonus': bonus,
    if (healed) 'healed': true,
  };

  factory Memory.fromJson(Map<String, dynamic> json) => Memory(
    kind: json['kind'] as String,
    label: json['label'] as String,
    age: json['age'] as int,
    tone: MemoryTone.values.byName(json['tone'] as String),
    severity: json['severity'] as int,
    owner: MemoryOwner.values.byName(json['owner'] as String),
    bonus: (json['bonus'] as num?)?.toDouble() ?? 1.0,
    healed: json['healed'] as bool? ?? false,
  );
}

/// Ayrı tutulmayan anıların birikimi: "genel izlenim". Değerler o yılki
/// ağırlıktır ve her yıl sabit oranda solar.
class Impression {
  const Impression({this.warmth = 0, this.grudge = 0, this.since = 0})
    : assert(warmth >= 0 && grudge >= 0);

  static const Impression none = Impression();

  /// Olumlu ve olumsuz birikim, [since] yaşındaki değeriyle.
  final double warmth;
  final double grudge;

  /// Değerlerin yazıldığı yıl oyuncunun yaşı.
  final int since;

  bool get isEmpty => warmth == 0 && grudge == 0;

  Map<String, Object> toJson() => {
    if (warmth != 0) 'warmth': warmth,
    if (grudge != 0) 'grudge': grudge,
    if (!isEmpty) 'since': since,
  };

  factory Impression.fromJson(Map<String, dynamic> json) => Impression(
    warmth: (json['warmth'] as num?)?.toDouble() ?? 0,
    grudge: (json['grudge'] as num?)?.toDouble() ?? 0,
    since: json['since'] as int? ?? 0,
  );
}
