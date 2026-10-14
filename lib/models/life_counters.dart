/// Ömür boyu sayaçlar: paylaşım kartındaki "hayatın sayıları" ve
/// başarımlar bunlardan beslenir. Değişmezdir.
class LifeCounters {
  const LifeCounters({
    this.moves = 0,
    this.rentPaid = 0,
    this.goldReceived = 0,
    this.promotions = 0,
    this.yearsWorked = 0,
    this.lifetimeIncome = 0,
    this.debtSpells = 0,
  });

  static const LifeCounters zero = LifeCounters();

  /// Kaç kez taşındı (bir kart `tasindi` bayrağını her eklediğinde).
  final int moves;

  /// Ömür boyu ödenen kira (TL, bugünün parasıyla).
  final int rentPaid;

  /// Kartlarla gelen altın (gram): düğün takısı, altın günü… Satın alma
  /// sayılmaz.
  final int goldReceived;

  /// Kaç kez terfi aldı.
  final int promotions;

  /// Bir işte geçen yıl sayısı.
  final int yearsWorked;

  /// Ömür boyu maaş ve emekli aylığı (TL).
  final int lifetimeIncome;

  /// Kaç kez borca düştü.
  final int debtSpells;

  LifeCounters copyWith({
    int? moves,
    int? rentPaid,
    int? goldReceived,
    int? promotions,
    int? yearsWorked,
    int? lifetimeIncome,
    int? debtSpells,
  }) {
    return LifeCounters(
      moves: moves ?? this.moves,
      rentPaid: rentPaid ?? this.rentPaid,
      goldReceived: goldReceived ?? this.goldReceived,
      promotions: promotions ?? this.promotions,
      yearsWorked: yearsWorked ?? this.yearsWorked,
      lifetimeIncome: lifetimeIncome ?? this.lifetimeIncome,
      debtSpells: debtSpells ?? this.debtSpells,
    );
  }

  Map<String, Object> toJson() => {
    'moves': moves,
    'rentPaid': rentPaid,
    'goldReceived': goldReceived,
    'promotions': promotions,
    'yearsWorked': yearsWorked,
    'lifetimeIncome': lifetimeIncome,
    'debtSpells': debtSpells,
  };

  /// Eksik alanlar 0 sayılır; eski kayıtlar da açılır.
  factory LifeCounters.fromJson(Map<String, dynamic>? json) {
    if (json == null) return zero;
    int read(String key) => (json[key] as int?) ?? 0;
    return LifeCounters(
      moves: read('moves'),
      rentPaid: read('rentPaid'),
      goldReceived: read('goldReceived'),
      promotions: read('promotions'),
      yearsWorked: read('yearsWorked'),
      lifetimeIncome: read('lifetimeIncome'),
      debtSpells: read('debtSpells'),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is LifeCounters &&
      other.moves == moves &&
      other.rentPaid == rentPaid &&
      other.goldReceived == goldReceived &&
      other.promotions == promotions &&
      other.yearsWorked == yearsWorked &&
      other.lifetimeIncome == lifetimeIncome &&
      other.debtSpells == debtSpells;

  @override
  int get hashCode => Object.hash(
    moves,
    rentPaid,
    goldReceived,
    promotions,
    yearsWorked,
    lifetimeIncome,
    debtSpells,
  );
}
