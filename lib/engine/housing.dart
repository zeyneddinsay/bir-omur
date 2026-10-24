import 'dart:math';

import '../models/models.dart';
import 'business.dart';
import 'economy.dart';
import 'person_factory.dart';
import 'relationships.dart';

/// Ev, araba ve taşınma kararları (Varlıklar sekmesi). Canlı doküman:
/// "Ev, şehir ve taşınma".
///
/// - Evden çıkınca kiraya geçilir, ev sahibi kişi olarak eklenir.
/// - Ev arkadaşıyla kira yarıya iner, ev arkadaşı kişi olarak eklenir.
/// - Ev ve araba parası yetiyorsa peşin, yetmiyorsa peşinatla (%20) alınır;
///   taksit düzenli gelirin yarısını geçemez. Satış önce krediyi kapatır.
/// - Başka şehre taşınınca mahalle değişir: eski komşu ve bakkal "eski"
///   olur, yeni şehirde yenileri (ya da o şehirdeki eskiler) gelir.
abstract final class Housing {
  /// Evden çıkma, taşınma ve kredi bu yaştan itibaren.
  static const int minAge = 18;

  /// 55 yaşından sonra memleketine taşınınca açılan bayrak (rozet).
  static const String homecomingFlag = 'memlekete_dondu';

  /// Ev ve arabada peşinat oranı.
  static const double downPaymentShare = 0.2;
  static const int houseLoanYears = 10;
  static const int carLoanYears = 5;

  /// Taksit (eski krediyle birlikte) düzenli gelirin bu oranını geçemez.
  static const double maxPaymentShare = 0.5;

  /// Ev ya da araba için peşin ödenecek tutar: para yetiyorsa tamamı,
  /// yetmiyorsa %20 peşinat.
  static int housePayment(Character c) => _payment(c, housePrice(c));

  static int carPayment(Character c) => _payment(c, Economy.newCarValue);

  static int housePrice(Character c) => Economy.houseValueIn(c.city);

  static int _payment(Character c, int price) =>
      c.stats.money >= price ? price : (price * downPaymentShare).round();

  /// Bu yılın düzenli geliri: maaş, emekli ya da yaşlılık aylığı ve
  /// işletme kârı (deftere bu yaşta yazılanlar).
  static int regularIncome(Character c) {
    var income = 0;
    for (final e in c.ledger) {
      if (e.age != c.age) continue;
      final regular = switch (e.source) {
        MoneySource.maas ||
        MoneySource.emekliAyligi ||
        MoneySource.yasliAyligi => true,
        // İşletmenin kârı ve kredi taksidi.
        MoneySource.isletme =>
          (e.ref ?? '').endsWith(':kar') || (e.ref ?? '').endsWith(':kredi'),
        _ => false,
      };
      if (regular) income += e.amount;
    }
    return max(0, income);
  }

  /// Ev ya da araba alınabilir mi: peşin ödenebiliyorsa evet; yoksa
  /// peşinat nakitten, taksit (eski krediyle birlikte) gelirin yarısını
  /// geçmemeli.
  static bool canFinance(Character c, {required bool house}) {
    final price = house ? housePrice(c) : Economy.newCarValue;
    if (c.stats.money >= price) return true;
    final loan = _loanFor(c, price, house: house);
    final a = c.assets;
    final years = max(loan.years, a.loanYearsLeft);
    final payment = (a.remainingLoan + loan.yearlyPayment * loan.years) / years;
    return payment <= regularIncome(c) * maxPaymentShare;
  }

  static LoanTerms _loanFor(Character c, int price, {required bool house}) =>
      LoanTerms(
        amount: price - _payment(c, price),
        years: house ? houseLoanYears : carLoanYears,
      );

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
  /// Borçlanan yaşlının yanına taşınma eşiği: bu yaştan sonra, kirada ve bu
  /// kadar borçluyken bir çocuğu onu yanına alır.
  static const int elderAge = 65;
  static const int elderDebtLimit = 500000;

  /// Yanına alacak çocuk en az bu yaşta (kendi evini kurmuş).
  static const int hostChildMinAge = 25;

  /// Borçlanan yaşlı (65+, kirada, borcu [elderDebtLimit] üstünde) hayattaki
  /// yetişkin bir çocuğunun yanına taşınır: önce aynı şehirdeki, sonra en
  /// yakın olduğu çocuk. Kira ve yaşam gideri biter; aylık borcu yavaş yavaş
  /// kapatır. Eşi de gelir. Çocuğun hafızasına anı yazılır. Uygun çocuk
  /// yoksa null (borç tavanı geçerli kalır).
  static (Character, Person)? moveInWithChild(
    Character c,
    PersonFactory f, {
    bool force = false,
  }) {
    if (!force &&
        (c.age < elderAge ||
            !c.home.paysRent ||
            c.stats.money > -elderDebtLimit)) {
      return null;
    }
    final children = [
      for (final p in c.people.all)
        if (p.kin == Kinship.cocuk &&
            p.isAlive &&
            p.ageAt(c.age) >= hostChildMinAge)
          p,
    ];
    if (children.isEmpty) return null;
    int score(Person p) =>
        (p.city == c.city ? 1000 : 0) +
        Relationships.closeness(p, c.age).round();
    children.sort((a, b) => score(b).compareTo(score(a)));
    var host = children.first.copyWith(
      roles: [...children.first.roles, const PersonRole(RoleKind.evSahibi)],
      lastContactAt: c.age,
    );
    host = Relationships.addMemory(
      host,
      Memory(
        kind: 'yanima_aldim',
        label: 'Yaşlanınca beni yanına aldım',
        age: c.age,
        tone: MemoryTone.olumlu,
        severity: 1,
      ),
      now: c.age,
    );
    var next = _leaveCurrentHome(c);
    next = next.copyWith(
      people: next.people.update(host),
      home: HomeKind.cocukYaninda,
      assets: next.assets.copyWith(rent: 0),
    );
    if (host.city != c.city) {
      next = settle(next.copyWith(city: host.city), f);
    }
    return (Economy.syncDerivedFlags(next), host);
  }

