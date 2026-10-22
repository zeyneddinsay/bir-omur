import '../models/models.dart';

/// Oyundaki 20 şehir ve türleri. Gerçek semt adları kullanılmaz.
abstract final class Cities {
  static const Map<String, CityType> types = {
    'İstanbul': CityType.buyuk,
    'Ankara': CityType.buyuk,
    'İzmir': CityType.buyuk,
    'Bursa': CityType.orta,
    'Trabzon': CityType.orta,
    'Konya': CityType.orta,
    'Adana': CityType.orta,
    'Eskişehir': CityType.orta,
    'Gaziantep': CityType.orta,
    'Samsun': CityType.orta,
    'Malatya': CityType.orta,
    'Denizli': CityType.orta,
    'Kayseri': CityType.orta,
    'Antalya': CityType.orta,
    'Erzurum': CityType.kucuk,
    'Kastamonu': CityType.kucuk,
    'Sivas': CityType.kucuk,
    'Rize': CityType.kucuk,
    'Mardin': CityType.kucuk,
    'Edirne': CityType.kucuk,
  };

  /// Şehirler, liste sırasıyla (doğum yeri bu listeden çekilir).
  static final List<String> all = List.unmodifiable(types.keys);

  /// Bilinmeyen şehir orta sayılır.
  static CityType typeOf(String city) => types[city] ?? CityType.orta;

  static List<String> ofType(CityType type) => [
    for (final MapEntry(key: city, value: t) in types.entries)
      if (t == type) city,
  ];
}
