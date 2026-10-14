import 'dart:math';

import '../models/models.dart';

/// Yeni doğan karakteri tohumlu rastgelelikle üretir.
///
/// İsim, şehir ve takım listeleri F0 için koddadır; F1'de içerik dosyasına
/// taşınabilir. Takımlar kurgusaldır.
class BirthGenerator {
  const BirthGenerator(this.random);

  final Random random;

  static const List<String> maleNames = [
    'Ahmet',
    'Mehmet',
    'Mustafa',
    'Ali',
    'Hüseyin',
    'Hasan',
    'İbrahim',
    'Murat',
    'Emre',
    'Burak',
    'Yusuf',
    'Eymen',
    'Kerem',
    'Ömer',
    'Can',
  ];

  static const List<String> femaleNames = [
    'Ayşe',
    'Fatma',
    'Zeynep',
    'Elif',
    'Emine',
    'Hatice',
    'Merve',
    'Esra',
    'Selin',
    'Defne',
    'Asya',
    'Zehra',
    'Büşra',
    'Ece',
    'Nur',
  ];

  static const List<String> hometowns = [
    'İstanbul',
    'Ankara',
    'İzmir',
    'Bursa',
    'Trabzon',
    'Konya',
    'Adana',
    'Erzurum',
    'Kastamonu',
    'Eskişehir',
    'Gaziantep',
    'Samsun',
    'Malatya',
    'Denizli',
    'Sivas',
    'Rize',
    'Kayseri',
    'Antalya',
    'Mardin',
    'Edirne',
  ];

  static const List<String> teams = [
    'Boğaziçi Martıları',
    'Anadolu Kartalları',
    'Karadeniz Fırtınası',
    'Ege Yıldızları',
  ];

  Character generate({String? name, Gender? gender}) {
    final Gender g = gender ?? _pick(Gender.values);
    final trimmed = name?.trim();
    return Character(
      name: (trimmed == null || trimmed.isEmpty)
          ? _pick(g == Gender.erkek ? maleNames : femaleNames)
          : trimmed,
      gender: g,
      age: 0,
      stats: Stats(
        health: _between(70, 95),
        happiness: _between(60, 85),
        knowledge: _between(0, 10),
        reputation: _between(45, 60),
        family: _between(60, 90),
        money: 0,
      ),
      temperament: _pick(Temperament.values),
      luck: _between(0, 100),
      hometown: _pick(hometowns),
      team: _pick(teams),
    );
  }

  T _pick<T>(List<T> items) => items[random.nextInt(items.length)];

  int _between(int min, int max) => min + random.nextInt(max - min + 1);
}
