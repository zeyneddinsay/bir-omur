import 'dart:math';

import '../models/models.dart';
import 'person_factory.dart';
import 'relationships.dart';

/// Kız isteme sahnesi: oyuncu erkekse damat, kadınsa gelin tarafı.
enum ProposalScene { damat, gelin }

/// Aşk, evlilik ve çocuklar (canlı doküman, "Aşk, evlilik ve çocuklar").
///
/// - Romantik ilişki yalnızca karşı cinsle kurulur (karar, 23 Ekim 2026).
/// - Romantik bağ 18 yaşından itibaren ve yaş kuralıyla: küçük olanın yaşı en
///   az büyüğün yarısı artı 7.
/// - Yol: arkadaş → flört (duygularını açıkla) → sevgili (ciddi düşünüyorum)
///   → nişanlı (teklif) → kız isteme (bir yıl sonra) → düğün (iki yıl sonra).
abstract final class Romance {
  /// Motorun türettiği bayraklar: hayatta bir eşi var; hayatta bir çocuğu
  /// var.
  static const String marriedFlag = 'evli';
  static const String parentFlag = 'cocuklu';

  /// Süren bir romantik ilişki (flört, sevgili, nişanlı); en az bir kez
  /// evlenmiş.
  static const String datingFlag = 'iliskide';
  static const String everMarriedFlag = 'evlenmis';
  static const Set<String> derivedFlags = {
    marriedFlag,
    parentFlag,
    datingFlag,
    everMarriedFlag,
  };

  /// Motorun planladığı olaylar.
  static const String weddingEvent = 'dugun';
  static const String birthEvent = 'bebek_dogdu';
  static const Map<ProposalScene, String> proposalEvents = {
    ProposalScene.damat: 'kiz_isteme_damat',
    ProposalScene.gelin: 'kiz_isteme_gelin',
  };

  /// Olaylardaki yuva adları.
  static const String partnerSlot = 'nisanli';
  static const String spouseSlot = 'es';

  static const int minAge = 18;

  /// "Biriyle tanış" aksiyonunun bedeli (kafe, kurs).
  static const int meetCost = 3000;
  static const int proposalMinAge = 20;

  /// Çocuk kararı bu yaş aralığında (oyuncu ve kadın eş için üst sınır).
  static const int childMinAge = 20;
  static const int childMaxAge = 45;

  /// Erkek oyuncu ve iki erkekte evlat edinme için üst yaş.
  static const int fatherMaxAge = 55;

  /// Bu yaştan sonra evlilik kız isteme ve düğün olmadan olur: teklif kabul
  /// edilince gelecek yıl belediyede sade bir nikâh ([lateWeddingEvent]).
  static const int lateMarriageAge = 70;
  static const String lateWeddingEvent = 'gec_nikah';

  /// En fazla çocuk; yeni karar için en küçüğün en az bu yaşta olması.
  static const int maxChildren = 4;
  static const int childGap = 2;

  /// Çocuk kararı için şimdilik erken mi: en küçük çocuk küçük ya da
  /// bebek yolda.
  static bool childTooSoon(Character c) {
    final kids = c.people.all
        .where((p) => p.kin == Kinship.cocuk && p.isAlive)
        .toList();
    if (kids.length >= maxChildren) return true;
    return kids.any((k) => k.ageAt(c.age) < childGap);
  }

  /// Eşiklerin yakınlıkları.
  static const int confessMin = 50;
  static const int seriousMin = 60;
  static const int proposeMin = 75;
  static const int childMin = 60;

  /// Flörtten sevgiliye geçmek için en az bir yıl.
  static const int datingYears = 1;

  static const Set<Bond> romanticBonds = {
    Bond.flort,
    Bond.sevgili,
    Bond.nisanli,
  };

  /// Romantik ilişkinin kurulabileceği cinsiyet: karşı cins.
  static Gender partnerGender(Character c) =>
      c.gender == Gender.erkek ? Gender.kadin : Gender.erkek;

  /// Yaş kuralı: ikisi de 18+ ve küçük olan en az büyüğün yarısı artı 7.
  static bool agesFit(int a, int b) {
    if (a < minAge || b < minAge) return false;
    final older = max(a, b);
    final younger = min(a, b);
    return younger >= older ~/ 2 + 7;
  }

  /// Hayattaki eş; yoksa null.
  static Person? spouse(Character c) =>
      c.people.all.where((p) => p.kin == Kinship.es && p.isAlive).firstOrNull;

  /// Süren romantik ilişki (flört, sevgili, nişanlı); yoksa null.
  static Person? partner(Character c) => c.people.all
      .where((p) => p.isAlive && romanticBonds.contains(p.bond))
      .firstOrNull;

  static bool isSingle(Character c) => spouse(c) == null && partner(c) == null;

  /// Eşini son iki yılda kaybetti: yas süresince yeni ilişki açılmaz.
  static bool mourning(Character c) => c.people.all.any(
    (p) => p.kin == Kinship.es && p.diedAt != null && c.age - p.diedAt! < 2,
  );

