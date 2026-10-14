/// Nakit dışındaki varlıklar ve düzenli yükümlülükler. Değişmezdir.
///
/// Bütün tutarlar bugünün TL'siyle tutulur (bkz. CLAUDE.md, F1 kararları):
/// enflasyon fiyatları büyütmez, nakdi eritir.
class Assets {
  const Assets({
    this.goldGrams = 0,
    this.houses = 0,
    this.cars = 0,
    this.carValue = 0,
    this.rent = defaultRent,
    this.loanPayment = 0,
    this.loanYearsLeft = 0,
  }) : assert(goldGrams >= 0 && houses >= 0 && cars >= 0 && carValue >= 0),
       assert(loanYearsLeft >= 0);

  static const Assets none = Assets();

  /// Kiracının yıllık kirası (TL). Kira zammı kartları bunu kalıcı artırır.
  static const int defaultRent = 120000;

  final int goldGrams;
  final int houses;
  final int cars;

  /// Arabaların bugünkü toplam değeri; her yıl biraz düşer.
  final int carValue;

  /// Yıllık kira. Yalnızca `kiraci` bayrağı varken ödenir.
  final int rent;

  /// Kredinin yıllık taksidi ve kalan yılı.
  final int loanPayment;
  final int loanYearsLeft;

  bool get hasLoan => loanYearsLeft > 0;

  int get remainingLoan => loanPayment * loanYearsLeft;

  Assets copyWith({
    int? goldGrams,
    int? houses,
    int? cars,
    int? carValue,
    int? rent,
    int? loanPayment,
    int? loanYearsLeft,
  }) {
    return Assets(
      goldGrams: goldGrams ?? this.goldGrams,
      houses: houses ?? this.houses,
      cars: cars ?? this.cars,
      carValue: carValue ?? this.carValue,
      rent: rent ?? this.rent,
      loanPayment: loanPayment ?? this.loanPayment,
      loanYearsLeft: loanYearsLeft ?? this.loanYearsLeft,
    );
  }

  Map<String, Object> toJson() => {
    'gold': goldGrams,
    'houses': houses,
    'cars': cars,
    'carValue': carValue,
    'rent': rent,
    'loanPayment': loanPayment,
    'loanYears': loanYearsLeft,
  };

  factory Assets.fromJson(Map<String, dynamic> json) => Assets(
    goldGrams: json['gold'] as int,
    houses: json['houses'] as int,
    cars: json['cars'] as int,
    carValue: json['carValue'] as int,
    rent: json['rent'] as int,
    loanPayment: json['loanPayment'] as int,
    loanYearsLeft: json['loanYears'] as int,
  );

  @override
  bool operator ==(Object other) =>
      other is Assets &&
      other.goldGrams == goldGrams &&
      other.houses == houses &&
      other.cars == cars &&
      other.carValue == carValue &&
      other.rent == rent &&
      other.loanPayment == loanPayment &&
      other.loanYearsLeft == loanYearsLeft;

  @override
  int get hashCode => Object.hash(
    goldGrams,
    houses,
    cars,
    carValue,
    rent,
    loanPayment,
    loanYearsLeft,
  );

  @override
  String toString() =>
      'Assets(altın:${goldGrams}g ev:$houses araba:$cars/$carValue '
      'kira:$rent kredi:$loanPayment×$loanYearsLeft)';
}
