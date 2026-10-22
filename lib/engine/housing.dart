import 'dart:math';

import '../models/models.dart';
import 'economy.dart';
import 'person_factory.dart';

/// Ev, araba ve taşınma kararları (Varlıklar sekmesi). Canlı doküman:
/// "Ev, şehir ve taşınma".
///
/// - Evden çıkınca kiraya geçilir, ev sahibi kişi olarak eklenir.
/// - Ev arkadaşıyla kira yarıya iner, ev arkadaşı kişi olarak eklenir.
/// - Ev ve araba peşinatla (%20) alınır, kalanı krediyle ödenir.
/// - Başka şehre taşınınca mahalle değişir: eski komşu ve bakkal "eski"
///   olur, yeni şehirde yenileri (ya da o şehirdeki eskiler) gelir.
abstract final class Housing {
  /// Evden çıkma, taşınma ve kredi bu yaştan itibaren.
  static const int minAge = 18;

  /// Ev ve arabada peşinat oranı.
  static const double downPaymentShare = 0.2;
  static const int houseLoanYears = 10;
  static const int carLoanYears = 5;

  static int houseDownPayment() =>
      (Economy.houseValue * downPaymentShare).round();

  static int carDownPayment() =>
      (Economy.newCarValue * downPaymentShare).round();

  /// Kiraya girerken depozito ve nakliye: yıllık kiranın dörtte biri.
  static int moveInCost(String city) => Economy.rentFor(city) ~/ 4;

  /// Ev arkadaşıyla girerken payına düşen depozito.
  static int shareMoveInCost(String city) => Economy.rentFor(city) ~/ 8;

  /// Başka şehre taşınmanın nakliye ve depozito gideri: yeni şehrin yıllık
  /// kirasının yarısı.
  static int relocationCost(String city) => Economy.rentFor(city) ~/ 2;

  /// Oyuncunun yaşadığı şehirde hayatta olan anne ya da baba var mı.
  static bool hasParentInCity(Character c) => Economy.parentInCity(c);

  /// Kirada tek başına: ev sahibi yeni kişi.
  static Character rentAlone(Character c, PersonFactory f) {
    var next = _leaveCurrentHome(c);
    next = next.copyWith(
      home: HomeKind.kira,
      assets: next.assets.copyWith(rent: Economy.rentFor(c.city)),
    );
    return _addLandlord(next, f);
  }

  /// Ev arkadaşıyla: ev arkadaşı ve ev sahibi yeni kişiler.
  static Character shareFlat(Character c, PersonFactory f) {
    var next = _leaveCurrentHome(c);
    next = next.copyWith(
      home: HomeKind.evArkadasi,
      assets: next.assets.copyWith(rent: Economy.rentFor(c.city)),
    );
    final (book, _) = f.add(
      next.people,
      now: c.age,
      age: max(18, c.age + f.between(-2, 3)),
      city: c.city,
      origin: Origin.kendin,
      base: 20,
      gender: c.gender,
      roles: const [PersonRole(RoleKind.evArkadasi)],
      marital: MaritalStatus.bekar,
    );
    return _addLandlord(next.copyWith(people: book), f);
  }

  /// Aileye dönüş: kira biter.
  static Character backToFamily(Character c) =>
      _leaveCurrentHome(c).copyWith(home: HomeKind.aile);

  /// Ev alır ve içine taşınır; peşinat nakitten, kalanı kredi.
  static Character buyHouse(Character c) {
    final down = houseDownPayment();
    final loan = LoanTerms(
      amount: Economy.houseValue - down,
      years: houseLoanYears,
    );
    var next = Economy.applyAssetEffect(
      _leaveCurrentHome(c),
      Effect(house: 1, loan: loan),
    );
    next = next.copyWith(
      home: HomeKind.kendiEvi,
      stats: next.stats.withMoneyDelta(-down),
    );
    return Economy.syncDerivedFlags(next);
  }

  /// Evi satar; kredinin kalanı satıştan ödenir. Evde oturuyorsa kiraya
  /// geçer.
  static Character sellHouse(Character c, PersonFactory f) {
    final a = c.assets;
    final proceeds = Economy.houseValue - a.remainingLoan;
    var next = c.copyWith(
      assets: a.copyWith(
        houses: a.houses - 1,
        loanPayment: 0,
        loanYearsLeft: 0,
      ),
      stats: c.stats.withMoneyDelta(proceeds),
    );
    if (c.home == HomeKind.kendiEvi && next.assets.houses == 0) {
      next = rentAlone(next, f);
    }
    return Economy.syncDerivedFlags(next);
  }

  /// Satılan evin nakde etkisi (kredi kalanı düşülmüş).
  static int houseSaleProceeds(Character c) =>
      Economy.houseValue - c.assets.remainingLoan;

  static Character buyCar(Character c) {
    final down = carDownPayment();
    final loan = LoanTerms(
      amount: Economy.newCarValue - down,
      years: carLoanYears,
    );
    final next = Economy.applyAssetEffect(c, Effect(car: 1, loan: loan));
    return Economy.syncDerivedFlags(
      next.copyWith(stats: next.stats.withMoneyDelta(-down)),
    );
  }

  static Character sellCar(Character c) {
    final value = c.assets.cars == 0 ? 0 : c.assets.carValue ~/ c.assets.cars;
    final next = Economy.applyAssetEffect(c, const Effect(car: -1));
    return Economy.syncDerivedFlags(
      next.copyWith(stats: next.stats.withMoneyDelta(value)),
    );
  }

