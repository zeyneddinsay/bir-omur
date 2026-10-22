import 'dart:math';

import '../models/models.dart';
import 'business_types.dart';
import 'person_factory.dart';
import 'relationships.dart';

/// İşletme açılamıyorsa sebebi.
enum BusinessBlocked {
  yas,

  /// Ön şart tutmuyor (yazılım için yazılımcılık ya da bilgisayar diploması).
  sart,

  /// Peşinata bile para yetmiyor.
  para,

  /// Aynı türde bir işletmesi zaten var.
  zatenVar,

  /// En fazla iki işletme.
  cokFazla,

  /// Bu türde işletmesi batalı iki yıl olmadı.
  iflas,

  /// Bu yılın vakti yetmiyor.
  vakit,
  askerde,
}

/// Bir işletmenin yılı.
class BusinessYear {
  const BusinessYear({
    required this.businessId,
    required this.type,
    required this.profit,
    required this.ownerShare,
    this.loanPaid = 0,
    this.bankrupt = false,
  });

  final String businessId;
  final String type;

  /// İşletmenin net kârı (eksi zarar).
  final int profit;

  /// Oyuncuya düşen pay (ortak payı düşülmüş).
  final int ownerShare;
  final int loanPaid;

  /// Nakit eksiye düşüp zarar edince zorunlu kapandı.
  final bool bankrupt;
}

/// İşletme kuralları (canlı doküman, "Kendi işin").
abstract final class BusinessRules {
  /// Motorun bayrakları: bir işletmesi üç şubeye ulaştı; bir akrabasını
  /// ortak etti; en az bir işletme açtı.
  static const String chainFlag = 'zincir_sahibi';
  static const String kinPartnerFlag = 'akraba_ortak';
  static const String ownerFlag = 'isletme_acti';
  static const Set<String> ownedFlags = {chainFlag, kinPartnerFlag, ownerFlag};

  /// Aynı anda en fazla iki işletme.
  static const int maxBusinesses = 2;

  /// Açmak ve büyütmek 2 vakit; reklam 1.
  static const int openTimeCost = 2;
  static const int adTimeCost = 1;

  /// Kredi: kuruluşun en fazla %70'i, 5 yıl.
  static const double maxLoanShare = 0.7;
  static const int loanYears = 5;

  /// Batan türü yeniden açmak için beklenecek yıl.
  static const int bankruptcyWait = 2;

  /// Müdürün yıllık maaşı (başında durulmazken).
  static const int managerWage = 450000;

  /// Ortak, kuruluşun bu oranı kadar sermaye koyar ve kârın bu oranını alır.
  static const double partnerShare = 0.3;

  /// Reklamın bedeli (kuruluşun oranı) ve itibara etkisi.
  static const double adCostShare = 0.05;
  static const int adReputation = 10;

  /// Kapatırken dükkân kirası cezası (yıllık sabit giderin dörtte biri).
  static int closingPenalty(Business b) {
    final t = BusinessTypes.require(b.type);
    return t.fixedCost * b.branches ~/ 4;
  }

  /// Ekipman değeri: kuruluşun %40'ı (şube başına).
  static int equipmentValue(Business b) {
    final t = BusinessTypes.require(b.type);
    return (t.setupCost * 0.4).round() * b.branches;
  }

  /// Satış değeri: ekipman + son yılların ortalama kârının iki katı (kâr
  /// ediyorsa).
  static int saleValue(Business b) {
    final avg = b.profits.isEmpty
        ? 0
        : b.profits.reduce((a, c) => a + c) ~/ b.profits.length;
    return equipmentValue(b) + (avg > 0 ? avg * 2 : 0) - remainingLoan(b);
  }

  static int remainingLoan(Business b) => b.loanPayment * b.loanYearsLeft;

  /// Kendi isteğiyle kapatınca eline geçen: ekipmanın yarısı, eksi kira
  /// cezası ve kalan kredi.
  static int closingValue(Business b) =>
      equipmentValue(b) ~/ 2 - closingPenalty(b) - remainingLoan(b);

  /// Bu işletmeyi açmak için gereken peşin para (krediyle %30).
  static int downPayment(BusinessType t, {required bool loan}) =>
      loan ? (t.setupCost * (1 - maxLoanShare)).round() : t.setupCost;

  /// Kredi verilir mi: işi varsa ya da itibarı 50 ve üstüyse.
  static bool loanAllowed(Character c) =>
      c.job != null || c.stats.reputation >= 50;

