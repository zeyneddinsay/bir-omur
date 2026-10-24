import 'dart:math';

import '../models/models.dart';
import 'people_tick.dart';
import 'relationships.dart';
import 'romance.dart';

/// Kişiyle yapılabilecek etkileşimler (İnsanlar sekmesi). İlk sürümün
/// listesi; "İş konuş" ve ortaklık D2 ve D3'te gelir.
enum InteractionKind {
  bulus,
  ara,
  hediye,
  dertles,
  borcIste,
  borcOde,
  lafSok,
  uzaklas,

  /// Anne: yemeğini öv.
  yemegiOv,

  /// Baba: maç izle.
  macIzle,

  /// Dede ve nine: elini öp.
  eliniOp,

  /// Kardeş: birlikte oyna.
  kardesleOyna,

  /// Komşu: çaya git.
  cayaGit,

  /// Duygularını açıkla: arkadaştan flörte.
  acil,

  /// "Ciddi düşünüyorum": flörtten sevgiliye.
  ciddi,

  /// Evlenme teklifi: sevgiliden nişanlıya.
  teklif,

  /// Ayrılmak ya da boşanmak.
  ayril,

  /// Eşle çocuk kararı.
  cocukIste,
}

/// Ara sohbetinin tonu.
enum CallTone { halHatir, nostalji, ozur, igne }

/// Bir etkileşimin neden yapılamadığı. Arayüz düğmeyi kapatır ve sebebi
/// gösterir.
enum Blocked {
  /// Bu yıl vakit kalmadı.
  vakit,

  /// Oyuncu bu etkileşim için çok küçük.
  yas,

  /// Karşıdaki kişi bu etkileşim için çok küçük.
  karsiYas,
  para,

  /// Kişi başka şehirde.
  uzak,
  yakinlikDusuk,

  /// Bu yıl bu kişiyle zaten yapıldı.
  buYil,

  /// Önce eski borç ödenmeli.
  borcVar,

  /// Bu tonda konuşacak bir anı yok.
  aniYok,

  /// Özür dileyecek bir kırgınlık yok.
  kirginlikYok,

  /// Flörtün üstünden henüz bir yıl geçmedi.
  erken,
}

/// İnsanlar sekmesindeki bir düğme: etkileşim, bedeli ve kapalıysa sebebi.
class InteractionOption {
  const InteractionOption(
    this.kind, {
    required this.timeCost,
    this.moneyCost = 0,
    this.blocked,
  });

  final InteractionKind kind;
  final int timeCost;
  final int moneyCost;
  final Blocked? blocked;

  bool get enabled => blocked == null;
}

/// Oyuncunun seçtiği etkileşim. Ara için [tone], nostalji ve iğnelemede
/// konuşulacak anının türü [memoryKind] gerekir.
class InteractionRequest {
  const InteractionRequest(
    this.kind,
    this.personId, {
    this.tone,
    this.memoryKind,
  });

  final InteractionKind kind;
  final String personId;
  final CallTone? tone;
  final String? memoryKind;
}

/// Etkileşimin sonucu. Metni arayüz [outcome] anahtarıyla
/// `assets/interactions.json` içinden kurar.
class InteractionResult {
  const InteractionResult({
    required this.kind,
    required this.personId,
    required this.outcome,
    required this.variant,
    this.tone,
    this.memory,
    this.healed = false,
    this.stats = const {},
    this.money = 0,
  });

  final InteractionKind kind;
  final String personId;
  final CallTone? tone;

  /// Metin anahtarı: `bulus.iyi`, `ara.nostalji.baristik`…
  final String outcome;

  /// Metin seçeneklerinden hangisi (0–999; arayüz listenin uzunluğuyla
  /// böler).
  final int variant;

  /// Kişinin ya da oyuncunun hafızasına yazılan anı; yoksa null.
  final Memory? memory;

  /// Olumsuz bir anı yumuşadı mı.
  final bool healed;
  final Map<StatKind, int> stats;
  final int money;
}

/// Etkileşim kuralları. Tutarlar bugünün TL'siyle; D2'de ekonomi gerçek
/// rakamlara çekilince güncellenir.
abstract final class Interactions {
  /// Etkileşimin istediği en az yakınlık (dertleşme, aşk adımları); arayüz
  /// kapalı seçeneğin altında "yakınlık en az 50 olmalı" diye gösterir.
  static int? closenessNeeded(InteractionKind kind) => switch (kind) {
    InteractionKind.dertles => confideMin,
    InteractionKind.acil => Romance.confessMin,
    InteractionKind.ciddi => Romance.seriousMin,
    InteractionKind.teklif => Romance.proposeMin,
    InteractionKind.cocukIste => Romance.childMin,
    _ => null,
  };