  /// Bu kişiye duygularını açabilir mi (yakınlık hariç).
  static bool canCourt(Character c, Person p) =>
      isSingle(c) &&
      !mourning(c) &&
      p.isAlive &&
      p.kin == null &&
      p.marital == MaritalStatus.bekar &&
      !romanticBonds.contains(p.bond) &&
      p.bond != Bond.eskiEs &&
      p.gender == partnerGender(c) &&
      agesFit(c.age, p.ageAt(c.age));

  /// Flörtün başladığı yaş ("açıldı" anısı); yoksa null.
  static int? datingSince(Person p) =>
      p.memories.where((m) => m.kind == 'acildi').map((m) => m.age).lastOrNull;

  static ProposalScene sceneFor(Character c, Person p) =>
      c.gender == Gender.erkek ? ProposalScene.damat : ProposalScene.gelin;

  /// Çocuk kararı açılır mı: eşle, yaşlar uygun, yakınlık hariç.
  static bool childAgeFits(Character c, Person spouse) {
    if (c.age < childMinAge) return false;
    final mothers = [
      if (c.gender == Gender.kadin) c.age,
      if (spouse.gender == Gender.kadin) spouse.ageAt(c.age),
    ];
    if (c.gender == Gender.erkek && c.age > fatherMaxAge) return false;
    if (spouse.gender == Gender.erkek && spouse.ageAt(c.age) > fatherMaxAge) {
      return false;
    }
    return mothers.every((age) => age <= childMaxAge);
  }

  /// Evlenir: nişanlı eş olur, iki taraf da evli; eşin anne ve babası
  /// (kayınvalide, kayınpeder) çevreye girer. Aile evinde yaşayan oyuncu
  /// kiraya çıkar (motor [Housing] ile yapar).
  static Character marry(Character c, String personId, PersonFactory f) {
    final p = c.people[personId]!;
    // Önceki evliliğin kayın ailesi artık kayın değildir.
    var book = clearInLaws(c.people);
    book = book.update(
      Relationships.addMemory(
        p.copyWith(
          kin: Kinship.es,
          clearBond: true,
          marital: MaritalStatus.evli,
          city: c.city,
          // Kadın eş kocasının soyadını alır; kayın aile kendi soyadıyla gelir
          // (aşağıda p.surname).
          surname: p.gender == Gender.kadin && c.surname.isNotEmpty
              ? c.surname
              : null,
          // Eş artık ev sahibin ya da ev arkadaşın değildir.
          roles: [
            for (final r in p.roles)
              r.kind == RoleKind.evSahibi || r.kind == RoleKind.evArkadasi
                  ? r.ended()
                  : r,
          ],
        ),
        Memory(
          kind: 'evlendik',
          label: 'Evlendik',
          age: c.age,
          tone: MemoryTone.olumlu,
          severity: 3,
        ),
        now: c.age,
      ),
    );
    final age = p.ageAt(c.age);
    for (final (kin, gender) in [
      (Kinship.kayinvalide, Gender.kadin),
      (Kinship.kayinpeder, Gender.erkek),
    ]) {
      // Kayın aile çoğunlukla hayatta; yaşları eşe göre.
      final parentAge = age + f.between(22, 34);
      if (parentAge > 85 || f.random.nextDouble() < 0.1) continue;
      (book, _) = addKinPerson(
        book,
        f,
        now: c.age,
        age: parentAge,
        city: p.city,
        kin: kin,
        gender: gender,
        surname: p.surname,
        base: 35,
      );
    }
    return c.copyWith(people: book);
  }

  /// Kayınvalide ve kayınpederin akrabalığı biter (boşanma, yeniden
  /// evlilik); tanıdık olarak kalırlar.
  static PeopleBook clearInLaws(PeopleBook book) {
    var next = book;
    for (final p in book.all) {
      if (p.kin == Kinship.kayinvalide || p.kin == Kinship.kayinpeder) {
        next = next.update(p.copyWith(clearKin: true, bond: Bond.tanidik));
      }
    }
    return next;
  }

  /// Ayrılık: flört, sevgili ya da nişan biterse eski sevgili; eşten
  /// boşanırsa eski eş olur ve evlilikte biriken nakit yarı yarıya bölünür.
  static (Character, int split) breakUp(Character c, String personId) {
    final p = c.people[personId]!;
    final divorce = p.kin == Kinship.es;
    // Boşanan kadın kızlık soyadına döner (anne ve babasınınki).
    final maiden = divorce && p.gender == Gender.kadin
        ? c.people.all
              .where(
                (x) =>
                    x.kin == Kinship.kayinvalide || x.kin == Kinship.kayinpeder,
              )
              .map((x) => x.surname)
              .lastOrNull
        : null;
    final book = divorce ? clearInLaws(c.people) : c.people;
    final next = p.copyWith(
      surname: maiden,
      clearKin: divorce,
      bond: divorce ? Bond.eskiEs : Bond.eskiSevgili,
      marital: divorce ? MaritalStatus.bekar : null,
    );
    final split = divorce && c.stats.money > 0 ? c.stats.money ~/ 2 : 0;
    return (
      c.copyWith(
        people: book.update(next),
        stats: c.stats.withMoneyDelta(-split),
      ),
      split,
    );
  }

