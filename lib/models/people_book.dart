import 'person.dart';

/// Bir hayattaki bütün kişiler, eklendikleri sırayla. Değişmezdir.
///
/// Kişiler silinmez: vefat eden, uzaklaşan ya da arşive düşen kişi kayıtta
/// kalır, çünkü anıları ve iplikleri ona bağlıdır.
class PeopleBook {
  PeopleBook._(this._people, this.nextId);

  PeopleBook.empty() : this._(const {}, 1);

  final Map<String, Person> _people;

  /// Bir sonraki kişinin kimlik numarası (`p<nextId>`).
  final int nextId;

  Iterable<Person> get all => _people.values;

  int get length => _people.length;

  Person? operator [](String id) => _people[id];

  /// Yeni kişi ekler; kimliği kitap verir.
  (PeopleBook, Person) add(Person Function(String id) build) {
    final id = 'p$nextId';
    final person = build(id);
    if (person.id != id) {
      throw ArgumentError('Kişi verilen kimliği kullanmalı: $id');
    }
    return (
      PeopleBook._(Map.unmodifiable({..._people, id: person}), nextId + 1),
      person,
    );
  }

  /// Var olan bir kişiyi günceller.
  PeopleBook update(Person person) {
    if (!_people.containsKey(person.id)) {
      throw ArgumentError('Kitapta olmayan kişi: ${person.id}');
    }
    return PeopleBook._(
      Map.unmodifiable({..._people, person.id: person}),
      nextId,
    );
  }

  /// Her kişiye [change] uygular.
  PeopleBook map(Person Function(Person) change) => PeopleBook._(
    Map.unmodifiable({for (final p in _people.values) p.id: change(p)}),
    nextId,
  );

  /// Oyuncu [now] yaşındayken doğmuş kişiler (küçük kardeşler sonra doğar).
  Iterable<Person> bornBy(int now) => all.where((p) => p.bornAt <= now);

  /// Hayatta, doğmuş ve arşivde olmayan kişiler.
  Iterable<Person> active(int now) =>
      bornBy(now).where((p) => p.isAlive && !p.archived);

  /// Bu akrabalıktaki kişiler (vefat edenler dahil).
  List<Person> withKin(Kinship kin) => [
    for (final p in all)
      if (p.kin == kin) p,
  ];

  Map<String, Object> toJson() => {
    'next': nextId,
    'people': [for (final p in all) p.toJson()],
  };

  factory PeopleBook.fromJson(Map<String, dynamic> json) {
    final people = [
      for (final p in json['people'] as List)
        Person.fromJson(p as Map<String, dynamic>),
    ];
    return PeopleBook._(
      Map.unmodifiable({for (final p in people) p.id: p}),
      json['next'] as int,
    );
  }
}