  static const int giftCost = 1500;
  static const int travelCost = 3000;
  static const int pocketMoney = 600;

  /// Borç istendiğinde kişinin verebileceği tutar, servetine göre.
  static const Map<WealthLevel, int> loanAmount = {
    WealthLevel.dar: 7000,
    WealthLevel.orta: 33000,
    WealthLevel.rahat: 80000,
    WealthLevel.zengin: 200000,
  };

  /// Uzun aradan sonra arama: bu kadar yıl görüşülmemişse ilk aramanın
  /// anısı 1,5 kat sayılır (kişi başına bir kez).
  static const int longGap = 5;
  static const double longGapBonus = 1.5;

  /// Dertleşmek için gereken yakınlık.
  static const int confideMin = 30;

  /// Bu yakınlığın altında olup husumeti yüksek kişi telefonu açmayabilir
  /// ya da hediyeyi geri çevirebilir.
  static const int coldHostility = 60;

  /// Nostalji ve iğneleme menüsünde gösterilen en fazla anı.
  static const int callMemoryChoices = 3;

  /// Her etkileşimin yazabileceği anıların türleri (metinleri
  /// `assets/interactions.json` içinde).
  static const List<String> memoryKinds = [
    'bulus',
    'bulus_tartisma',
    'hediye',
    'dertles',
    'borcunu_odedi',
    'borc_vermedi',
    'laf_soktu',
    'aradi',
    'yillar_sonra',
    'eski_gunler',
    'baristik',
    'hala_kirgin',
    'ozur_diledi',
    'igneledi',
    'yemegini_ovdu',
    'mac_izledik',
    'elini_optu',
    'birlikte_oynadik',
    'caya_geldi',
    'acildi',
    'acilmadi',
    'sevgili_olduk',
    'ayrildik',
    'evet_dedi',
    'teklif_reddi',
    'bosandik',
    'cocuk_karari',
    'cocuk_istemedi',
  ];

  /// Motorun üretebileceği bütün sonuç anahtarları. Her biri için
  /// `assets/interactions.json` içinde en az bir metin olmalı.
  static const List<String> outcomes = [
    'bulus.iyi',
    'bulus.sikici',
    'bulus.tartisma',
    'hediye.iyi',
    'hediye.reddetti',
    'dertles.iyi',
    'dertles.yayildi',
    'borc.verdi',
    'borc.vermedi',
    'borcode.iyi',
    'lafsok.iyi',
    'lafsok.gecti',
    'uzaklas.iyi',
    'ara.halhatir',
    'ara.yillarsonra',
    'ara.acmadi',
    'ara.nostalji.olumlu',
    'ara.nostalji.baristik',
    'ara.nostalji.kirgin',
    'ara.ozur.kabul',
    'ara.ozur.red',
    'ara.igne.iyi',
    'ara.igne.guldu',
    'anne.yemek',
    'baba.mac',
    'baba.mac.kaybettik',
    'dede.el',
    'dede.el.harclik',
    'kardes.oyun',
    'komsu.cay',
    'acil.evet',
    'acil.hayir',
    'ciddi.evet',
    'ciddi.hayir',
    'teklif.evet',
    'teklif.hayir',
    'ayril.iyi',
    'ayril.bosanma',
    'cocuk.evet',
    'cocuk.hayir',
  ];

  /// Etkileşimin en küçük oyuncu yaşı ve karşıdakinin en küçük yaşı.
  static const Map<InteractionKind, ({int player, int other})> minAges = {
    InteractionKind.bulus: (player: 6, other: 7),
    InteractionKind.ara: (player: 11, other: 7),
    InteractionKind.hediye: (player: 11, other: 7),
    InteractionKind.dertles: (player: 11, other: 11),
    InteractionKind.borcIste: (player: 18, other: 18),
    InteractionKind.borcOde: (player: 18, other: 18),
    InteractionKind.lafSok: (player: 7, other: 7),
    InteractionKind.uzaklas: (player: 15, other: 0),
    InteractionKind.yemegiOv: (player: 6, other: 0),
    InteractionKind.macIzle: (player: 6, other: 0),
    InteractionKind.eliniOp: (player: 6, other: 0),
    InteractionKind.kardesleOyna: (player: 6, other: 4),
    InteractionKind.cayaGit: (player: 12, other: 0),
    InteractionKind.acil: (player: 18, other: 18),
    InteractionKind.ciddi: (player: 18, other: 18),
    InteractionKind.teklif: (player: Romance.proposalMinAge, other: 18),
    InteractionKind.ayril: (player: 18, other: 18),
    InteractionKind.cocukIste: (player: Romance.childMinAge, other: 18),
  };

