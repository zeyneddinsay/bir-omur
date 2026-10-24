import 'package:bir_omur/engine/engine.dart';
import 'package:bir_omur/models/models.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/families.dart';
import '../helpers/people.dart';
import '../helpers/test_character.dart';

void main() {
  final factory = PersonFactory(SeededRandom(3), realFamilies());

  Person? withRole(Character c, RoleKind role) =>
      c.people.all.where((p) => p.hasRole(role)).firstOrNull;

  test('evden çıkınca kiraya geçilir, ev sahibi kişi olarak gelir', () {
    final c = Housing.rentAlone(testCharacter(age: 20), factory);
    expect(c.home, HomeKind.kira);
    expect(c.assets.rent, Economy.rentFor(c.city));
    final landlord = withRole(c, RoleKind.evSahibi)!;
    expect(landlord.city, c.city);
    expect(landlord.ageAt(20), greaterThanOrEqualTo(40));
    expect(Economy.syncDerivedFlags(c).hasFlag(Economy.renterFlag), isTrue);
  });

  test(
    'ev sahibi vefat edince ev çocuğuna kalır: aynı soyadlı yeni ev sahibi',
    () {
      var c = Housing.rentAlone(testCharacter(age: 50), factory);
      final landlord = withRole(c, RoleKind.evSahibi)!;
      expect(Housing.inheritLandlord(c, factory), isNull);
      c = c.copyWith(people: c.people.update(landlord.copyWith(diedAt: 50)));
      final (next, heir) = Housing.inheritLandlord(c, factory)!;
      expect(heir.isAlive, isTrue);
      expect(heir.surname, landlord.surname);
      expect(heir.hasRole(RoleKind.evSahibi), isTrue);
      expect(next.people[landlord.id]!.hasRole(RoleKind.evSahibi), isFalse);
      expect(Housing.inheritLandlord(next, factory), isNull);
    },
  );

  test('ev arkadaşıyla kira yarı; ev arkadaşı aynı cinsiyette ve yaşıt', () {
    final c = Housing.shareFlat(testCharacter(age: 22), factory);
    expect(c.home, HomeKind.evArkadasi);
    expect(Economy.rentDue(c), Economy.rentFor(c.city) ~/ 2);
    final mate = withRole(c, RoleKind.evArkadasi)!;
    expect(mate.gender, c.gender);
    expect(mate.ageAt(22), inInclusiveRange(20, 25));
  });

  test('aileye dönünce kira biter, ev sahibi "eski" olur', () {
    final renter = Housing.rentAlone(testCharacter(age: 20), factory);
    final back = Housing.backToFamily(renter);
    expect(back.home, HomeKind.aile);
    expect(Economy.rentDue(back), 0);
    final landlord = back.people.all.firstWhere(
      (p) => p.hasRole(RoleKind.evSahibi, activeOnly: false),
    );
    expect(landlord.hasRole(RoleKind.evSahibi), isFalse);
  });

  test('ev alma: peşinat nakitten, kalanı kredi; satınca kredi kapanır', () {
    final buyer = testCharacter(age: 30, money: 2000000);
    final owner = Housing.buyHouse(buyer);
    expect(owner.home, HomeKind.kendiEvi);
    expect(owner.assets.houses, 1);
    expect(owner.stats.money, 2000000 - Housing.housePayment(buyer));
    final loan = owner.assets.remainingLoan;
    expect(loan, greaterThan(0));

    final sold = Housing.sellHouse(owner, factory);
    expect(sold.assets.houses, 0);
    expect(sold.assets.hasLoan, isFalse);
    expect(
      sold.stats.money,
      owner.stats.money + Economy.houseValueIn(buyer.city) - loan,
    );
    expect(sold.home, HomeKind.kira, reason: 'oturduğu evi satan kiraya çıkar');
  });

  test('araba: ehliyet ister; peşinat ve kredi; satınca değeri gelir', () {
    final action = ActionCatalog.byId('araba_al')!;
    expect(action.isAvailableFor(testCharacter(age: 25)), isFalse);
    final licensed = testCharacter(
      age: 25,
      money: 1000000,
      flags: {'ehliyet_var'},
    );
    expect(action.isAvailableFor(licensed), isTrue);
    final c = Housing.buyCar(licensed);
    expect(c.assets.cars, 1);
    expect(c.stats.money, 1000000 - Housing.carPayment(licensed));
    final sold = Housing.sellCar(c);
    expect(sold.assets.cars, 0);
    expect(
      sold.stats.money,
      c.stats.money + Economy.newCarValue - c.assets.remainingLoan,
    );
    expect(sold.assets.hasLoan, isFalse, reason: 'satış krediyi kapatır');
  });

  test('aile evine dönüş yalnızca anne ya da baba o şehirdeyse', () {
    final action = ActionCatalog.byId('aileye_don')!;
    final renter = testCharacter(age: 25, home: HomeKind.kira);
    expect(action.isAvailableFor(renter), isFalse, reason: 'ailesi yok');
    final withMother = withPeople(renter, [
      testPerson(
        'x',
        kin: Kinship.anne,
        gender: Gender.kadin,
        age: 50,
        playerAge: 25,
      ),
    ]);
    expect(action.isAvailableFor(withMother), isTrue);
    final away = withPeople(renter, [
      testPerson(
        'x',
        kin: Kinship.anne,
        gender: Gender.kadin,
        age: 50,
        playerAge: 25,
        city: 'Rize',
      ),
    ]);
    expect(action.isAvailableFor(away), isFalse);
  });

  test('başka şehre taşınma: mahalle değişir, sayılır, iş biter', () {
    final start = Housing.ensureNeighbours(testCharacter(age: 30), factory);
    final oldNeighbour = withRole(start, RoleKind.komsu)!;
    final moved = Housing.moveTo(start, 'İzmir', factory);
    expect(moved.city, 'İzmir');
    expect(moved.home, HomeKind.kira);
    expect(moved.counters.moves, 1);
    expect(moved.hasFlag(Economy.movedFlag), isTrue);
    expect(
      moved.stats.money,
      start.stats.money - Housing.relocationCost('İzmir'),
    );
    expect(moved.people[oldNeighbour.id]!.hasRole(RoleKind.komsu), isFalse);
    final newNeighbour = withRole(moved, RoleKind.komsu)!;
    expect(newNeighbour.city, 'İzmir');
    expect(withRole(moved, RoleKind.bakkal)!.city, 'İzmir');

    // Eski şehre dönünce eski komşu yeniden komşu olur.
    final back = Housing.moveTo(moved, start.city, factory);
    expect(back.people[oldNeighbour.id]!.hasRole(RoleKind.komsu), isTrue);
  });

  test('motor: taşınma şartları ve sebepleri', () {
    // 18 yaş desteği büyük olan (varlıklı) bir aile seç: kira gücü yeter.
    late LifeEngine engine;
    for (var seed = 0; ; seed++) {
      engine = LifeEngine(
        deck: EventDeck(const []),
        seed: seed,
        families: realFamilies(),
      )..startLife();
      if (engine.state.character.background == FamilyBackground.varlikli) break;
    }
    MoveBlocked? reason(String city) =>
        engine.moveOptions().firstWhere((o) => o.$1 == city).$2;
    // Küçük bir şehir: kirası ucuz.
    final other = Cities.all.firstWhere(
      (city) =>
          city != engine.state.character.city &&
          Cities.typeOf(city) == CityType.kucuk,
    );
    expect(reason(other), MoveBlocked.yas);
    while (engine.state.character.age < 18) {
      engine.advanceYear();
    }
    expect(reason(engine.state.character.city), MoveBlocked.ayniSehir);
    expect(reason(other), isNull, reason: '18 yaş desteğiyle parası yeter');
    final state = engine.moveTo(other);
    expect(state.character.city, other);
    expect(state.timeLeft, ActionCatalog.timeFor(state.character) - 2);
    expect(state.character.ledger.last.source, MoneySource.tasinma);
  });

  test('emekli bakkalın yerine yenisi gelir', () {
    var c = Housing.ensureNeighbours(testCharacter(age: 30), factory);
    final grocer = withRole(c, RoleKind.bakkal)!;
    c = c.copyWith(
      people: c.people.update(
        grocer.copyWith(roles: [for (final r in grocer.roles) r.ended()]),
      ),
    );
    c = Housing.ensureNeighbours(c, factory);
    final next = withRole(c, RoleKind.bakkal)!;
    expect(next.id, isNot(grocer.id));
  });
}
