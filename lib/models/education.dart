/// Lise türü: LGS sonucuna ve seçime göre (canlı doküman, "Eğitim yolu").
enum HighSchool {
  /// Mahalledeki lise.
  duz('duz'),

  /// Anadolu lisesi: LGS'de iyi puan.
  anadolu('anadolu'),

  /// Fen lisesi: LGS'de çok iyi puan.
  fen('fen'),

  /// Meslek lisesi: ustalık yolunu açar, YKS'de puanı düşürür.
  meslek('meslek');

  const HighSchool(this.id);

  final String id;

  static HighSchool? fromId(String id) {
    for (final h in values) {
      if (h.id == id) return h;
    }
    return null;
  }
}

/// Oyuncunun eğitim durumu. Değişmezdir; kayda girer.
class Education {
  const Education({
    this.highSchool,
    this.yksScore,
    this.yksAttempts = 0,
    this.department,
    this.uniCity,
    this.uniStartAge,
    this.uniYears = 0,
    this.extraYears = 0,
    this.graduatedAt,
    this.scholarship = 0,
    this.openEducation = false,
    this.apprentice = false,
  });

  static const Education none = Education();

  /// 15 yaşında belirlenir; öncesinde null.
  final HighSchool? highSchool;

  /// Son YKS puanı (100–500); sınava girmediyse null.
  final int? yksScore;
  final int yksAttempts;

  /// Okuduğu ya da bitirdiği bölümün kimliği.
  final String? department;
  final String? uniCity;
  final int? uniStartAge;

  /// Bölümün normal süresi (yıl).
  final int uniYears;

  /// Alttan kalan dersler yüzünden uzayan yıllar.
  final int extraYears;

  /// Mezun olduğu yaş; okumadıysa ya da okuyorsa null.
  final int? graduatedAt;

  /// Yıllık burs (TL); yoksa 0.
  final int scholarship;

  /// Açıköğretim: evden okur, vakit ayırmadan.
  final bool openEducation;

  /// Bir ustanın yanında çırak (oto tamircisi yolu).
  final bool apprentice;

  /// Üniversitede okuyor (mezun olmadı, bırakmadı).
  bool get isStudent => department != null && graduatedAt == null;

  bool get isGraduate => graduatedAt != null;

  /// Mezuniyet yaşı: başlangıç + süre + uzayan yıllar.
  int? get expectedGraduation =>
      uniStartAge == null ? null : uniStartAge! + uniYears + extraYears;

  Education copyWith({
    HighSchool? highSchool,
    int? yksScore,
    int? yksAttempts,
    String? department,
    String? uniCity,
    int? uniStartAge,
    int? uniYears,
    int? extraYears,
    int? graduatedAt,
    int? scholarship,
    bool? openEducation,
    bool? apprentice,
  }) => Education(
    highSchool: highSchool ?? this.highSchool,
    yksScore: yksScore ?? this.yksScore,
    yksAttempts: yksAttempts ?? this.yksAttempts,
    department: department ?? this.department,
    uniCity: uniCity ?? this.uniCity,
    uniStartAge: uniStartAge ?? this.uniStartAge,
    uniYears: uniYears ?? this.uniYears,
    extraYears: extraYears ?? this.extraYears,
    graduatedAt: graduatedAt ?? this.graduatedAt,
    scholarship: scholarship ?? this.scholarship,
    openEducation: openEducation ?? this.openEducation,
    apprentice: apprentice ?? this.apprentice,
  );

  Map<String, Object> toJson() => {
    'highSchool': ?highSchool?.id,
    'yks': ?yksScore,
    if (yksAttempts > 0) 'yksAttempts': yksAttempts,
    'department': ?department,
    'uniCity': ?uniCity,
    'uniStart': ?uniStartAge,
    if (uniYears > 0) 'uniYears': uniYears,
    if (extraYears > 0) 'extraYears': extraYears,
    'graduatedAt': ?graduatedAt,
    if (scholarship > 0) 'scholarship': scholarship,
    if (openEducation) 'open': true,
    if (apprentice) 'apprentice': true,
  };

  factory Education.fromJson(Map<String, dynamic>? json) {
    if (json == null) return none;
    return Education(
      highSchool: switch (json['highSchool']) {
        final String id => HighSchool.fromId(id),
        _ => null,
      },
      yksScore: json['yks'] as int?,
      yksAttempts: json['yksAttempts'] as int? ?? 0,
      department: json['department'] as String?,
      uniCity: json['uniCity'] as String?,
      uniStartAge: json['uniStart'] as int?,
      uniYears: json['uniYears'] as int? ?? 0,
      extraYears: json['extraYears'] as int? ?? 0,
      graduatedAt: json['graduatedAt'] as int?,
      scholarship: json['scholarship'] as int? ?? 0,
      openEducation: json['open'] as bool? ?? false,
      apprentice: json['apprentice'] as bool? ?? false,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is Education &&
      other.highSchool == highSchool &&
      other.yksScore == yksScore &&
      other.yksAttempts == yksAttempts &&
      other.department == department &&
      other.uniCity == uniCity &&
      other.uniStartAge == uniStartAge &&
      other.uniYears == uniYears &&
      other.extraYears == extraYears &&
      other.graduatedAt == graduatedAt &&
      other.scholarship == scholarship &&
      other.openEducation == openEducation &&
      other.apprentice == apprentice;

  @override
  int get hashCode => Object.hash(
    highSchool,
    yksScore,
    yksAttempts,
    department,
    uniCity,
    uniStartAge,
    uniYears,
    extraYears,
    graduatedAt,
    scholarship,
    openEducation,
    apprentice,
  );
}