  /// Kardeşle oyun bu yaşa kadar (ikisi için de).
  static const int playMaxAge = 14;

  /// Bu yaşın altındaki oyuncuya sonuç metninin çocuk hâli gösterilir
  /// (`bulus.iyi.cocuk`): çocuk çay bahçesinde oturup hesap ödemez.
  static const int childTextMaxAge = 12;

  /// Bu yıl yapılanları tutan anahtar: `p3:bulus`.
  static String usedKey(String personId, InteractionKind kind) =>
      '$personId:${kind.name}';

  /// Bu kişiyle şu an görünen etkileşimler. Role uymayanlar listede yoktur;
  /// şartı sağlanmayanlar [InteractionOption.blocked] ile gelir.
  static List<InteractionOption> optionsFor(
    Character c,
    Person p, {
    required int timeLeft,
    required Set<String> used,
  }) {
    final now = c.age;
    if (!p.isAlive || p.bornAt > now) return const [];
    // Aynı evde yaşanan anne, baba ve kardeş aranmaz, onlarla "buluşulmaz".
    final household = livesWithPlayer(c, p);
    final kinds = [
      if (!p.archived && !household) InteractionKind.bulus,
      if (!household) InteractionKind.ara,
      if (!p.archived) ...[
        InteractionKind.hediye,
        InteractionKind.dertles,
        if (p.loan > 0) InteractionKind.borcOde else InteractionKind.borcIste,
        InteractionKind.lafSok,
        if (!PeopleTick.coreKin.contains(p.kin) &&
            !Romance.romanticBonds.contains(p.bond))
          InteractionKind.uzaklas,
        if (p.kin == Kinship.anne) InteractionKind.yemegiOv,
        if (p.kin == Kinship.baba) InteractionKind.macIzle,
        if (p.kin == Kinship.dede || p.kin == Kinship.nine)
          InteractionKind.eliniOp,
        if (p.kin == Kinship.kardes &&
            now <= playMaxAge &&
            p.ageAt(now) <= playMaxAge)
          InteractionKind.kardesleOyna,
        if (p.hasRole(RoleKind.komsu)) InteractionKind.cayaGit,
        if (Romance.canCourt(c, p)) InteractionKind.acil,
        if (p.bond == Bond.flort) InteractionKind.ciddi,
        if (p.bond == Bond.sevgili) InteractionKind.teklif,
        if (Romance.romanticBonds.contains(p.bond) || p.kin == Kinship.es)
          InteractionKind.ayril,
        if (p.kin == Kinship.es && Romance.childAgeFits(c, p))
          InteractionKind.cocukIste,
      ],
    ];
    return [
      for (final kind in kinds)
        _option(c, p, kind, timeLeft: timeLeft, used: used),
    ];
  }

  static InteractionOption _option(
    Character c,
    Person p,
    InteractionKind kind, {
    required int timeLeft,
    required Set<String> used,
  }) {
    final now = c.age;
    final near = _sameCity(c, p);
    final timeCost = kind == InteractionKind.bulus && !near ? 2 : 1;
    final moneyCost = switch (kind) {
      InteractionKind.hediye => giftCost,
      InteractionKind.bulus when !near => travelCost,
      InteractionKind.borcOde => p.loan,
      _ => 0,
    };
    Blocked? blocked;
    final ages = minAges[kind]!;
    final otherAge = p.ageAt(now);
    if (now < ages.player) {
      blocked = Blocked.yas;
    } else if (otherAge < ages.other) {
      blocked = Blocked.karsiYas;
    } else if (used.contains(usedKey(p.id, kind))) {
      blocked = Blocked.buYil;
    } else if (timeLeft < timeCost) {
      blocked = Blocked.vakit;
    } else if (moneyCost > 0 && c.stats.money < moneyCost) {
      blocked = Blocked.para;
    } else if (!near && _needsSameCity(kind)) {
      blocked = Blocked.uzak;
    } else if (Relationships.closeness(p, now) < (closenessNeeded(kind) ?? 0)) {
      blocked = Blocked.yakinlikDusuk;
    } else if (kind == InteractionKind.ciddi &&
        now - (Romance.datingSince(p) ?? now) < Romance.datingYears) {
      blocked = Blocked.erken;
    } else if (kind == InteractionKind.cocukIste && Romance.childTooSoon(c)) {
      blocked = Blocked.erken;
    }
    return InteractionOption(
      kind,
      timeCost: timeCost,
      moneyCost: moneyCost,
      blocked: blocked,
    );
  }

