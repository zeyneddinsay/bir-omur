/// Oyuncunun nerede yaşadığı. Gideri ve kişileri belirler (canlı doküman,
/// "Ev, şehir ve taşınma").
enum HomeKind {
  /// Ailesiyle; gider yok. Doğumdan itibaren.
  aile('aile'),

  /// Üniversite yurdu; düşük yaşam gideri.
  yurt('yurt'),

  /// Ev arkadaşıyla; kiranın yarısı ve yaşam gideri.
  evArkadasi('ev_arkadasi'),

  /// Tek başına kirada; kira ve yaşam gideri.
  kira('kira'),

  /// Kendi evinde; kira yok, yaşam gideri var.
  kendiEvi('kendi_evi'),

  /// Yaşlılıkta yetişkin bir çocuğunun evinde; kira ve gider yok. Ev
  /// sahibi çocuk [RoleKind.evSahibi] rolünü taşır.
  cocukYaninda('cocuk_yaninda');

  const HomeKind(this.id);

  final String id;

  /// Kira ödenen evler.
  bool get paysRent => this == evArkadasi || this == kira;

  /// Ailenin yanından ayrılmış mı.
  bool get awayFromFamily => this != aile;

  static HomeKind? fromId(String id) {
    for (final h in values) {
      if (h.id == id) return h;
    }
    return null;
  }
}

/// Şehir türü: kira, ev ve maaş çarpanları.
enum CityType {
  buyuk(rent: 1.4, salary: 1.15),
  orta(rent: 1.0, salary: 1.0),
  kucuk(rent: 0.6, salary: 0.9);

  const CityType({required this.rent, required this.salary});

  /// Kira ve ev fiyatı çarpanı.
  final double rent;

  /// Maaş çarpanı.
  final double salary;
}