  static String ownerOccupation(String type) => switch (type) {
    'simit' => 'simitci',
    'berber' => 'berber',
    'oto_yikama' => 'oto_yikamaci',
    _ => 'yazilimci',
  };

  static BusinessBlocked? openBlocked(
    Character c,
    BusinessType t, {
    required int timeLeft,
  }) {
    if (c.hasFlag('askerde')) return BusinessBlocked.askerde;
    if (c.age < t.minAge) return BusinessBlocked.yas;
    if (!BusinessTypes.qualifies(c, t)) return BusinessBlocked.sart;
    if (c.businesses.any((b) => b.type == t.id)) {
      return BusinessBlocked.zatenVar;
    }
    if (c.businesses.length >= maxBusinesses) return BusinessBlocked.cokFazla;
    final failed = c.bankruptcies[t.id];
    if (failed != null && c.age - failed < bankruptcyWait) {
      return BusinessBlocked.iflas;
    }
    final canLoan = loanAllowed(c);
    if (c.stats.money < downPayment(t, loan: canLoan)) {
      return BusinessBlocked.para;
    }
    if (timeLeft < openTimeCost) return BusinessBlocked.vakit;
    return null;
  }

  /// İşletme açar. Para yetmezse (ve kredi verilirse) kalanı kredi.
  /// Çalışanlar ve mahalledeki rakipler kişi olarak gelir.
  static Character open(Character c, BusinessType t, PersonFactory f) {
    final useLoan = c.stats.money < t.setupCost;
    final down = downPayment(t, loan: useLoan);
    final loanAmount = t.setupCost - down;
    final loan = useLoan
        ? LoanTerms(amount: loanAmount, years: loanYears)
        : null;
    var people = c.people;
    final staff = <String>[];
    for (var i = 0; i < t.staffPerBranch; i++) {
      final Person p;
      (people, p) = f.add(
        people,
        now: c.age,
        age: f.between(19, 45),
        city: c.city,
        origin: Origin.isYeri,
        base: 15,
        roles: const [PersonRole(RoleKind.calisan)],
      );
      staff.add(p.id);
    }
    // Mahallede aynı işi yapan 0–2 rakip.
    final rivals = f.random.nextInt(3);
    for (var i = 0; i < rivals; i++) {
      (people, _) = f.add(
        people,
        now: c.age,
        age: f.between(30, 60),
        city: c.city,
        origin: Origin.mahalle,
        base: 5,
        roles: const [PersonRole(RoleKind.rakip)],
        occupation: ownerOccupation(t.id),
      );
    }
    // Aynı türden aynı anda bir işletme olduğu için tür ve yaş benzersiz.
    final id = '${t.id}_${c.age}';
    final business = Business(
      id: id,
      type: t.id,
      name: c.surname,
      city: c.city,
      openedAt: c.age,
      staff: staff,
      loanPayment: loan?.yearlyPayment ?? 0,
      loanYearsLeft: loan?.years ?? 0,
    );
    return c.copyWith(
      stats: c.stats.withMoneyDelta(-down),
      people: people,
      businesses: [...c.businesses, business],
      flags: {...c.flags, ownerFlag},
    );
  }

  /// Rakip sayısı: aynı şehirde, aynı işi yapan, rakip rolü süren kişiler.
  static int rivalCount(Character c, Business b) => c.people
      .active(c.age)
      .where(
        (p) =>
            p.city == b.city &&
            p.hasRole(RoleKind.rakip) &&
            p.occupation == ownerOccupation(b.type),
      )
      .length;

  /// Yılın ekonomisi: enflasyon %35'i aşarsa kriz (0,85), %20'nin altında
  /// iyi yıl (1,1).
  static double economyFactor(double inflation) {
    if (inflation > 0.35) return 0.85;
    if (inflation < 0.20) return 1.1;
    return 1.0;
  }

  static double reputationFactor(Business b) {
    var f = 0.7 + b.reputation / 100 * 0.6;
    // Pahalıda müşteri itibara daha duyarlı.
    if (b.price == PriceLevel.pahali) f = 1 + (f - 1) * 2;
    return f;
  }

  static double priceFactor(PriceLevel p) => switch (p) {
    PriceLevel.ucuz => 0.9,
    PriceLevel.normal => 1.0,
    PriceLevel.pahali => 1.1,
  };

  static double managementFactor(Business b, BusinessType t) {
    if (b.present) return 1.1;
    return t.laborBound ? 0.6 : 0.95;
  }

  /// Müdür sayısı: başında durulmazsa ana dükkân için bir, her ek şube
  /// için bir.
  static int managers(Business b) => b.branches - 1 + (b.present ? 0 : 1);