  static bool _needsSameCity(InteractionKind kind) => const {
    InteractionKind.yemegiOv,
    InteractionKind.macIzle,
    InteractionKind.eliniOp,
    InteractionKind.kardesleOyna,
    InteractionKind.cayaGit,
  }.contains(kind);

  /// Aynı evde yaşanan anne, baba ve kardeş (bkz. [PeopleTick.livesTogether]).
  static bool livesWithPlayer(Character c, Person p) =>
      PeopleTick.livesTogether(c, p);

  /// Aynı şehirde mi (oyuncunun şu an yaşadığı şehir).
  static bool _sameCity(Character c, Person p) => p.city == c.city;

  /// Bu kişiyle şu an yapılabilecek bütün istekler; Ara her açık ton ve
  /// (nostalji ve iğnelemede) her anı için ayrı. Simülasyon ve denge
  /// raporu kullanır.
  static List<InteractionRequest> requestsFor(
    Person p,
    List<InteractionOption> options,
    int now,
  ) => [
    for (final o in options)
      if (o.enabled)
        if (o.kind != InteractionKind.ara)
          InteractionRequest(o.kind, p.id)
        else
          for (final tone in CallTone.values)
            if (toneBlocked(p, tone, now) == null)
              ...switch (tone) {
                CallTone.nostalji || CallTone.igne => [
                  for (final m in callMemories(
                    p,
                    now,
                    tone: tone == CallTone.igne ? MemoryTone.olumsuz : null,
                  ))
                    InteractionRequest(
                      o.kind,
                      p.id,
                      tone: tone,
                      memoryKind: m.kind,
                    ),
                ],
                _ => [InteractionRequest(o.kind, p.id, tone: tone)],
              },
  ];

  /// Ara sohbetinde bu tonun açık olup olmadığı.
  static Blocked? toneBlocked(Person p, CallTone tone, int now) =>
      switch (tone) {
        CallTone.halHatir => null,
        CallTone.nostalji =>
          callMemories(p, now).isEmpty ? Blocked.aniYok : null,
        CallTone.igne =>
          callMemories(p, now, tone: MemoryTone.olumsuz).isEmpty
              ? Blocked.aniYok
              : null,
        CallTone.ozur => _grievance(p) == null ? Blocked.kirginlikYok : null,
      };

  /// Sohbette açılabilecek ortak anılar, en güçlüden başlayarak en fazla
  /// [callMemoryChoices]. [tone] verilirse yalnızca o tondakiler.
  static List<Memory> callMemories(Person p, int now, {MemoryTone? tone}) {
    final shared =
        p.memories
            .where((m) => m.owner == MemoryOwner.ikisi)
            .where((m) => tone == null || m.tone == tone)
            .toList()
          ..sort(
            (a, b) => Relationships.weightOf(
              b,
              p,
              now,
            ).compareTo(Relationships.weightOf(a, p, now)),
          );
    // Aynı türden anı ("eski günleri andık" iki kez) listede bir kez, en
    // güçlü hâliyle durur; seçim türle yapılır.
    final seen = <String>{};
    return [
      for (final m in shared)
        if (seen.add(m.kind)) m,
    ].take(callMemoryChoices).toList();
  }

  static Memory? _grievance(Person p) {
    for (final m in p.memories) {
      if (m.tone == MemoryTone.olumsuz && m.affectsBars && !m.healed) {
        return m;
      }
    }
    return null;
  }

