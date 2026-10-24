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

  /// Bu türdeki işletmesini satalı ya da kapatalı iki yıl olmadı.
  yeniKapandi,

  /// Para peşinata yetiyor ama kredi verilmiyor (iş ya da itibar yok).
  kredi,

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
    this.liquidation = 0,
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

  /// Batışta ekipman satışı eksi kalan kredi.
  final int liquidation;
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

  /// Açmak ve büyütmek 2 vakit; reklam ve tanıdık işe almak 1.
  static const int openTimeCost = 2;
  static const int adTimeCost = 1;

  /// Kredi: kuruluşun en fazla %70'i, 5 yıl, 18 yaşından itibaren.
  static const double maxLoanShare = 0.7;
  static const int loanYears = 5;
  static const int minLoanAge = 18;

  /// Batan, satılan ya da kapatılan türü yeniden açmak için beklenecek yıl.
  static const int bankruptcyWait = 2;
  static const int exitWait = 2;

  /// Müdürün yıllık maaşı (başında durulmazken ve ek şubelerde).
  static const int managerWage = 340000;

  /// Bu işletmenin müdür (ya da tezgâhta duran usta) maaşı: cironun
  /// %35'i, en fazla [managerWage]. Simit tezgâhına 340 bin maaşlı müdür
  /// tutulmaz; askerdeki ya da başka işteki sahibi batmasın.
  static int managerWageFor(BusinessType t) =>
      min(managerWage, (t.revenue * 0.35).round());

  /// Ortak, kuruluşun bu oranı kadar sermaye koyar ve kârın bu oranını alır.
  static const double partnerShare = 0.3;

  /// Reklam: bedeli kuruluşun oranı; o yılın cirosunu artırır, itibara
  /// kalıcı küçük bir katkısı olur.
  static const double adCostShare = 0.05;
  static const double adBoost = 0.1;
  static const int adReputation = 3;

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

  /// Satış değeri: ekipman + ortalama kârın kâr geçmişine göre katı (1 yıl
  /// 0, 2 yıl 1, 3 yıl 2 kat); zarardaysa yalnızca ekipman. Kalan kredi
  /// düşülür.
  static int saleValue(Business b) {
    final avg = b.profits.isEmpty
        ? 0
        : b.profits.reduce((a, c) => a + c) ~/ b.profits.length;
    final multiple = max(0, b.profits.length - 1);
    return equipmentValue(b) +
        (avg > 0 ? avg * multiple : 0) -
        remainingLoan(b);
  }

  /// Alıcı yalnızca son yılı kârlı işletmeye çıkar; zarardaki kapatılır.
  static bool canSell(Business b) => (b.lastProfit ?? 0) > 0;

  static int remainingLoan(Business b) => b.loanPayment * b.loanYearsLeft;

  /// Kendi isteğiyle kapatınca: ekipmanın yarısı, eksi kira cezası ve kalan
  /// kredi.
  static int closingValue(Business b) =>
      equipmentValue(b) ~/ 2 - closingPenalty(b) - remainingLoan(b);

  /// Ortağın çıkışta alacağı: sermayesi ya da değerden payı, hangisi
  /// büyükse; değer yetmezse değer kadar.
  static int partnerPayout(Business b, int value) {
    if (b.partnerId == null || value <= 0) return 0;
    return min(value, max(b.partnerCapital, (value * b.partnerShare).round()));
  }

  /// Satışta ya da kapanışta oyuncunun eline geçen (ortağın payı düşülmüş).
  static int exitValue(Business b, {required bool sell}) {
    final value = sell ? saleValue(b) : closingValue(b);
    return value - partnerPayout(b, value);
  }

  /// Bu işletmeyi açmak için gereken peşin para (krediyle %30).
  static int downPayment(BusinessType t, {required bool loan}) =>
      loan ? (t.setupCost * (1 - maxLoanShare)).round() : t.setupCost;

  /// Kredi verilir mi: 18 yaşında ve üstünde; işi varsa ya da itibarı 50
  /// ve üstüyse.
  static bool loanAllowed(Character c) =>
      c.age >= minLoanAge && (c.job != null || c.stats.reputation >= 50);

  static String ownerOccupation(String type) => switch (type) {
    'simit' => 'simitci',
    'berber' => 'berber',
    'oto_yikama' => 'oto_yikamaci',
    _ => 'yazilimci',
  };

  /// Aynı iş kolu mu: tek kişilik yazılım ile ekipli yazılım aynı koldur.
  static bool sameLine(String a, String b) =>
      a == b || a.startsWith('${b}_') || b.startsWith('${a}_');

  static BusinessBlocked? openBlocked(
    Character c,
    BusinessType t, {
    required int timeLeft,
  }) {
    if (c.hasFlag('askerde')) return BusinessBlocked.askerde;
    if (c.age < t.minAge) return BusinessBlocked.yas;
    if (!BusinessTypes.qualifies(c, t)) return BusinessBlocked.sart;
    if (c.businesses.any((b) => sameLine(b.type, t.id))) {
      return BusinessBlocked.zatenVar;
    }
    if (c.businesses.length >= maxBusinesses) return BusinessBlocked.cokFazla;
    bool recent(Map<String, int> ages, int wait) => ages.entries.any(
      (e) => sameLine(e.key, t.id) && c.age - e.value < wait,
    );
    if (recent(c.bankruptcies, bankruptcyWait)) return BusinessBlocked.iflas;
    if (recent(c.businessExits, exitWait)) return BusinessBlocked.yeniKapandi;
    final canLoan = loanAllowed(c);
    if (c.stats.money < downPayment(t, loan: canLoan)) {
      final loanWouldHelp =
          !canLoan && c.stats.money >= downPayment(t, loan: true);
      return loanWouldHelp ? BusinessBlocked.kredi : BusinessBlocked.para;
    }
    if (timeLeft < openTimeCost) return BusinessBlocked.vakit;
    return null;
  }

  /// Oyuncu işletmenin başında sayılır mı: başında durmayı seçmiş, aynı
  /// şehirde ve askerde değil.
  static bool isPresent(Character c, Business b) =>
      b.present && b.city == c.city && !c.hasFlag('askerde');

  /// Yeni bir yabancı çalışan.
  static (PeopleBook, Person) _hireStranger(
    PeopleBook people,
    Character c,
    String city,
    String type,
    PersonFactory f,
  ) => f.add(
    people,
    now: c.age,
    age: f.between(19, 45),
    city: city,
    origin: Origin.isYeri,
    base: 15,
    roles: const [PersonRole(RoleKind.calisan)],
    occupation: ownerOccupation(type),
  );

  /// İşletme açar. Para yetmezse (ve kredi verilirse) kalanı kredi.
  /// Çalışanlar ve mahalledeki rakipler kişi olarak gelir. İşi yoksa
  /// başında durur (öteki işletmesi müdüre kalır); işi varsa müdürle açar.
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
      (people, p) = _hireStranger(people, c, c.city, t.id, f);
      staff.add(p.id);
    }
    // Mahallede aynı işi yapan 0–2 rakip; dünya küçük: tanıdık çıkabilir.
    final rivals = f.random.nextInt(3);
    for (var i = 0; i < rivals; i++) {
      (people, _) = f.addOrReuse(
        people,
        now: c.age,
        minAge: 30,
        maxAge: 60,
        city: c.city,
        origin: Origin.mahalle,
        base: 5,
        roles: const [PersonRole(RoleKind.rakip)],
        occupation: ownerOccupation(t.id),
      );
    }
    // Aynı türden aynı anda bir işletme olduğu için tür ve yaş benzersiz.
    final id = '${t.id}_${c.age}';
    final present = c.job == null;
    final next = c.copyWith(
      stats: c.stats.withMoneyDelta(-down),
      people: people,
      businesses: [
        ...c.businesses,
        Business(
          id: id,
          type: t.id,
          name: c.surname,
          city: c.city,
          openedAt: c.age,
          staff: staff,
          // Başında durma seçimi müdürü ve öteki işletmeleri düzenler.
          present: !present,
          loanPayment: loan?.yearlyPayment ?? 0,
          loanYearsLeft: loan?.years ?? 0,
        ),
      ],
      flags: {...c.flags, ownerFlag},
    );
    return setPresent(next, id, present, f);
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
    if (b.price == PriceLevel.pahali) f = 1 + (f - 1) * 1.5;
    return f;
  }

  static double priceFactor(PriceLevel p) => switch (p) {
    PriceLevel.ucuz => 0.9,
    PriceLevel.normal => 1.0,
    PriceLevel.pahali => 1.1,
  };

  static double managementFactor(Character c, Business b, BusinessType t) {
    if (isPresent(c, b)) return 1.1;
    return t.laborBound ? 0.6 : 0.95;
  }

  /// Müdür maaşı ödenen kişi sayısı: başında durulmazsa ana dükkân için
  /// bir; emek işi olmayanlarda her ek şube için bir (emek işinde ek
  /// şubeyi oradaki usta yönetir).
  static int managers(Character c, Business b, BusinessType t) =>
      (t.laborBound ? 0 : b.branches - 1) + (isPresent(c, b) ? 0 : 1);

  /// Bu yılın beklenen (şanssız) kârı; arayüz tahmin olarak gösterir.
  static int expectedProfit(Character c, Business b, {double inflation = 0.3}) {
    final t = BusinessTypes.require(b.type);
    return _profit(
      c,
      b,
      t,
      economyFactor(inflation),
      1.0,
      advertised: b.advertisedAt == c.age,
    );
  }

  static int _profit(
    Character c,
    Business b,
    BusinessType t,
    double economy,
    double luck, {
    required bool advertised,
  }) {
    final rivals = max(0.5, 1 - 0.1 * rivalCount(c, b));
    // Ek şubeleri müdür ya da usta yönetir.
    final management = managementFactor(c, b, t) + (b.branches - 1) * 0.95;
    final revenue =
        t.revenue *
        management *
        reputationFactor(b) *
        economy *
        priceFactor(b.price) *
        rivals *
        luck *
        (advertised ? 1 + adBoost : 1);
    final costs =
        (t.fixedCost + t.wages) * b.branches +
        managers(c, b, t) * managerWageFor(t);
    return (revenue - costs).round();
  }

  /// Yaşlanınca işletmelerin yılı: kâr ya da zarar, kredi taksidi, ortak
  /// payı, itibar kayması. Yılın sonunda nakit eksideyse zarar eden
  /// işletmeler batar. [c] yaşlanmış karakterdir; reklam geçen yılın
  /// (bir önceki yaşın) aksiyonudur.
  static (Character, List<BusinessYear>) yearOf(
    Character c,
    double inflation,
    Random random,
  ) {
    if (c.businesses.isEmpty) return (c, const []);
    final drafts = <(Business next, int profit, int share, int loanPaid)>[];
    var money = c.stats.money;
    for (final b in c.businesses) {
      final t = BusinessTypes.require(b.type);
      // Yılın şansı: ortalaması 1, oynama payı türüne göre.
      final luck =
          1 + t.volatility * ((random.nextDouble() + random.nextDouble()) - 1);
      final profit = _profit(
        c,
        b,
        t,
        economyFactor(inflation),
        luck,
        advertised: b.advertisedAt == c.age - 1,
      );
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
      drafts.add((next, profit, share, loanPaid));
    }
    final broke = money < 0;
    final reports = <BusinessYear>[];
    final kept = <Business>[];
    var people = c.people;
    final bankruptcies = {...c.bankruptcies};
    for (final (next, profit, share, loanPaid) in drafts) {
      final bankrupt = broke && profit < 0;
      // Batışta ekipman yarı fiyatına satılır; kalan kredi borca kalır;
      // ortak sermayesini kaybeder.
      final liquidation = bankrupt
          ? equipmentValue(next) ~/ 2 - remainingLoan(next)
          : 0;
      money += liquidation;
      reports.add(
        BusinessYear(
          businessId: next.id,
          type: next.type,
          profit: profit,
          ownerShare: share,
          loanPaid: loanPaid,
          bankrupt: bankrupt,
          liquidation: liquidation,
        ),
      );
      if (bankrupt) {
        people = _releaseStaff(people, next, c.age, bitter: true);
        people = _endRivals(people, c, next);
        bankruptcies[next.type] = c.age;
      } else {
        kept.add(next);
      }
    }
    // İtibarlı ve kâr eden işletme sahibinin sözü dinlenir.
    final known = kept.any(
      (b) => b.reputation >= 70 && (b.lastProfit ?? 0) > 0,
    );
    final stats = c.stats.copyWith(money: money);
    return (
      c.copyWith(
        stats: known ? stats.withDelta(StatKind.reputation, 2) : stats,
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

  /// İşletme kapanınca o şehirde aynı işi yapan rakipler artık rakip
  /// değildir (aynı kolda başka işletmesi yoksa).
  static PeopleBook _endRivals(PeopleBook people, Character c, Business b) {
    final stillThere = c.businesses.any(
      (x) => x.id != b.id && x.city == b.city && sameLine(x.type, b.type),
    );
    if (stillThere) return people;
    var book = people;
    for (final p in book.all.toList()) {
      if (p.city != b.city ||
          !p.hasRole(RoleKind.rakip) ||
          p.occupation != ownerOccupation(b.type)) {
        continue;
      }
      book = book.update(
        p.copyWith(
          roles: [
            for (final r in p.roles) r.kind == RoleKind.rakip ? r.ended() : r,
          ],
        ),
      );
    }
    return book;
  }

  static Business? _find(Character c, String id) =>
      c.businesses.where((b) => b.id == id).firstOrNull;

  static Character _replace(Character c, Business b) => c.copyWith(
    businesses: [for (final x in c.businesses) x.id == b.id ? b : x],
  );

  /// Başında durur ya da müdüre bırakır. Başında durulan işletme tektir:
  /// öteki müdüre kalır. Müdür kişi olarak gelir (dünya küçük: tanıdık
  /// çıkabilir); başına dönülünce müdürün rolü biter.
  static Character setPresent(
    Character c,
    String id,
    bool present,
    PersonFactory f,
  ) {
    final b = _find(c, id)!;
    if (b.present == present) return c;
    var next = c;
    if (present) {
      for (final other in c.businesses) {
        if (other.id != id && other.present) {
          next = setPresent(next, other.id, false, f);
        }
      }
      var people = next.people;
      if (b.managerId case final m?) {
        if (people[m] case final manager?) {
          people = people.update(
            manager.copyWith(
              roles: [
                for (final r in manager.roles)
                  r.kind == RoleKind.mudur ? r.ended() : r,
              ],
            ),
          );
        }
      }
      return _replace(
        next.copyWith(people: people),
        b.copyWith(present: true, clearManager: true),
      );
    }
    final (people, manager) = f.addOrReuse(
      next.people,
      now: c.age,
      minAge: 30,
      maxAge: 55,
      city: b.city,
      origin: Origin.isYeri,
      base: 15,
      roles: const [PersonRole(RoleKind.mudur)],
    );
    return _replace(
      next.copyWith(people: people),
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
      (people, p) = _hireStranger(people, c, b.city, target.id, f);
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
            partnerCapital: b.partnerCapital,
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

  /// Yerine tanıdık alınabilecek yabancı çalışan (ilk gelenlerden, işe
  /// alınmış tanıdık değil).
  static String? _strangerOf(Character c, Business b) {
    for (final id in b.staff) {
      final p = c.people[id];
      if (p != null &&
          p.kin == null &&
          p.origin == Origin.isYeri &&
          !p.memories.any((m) => m.kind == 'ise_aldi')) {
        return id;
      }
    }
    return null;
  }

  /// İşe alınabilecek tanıdıklar: aynı şehirde, 18–60 yaşında, kamuda ya da
  /// emekli olmayan, yere bağlı bir rolü (patron, rakip, çalışan, ortak…)
  /// olmayan, kırgın olmayan. Yerine geçilecek yabancı çalışan yoksa boş.
  static List<Person> hireCandidates(Character c, Business b) {
    if (_strangerOf(c, b) == null) return const [];
    const busy = {'memur', 'ogretmen', 'polis', 'doktor', 'emekli'};
    return [
      for (final p in c.people.active(c.age))
        if (p.isAlive &&
            p.city == b.city &&
            p.ageAt(c.age) >= 18 &&
            p.ageAt(c.age) <= 60 &&
            !busy.contains(p.occupation) &&
            !p.roles.any(
              (r) => r.active && PersonFactory.placeRoles.contains(r.kind),
            ) &&
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
    final replaced = _strangerOf(c, b)!;
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
        p.copyWith(
          roles: [...p.roles, const PersonRole(RoleKind.calisan)],
          occupation: ownerOccupation(b.type),
        ),
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
  /// husumeti düşük, yetişkin; daha önce ortağı olmamış.
  static List<Person> partnerCandidates(Character c, Business b) {
    if (b.partnerId != null) return const [];
    return [
      for (final p in c.people.active(c.age))
        if (p.isAlive &&
            p.ageAt(c.age) >= 25 &&
            !p.hasRole(RoleKind.ortak, activeOnly: false) &&
            (p.wealth == WealthLevel.rahat || p.wealth == WealthLevel.zengin) &&
            Relationships.closeness(p, c.age) >= 50 &&
            Relationships.hostility(p, c.age) < 40)
          p,
    ];
  }

  static int partnerCapital(Business b) =>
      (BusinessTypes.require(b.type).setupCost * partnerShare).round() *
      b.branches;

  /// Ortak alır: ortak sermaye koyar, kârın payını alır; çıkışta en az
  /// sermayesini geri alır.
  static Character takePartner(Character c, String id, String personId) {
    final b = _find(c, id)!;
    final p = c.people[personId]!;
    final capital = partnerCapital(b);
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
        stats: c.stats.withMoneyDelta(capital),
        flags: {...c.flags, if (p.kin != null) kinPartnerFlag},
      ),
      b.copyWith(
        partnerId: personId,
        partnerShare: partnerShare,
        partnerCapital: capital,
      ),
    );
  }

  /// İşletmeyi satar ya da kapatır: ortak payını alır, çalışanlar "eski"
  /// olur, rakipler rakip olmaktan çıkar; aynı tür 2 yıl açılamaz.
  static Character dispose(Character c, String id, {required bool sell}) {
    final b = _find(c, id)!;
    var people = _releaseStaff(c.people, b, c.age, bitter: false);
    people = _endRivals(people, c, b);
    return c.copyWith(
      stats: c.stats.withMoneyDelta(exitValue(b, sell: sell)),
      people: people,
      businesses: [
        for (final x in c.businesses)
          if (x.id != id) x,
      ],
      businessExits: {...c.businessExits, b.type: c.age},
    );
  }

  /// Yılın sonunda: vefat eden ya da emekli olan (rolü biten) çalışan ve
  /// müdürün yerine yenisi gelir; vefat eden ortağın ortaklığı biter.
  static Character refreshStaff(Character c, PersonFactory f) {
    if (c.businesses.isEmpty) return c;
    var next = c;
    for (final b in c.businesses) {
      var people = next.people;
      bool gone(String id, RoleKind role) {
        final p = people[id];
        return p == null || !p.isAlive || !p.hasRole(role);
      }

      final staff = <String>[];
      for (final id in b.staff) {
        if (!gone(id, RoleKind.calisan)) {
          staff.add(id);
          continue;
        }
        if (people[id] case final p? when p.hasRole(RoleKind.calisan)) {
          people = people.update(
            p.copyWith(
              roles: [
                for (final r in p.roles)
                  r.kind == RoleKind.calisan ? r.ended() : r,
              ],
            ),
          );
        }
        final Person fresh;
        (people, fresh) = _hireStranger(people, next, b.city, b.type, f);
        staff.add(fresh.id);
      }
      var updated = b.copyWith(staff: staff);
      if (b.managerId case final m? when gone(m, RoleKind.mudur)) {
        final Person manager;
        (people, manager) = f.add(
          people,
          now: next.age,
          age: f.between(30, 55),
          city: b.city,
          origin: Origin.isYeri,
          base: 15,
          roles: const [PersonRole(RoleKind.mudur)],
        );
        updated = updated.copyWith(managerId: manager.id);
      }
      if (b.partnerId case final p? when !(people[p]?.isAlive ?? false)) {
        updated = updated.copyWith(clearPartner: true);
      }
      next = _replace(next.copyWith(people: people), updated);
    }
    return next;
  }
}