  /// Bir yılın beklenen (şanssız) kârı; arayüz tahmin olarak gösterir.
  static int expectedProfit(Character c, Business b, {double inflation = 0.3}) {
    final t = BusinessTypes.require(b.type);
    return _profit(c, b, t, economyFactor(inflation), 1.0);
  }

  static int _profit(
    Character c,
    Business b,
    BusinessType t,
    double economy,
    double luck,
  ) {
    final rivals = max(0.5, 1 - 0.1 * rivalCount(c, b));
    // Ek şubeleri müdür yönetir (kendi ustası olduğu için emek işinde de
    // 0,95).
    final management = managementFactor(b, t) + (b.branches - 1) * 0.95;
    final revenue =
        t.revenue *
        management *
        reputationFactor(b) *
        economy *
        priceFactor(b.price) *
        rivals *
        luck;
    final costs =
        (t.fixedCost + t.wages) * b.branches + managers(b) * managerWage;
    return (revenue - costs).round();
  }

  /// Yaşlanınca işletmelerin yılı: kâr ya da zarar, kredi taksidi, ortak
  /// payı, itibar kayması; nakit eksiye düşüp zarar edeni batırır.
  static (Character, List<BusinessYear>) yearOf(
    Character c,
    double inflation,
    Random random,
  ) {
    if (c.businesses.isEmpty) return (c, const []);
    final reports = <BusinessYear>[];
    final kept = <Business>[];
    var money = c.stats.money;
    var people = c.people;
    var bankruptcies = {...c.bankruptcies};
    for (final b in c.businesses) {
      final t = BusinessTypes.require(b.type);
      // Yılın şansı: ortalaması 1, oynama payı türüne göre.
      final luck =
          1 + t.volatility * ((random.nextDouble() + random.nextDouble()) - 1);
      final profit = _profit(c, b, t, economyFactor(inflation), luck);
      final share = profit > 0
          ? (profit * (1 - b.partnerShare)).round()
          : profit;
      final loanPaid = b.loanYearsLeft > 0 ? b.loanPayment : 0;
      money += share - loanPaid;
      final drift = switch (b.price) {
        PriceLevel.ucuz => 2,
        PriceLevel.normal => 0,
        PriceLevel.pahali => b.reputation >= 70 ? 0 : -2,
      };
      final next = b.copyWith(
        // İtibar her yıl ortaya uzaklığının onda biri kadar döner.
        reputation:
            (b.reputation +
                    drift +
                    (profit > 0 ? 1 : -2) +
                    ((50 - b.reputation) / 10).round())
                .clamp(0, 100),
        profits: [
          ...b.profits,
          profit,
        ].reversed.take(3).toList().reversed.toList(),
        loanYearsLeft: max(0, b.loanYearsLeft - 1),
        loanPayment: b.loanYearsLeft > 1 ? b.loanPayment : 0,
      );
      final bankrupt = money < 0 && profit < 0;
      reports.add(
        BusinessYear(
          businessId: b.id,
          type: b.type,
          profit: profit,
          ownerShare: share,
          loanPaid: loanPaid,
          bankrupt: bankrupt,
        ),
      );
      if (bankrupt) {
        // Ekipman yarı fiyatına satılır; kalan kredi borca kalır.
        money += equipmentValue(next) ~/ 2 - remainingLoan(next);
        people = _releaseStaff(people, next, c.age, bitter: true);
        bankruptcies[b.type] = c.age;
      } else {
        kept.add(next);
      }
    }
    return (
      c.copyWith(
        stats: c.stats.copyWith(money: money),
        businesses: kept,
        people: people,
        bankruptcies: bankruptcies,
      ),
      reports,
    );
  }

  /// Çalışanlar ve müdür "eski çalışan" olur; ortaklık biter. Batışta
  /// ortağa kırgınlık yazılır.
  static PeopleBook _releaseStaff(
    PeopleBook people,
    Business b,
    int now, {
    required bool bitter,
  }) {
    var book = people;
    for (final id in [...b.staff, ?b.managerId]) {
      final p = book[id];
      if (p == null) continue;
      book = book.update(
        p.copyWith(
          roles: [
            for (final r in p.roles)
              r.kind == RoleKind.calisan || r.kind == RoleKind.mudur
                  ? r.ended()
                  : r,
          ],
        ),
      );
    }
    if (b.partnerId case final id?) {
      final p = book[id];
      if (p != null) {
        var next = p.copyWith(
          roles: [
            for (final r in p.roles) r.kind == RoleKind.ortak ? r.ended() : r,
          ],
        );
        if (bitter) {
          next = Relationships.addMemory(
            next,
            Memory(
              kind: 'ortaklik_batti',
              label: 'Ortaklığımız battı, sermayem gitti',
              age: now,
              tone: MemoryTone.olumsuz,
              severity: 2,
            ),
            now: now,
          );
        }
        book = book.update(next);
      }
    }
    return book;
  }