  /// Etkileşimi uygular. Şartları sağlanmıyorsa [StateError] fırlatır.
  static (Character, InteractionResult) resolve(
    Random random,
    Character c,
    InteractionRequest request, {
    required int timeLeft,
    required Set<String> used,
    required Map<String, String> memoryLabels,
  }) {
    final p = c.people[request.personId];
    if (p == null) throw StateError('Kişi yok: ${request.personId}');
    final option = optionsFor(
      c,
      p,
      timeLeft: timeLeft,
      used: used,
    ).where((o) => o.kind == request.kind).firstOrNull;
    if (option == null) {
      throw StateError('${request.kind.name} bu kişiyle yapılamaz');
    }
    if (!option.enabled) {
      throw StateError('${request.kind.name} kapalı: ${option.blocked!.name}');
    }
    return _Resolver(random, c, p, request, option, memoryLabels).run();
  }
}

class _Resolver {
  _Resolver(this.random, this.c, this.p, this.request, this.option, this.labels)
    : now = c.age;

  final Random random;
  final Character c;
  Person p;
  final InteractionRequest request;
  final InteractionOption option;
  final Map<String, String> labels;
  final int now;

  final Map<StatKind, int> _stats = {};
  int _money = 0;
  Memory? _memory;
  bool _healed = false;

  int get _closeness => Relationships.closeness(p, now);
  int get _hostility => Relationships.hostility(p, now);

  (Character, InteractionResult) run() {
    _money -= option.moneyCost;
    final outcome = switch (request.kind) {
      InteractionKind.bulus => _meet(),
      InteractionKind.ara => _call(),
      InteractionKind.hediye => _gift(),
      InteractionKind.dertles => _confide(),
      InteractionKind.borcIste => _borrow(),
      InteractionKind.borcOde => _repay(),
      InteractionKind.lafSok => _jab(),
      InteractionKind.uzaklas => _drift(),
      InteractionKind.yemegiOv => _simple('anne.yemek', 'yemegini_ovdu', 2),
      InteractionKind.macIzle => _match(),
      InteractionKind.eliniOp => _kiss(),
      InteractionKind.kardesleOyna => _simple(
        'kardes.oyun',
        'birlikte_oynadik',
        3,
      ),
      InteractionKind.cayaGit => _simple('komsu.cay', 'caya_geldi', 1),
      InteractionKind.acil => _confess(),
      InteractionKind.ciddi => _serious(),
      InteractionKind.teklif => _propose(),
      InteractionKind.ayril => _breakUp(),
      InteractionKind.cocukIste => _askChild(),
    };

    if (request.kind != InteractionKind.uzaklas) {
      p = Relationships.touch(p, now).copyWith(archived: false);
    }
    var stats = c.stats;
    _stats.forEach((kind, delta) => stats = stats.withDelta(kind, delta));
    stats = stats.withMoneyDelta(_money);
    final character = c.copyWith(stats: stats, people: c.people.update(p));
    return (
      character,
      InteractionResult(
        kind: request.kind,
        personId: p.id,
        tone: request.tone,
        outcome: outcome,
        variant: random.nextInt(1000),
        memory: _memory,
        healed: _healed,
        stats: Map.unmodifiable(_stats),
        money: _money,
      ),
    );
  }

  bool _chance(double p) => random.nextDouble() < p;

  void _remember(
    String kind,
    MemoryTone tone,
    int severity, {
    MemoryOwner owner = MemoryOwner.ikisi,
    double bonus = 1.0,
  }) {
    final memory = Memory(
      kind: kind,
      label: labels[kind] ?? kind,
      age: now,
      tone: tone,
      severity: severity,
      owner: owner,
      bonus: bonus,
    );
    p = Relationships.addMemory(p, memory, now: now);
    _memory = memory;
  }

  void _happy(int delta) => _stats.update(
    StatKind.happiness,
    (v) => v + delta,
    ifAbsent: () => delta,
  );

  String _meet() {
    final good = (0.6 + _closeness / 250 - _hostility / 150).clamp(0.15, 0.95);
    if (_chance(good)) {
      _remember('bulus', MemoryTone.olumlu, 1);
      _happy(3);
      return 'bulus.iyi';
    }
    if (_hostility >= 50) {
      _remember('bulus_tartisma', MemoryTone.olumsuz, 1);
      _happy(-2);
      return 'bulus.tartisma';
    }
    return 'bulus.sikici';
  }

  String _gift() {
    if (_hostility >= Interactions.coldHostility && _chance(0.5)) {
      return 'hediye.reddetti';
    }
    _remember('hediye', MemoryTone.olumlu, p.hasTrait(Trait.cikarci) ? 2 : 1);
    _happy(1);
    return 'hediye.iyi';
  }