  /// Yanında yaşadığı çocuk vefat ettiyse başka bir yetişkin çocuğu onu
  /// yanına alır; kimse kalmadıysa yeniden kiraya çıkar.
  static Character rehomeIfHostGone(Character c, PersonFactory f) {
    if (c.home != HomeKind.cocukYaninda) return c;
    final hosted = c.people.all.any(
      (p) =>
          p.isAlive && p.kin == Kinship.cocuk && p.hasRole(RoleKind.evSahibi),
    );
    if (hosted) return c;
    if (moveInWithChild(c, f, force: true) case (final moved, _)) return moved;
    return rentAlone(c, f);
  }

  static Character backToFamily(Character c) =>
      _leaveCurrentHome(c).copyWith(home: HomeKind.aile);

  /// Ev alır ve içine taşınır; peşinat nakitten, kalanı kredi.
  static Character buyHouse(Character c) {
    final price = housePrice(c);
    final down = housePayment(c);
    final loan = down < price ? _loanFor(c, price, house: true) : null;
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
    final proceeds = houseSaleProceeds(c);
    final sold = Economy.applyAssetEffect(c, const Effect(house: -1));
    var next = sold.copyWith(
      assets: sold.assets.copyWith(loanPayment: 0, loanYearsLeft: 0),
      stats: c.stats.withMoneyDelta(proceeds),
    );
    if (c.home == HomeKind.kendiEvi && next.assets.houses == 0) {
      next = rentAlone(next, f);
    }
    return Economy.syncDerivedFlags(next);
  }

  /// Satılan evin nakde etkisi (kredi kalanı düşülmüş).
  static int houseSaleProceeds(Character c) => c.assets.houses == 0
      ? 0
      : c.assets.houseValue ~/ c.assets.houses - c.assets.remainingLoan;

  static Character buyCar(Character c) {
    final down = carPayment(c);
    final loan = down < Economy.newCarValue
        ? _loanFor(c, Economy.newCarValue, house: false)
        : null;
    final next = Economy.applyAssetEffect(c, Effect(car: 1, loan: loan));
    return Economy.syncDerivedFlags(
      next.copyWith(stats: next.stats.withMoneyDelta(-down)),
    );
  }

  /// Arabayı satar; kredinin kalanı önce satıştan ödenir.
  static Character sellCar(Character c) {
    final proceeds = carSaleValue(c);
    final next = Economy.applyAssetEffect(c, const Effect(car: -1));
    return Economy.syncDerivedFlags(
      next.copyWith(
        assets: next.assets.copyWith(loanPayment: 0, loanYearsLeft: 0),
        stats: next.stats.withMoneyDelta(proceeds),
      ),
    );
  }

  /// Arabanın satışından nakde geçen: bugünkü değeri eksi kalan kredi.
  static int carSaleValue(Character c) =>
      (c.assets.cars == 0 ? 0 : c.assets.carValue ~/ c.assets.cars) -
      c.assets.remainingLoan;

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
      counters: next.counters.copyWith(
        moves: next.counters.moves + 1,
        lastMoveAt: c.age,
      ),
    );
    // Yaşlılığında memleketine dönen.
    if (city == c.hometown && c.age >= 55) {
      next = next.copyWith(flags: {...next.flags, homecomingFlag});
    }
    next = moveHousehold(next);
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

  /// Kira ve yaşam giderini karşılayabilir mi: düzenli geliri yetiyor ya da
  /// üç yıllık gideri cebinde.
  static bool canAffordHome(Character c, int rent) {
    final yearly = rent + Economy.livingCost;
    return regularIncome(c) >= yearly || c.stats.money >= 3 * yearly;
  }

  /// Eş ve 18 yaşından küçük çocuklar oyuncunun şehrine taşınır.
  static Character moveHousehold(Character c) {
    var book = c.people;
    for (final p in book.all.toList()) {
      final household =
          p.isAlive &&
          p.city != c.city &&
          (p.kin == Kinship.es ||
              (p.kin == Kinship.cocuk && p.ageAt(c.age) < 19));
      if (household) book = book.update(p.copyWith(city: c.city));
    }
    return c.copyWith(people: book);
  }

  /// Okul yüzünden şehir ya da ev değişince (yurda yerleşme, mezuniyet):
  /// mahalle değişir; kiraya çıkana şehrin kirası ve ev sahibi gelir.
  static Character settle(Character c, PersonFactory f) {
    var next = changeNeighbourhood(c, f);
    next = moveHousehold(next);
    // Başka şehirdeki işletme müdüre kalır.
    for (final b in next.businesses) {
      if (b.present && b.city != next.city) {
        next = BusinessRules.setPresent(next, b.id, false, f);
      }
    }
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
    final (book, _) = f.addOrReuse(
      c.people,
      now: c.age,
      minAge: 40,
      maxAge: 72,
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

  /// Orada ailesi yok ve geliri kirayı karşılamıyor.
  gelir,
}