  static Business? _find(Character c, String id) =>
      c.businesses.where((b) => b.id == id).firstOrNull;

  static Character _replace(Character c, Business b) => c.copyWith(
    businesses: [for (final x in c.businesses) x.id == b.id ? b : x],
  );

  /// Başında durur ya da müdüre bırakır. Müdür ilk bırakışta kişi olarak
  /// gelir.
  static Character setPresent(
    Character c,
    String id,
    bool present,
    PersonFactory f,
  ) {
    final b = _find(c, id)!;
    if (b.present == present) return c;
    if (present || b.managerId != null) {
      return _replace(c, b.copyWith(present: present));
    }
    final (people, manager) = f.add(
      c.people,
      now: c.age,
      age: f.between(30, 55),
      city: b.city,
      origin: Origin.isYeri,
      base: 15,
      roles: const [PersonRole(RoleKind.mudur)],
    );
    return _replace(
      c.copyWith(people: people),
      b.copyWith(present: false, managerId: manager.id),
    );
  }

  static Character setPrice(Character c, String id, PriceLevel price) =>
      _replace(c, _find(c, id)!.copyWith(price: price));

  static int adCost(Business b) =>
      (BusinessTypes.require(b.type).setupCost * adCostShare).round() *
      b.branches;

  static bool canAdvertise(Character c, Business b) =>
      b.advertisedAt != c.age && c.stats.money >= adCost(b);

  static Character advertise(Character c, String id) {
    final b = _find(c, id)!;
    return _replace(
      c.copyWith(stats: c.stats.withMoneyDelta(-adCost(b))),
      b.copyWith(
        advertisedAt: c.age,
        reputation: (b.reputation + adReputation).clamp(0, 100),
      ),
    );
  }

  /// Şube açmanın ya da büyütmenin bedeli.
  static int expandCost(Business b) {
    final t = BusinessTypes.require(b.type);
    if (t.upgradeTo case final up?) return BusinessTypes.require(up).setupCost;
    return t.setupCost;
  }

  /// Şube açılabilir ya da büyütülebilir mi: kâr eden, en az 2 yıllık,
  /// sınırın altında, parası yeten.
  static bool canExpand(Character c, Business b) {
    final t = BusinessTypes.require(b.type);
    if (c.age - b.openedAt < 2) return false;
    if ((b.lastProfit ?? 0) <= 0) return false;
    if (t.upgradeTo == null && b.branches >= t.maxBranches) return false;
    return c.stats.money >= expandCost(b);
  }

  /// Şube açar (çalışanlar gelir) ya da tek kişilik yazılımı ekipli
  /// şirkete dönüştürür.
  static Character expand(Character c, String id, PersonFactory f) {
    final b = _find(c, id)!;
    final t = BusinessTypes.require(b.type);
    final cost = expandCost(b);
    final target = t.upgradeTo == null
        ? t
        : BusinessTypes.require(t.upgradeTo!);
    var people = c.people;
    final staff = [...b.staff];
    for (var i = 0; i < target.staffPerBranch; i++) {
      final Person p;
      (people, p) = f.add(
        people,
        now: c.age,
        age: f.between(22, 40),
        city: b.city,
        origin: Origin.isYeri,
        base: 15,
        roles: const [PersonRole(RoleKind.calisan)],
      );
      staff.add(p.id);
    }
    final next = t.upgradeTo == null
        ? b.copyWith(branches: b.branches + 1, staff: staff)
        : Business(
            id: b.id,
            type: target.id,
            name: b.name,
            city: b.city,
            openedAt: b.openedAt,
            reputation: b.reputation,
            price: b.price,
            present: b.present,
            staff: staff,
            managerId: b.managerId,
            partnerId: b.partnerId,
            partnerShare: b.partnerShare,
            profits: b.profits,
            advertisedAt: b.advertisedAt,
            loanPayment: b.loanPayment,
            loanYearsLeft: b.loanYearsLeft,
          );
    return _replace(
      c.copyWith(
        stats: c.stats.withMoneyDelta(-cost),
        people: people,
        flags: {...c.flags, if (next.branches >= 3) chainFlag},
      ),
      next,
    );
  }