  String _confide() {
    _remember('dertles', MemoryTone.olumlu, 1);
    _happy(5);
    if (p.hasTrait(Trait.dedikoducu) && _chance(0.5)) {
      _stats[StatKind.reputation] = -3;
      return 'dertles.yayildi';
    }
    return 'dertles.iyi';
  }

  String _borrow() {
    var chance = _closeness / 100 - _hostility / 100;
    if (p.hasTrait(Trait.comert)) chance += 0.25;
    if (p.hasTrait(Trait.cikarci)) chance -= 0.2;
    if (p.wealth == WealthLevel.dar) chance -= 0.2;
    if (_chance(chance.clamp(0.05, 0.95))) {
      final amount = Interactions.loanAmount[p.wealth]!;
      _money += amount;
      p = p.copyWith(loan: amount);
      return 'borc.verdi';
    }
    _remember('borc_vermedi', MemoryTone.olumsuz, 1, owner: MemoryOwner.oyuncu);
    return 'borc.vermedi';
  }

  String _repay() {
    p = p.copyWith(loan: 0);
    _remember('borcunu_odedi', MemoryTone.olumlu, 1);
    return 'borcode.iyi';
  }

  String _jab() {
    _happy(1);
    if (p.hasTrait(Trait.gamsiz) && _chance(0.4)) return 'lafsok.gecti';
    _remember('laf_soktu', MemoryTone.olumsuz, 1);
    return 'lafsok.iyi';
  }

  double get _warmth => (_closeness - 50) / 100;

  String _confess() {
    if (_chance((0.45 + _warmth).clamp(0.2, 0.9))) {
      p = p.copyWith(bond: Bond.flort);
      _remember('acildi', MemoryTone.olumlu, 2);
      _happy(5);
      return 'acil.evet';
    }
    // Kibar bir ret husumet doğurmaz; yalnızca oyuncunun hatırladığı bir an.
    _remember('acilmadi', MemoryTone.olumsuz, 1, owner: MemoryOwner.oyuncu);
    _happy(-4);
    return 'acil.hayir';
  }

  String _serious() {
    if (_chance((0.55 + _warmth).clamp(0.3, 0.95))) {
      p = p.copyWith(bond: Bond.sevgili);
      _remember('sevgili_olduk', MemoryTone.olumlu, 2);
      _happy(4);
      return 'ciddi.evet';
    }
    p = p.copyWith(bond: Bond.eskiSevgili);
    _remember('ayrildik', MemoryTone.olumsuz, 2);
    _happy(-5);
    return 'ciddi.hayir';
  }

  String _propose() {
    if (_chance((0.5 + _warmth).clamp(0.3, 0.95))) {
      p = p.copyWith(bond: Bond.nisanli);
      _remember('evet_dedi', MemoryTone.olumlu, 3);
      _happy(8);
      return 'teklif.evet';
    }
    _remember('teklif_reddi', MemoryTone.olumsuz, 3);
    _happy(-6);
    return 'teklif.hayir';
  }

  String _breakUp() {
    final divorce = p.kin == Kinship.es;
    p = p.copyWith(
      clearKin: divorce,
      bond: divorce ? Bond.eskiEs : Bond.eskiSevgili,
      marital: divorce ? MaritalStatus.bekar : null,
    );
    _remember(divorce ? 'bosandik' : 'ayrildik', MemoryTone.olumsuz, 2);
    _happy(-5);
    if (!divorce) return 'ayril.iyi';
    // Evlilikte biriken nakit yarı yarıya bölünür.
    if (c.stats.money > 0) _money -= c.stats.money ~/ 2;
    return 'ayril.bosanma';
  }

  String _askChild() {
    final kids = c.people.all.where((x) => x.kin == Kinship.cocuk).length;
    if (_chance((0.6 + _warmth - 0.2 * kids).clamp(0.1, 0.9))) {
      _remember('cocuk_karari', MemoryTone.olumlu, 2);
      _happy(3);
      return 'cocuk.evet';
    }
    _remember('cocuk_istemedi', MemoryTone.olumsuz, 1);
    _happy(-2);
    return 'cocuk.hayir';
  }

  String _drift() {
    p = p.copyWith(archived: true);
    return 'uzaklas.iyi';
  }