  /// Bebek doğar ya da evlat edinilir. Adı: [name] verilirse o, yoksa
  /// bugünün adlarından rastgele.
  static (Character, Person) addChild(
    Character c,
    PersonFactory f, {
    required Gender gender,
    String? name,
  }) {
    final spouse = Romance.spouse(c);
    final surname = c.gender == Gender.erkek || spouse == null
        ? c.surname
        : spouse.gender == Gender.erkek
        ? spouse.surname
        : c.surname;
    final (book, child) = addKinPerson(
      c.people,
      f,
      now: c.age,
      age: 0,
      city: c.city,
      kin: Kinship.cocuk,
      gender: gender,
      surname: surname,
      base: 75,
      name: name,
    );
    return (c.copyWith(people: book), child);
  }

  /// Çocuğun adı için iki öneri: kayın ailenin büyüğünün adı (çocuğun
  /// cinsiyetinde) ve annenin önerisi (bugünün adlarından).
  static ({String inLaw, String mother}) nameSuggestions(
    Character c,
    Gender gender,
    PersonFactory f,
  ) {
    // Çocukların, oyuncunun ve eşin adı yeniden önerilmez.
    final taken = {
      c.name,
      for (final p in c.people.all)
        if (p.kin == Kinship.cocuk || p.kin == Kinship.es) p.name,
    };
    String pick(List<String> names) {
      final free = [
        for (final n in names)
          if (!taken.contains(n)) n,
      ];
      final pool = free.isEmpty ? names : free;
      return pool[f.random.nextInt(pool.length)];
    }

    // Büyüklerin adı: kayın aile ya da oyuncunun anne-babası, dede-ninesi.
    const elders = {
      Kinship.kayinpeder,
      Kinship.kayinvalide,
      Kinship.anne,
      Kinship.baba,
      Kinship.dede,
      Kinship.nine,
    };
    final elderNames = [
      for (final p in c.people.all)
        if (p.gender == gender &&
            elders.contains(p.kin) &&
            !taken.contains(p.name))
          p.name,
    ];
    final inLaw = elderNames.isNotEmpty
        ? elderNames[f.random.nextInt(elderNames.length)]
        : pick(f.families.namesFor(gender, NameEra.eski));
    taken.add(inLaw);
    final mother = pick(f.families.namesFor(gender, NameEra.yeni));
    return (inLaw: inLaw, mother: mother);
  }

  static (PeopleBook, Person) addKinPerson(
    PeopleBook book,
    PersonFactory f, {
    required int now,
    required int age,
    required String city,
    required Kinship kin,
    required Gender gender,
    required String surname,
    required int base,
    String? name,
  }) {
    final chosen =
        name ??
        f.pickName(
          f.families.namesFor(gender, NameEra.forAgeGap(age - now)),
          taken: PersonFactory.takenNames(book),
        );
    final trait = Trait.values[f.random.nextInt(Trait.values.length)];
    final seed = f.random.nextInt(1 << 30);
    return book.add(
      (id) => Person(
        id: id,
        name: chosen,
        surname: surname,
        gender: gender,
        bornAt: now - age,
        city: city,
        origin: Origin.aile,
        metAt: now,
        base: base,
        portraitSeed: seed,
        kin: kin,
        traits: {trait},
        marital: age >= 25 ? MaritalStatus.evli : MaritalStatus.bekar,
        occupation: age >= 65 ? 'emekli' : null,
        lastContactAt: now,
      ),
    );
  }

  /// Biriyle tanışır (kafe, kurs, arkadaş ortamı): karşı cinsten, yaş
  /// kuralına uyan, bekâr, aynı şehirden biri arkadaş olarak gelir.
  static Character meet(Character c, PersonFactory f) {
    final gender = partnerGender(c);
    final low = max(minAge, c.age ~/ 2 + 7);
    final high = max(low, min(c.age + 6, (c.age - 7) * 2));
    final (book, _) = f.add(
      c.people,
      now: c.age,
      age: f.between(low, high),
      city: c.city,
      origin: Origin.kendin,
      base: 45,
      gender: gender,
      marital: MaritalStatus.bekar,
      bond: Bond.arkadas,
    );
    return c.copyWith(people: book);
  }

  /// Motorun bayrakları: eş ve çocuk.
  static Character syncFlags(Character c) {
    final flags = {...c.flags};
    void set(String flag, bool on) => on ? flags.add(flag) : flags.remove(flag);
    set(marriedFlag, spouse(c) != null);
    set(datingFlag, partner(c) != null);
    set(
      everMarriedFlag,
      c.people.all.any((p) => p.kin == Kinship.es || p.bond == Bond.eskiEs),
    );
    set(
      parentFlag,
      c.people.all.any((p) => p.kin == Kinship.cocuk && p.isAlive),
    );
    if (flags.length == c.flags.length && flags.containsAll(c.flags)) return c;
    return c.copyWith(flags: flags);
  }
}
