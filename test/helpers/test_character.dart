import 'package:bir_omur/models/models.dart';

/// Testler için varsayılanlarla doldurulmuş karakter.
Character testCharacter({
  int age = 25,
  int health = 50,
  int happiness = 50,
  int knowledge = 50,
  int reputation = 50,
  int family = 50,
  int money = 10000,
  int luck = 50,
  Gender gender = Gender.erkek,
  Temperament temperament = Temperament.sakin,
  Set<String> flags = const {},
  List<CardRecord> history = const [],
  Assets assets = Assets.none,
  Job? job,
  int pension = 0,
}) {
  return Character(
    name: 'Deneme',
    gender: gender,
    age: age,
    stats: Stats(
      health: health,
      happiness: happiness,
      knowledge: knowledge,
      reputation: reputation,
      family: family,
      money: money,
    ),
    temperament: temperament,
    luck: luck,
    hometown: 'Kastamonu',
    team: 'Boğaziçi Martıları',
    flags: flags,
    history: history,
    assets: assets,
    job: job,
    pension: pension,
  );
}
