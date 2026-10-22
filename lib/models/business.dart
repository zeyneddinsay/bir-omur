/// Fiyat politikası: ucuz daha çok müşteri getirir ama az kazandırır;
/// pahalı müşteriyi itibara daha duyarlı kılar.
enum PriceLevel { ucuz, normal, pahali }

/// Oyuncunun bir işletmesi (canlı doküman, "Kendi işin"). Değişmezdir.
class Business {
  const Business({
    required this.id,
    required this.type,
    required this.name,
    required this.city,
    required this.openedAt,
    this.reputation = 50,
    this.price = PriceLevel.normal,
    this.present = true,
    this.branches = 1,
    this.staff = const [],
    this.partnerId,
    this.partnerShare = 0,
    this.profits = const [],
    this.advertisedAt,
    this.loanPayment = 0,
    this.loanYearsLeft = 0,
    this.managerId,
    this.partnerCapital = 0,
  });

  /// Oyuncunun işletmeleri arasında benzersiz (`b1`, `b2`…).
  final String id;

  /// İşletme türü kimliği ([BusinessType.id]).
  final String type;

  /// Tabeladaki ad (kurgusal).
  final String name;
  final String city;
  final int openedAt;

  /// 0–100; ciroyu 0,7–1,3 arasında çarpar.
  final int reputation;
  final PriceLevel price;

  /// Başında duruyor (1,1) ya da müdüre bırakmış (0,95).
  final bool present;

  /// Şube sayısı (en fazla 3); her ek şube bir müdür ister.
  final int branches;

  /// Çalışanların kişi kimlikleri.
  final List<String> staff;

  /// Müdür (başında durmazken); kişi kimliği.
  final String? managerId;

  /// Ortak ve kârdaki payı (0–0,5).
  final String? partnerId;
  final double partnerShare;

  /// Ortağın koyduğu sermaye; çıkışta en az bunu geri alır.
  final int partnerCapital;

  /// Son yılların kârları (en yenisi sonda; en fazla 3).
  final List<int> profits;

  /// Reklam verilen yaş; o yıl itibar artar.
  final int? advertisedAt;

  /// İşletme kredisi.
  final int loanPayment;
  final int loanYearsLeft;

  int? get lastProfit => profits.isEmpty ? null : profits.last;

  Business copyWith({
    String? name,
    String? city,
    int? reputation,
    PriceLevel? price,
    bool? present,
    int? branches,
    List<String>? staff,
    String? managerId,
    bool clearManager = false,
    String? partnerId,
    bool clearPartner = false,
    double? partnerShare,
    int? partnerCapital,
    List<int>? profits,
    int? advertisedAt,
    int? loanPayment,
    int? loanYearsLeft,
  }) => Business(
    id: id,
    type: type,
    name: name ?? this.name,
    city: city ?? this.city,
    openedAt: openedAt,
    reputation: reputation ?? this.reputation,
    price: price ?? this.price,
    present: present ?? this.present,
    branches: branches ?? this.branches,
    staff: staff ?? this.staff,
    managerId: clearManager ? null : (managerId ?? this.managerId),
    partnerId: clearPartner ? null : (partnerId ?? this.partnerId),
    partnerShare: clearPartner ? 0 : (partnerShare ?? this.partnerShare),
    partnerCapital: clearPartner ? 0 : (partnerCapital ?? this.partnerCapital),
    profits: profits ?? this.profits,
    advertisedAt: advertisedAt ?? this.advertisedAt,
    loanPayment: loanPayment ?? this.loanPayment,
    loanYearsLeft: loanYearsLeft ?? this.loanYearsLeft,
  );

  Map<String, Object> toJson() => {
    'id': id,
    'type': type,
    'name': name,
    'city': city,
    'openedAt': openedAt,
    'reputation': reputation,
    'price': price.name,
    'present': present,
    'branches': branches,
    if (staff.isNotEmpty) 'staff': staff,
    'manager': ?managerId,
    'partner': ?partnerId,
    if (partnerShare > 0) 'partnerShare': partnerShare,
    if (partnerCapital > 0) 'partnerCapital': partnerCapital,
    if (profits.isNotEmpty) 'profits': profits,
    'advertisedAt': ?advertisedAt,
    if (loanYearsLeft > 0) 'loanPayment': loanPayment,
    if (loanYearsLeft > 0) 'loanYears': loanYearsLeft,
  };

  factory Business.fromJson(Map<String, dynamic> json) => Business(
    id: json['id'] as String,
    type: json['type'] as String,
    name: json['name'] as String,
    city: json['city'] as String,
    openedAt: json['openedAt'] as int,
    reputation: json['reputation'] as int? ?? 50,
    price: PriceLevel.values.asNameMap()[json['price']] ?? PriceLevel.normal,
    present: json['present'] as bool? ?? true,
    branches: json['branches'] as int? ?? 1,
    staff: [...?(json['staff'] as List?)?.cast<String>()],
    managerId: json['manager'] as String?,
    partnerId: json['partner'] as String?,
    partnerShare: (json['partnerShare'] as num? ?? 0).toDouble(),
    partnerCapital: json['partnerCapital'] as int? ?? 0,
    profits: [...?(json['profits'] as List?)?.cast<int>()],
    advertisedAt: json['advertisedAt'] as int?,
    loanPayment: json['loanPayment'] as int? ?? 0,
    loanYearsLeft: json['loanYears'] as int? ?? 0,
  );

  @override
  bool operator ==(Object other) =>
      other is Business && _key(other) == _key(this);

  String _key(Business b) => b.toJson().toString();

  @override
  int get hashCode => toJson().toString().hashCode;
}