  /// İşe alınabilecek tanıdıklar: aynı şehirde, 18–60 yaşında, işi olmayan
  /// ya da sıradan işte çalışan, kırgın olmayan ve henüz bu işletmede
  /// olmayan. Yalnızca çalışanı olan işletmede.
  static List<Person> hireCandidates(Character c, Business b) {
    if (b.staff.isEmpty) return const [];
    const busy = {'memur', 'ogretmen', 'polis', 'doktor', 'emekli'};
    return [
      for (final p in c.people.active(c.age))
        if (p.isAlive &&
            p.city == b.city &&
            p.ageAt(c.age) >= 18 &&
            p.ageAt(c.age) <= 60 &&
            !busy.contains(p.occupation) &&
            !b.staff.contains(p.id) &&
            p.id != b.managerId &&
            p.id != b.partnerId &&
            Relationships.closeness(p, c.age) >= 30 &&
            Relationships.hostility(p, c.age) < 40)
          p,
    ];
  }

  /// Tanıdığını işe alır: yabancı bir çalışanın yerine geçer (o "eski
  /// çalışan" olur). Tanıdık güvenilirdir: itibar +3; ona olumlu anı
  /// yazılır.
  static Character hireKnown(Character c, String id, String personId) {
    final b = _find(c, id)!;
    final p = c.people[personId]!;
    final replaced = b.staff.firstWhere(
      (s) => c.people[s]?.kin == null,
      orElse: () => b.staff.first,
    );
    var book = c.people;
    if (book[replaced] case final old?) {
      book = book.update(
        old.copyWith(
          roles: [
            for (final r in old.roles)
              r.kind == RoleKind.calisan ? r.ended() : r,
          ],
        ),
      );
    }
    book = book.update(
      Relationships.addMemory(
        p.copyWith(roles: [...p.roles, const PersonRole(RoleKind.calisan)]),
        Memory(
          kind: 'ise_aldi',
          label: 'Beni dükkânına işe aldı',
          age: c.age,
          tone: MemoryTone.olumlu,
          severity: 2,
        ),
        now: c.age,
      ),
    );
    return _replace(
      c.copyWith(people: book),
      b.copyWith(
        staff: [
          for (final s in b.staff)
            if (s == replaced) personId else s,
        ],
        reputation: (b.reputation + 3).clamp(0, 100),
      ),
    );
  }

  /// Ortak olabilecek tanıdıklar: yakın (50+), varlıklı ya da rahat,
  /// husumeti düşük, yetişkin.
  static List<Person> partnerCandidates(Character c, Business b) {
    if (b.partnerId != null) return const [];
    return [
      for (final p in c.people.active(c.age))
        if (p.ageAt(c.age) >= 25 &&
            (p.wealth == WealthLevel.rahat || p.wealth == WealthLevel.zengin) &&
            Relationships.closeness(p, c.age) >= 50 &&
            Relationships.hostility(p, c.age) < 40)
          p,
    ];
  }

  static int partnerCapital(Business b) =>
      (BusinessTypes.require(b.type).setupCost * partnerShare).round() *
      b.branches;

  /// Ortak alır: ortak sermaye koyar, kârın payını alır.
  static Character takePartner(Character c, String id, String personId) {
    final b = _find(c, id)!;
    final p = c.people[personId]!;
    final people = c.people.update(
      Relationships.addMemory(
        p.copyWith(roles: [...p.roles, const PersonRole(RoleKind.ortak)]),
        Memory(
          kind: 'ortak_oldu',
          label: 'İşine ortak olmamı istedi',
          age: c.age,
          tone: MemoryTone.olumlu,
          severity: 1,
        ),
        now: c.age,
      ),
    );
    return _replace(
      c.copyWith(
        people: people,
        stats: c.stats.withMoneyDelta(partnerCapital(b)),
        flags: {...c.flags, if (p.kin != null) kinPartnerFlag},
      ),
      b.copyWith(partnerId: personId, partnerShare: partnerShare),
    );
  }

  /// İşletmeyi satar ya da kapatır; çalışanlar "eski" olur.
  static Character dispose(Character c, String id, {required bool sell}) {
    final b = _find(c, id)!;
    final value = sell ? saleValue(b) : closingValue(b);
    return c.copyWith(
      stats: c.stats.withMoneyDelta(value),
      people: _releaseStaff(c.people, b, c.age, bitter: false),
      businesses: [
        for (final x in c.businesses)
          if (x.id != id) x,
      ],
    );
  }
}