  String _simple(String outcome, String memoryKind, int happiness) {
    _remember(memoryKind, MemoryTone.olumlu, 1);
    _happy(happiness);
    return outcome;
  }

  String _match() {
    _remember('mac_izledik', MemoryTone.olumlu, 1);
    if (_chance(0.3)) {
      _happy(-2);
      return 'baba.mac.kaybettik';
    }
    _happy(2);
    return 'baba.mac';
  }

  String _kiss() {
    // Her bayram yapılabilen küçük bir jest: anısı hafif sayılır.
    _remember('elini_optu', MemoryTone.olumlu, 1, bonus: 0.6);
    _happy(2);
    if (now < 18) {
      _money += Interactions.pocketMoney;
      return 'dede.el.harclik';
    }
    return 'dede.el';
  }

  /// Uzun aradan sonra ilk arama mı; öyleyse çarpanı bir kez kullanır.
  double _reunionBonus() {
    if (p.reunited || now - p.lastContactAt < Interactions.longGap) return 1;
    p = p.copyWith(reunited: true);
    return Interactions.longGapBonus;
  }

  String _call() {
    final tone = request.tone;
    if (tone == null) throw StateError('Ara için ton seçilmeli');
    final blocked = Interactions.toneBlocked(p, tone, now);
    if (blocked != null) throw StateError('Bu ton kapalı: ${blocked.name}');

    if (tone != CallTone.ozur &&
        _hostility >= Interactions.coldHostility &&
        _closeness < Relationships.hostileLabelMaxCloseness &&
        _chance(0.5)) {
      return 'ara.acmadi';
    }
    final bonus = _reunionBonus();
    switch (tone) {
      case CallTone.halHatir:
        if (bonus > 1) {
          _remember('yillar_sonra', MemoryTone.olumlu, 2, bonus: bonus);
          _happy(4);
          return 'ara.yillarsonra';
        }
        _remember('aradi', MemoryTone.olumlu, 1);
        _happy(1);
        return 'ara.halhatir';
      case CallTone.nostalji:
        final m = _chosenMemory(null);
        if (m.tone == MemoryTone.olumlu) {
          _remember('eski_gunler', MemoryTone.olumlu, 2, bonus: bonus);
          _happy(3);
          return 'ara.nostalji.olumlu';
        }
        if (_chance(_forgiveChance(0.75))) {
          p = Relationships.heal(p, kind: m.kind, now: now);
          _healed = true;
          _remember('baristik', MemoryTone.olumlu, 2, bonus: bonus);
          _happy(4);
          return 'ara.nostalji.baristik';
        }
        _remember('hala_kirgin', MemoryTone.olumsuz, 1);
        _happy(-2);
        return 'ara.nostalji.kirgin';
      case CallTone.ozur:
        final chance = _forgiveChance(0.75) + _closeness / 200;
        if (_chance(chance.clamp(0.05, 0.98))) {
          p = Relationships.heal(p, now: now);
          _healed = true;
          _remember('ozur_diledi', MemoryTone.olumlu, 1, bonus: bonus);
          _happy(2);
          return 'ara.ozur.kabul';
        }
        return 'ara.ozur.red';
      case CallTone.igne:
        _chosenMemory(MemoryTone.olumsuz);
        _happy(2);
        if (p.hasTrait(Trait.gamsiz) && _chance(0.4)) return 'ara.igne.guldu';
        _remember(
          'igneledi',
          MemoryTone.olumsuz,
          p.hasTrait(Trait.kiskanc) ? 3 : 2,
        );
        return 'ara.igne.iyi';
    }
  }

  /// Kişiliğe göre affetme olasılığı: Gamsız kolay, Kıskanç zor affeder;
  /// Vefalı unutmaz.
  double _forgiveChance(double normal) {
    if (p.hasTrait(Trait.gamsiz)) return 0.95;
    if (p.hasTrait(Trait.kiskanc)) return 0.5;
    if (p.hasTrait(Trait.vefali)) return 0.6;
    return normal;
  }

  Memory _chosenMemory(MemoryTone? tone) {
    final choices = Interactions.callMemories(p, now, tone: tone);
    final kind = request.memoryKind;
    final chosen = choices.where((m) => m.kind == kind).firstOrNull;
    if (chosen == null) {
      throw StateError('Sohbette açılacak anı seçilmeli: $kind');
    }
    return chosen;
  }
}