  /// Bir arabanın bugünkü satış değeri.
  static int carSaleValue(Character c) =>
      c.assets.cars == 0 ? 0 : c.assets.carValue ~/ c.assets.cars;

  /// Başka şehre taşınır: kiraya geçer (ailesi o şehirdeyse ve isterse
  /// aileyle yaşar), mahalle değişir.
  static Character moveTo(
    Character c,
    String city,
    PersonFactory f, {
    bool withFamily = false,
  }) {
    var next = _leaveCurrentHome(c);
    next = next.copyWith(
      city: city,
      stats: next.stats.withMoneyDelta(-relocationCost(city)),
      counters: next.counters.copyWith(moves: next.counters.moves + 1),
    );
    next = changeNeighbourhood(next, f);
    if (withFamily && hasParentInCity(next)) {
      next = next.copyWith(home: HomeKind.aile);
    } else {
      next = next.copyWith(
        home: HomeKind.kira,
        assets: next.assets.copyWith(rent: Economy.rentFor(city)),
      );
      next = _addLandlord(next, f);
    }
    return Economy.syncDerivedFlags(next);
  }

  /// Oyuncunun şehrinde komşu teyze ve bakkal yoksa (vefat, emeklilik,
  /// taşınma) yenisi gelir. Her yıl motor çağırır.
  static Character ensureNeighbours(Character c, PersonFactory f) {
    // Yurtta komşu teyze ve bakkal yok.
    if (c.home == HomeKind.yurt) return c;
    var book = c.people;
    bool has(RoleKind role) =>
        book.active(c.age).any((p) => p.city == c.city && p.hasRole(role));
    if (!has(RoleKind.komsu)) {
      (book, _) = f.add(
        book,
        now: c.age,
        age: f.between(45, 65),
        city: c.city,
        origin: Origin.mahalle,
        base: 25,
        gender: Gender.kadin,
        roles: const [PersonRole(RoleKind.komsu)],
        requiredTrait: Trait.dedikoducu,
        occupation: 'ev_hanimi',
        marital: MaritalStatus.evli,
      );
    }
    if (!has(RoleKind.bakkal)) {
      (book, _) = f.add(
        book,
        now: c.age,
        age: f.between(35, 60),
        city: c.city,
        origin: Origin.mahalle,
        base: 20,
        gender: Gender.erkek,
        roles: const [PersonRole(RoleKind.bakkal)],
        occupation: 'bakkal',
        marital: MaritalStatus.evli,
      );
    }
    return identical(book, c.people) ? c : c.copyWith(people: book);
  }

  /// Okul yüzünden şehir ya da ev değişince (yurda yerleşme, mezuniyet):
  /// mahalle değişir; kiraya çıkana şehrin kirası ve ev sahibi gelir.
  static Character settle(Character c, PersonFactory f) {
    var next = changeNeighbourhood(c, f);
    final hasLandlord = next.people
        .active(next.age)
        .any((p) => p.hasRole(RoleKind.evSahibi));
    if (next.home == HomeKind.kira && !hasLandlord) {
      next = _addLandlord(
        next.copyWith(
          assets: next.assets.copyWith(rent: Economy.rentFor(next.city)),
        ),
        f,
      );
    }
    return Economy.syncDerivedFlags(next);
  }

  /// Eski şehrin komşu ve bakkal rolleri biter; yeni şehirde rolü bitmiş
  /// eski tanıdık komşular varsa geri döner, yoksa yenileri gelir.
  static Character changeNeighbourhood(Character c, PersonFactory f) {
    var book = c.people;
    const local = {RoleKind.komsu, RoleKind.bakkal};
    for (final p in book.bornBy(c.age).toList()) {
      if (!p.isAlive) continue;
      final hasLocal = p.roles.any((r) => local.contains(r.kind));
      if (!hasLocal) continue;
      final here = p.city == c.city;
      book = book.update(
        p.copyWith(
          roles: [
            for (final r in p.roles)
              if (local.contains(r.kind))
                PersonRole(r.kind, active: here)
              else
                r,
          ],
          archived: here ? false : p.archived,
        ),
      );
    }
    return ensureNeighbours(c.copyWith(people: book), f);
  }

  /// Eski evin ev sahibi ve ev arkadaşı rolleri biter.
  static Character _leaveCurrentHome(Character c) {
    var book = c.people;
    const homeRoles = {RoleKind.evSahibi, RoleKind.evArkadasi};
    for (final p in book.all.toList()) {
      if (!p.roles.any((r) => r.active && homeRoles.contains(r.kind))) {
        continue;
      }
      book = book.update(
        p.copyWith(
          roles: [
            for (final r in p.roles) homeRoles.contains(r.kind) ? r.ended() : r,
          ],
        ),
      );
    }
    return c.copyWith(people: book);
  }

  static Character _addLandlord(Character c, PersonFactory f) {
    final (book, _) = f.add(
      c.people,
      now: c.age,
      age: f.between(40, 72),
      city: c.city,
      origin: Origin.kendin,
      base: 15,
      roles: const [PersonRole(RoleKind.evSahibi)],
      wealth: WealthLevel.rahat,
    );
    return c.copyWith(people: book);
  }
}

/// Bir şehre neden taşınılamadığı.
enum MoveBlocked {
  /// Bu yılın vakti yetmiyor (taşınma 2 vakit).
  vakit,
  para,

  /// 18 yaşından küçük.
  yas,

  /// Üniversite öğrencisi; okuduğu şehirden taşınamaz.
  ogrenci,

  /// Kendi evinde oturuyor; önce evi satmalı.
  evSahibi,

  /// Zaten bu şehirde.
  ayniSehir,
}
