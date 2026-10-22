import 'package:bir_omur/models/models.dart';

/// Testler için kişi; oyuncu [playerAge] yaşındayken [age] yaşında.
Person testPerson(
  String id, {
  String name = 'Kerem',
  Gender gender = Gender.erkek,
  int age = 30,
  int playerAge = 30,
  String city = 'Konya',
  Kinship? kin,
  Side? side,
  Bond? bond,
  List<PersonRole> roles = const [],
  Set<Trait> traits = const {},
  int base = 40,
  List<Memory> memories = const [],
  int? lastContactAt,
  int? lastEventAt,
  bool archived = false,
}) => Person(
  id: id,
  name: name,
  surname: 'Yılmaz',
  gender: gender,
  bornAt: playerAge - age,
  city: city,
  origin: Origin.okul,
  metAt: 0,
  base: base,
  portraitSeed: id.hashCode & 0xffff,
  kin: kin,
  side: side,
  bond: bond,
  roles: roles,
  traits: traits,
  memories: memories,
  lastContactAt: lastContactAt ?? playerAge,
  lastEventAt: lastEventAt,
  archived: archived,
);

/// Karakterin kişi kitabını [people] ile değiştirir. Kimlikler sırayla
/// `p1`, `p2`… olmalı.
Character withPeople(Character c, List<Person> people) {
  var book = PeopleBook.empty();
  for (final p in people) {
    final (next, _) = book.add(
      (id) => Person.fromJson({...p.toJson(), 'id': id}),
    );
    book = next;
  }
  return c.copyWith(people: book);
}

Memory testMemory(
  String kind, {
  MemoryTone tone = MemoryTone.olumsuz,
  int severity = 2,
  int age = 14,
  MemoryOwner owner = MemoryOwner.ikisi,
}) => Memory(
  kind: kind,
  label: kind,
  age: age,
  tone: tone,
  severity: severity,
  owner: owner,
);
