import 'dart:math';

import '../models/models.dart';
import 'birth.dart';
import 'business.dart';
import 'business_types.dart';
import 'careers.dart';
import 'cities.dart';
import 'death_check.dart';
import 'economy.dart';
import 'education.dart';
import 'effect_resolver.dart';
import 'event_deck.dart';
import 'housing.dart';
import 'jobs.dart';
import 'interactions.dart';
import 'life_action.dart';
import 'life_note.dart';
import 'military.dart';
import 'people_tick.dart';
import 'person_factory.dart';
import 'relationships.dart';
import 'schedule_queue.dart';
import 'seeded_random.dart';
import 'summary_builder.dart';
import 'year_tick.dart';

/// Yılın hangi aşamasında olunduğu.
enum YearPhase {
  /// Bekleyen olay kartları var.
  cards,

  /// Kartlar bitti; aksiyon hakları kullanılabilir, sonra "Yaşlan".
  actions,

  /// Hayat bitti; [LifeState.summary] dolu.
  dead,
}

/// Bir hayatın o anki tam durumu. Değişmezdir.
class LifeState {
  const LifeState({
    required this.character,
    required this.phase,
    this.queue = const ScheduleQueue(),
    this.pendingCards = const [],
    this.timeSpent = 0,
    this.actionsUsed = const {},
    this.lastOutcome,
    this.summary,
    this.news = const [],
    this.interactionsUsed = const {},
    this.lastInteraction,
    this.notes = const [],
    this.listings = const [],
    this.applied = const {},
  });

  final Character character;
  final YearPhase phase;
  final ScheduleQueue queue;

  /// Bu yıl henüz kaydırılmamış olaylar; ilki ekrandaki olaydır.
  final List<PendingEvent> pendingCards;

  /// Bu yıl harcanan vakit. Kalan vakit her an karakterin durumundan
  /// hesaplanır; böylece tempo ya da iş değişince vakit kendiliğinden
  /// uyar ve düğmeyle vakit kazanılamaz.
  final int timeSpent;

  /// Kalan vakit; aksiyon aşaması dışında 0.
  int get timeLeft => phase == YearPhase.actions
      ? max(0, ActionCatalog.timeFor(character) - timeSpent)
      : 0;

  /// Bu yıl yapılmış aksiyonlar; aynı aksiyon yılda bir kez yapılır.
  final Set<String> actionsUsed;

  /// Son kart seçiminin sonucu (arayüzde zar sonucunu göstermek için).
  final ChoiceOutcome? lastOutcome;
  final LifeSummary? summary;

  /// Bu yılın çevreden haberleri (yıl günlüğü).
  final List<PersonNews> news;

  /// Bu yıl yapılan etkileşimler (`p3:bulus`); her etkileşim kişi başına
  /// yılda bir kez yapılır.
  final Set<String> interactionsUsed;

  /// Son etkileşimin sonucu (arayüz metni için). Kaydedilmez.
  final InteractionResult? lastInteraction;

  /// Bu yılın oyuncunun kendi hayatından notları (yıl günlüğü).
  final List<LifeNote> notes;

  /// Bu yılın iş ilanları (oyuncunun şehrinde).
  final List<JobListing> listings;

  /// Bu yıl başvurulan ilanlar (`meslek|şirket`).
  final Set<String> applied;

  LifeState copyWith({
    Character? character,
    int? timeSpent,
    Set<String>? actionsUsed,
    List<PersonNews>? news,
    Set<String>? interactionsUsed,
    InteractionResult? lastInteraction,
    List<LifeNote>? notes,
    List<JobListing>? listings,
    Set<String>? applied,
  }) => LifeState(
    character: character ?? this.character,
    phase: phase,
    queue: queue,
    pendingCards: pendingCards,
    timeSpent: timeSpent ?? this.timeSpent,
    actionsUsed: actionsUsed ?? this.actionsUsed,
    lastOutcome: lastOutcome,
    summary: summary,
    news: news == null ? this.news : List.unmodifiable(news),
    interactionsUsed: interactionsUsed ?? this.interactionsUsed,
    lastInteraction: lastInteraction ?? this.lastInteraction,
    notes: notes == null ? this.notes : List.unmodifiable(notes),
    listings: listings == null ? this.listings : List.unmodifiable(listings),
    applied: applied ?? this.applied,
  );

  LifeState withNews(List<PersonNews> news) => copyWith(news: news);

  PendingEvent? get currentEvent =>
      pendingCards.isEmpty ? null : pendingCards.first;

  bool get isOver => phase == YearPhase.dead;
}

/// Oyun motorunun cephesi. Bir hayatı doğumdan ölüme yürütür.
///
/// Bütün rastgelelik tek bir [SeededRandom] üzerinden gelir: aynı tohum ve
/// aynı seçimler aynı hayatı üretir. Durum [toSnapshot] ile kaydedilir,
/// [LifeEngine.restore] ile kaldığı yerden sürer.
class LifeEngine {
  LifeEngine({
    required this.deck,
    required this.seed,
    CareerBook? careers,
    FamilyBook? families,
    InteractionBook? interactions,
  }) : careers = careers ?? CareerBook.empty,
       families = families ?? FamilyBook.minimal,
       interactions = interactions ?? InteractionBook.minimal,
       _random = SeededRandom(seed);

  LifeEngine._restored(
    this.deck,
    this.careers,
    this.families,
    this.interactions,
    this.seed,
    this._random,
  );

  final EventDeck deck;
  final CareerBook careers;

  /// Doğumda aile üretimi için; yalnızca [startLife] kullanır.
  final FamilyBook families;

  /// Etkileşimlerin anı etiketleri (sonuç metinlerini arayüz kurar).
  final InteractionBook interactions;
  final int seed;
  final SeededRandom _random;

  /// Kayıt biçimi değişirse artırılır. Sürüm 2 (D1): kişiler, hafıza ve yeni
  /// olay biçimi. Sürüm 1 kayıtları dönüştürülemez; eski kartlar ve kişisiz
  /// karakter yeni sisteme taşınamaz, oyuncuya bildirilip silinir.
  static const int snapshotVersion = 2;

  /// Kayıt bu sürümle sürdürülebilir mi.
  static bool canRestore(Map<String, dynamic> snapshot) =>
      snapshot['version'] == snapshotVersion;

  late final EffectResolver _resolver = EffectResolver(
    _random,
    careers: careers,
  );
  late final DeathCheck _deathCheck = DeathCheck(_random);
  late final EconomyTick _economyTick = EconomyTick(_random);
  late final CareerTick _careerTick = CareerTick(_random, careers);
  late final SummaryBuilder _summaryBuilder = SummaryBuilder(deck);
  static const YearTick _yearTick = YearTick();

  late LifeState _state;

  LifeState get state => _state;

  Market _market = Market.initial;
  EconomyReport? _lastEconomy;

  /// Altın fiyatı ve son yılın enflasyonu.
  Market get market => _market;

  /// Son yaşlanmadaki ekonomik döküm; ilk yılda null. Kaydedilmez.
  EconomyReport? get lastEconomy => _lastEconomy;

  CareerReport? _lastCareer;

  /// Son yaşlanmadaki iş dökümü (gelir, terfi, emeklilik). Kaydedilmez.
  CareerReport? get lastCareer => _lastCareer;

  /// Yeni bir hayat başlatır ve 0 yaşının kartlarını çeker.
  LifeState startLife({String? name, Gender? gender}) {
    final character = BirthGenerator(
      _random,
      families: families,
    ).generate(name: name, gender: gender);
    return _state = _beginYear(
      Relationships.syncFamilyBond(character),
      const ScheduleQueue(),
    );
  }

  /// Ekrandaki kartı [side] yönüne kaydırır.
  LifeState choose(ChoiceSide side) {
    final event = _state.currentEvent;
    if (_state.phase != YearPhase.cards || event == null) {
      throw StateError('Şu an seçilecek kart yok (${_state.phase})');
    }
    if (side == ChoiceSide.up && event.card.up == null) {
      throw StateError('${event.card.id} kartında yukarı seçeneği yok');
    }

    final outcome = _resolver.resolve(_state.character, event, side);
    final character = Relationships.syncFamilyBond(
      YearTick.updateHardshipFlags(
        _booked(
          _state.character,
          outcome.character,
          MoneySource.olay,
          ref: '${event.card.id}:${side.name}',
        ),
      ),
    );
    var queue = _state.queue;
    for (final thread in outcome.scheduled) {
      queue = queue.add(
        thread.event.cardId,
        atAge: character.age + thread.event.inYears,
        people: thread.people,
      );
    }

    // Seçim koşulları değiştirdiyse (celp, istifa) artık uymayan olaylar düşer.
    final remaining = [
      for (final e in _state.pendingCards.skip(1))
        if (e.card.conditions.isMetBy(character)) e,
    ];
    final storedOutcome = ChoiceOutcome(
      character: character,
      choice: outcome.choice,
      rollSucceeded: outcome.rollSucceeded,
      scheduled: outcome.scheduled,
    );
    if (remaining.isNotEmpty) {
      return _state = LifeState(
        character: character,
        phase: YearPhase.cards,
        queue: queue,
        pendingCards: remaining,
        lastOutcome: storedOutcome,
        news: _state.news,
        notes: _state.notes,
        listings: _state.listings,
      );
    }
    return _state = _actionsPhase(
      character,
      queue,
      lastOutcome: storedOutcome,
      notes: _state.notes,
    ).withNews(_state.news).copyWith(listings: _state.listings);
  }

  /// Bu yıl yapılabilecek aksiyonlar ve yapılıp yapılamayacakları.
  List<(LifeAction action, bool enabled)> availableActions() => [
    for (final (action, blocked) in actionOptions()) (action, blocked == null),
  ];

  /// Ev ve arabada kredi şartı.
  static bool _financed(LifeAction action, Character c) =>
      switch (action.special) {
        ActionSpecial.evAl => Housing.canFinance(c, house: true),
        ActionSpecial.arabaAl => Housing.canFinance(c, house: false),
        _ => true,
      };

  /// Bu yıl görünen aksiyonlar; kapalıysa sebebi (arayüz gösterir).
  List<(LifeAction action, ActionBlocked? blocked)> actionOptions() {
    final c = _state.character;
    final canAct = _state.phase == YearPhase.actions;
    ActionBlocked? reason(LifeAction action) {
      if (_state.actionsUsed.contains(action.id)) return ActionBlocked.buYil;
      if (!canAct || _state.timeLeft < action.timeCost) {
        return ActionBlocked.vakit;
      }
      if (!action.canAfford(c, _market)) return ActionBlocked.para;
      if (!_financed(action, c)) return ActionBlocked.kredi;
      return null;
    }

    return [
      for (final action in ActionCatalog.availableFor(c))
        (action, reason(action)),
    ];
  }

  LifeState doAction(String actionId) {
    final action = ActionCatalog.byId(actionId);
    final c = _state.character;
    if (action == null) {
      throw ArgumentError.value(actionId, 'actionId', 'bilinmeyen aksiyon');
    }
    if (_state.phase != YearPhase.actions) {
      throw StateError('Aksiyonlar yalnızca kartlardan sonra yapılır');
    }
    if (_state.timeLeft < action.timeCost) {
      throw StateError('Bu yılın vakti yetmiyor');
    }
    if (!action.isAvailableFor(c)) {
      throw StateError('$actionId şu an yapılamaz');
    }
    if (!action.canAfford(c, _market)) {
      throw StateError('$actionId için para yetmiyor');
    }
    if (_state.actionsUsed.contains(actionId)) {
      throw StateError('$actionId bu yıl zaten yapıldı');
    }
    if (!_financed(action, c)) {
      throw StateError('$actionId için kredi çıkmıyor');
    }

    var character = switch (action.special) {
      final special? => _applySpecial(special, c),
      null => EffectResolver.applyEffect(
        c,
        action.totalEffect(_market),
        careers: careers,
      ),
    };
    character = YearTick.updateHardshipFlags(
      _booked(c, character, MoneySource.aksiyon, ref: actionId),
    );
    final note = switch (action.special) {
      ActionSpecial.kpss => LifeNote(
        character.hasFlag(JobMarket.kpssFlag)
            ? NoteKind.kpssGecti
            : NoteKind.kpssKaldi,
      ),
      ActionSpecial.yazilimKursu => const LifeNote(NoteKind.yazilimKursu),
      _ => null,
    };
    return _state = _state.copyWith(
      character: character,
      timeSpent: _state.timeSpent + action.timeCost,
      actionsUsed: {..._state.actionsUsed, actionId},
      notes: note == null ? null : [..._state.notes, note],
    );
  }

  /// [personId] kişisiyle şu an görünen etkileşimler; aksiyon aşaması
  /// dışında hepsi vakit yüzünden kapalıdır.
  List<InteractionOption> interactionsWith(String personId) {
    final p = _state.character.people[personId];
    if (p == null) return const [];
    return Interactions.optionsFor(
      _state.character,
      p,
      timeLeft: _state.timeLeft,
      used: _state.interactionsUsed,
    );
  }

  /// Şu an yapılabilecek bütün etkileşim istekleri, yaşayan herkesle
  /// (simülasyon ve denge raporu için).
  List<InteractionRequest> possibleInteractions() {
    final c = _state.character;
    return [
      for (final p in c.people.bornBy(c.age))
        if (p.isAlive)
          ...Interactions.requestsFor(p, interactionsWith(p.id), c.age),
    ];
  }

  /// Bir kişiyle etkileşir (İnsanlar sekmesi). Yalnızca aksiyon aşamasında.
  LifeState interact(InteractionRequest request) {
    if (_state.phase != YearPhase.actions) {
      throw StateError('Etkileşimler yalnızca kartlardan sonra yapılır');
    }
    final option = interactionsWith(request.personId)
        .where((o) => o.kind == request.kind)
        .firstOrNull;
    if (option == null) {
      throw StateError('${request.kind.name} bu kişiyle yapılamaz');
    }
    final (character, result) = Interactions.resolve(
      _random,
      _state.character,
      request,
      timeLeft: _state.timeLeft,
      used: _state.interactionsUsed,
      memoryLabels: interactions.memoryLabels,
    );
    return _state = _state.copyWith(
      character: Relationships.syncFamilyBond(
        YearTick.updateHardshipFlags(
          _booked(
            _state.character,
            character,
            MoneySource.etkilesim,
            ref: request.kind.name,
          ),
        ),
      ),
      timeSpent: _state.timeSpent + option.timeCost,
      interactionsUsed: {
        ..._state.interactionsUsed,
        Interactions.usedKey(request.personId, request.kind),
      },
      lastInteraction: result,
    );
  }

  /// "Yaşlan": yıl sonu ölüm kontrolü, sonra bir sonraki yaş ve kartları.
  LifeState advanceYear() {
    if (_state.phase != YearPhase.actions) {
      throw StateError('Yaşlanmadan önce kartlar bitmeli (${_state.phase})');
    }
    // Tercih yapmadan yaşlanan, okumadan çalışmayı seçmiş sayılır.
    if (_state.character.hasFlag(EducationRules.pendingFlag)) {
      declineTercih(TercihKind.calis);
    }
    final cause = _deathCheck.check(_state.character);
    if (cause != null) {
      final dead = _state.character.copyWith(isAlive: false);
      return _state = LifeState(
        character: dead,
        phase: YearPhase.dead,
        queue: _state.queue,
        summary: _summaryBuilder.build(dead, cause, _market),
      );
    }
    // Önce geçen yılın ekonomisi (erime, kira, kredi), sonra yeni yaşın
    // geliri; böylece yılın geliri o yıl erimez.
    final (afterEconomy, market, report) = _economyTick.apply(
      _state.character,
      _market,
    );
    _market = market;
    _lastEconomy = report;
    final aged = _yearTick.apply(afterEconomy);
    final (paid, careerReport) = _careerTick.apply(aged);
    _lastCareer = careerReport;
    final age = aged.age;
    final afterCareer = paid.withLedger([
      MoneyEntry(
        age: age,
        source: MoneySource.enflasyon,
        amount: -report.cashEroded,
      ),
      MoneyEntry(age: age, source: MoneySource.kira, amount: -report.rentPaid),
      MoneyEntry(age: age, source: MoneySource.kredi, amount: -report.loanPaid),
      MoneyEntry(age: age, source: MoneySource.araba, amount: -report.carCost),
      MoneyEntry(
        age: age,
        source: MoneySource.yasamGideri,
        amount: -report.livingCost,
      ),
      MoneyEntry(
        age: age,
        source: MoneySource.aileDestegi,
        amount: aged.stats.money - afterEconomy.stats.money,
      ),
      MoneyEntry(
        age: age,
        source: careerReport.source,
        amount: careerReport.income,
      ),
      MoneyEntry(
        age: age,
        source: MoneySource.tazminat,
        amount: careerReport.severance,
      ),
      MoneyEntry(
        age: age,
        source: MoneySource.terfi,
        amount:
            paid.stats.money -
            aged.stats.money -
            careerReport.income -
            careerReport.severance,
      ),
    ]);
    final (afterBusiness, businessNotes) = _businessYear(
      afterCareer,
      report.inflation,
    );
    final (studied, notes, queue) = _schoolYear(afterBusiness, _state.queue);
    notes.insertAll(0, businessNotes);
    final soldier = Military.inService(studied);
    final served = Military.returnHome(studied, _factory);
    if (soldier) notes.add(const LifeNote(NoteKind.askerlik));
    if (careerReport.fired) notes.add(const LifeNote(NoteKind.kovuldun));
    if (careerReport.retired) notes.add(const LifeNote(NoteKind.emekliOldun));
    final (character, news) = PeopleTick(
      _random,
      families,
      cities: BirthGenerator.hometowns,
    ).apply(Economy.syncDerivedFlags(YearTick.updateHardshipFlags(served)));
    final settled = Relationships.syncFamilyBond(
      Housing.ensureNeighbours(character, _factory),
    );
    final listings = JobMarket.listingsFor(settled, careers, _random);
    return _state = _beginYear(
      settled,
      queue,
      notes: notes,
    ).withNews(news).copyWith(listings: listings);
  }

  /// İşletmelerin yılı: kâr ya da zarar, kredi, batış; deftere ve
  /// günlüğe yazılır.
  (Character, List<LifeNote>) _businessYear(Character c, double inflation) {
    if (c.businesses.isEmpty) return (c, const []);
    final (next, years) = BusinessRules.yearOf(c, inflation, _random);
    final entries = <MoneyEntry>[];
    final notes = <LifeNote>[];
    var booked = 0;
    for (final y in years) {
      entries.add(
        MoneyEntry(
          age: c.age,
          source: MoneySource.isletme,
          amount: y.ownerShare,
          ref: '${y.type}:kar',
        ),
      );
      entries.add(
        MoneyEntry(
          age: c.age,
          source: MoneySource.isletme,
          amount: -y.loanPaid,
          ref: '${y.type}:kredi',
        ),
      );
      booked += y.ownerShare - y.loanPaid;
      notes.add(LifeNote(NoteKind.isletmeYili, '${y.type}|${y.profit}'));
      if (y.bankrupt) notes.add(LifeNote(NoteKind.isletmeBatti, y.type));
    }
    // Batışta ekipman satışı ve kalan kredi.
    final rest = next.stats.money - c.stats.money - booked;
    if (rest != 0) {
      entries.add(
        MoneyEntry(
          age: c.age,
          source: MoneySource.isletme,
          amount: rest,
          ref: '${years.firstWhere((y) => y.bankrupt).type}:iflas',
        ),
      );
    }
    return (next.withLedger(entries), notes);
  }

  /// Yaşlanınca okulun yılı: lise bitince (19) sınıf rolleri biter;
  /// üniversitede dersler, burs ve mezuniyet. Mezuniyet olayı aynı yıl
  /// gelir.
  (Character, List<LifeNote>, ScheduleQueue) _schoolYear(
    Character c,
    ScheduleQueue queue,
  ) {
    final notes = <LifeNote>[];
    var next = c;
    if (next.age == EducationRules.yksAge + 1) {
      next = EducationRules.endSchoolRoles(next, origin: Origin.okul);
    }
    final (afterStudy, note) = EducationRules.yearOfStudy(next, _random);
    next = afterStudy;
    if (note == EducationNote.dersKaldi) {
      notes.add(const LifeNote(NoteKind.dersKaldi));
    } else if (note == EducationNote.mezunOldu) {
      notes.add(LifeNote(NoteKind.mezunOldu, next.education.department));
      if (next.city != c.city) {
        notes.add(LifeNote(NoteKind.eveDondu, next.city));
      }
      if (next.city != c.city || next.home != c.home) {
        next = Housing.settle(next, _factory);
      }
      if (deck.byId(graduationEvent) != null) {
        queue = queue.add(graduationEvent, atAge: next.age);
      }
    }
    final burs = EducationRules.scholarshipFor(next);
    if (burs > 0) {
      next = next.copyWith(stats: next.stats.withMoneyDelta(burs)).withLedger([
        MoneyEntry(age: next.age, source: MoneySource.burs, amount: burs),
      ]);
    }
    return (next, notes, queue);
  }

  /// Mezuniyet yılında gelen olay (iplik).
  static const String graduationEvent = 'mezuniyet';

  /// Bu yılın ilanları ve başvurulamıyorsa sebebi.
  List<(JobListing listing, ListingBlocked? blocked)> listingOptions() {
    final c = _state.character;
    return [
      for (final l in _state.listings)
        (
          l,
          JobMarket.blocked(
            c,
            l,
            careers,
            timeLeft: _state.timeLeft,
            applied: _state.applied,
          ),
        ),
    ];
  }

  /// Bu ilan için aracı olabilecek tanıdıklar ("Kerem'e sor").
  List<Person> listingReferences(JobListing listing) =>
      JobMarket.references(_state.character, listing, careers);

  /// İlana başvurur ve mülakata girer (1 vakit). [side] mülakat sorusunun
  /// cevabı; [referenceId] aracı olan tanıdık.
  LifeState applyFor(
    JobListing listing,
    ChoiceSide side, {
    String? referenceId,
  }) {
    final option = listingOptions().where((o) => o.$1 == listing).firstOrNull;
    if (option == null || option.$2 != null) {
      throw StateError('Bu ilana başvurulamaz: ${option?.$2}');
    }
    final c = _state.character;
    final career = careers.require(listing.careerId);
    final reference = referenceId == null ? null : c.people[referenceId];
    if (reference != null && !listingReferences(listing).contains(reference)) {
      throw StateError('$referenceId bu ilan için aracı olamaz');
    }
    final question = career.interviews.isEmpty
        ? null
        : career.interviews[listing.interview % career.interviews.length];
    final answer = switch (side) {
      ChoiceSide.right => question?.right,
      _ => question?.left,
    };
    final result = JobMarket.interview(
      c,
      listing,
      careers,
      answer ?? const InterviewAnswer(label: '', stat: RollStat.knowledge),
      _random,
      reference: reference,
    );
    var next = c;
    final LifeNote note;
    if (result == InterviewResult.olmadi) {
      note = LifeNote(NoteKind.mulakatOlmadi, listing.company);
    } else {
      next = JobMarket.hire(
        c,
        listing,
        careers,
        _factory,
        reference: result == InterviewResult.torpilleAlindi ? reference : null,
      );
      note = LifeNote(
        NoteKind.isBuldun,
        '${listing.company}|${listing.careerId}|${listing.tier}',
      );
    }
    _lastInterview = result;
    return _state = _state.copyWith(
      character: Relationships.syncFamilyBond(next),
      timeSpent: _state.timeSpent + 1,
      applied: {..._state.applied, JobMarket.key(listing)},
      notes: [..._state.notes, note],
    );
  }

  InterviewResult? _lastInterview;

  /// Son mülakatın sonucu (arayüz için). Kaydedilmez.
  InterviewResult? get lastInterview => _lastInterview;

  /// İşteyken patronla konuşmak 1 vakit.
  static const int requestTimeCost = 1;

  /// Terfi ya da zam istenebilir mi (iş var, vakit var, bu yıl istenmedi).
  bool canRequest({required bool promotion}) =>
      requestBlocked(promotion: promotion) == null;

  /// Terfi ya da zam neden istenemez; null ise istenebilir.
  RequestBlocked? requestBlocked({required bool promotion}) {
    final c = _state.character;
    final job = c.job;
    if (job == null) return RequestBlocked.isYok;
    final reason = promotion
        ? JobMarket.promotionBlocked(c, careers)
        : JobMarket.raiseBlocked(c);
    if (reason != null) return reason;
    final asked = promotion ? job.promotionAskedAt : job.raiseAskedAt;
    if (asked == c.age) return RequestBlocked.buYil;
    if (_state.timeLeft < requestTimeCost) return RequestBlocked.vakit;
    return null;
  }

  /// Terfi ister (1 vakit, yılda bir).
  LifeState requestPromotion() {
    if (!canRequest(promotion: true)) {
      throw StateError('Şu an terfi istenemez');
    }
    final before = _state.character;
    final (c, result) = JobMarket.requestPromotion(before, careers, _random);
    final note = switch (result) {
      RequestResult.evet => LifeNote(
        NoteKind.terfi,
        '${c.job!.careerId}|${c.job!.tier}',
      ),
      RequestResult.hayir => const LifeNote(NoteKind.terfiReddi),
      RequestResult.zamaniDegil => const LifeNote(NoteKind.terfiZamaniDegil),
    };
    return _state = _state.copyWith(
      character: _booked(before, c, MoneySource.terfi),
      timeSpent: _state.timeSpent + requestTimeCost,
      notes: [..._state.notes, note],
    );
  }

  /// Zam ister (1 vakit, yılda bir).
  LifeState requestRaise() {
    if (!canRequest(promotion: false)) {
      throw StateError('Şu an zam istenemez');
    }
    final (c, result) = JobMarket.requestRaise(_state.character, _random);
    final note = switch (result) {
      RequestResult.evet => const LifeNote(NoteKind.zam),
      RequestResult.hayir => const LifeNote(NoteKind.zamReddi),
      RequestResult.zamaniDegil => const LifeNote(NoteKind.zamZamaniDegil),
    };
    return _state = _state.copyWith(
      character: c,
      timeSpent: _state.timeSpent + requestTimeCost,
      notes: [..._state.notes, note],
    );
  }

  /// İşten ayrılır.
  LifeState quitJob() {
    final c = _state.character;
    if (c.job == null) throw StateError('İş yok');
    return _state = _state.copyWith(
      character: Careers.leaveJob(c),
      notes: [..._state.notes, const LifeNote(NoteKind.istifa)],
    );
  }

  /// 25 yıl çalışıp 55 yaşına gelen erken emekli olabilir.
  LifeState retireEarly() {
    final c = _state.character;
    if (!JobMarket.canRetireEarly(c)) throw StateError('Erken emeklilik yok');
    return _state = _state.copyWith(
      character: Economy.syncDerivedFlags(Careers.retire(c, careers)),
      notes: [..._state.notes, const LifeNote(NoteKind.emekliOldun)],
    );
  }

  /// Çalışma temposunu değiştirir (vakti hemen etkiler).
  LifeState setTempo(Tempo tempo) {
    final c = _state.character;
    final job = c.job;
    if (job == null || job.tempo == tempo) return _state;
    final next = c.copyWith(job: job.copyWith(tempo: tempo));
    if (!_timeFits(next)) throw StateError('Bu tempo için vakit kalmadı');
    return _state = _state.copyWith(character: next);
  }

  /// Tempo bu yıl değiştirilebilir mi: yüklenmek 1 vakit ister.
  bool canSetTempo(Tempo tempo) {
    final job = _state.character.job;
    if (job == null || _state.phase != YearPhase.actions) return false;
    return _timeFits(
      _state.character.copyWith(job: job.copyWith(tempo: tempo)),
    );
  }

  /// Değişiklikten sonra harcanan vakit yeni hakkı aşmıyor mu.
  bool _timeFits(Character next) =>
      ActionCatalog.timeFor(next) >= _state.timeSpent;

  /// Açılabilecek işletmeler ve kapalıysa sebebi.
  List<(BusinessType type, BusinessBlocked? blocked)> businessOptions() {
    final c = _state.character;
    final time = _state.timeLeft;
    return [
      for (final t in BusinessTypes.openable)
        (t, BusinessRules.openBlocked(c, t, timeLeft: time)),
    ];
  }

  /// İşletme açar (2 vakit).
  LifeState openBusiness(String typeId) {
    final option = businessOptions()
        .where((o) => o.$1.id == typeId)
        .firstOrNull;
    if (option == null || option.$2 != null) {
      throw StateError('$typeId açılamaz: ${option?.$2}');
    }
    final before = _state.character;
    final next = BusinessRules.open(before, option.$1, _factory);
    return _state = _state.copyWith(
      character: YearTick.updateHardshipFlags(
        _booked(before, next, MoneySource.isletme, ref: '$typeId:kurulus'),
      ),
      timeSpent: _state.timeSpent + BusinessRules.openTimeCost,
      notes: [..._state.notes, LifeNote(NoteKind.isletmeAcildi, typeId)],
    );
  }

  Business _business(String id) =>
      _state.character.businesses.firstWhere((b) => b.id == id);

  /// Başında durur ya da müdüre bırakır (vakti hemen etkiler).
  LifeState setBusinessPresent(String id, bool present) {
    if (!canSetBusinessPresent(id, present)) {
      throw StateError('Başında durma değiştirilemez');
    }
    final c = _state.character;
    final next = BusinessRules.setPresent(c, id, present, _factory);
    if (!_timeFits(next)) throw StateError('Başında durmaya vakit kalmadı');
    return _state = _state.copyWith(character: next);
  }

  /// Başında durma seçimi bu yıl değiştirilebilir mi (vakit yetiyor mu).
  bool canSetBusinessPresent(String id, bool present) {
    if (_state.phase != YearPhase.actions) return false;
    final c = _state.character;
    final b = _business(id);
    if (b.present == present) return true;
    if (present && b.city != c.city) return false;
    final next = c.copyWith(
      businesses: [
        for (final x in c.businesses)
          x.id == id ? x.copyWith(present: present) : x,
      ],
    );
    return _timeFits(next);
  }

  LifeState setBusinessPrice(String id, PriceLevel price) => _state = _state
      .copyWith(character: BusinessRules.setPrice(_state.character, id, price));

  bool canAdvertise(String id) =>
      _state.phase == YearPhase.actions &&
      _state.timeLeft >= BusinessRules.adTimeCost &&
      BusinessRules.canAdvertise(_state.character, _business(id));

  /// Reklam verir (1 vakit, yılda bir).
  LifeState advertiseBusiness(String id) {
    if (!canAdvertise(id)) throw StateError('Reklam verilemez');
    final before = _state.character;
    final b = _business(id);
    final next = BusinessRules.advertise(before, id);
    return _state = _state.copyWith(
      character: _booked(
        before,
        next,
        MoneySource.isletme,
        ref: '${b.type}:reklam',
      ),
      timeSpent: _state.timeSpent + BusinessRules.adTimeCost,
    );
  }

  bool canExpand(String id) =>
      _state.phase == YearPhase.actions &&
      _state.timeLeft >= BusinessRules.openTimeCost &&
      BusinessRules.canExpand(_state.character, _business(id));

  /// Şube açar ya da büyütür (2 vakit).
  LifeState expandBusiness(String id) {
    if (!canExpand(id)) throw StateError('Büyütülemez');
    final before = _state.character;
    final b = _business(id);
    final upgrade = BusinessTypes.require(b.type).upgradeTo != null;
    final next = BusinessRules.expand(before, id, _factory);
    return _state = _state.copyWith(
      character: YearTick.updateHardshipFlags(
        _booked(before, next, MoneySource.isletme, ref: '${b.type}:sube'),
      ),
      timeSpent: _state.timeSpent + BusinessRules.openTimeCost,
      notes: [
        ..._state.notes,
        LifeNote(
          upgrade ? NoteKind.isletmeBuyudu : NoteKind.subeAcildi,
          b.type,
        ),
      ],
    );
  }

  /// Ortak olabilecek tanıdıklar.
  List<Person> partnerCandidates(String id) =>
      BusinessRules.partnerCandidates(_state.character, _business(id));

  /// Ortak alır: sermaye gelir, kârın %30'u ortağın.
  LifeState takePartner(String id, String personId) {
    final candidates = partnerCandidates(id);
    if (!candidates.any((p) => p.id == personId)) {
      throw StateError('$personId ortak olamaz');
    }
    final before = _state.character;
    final b = _business(id);
    final next = BusinessRules.takePartner(before, id, personId);
    return _state = _state.copyWith(
      character: _booked(
        before,
        next,
        MoneySource.isletme,
        ref: '${b.type}:ortak',
      ),
      notes: [
        ..._state.notes,
        LifeNote(
          NoteKind.ortakAlindi,
          '${b.type}|${before.people[personId]!.name}',
        ),
      ],
    );
  }

  /// İşletmeyi satar ya da kapatır.
  LifeState disposeBusiness(String id, {required bool sell}) {
    final before = _state.character;
    final b = _business(id);
    final next = BusinessRules.dispose(before, id, sell: sell);
    return _state = _state.copyWith(
      character: YearTick.updateHardshipFlags(
        _booked(
          before,
          next,
          MoneySource.isletme,
          ref: '${b.type}:${sell ? 'satis' : 'kapanis'}',
        ),
      ),
      notes: [
        ..._state.notes,
        LifeNote(
          sell ? NoteKind.isletmeSatildi : NoteKind.isletmeKapandi,
          b.type,
        ),
      ],
    );
  }

  PersonFactory get _factory => PersonFactory(_random, families);

  /// YKS tercihinde puanın yettiği bölüm ve şehirler; tercih beklemiyorsa
  /// boş.
  List<(Department, String)> tercihPlacements() =>
      _state.character.hasFlag(EducationRules.pendingFlag)
      ? EducationRules.placements(_state.character)
      : const [];

  /// Bir bölüme yerleşir.
  LifeState enroll(String departmentId, String city) {
    final c = _state.character;
    final placement = tercihPlacements()
        .where((p) => p.$1.id == departmentId && p.$2 == city)
        .firstOrNull;
    if (placement == null) {
      throw StateError('$departmentId / $city tercih edilemez');
    }
    var next = EducationRules.enroll(c, placement.$1, city, _factory);
    if (next.city != c.city || next.home != c.home) {
      next = Housing.settle(next, _factory);
    }
    // Örgün öğrenci tam zamanlı çalışamaz; açıköğretimde iş sürer.
    final quits = next.job != null && !next.education.openEducation;
    if (quits) next = Careers.leaveJob(next);
    return _state = _state.copyWith(
      character: next,
      notes: [
        ..._state.notes,
        if (quits) const LifeNote(NoteKind.istifa),
        LifeNote(NoteKind.yerlesti, '$departmentId:${next.education.uniCity}'),
      ],
    );
  }

  /// Yerleşmeden devam: mezuna kalmak, çalışmak ya da çırak girmek.
  LifeState declineTercih(TercihKind kind) {
    final c = _state.character;
    if (!c.hasFlag(EducationRules.pendingFlag) || kind == TercihKind.bolum) {
      throw StateError('Şu an tercih yok ya da bölüm seçilmeli');
    }
    var next = EducationRules.decline(c, kind);
    // Çırak giren hemen bir ustanın yanında işe başlar.
    final apprentice = careers.byId(apprenticeCareer);
    if (kind == TercihKind.cirak && apprentice?.listing != null) {
      final info = apprentice!.listing!;
      next = JobMarket.hire(
        next,
        JobListing(
          careerId: apprentice.id,
          tier: 1,
          company: info.companies[_random.nextInt(info.companies.length)],
          ad: info.ads.first,
          interview: 0,
        ),
        careers,
        _factory,
      );
    }
    final note = switch (kind) {
      TercihKind.mezunaKal => NoteKind.mezunaKaldi,
      TercihKind.cirak => NoteKind.cirakOldu,
      _ => NoteKind.calismayiSecti,
    };
    return _state = _state.copyWith(
      character: next,
      notes: [..._state.notes, LifeNote(note)],
    );
  }

  /// Çırak girenin mesleği.
  static const String apprenticeCareer = 'oto_tamircisi';

  /// Taşınma 2 vakit sürer.
  static const int moveTimeCost = 2;

  /// Taşınılabilecek şehirler: kapalıysa sebebi, açıksa gideri.
  List<(String city, MoveBlocked? blocked, int cost)> moveOptions() {
    final c = _state.character;
    MoveBlocked? reason(String city) {
      if (city == c.city) return MoveBlocked.ayniSehir;
      if (c.age < Housing.minAge) return MoveBlocked.yas;
      if (c.hasFlag(ActionCatalog.studentFlag)) return MoveBlocked.ogrenci;
      if (c.home == HomeKind.kendiEvi) return MoveBlocked.evSahibi;
      if (_state.phase != YearPhase.actions || _state.timeLeft < moveTimeCost) {
        return MoveBlocked.vakit;
      }
      if (c.stats.money < Housing.relocationCost(city)) return MoveBlocked.para;
      return null;
    }

    return [
      for (final city in Cities.all)
        (city, reason(city), Housing.relocationCost(city)),
    ];
  }

  /// Başka şehre taşınır. İşi varsa bırakır (iş şehre bağlıdır).
  /// [withFamily]: o şehirde anne ya da baba varsa yanlarına.
  LifeState moveTo(String city, {bool withFamily = false}) {
    final option = moveOptions().where((o) => o.$1 == city).firstOrNull;
    if (option == null || option.$2 != null) {
      throw StateError('$city şehrine taşınılamaz: ${option?.$2}');
    }
    final c = _state.character;
    // İş bırakılır; işletmeler eski şehirde müdüre kalır.
    var leaving = Careers.leaveJob(c);
    for (final b in leaving.businesses) {
      leaving = BusinessRules.setPresent(leaving, b.id, false, _factory);
    }
    final moved = Housing.moveTo(
      leaving,
      city,
      _factory,
      withFamily: withFamily,
    );
    return _state = _state.copyWith(
      character: YearTick.updateHardshipFlags(
        _booked(c, moved, MoneySource.tasinma, ref: city),
      ),
      notes: [
        ..._state.notes,
        if (c.job != null) const LifeNote(NoteKind.istifa),
      ],
      timeSpent: _state.timeSpent + moveTimeCost,
      listings: JobMarket.listingsFor(moved, careers, _random),
      applied: const {},
    );
  }

  Character _applySpecial(ActionSpecial special, Character c) =>
      switch (special) {
        ActionSpecial.evdenCik => Housing.rentAlone(
          c.copyWith(
            stats: c.stats.withMoneyDelta(-Housing.moveInCost(c.city)),
          ),
          _factory,
        ),
        ActionSpecial.evArkadasi => Housing.shareFlat(
          c.copyWith(
            stats: c.stats.withMoneyDelta(-Housing.shareMoveInCost(c.city)),
          ),
          _factory,
        ),
        ActionSpecial.aileyeDon => Housing.backToFamily(c),
        ActionSpecial.evAl => Housing.buyHouse(c),
        ActionSpecial.evSat => Housing.sellHouse(c, _factory),
        ActionSpecial.arabaAl => Housing.buyCar(c),
        ActionSpecial.arabaSat => Housing.sellCar(c),
        ActionSpecial.kpss =>
          JobMarket.sitKpss(c, _random)
              ? JobMarket.withFlag(c, JobMarket.kpssFlag)
              : c,
        ActionSpecial.yazilimKursu => JobMarket.withFlag(
          c.copyWith(
            stats: c.stats
                .withMoneyDelta(-JobMarket.codingCourseCost)
                .withDelta(StatKind.knowledge, 3),
          ),
          JobMarket.codingFlag,
        ),
      };

  /// [before] ile [after] arasındaki para farkını tek bir kaynakla deftere
  /// yazar (fark yoksa yazmaz).
  static Character _booked(
    Character before,
    Character after,
    MoneySource source, {
    String? ref,
  }) {
    final diff = after.stats.money - before.stats.money;
    if (diff == 0) return after;
    return after.withLedger([
      MoneyEntry(age: after.age, source: source, amount: diff, ref: ref),
    ]);
  }

  /// Hayatın tam durumu; JSON'a çevrilip kaydedilebilir. Son kartın zar
  /// sonucu (lastOutcome) yalnızca arayüz içindir, kaydedilmez.
  Map<String, Object?> toSnapshot() => {
    'version': snapshotVersion,
    'seed': seed,
    'rng': _random.state,
    'market': _market.toJson(),
    'phase': _state.phase.name,
    'character': _state.character.toJson(),
    'queue': _state.queue.toJson(),
    'pending': [for (final e in _state.pendingCards) e.toJson()],
    'timeSpent': _state.timeSpent,
    'actionsUsed': _state.actionsUsed.toList(),
    'cause': _state.summary?.cause.name,
    'news': [for (final n in _state.news) n.toJson()],
    'notes': [for (final n in _state.notes) n.toJson()],
    'listings': [for (final l in _state.listings) l.toJson()],
    'applied': _state.applied.toList(),
    'interactionsUsed': _state.interactionsUsed.toList(),
  };

  /// [toSnapshot] ile kaydedilmiş hayatı kaldığı yerden sürdürür.
  ///
  /// Kayıttan sonra kart dosyaları değişmiş olabilir: artık olmayan bekleyen
  /// kartlar atlanır; yıl kartsız kalırsa aksiyon aşamasına geçilir.
  factory LifeEngine.restore({
    required EventDeck deck,
    CareerBook? careers,
    FamilyBook? families,
    InteractionBook? interactions,
    required Map<String, dynamic> snapshot,
  }) {
    final version = snapshot['version'];
    if (version != snapshotVersion) {
      throw FormatException('Desteklenmeyen kayıt sürümü: $version');
    }
    final engine = LifeEngine._restored(
      deck,
      careers ?? CareerBook.empty,
      families ?? FamilyBook.minimal,
      interactions ?? InteractionBook.minimal,
      snapshot['seed'] as int,
      SeededRandom.fromState(snapshot['rng'] as int),
    ).._market = Market.fromJson(snapshot['market'] as Map<String, dynamic>);
    final character = Character.fromJson(
      snapshot['character'] as Map<String, dynamic>,
    );
    final queue = ScheduleQueue.fromJson(snapshot['queue'] as List);
    final phase = YearPhase.values.byName(snapshot['phase'] as String);
    final pending = [
      for (final raw in snapshot['pending'] as List)
        if (deck.byId((raw as Map<String, dynamic>)['id'] as String)
            case final card?)
          PendingEvent(card, {
            ...?(raw['people'] as Map<String, dynamic>?)
                ?.cast<String, String>(),
          }),
    ];

    engine._state = switch (phase) {
      YearPhase.dead => LifeState(
        character: character,
        phase: phase,
        queue: queue,
        summary: engine._summaryBuilder.build(
          character,
          DeathCause.values.byName(snapshot['cause'] as String),
          engine._market,
        ),
      ),
      YearPhase.cards when pending.isEmpty => engine._actionsPhase(
        character,
        queue,
      ),
      YearPhase.cards => LifeState(
        character: character,
        phase: phase,
        queue: queue,
        pendingCards: List.unmodifiable(pending),
      ),
      YearPhase.actions => LifeState(
        character: character,
        phase: phase,
        queue: queue,
        timeSpent:
            snapshot['timeSpent'] as int? ??
            ActionCatalog.timeFor(character) - (snapshot['timeLeft'] as int),
        actionsUsed: {...(snapshot['actionsUsed'] as List).cast<String>()},
      ),
    };
    final news = snapshot['news'] as List?;
    final used = snapshot['interactionsUsed'] as List?;
    engine._state = engine._state.copyWith(
      news: [
        for (final n in news ?? const [])
          PersonNews.fromJson(n as Map<String, dynamic>),
      ],
      interactionsUsed: {...?used?.cast<String>()},
      notes: [
        for (final n in snapshot['notes'] as List? ?? const [])
          LifeNote.fromJson(n as Map<String, dynamic>),
      ],
      listings: [
        for (final l in snapshot['listings'] as List? ?? const [])
          JobListing.fromJson(l as Map<String, dynamic>),
      ],
      applied: {...?(snapshot['applied'] as List?)?.cast<String>()},
    );
    return engine;
  }

  /// Yılın olayları: önce dönemeçler, sonra zamanı gelen iplikler (aynı
  /// kişilerle), sonra rastgele olaylar. Dönemeçler dahil yılda en fazla
  /// [EventDeck.maxPerYear] olay; sığmayan iplik sonraki yıla kalır.
  /// İpliğin kişisi artık uygun değilse (vefat, arşiv, rolü bitti) iplik
  /// düşer. (Kapanış metinleri D4a'da gelir.)
  LifeState _beginYear(
    Character character,
    ScheduleQueue queue, {
    List<LifeNote> notes = const [],
  }) {
    final age = character.age;
    var (due, rest) = queue.takeDue(age);
    final milestones = deck.milestones(character, _random);
    final busy = {for (final e in milestones) ...e.people.values};
    final chained = <PendingEvent>[];
    for (final entry in due) {
      // Kayıttan sonra içerikten kaldırılmış iplik sessizce düşer.
      final card = deck.byId(entry.cardId);
      if (card == null || !card.conditions.isMetBy(character)) continue;
      if (milestones.length + chained.length >= EventDeck.maxPerYear) {
        rest = rest.add(entry.cardId, atAge: age + 1, people: entry.people);
        continue;
      }
      final people = EventDeck.bind(
        card,
        character,
        _random,
        fixed: entry.people,
        busy: busy,
      );
      if (people == null) continue;
      busy.addAll(people.values);
      chained.add(PendingEvent(card, Map.unmodifiable(people)));
    }
    final room = EventDeck.maxPerYear - milestones.length - chained.length;
    final drawn = deck.draw(
      character,
      _random,
      count: min(room, _eventCountFor(age) - chained.length),
      exclude: {
        for (final e in [...milestones, ...chained]) e.card.id,
      },
      themes: {for (final e in chained) e.card.theme},
      busy: busy,
    );
    final events = [...milestones, ...chained, ...drawn];
    if (events.isEmpty) return _actionsPhase(character, rest, notes: notes);
    return LifeState(
      character: character,
      phase: YearPhase.cards,
      queue: rest,
      pendingCards: List.unmodifiable(events),
      notes: List.unmodifiable(notes),
    );
  }

  /// Kartlar bitince serbest zaman. Bu yılın kartları seçildikten sonra
  /// belli olan okul sonuçları burada işlenir: 15 yaşında lise türü
  /// (LGS ve lise seçimi kartlarından sonra), 18 yaşında YKS puanı.
  LifeState _actionsPhase(
    Character character,
    ScheduleQueue queue, {
    ChoiceOutcome? lastOutcome,
    List<LifeNote> notes = const [],
  }) {
    final newNotes = [...notes];
    var c = EducationRules.assignHighSchool(character);
    if (c.education.highSchool != character.education.highSchool) {
      newNotes.add(LifeNote(NoteKind.lise, c.education.highSchool!.id));
    }
    final beforeYks = c;
    c = EducationRules.sitYks(c, _random);
    if (c.education.yksScore != beforeYks.education.yksScore) {
      newNotes.add(LifeNote(NoteKind.yksPuani, '${c.education.yksScore}'));
    }
    return LifeState(
      character: c,
      phase: YearPhase.actions,
      queue: queue,
      lastOutcome: lastOutcome,
      notes: List.unmodifiable(newNotes),
    );
  }

  /// Dönemeç ve iplik dışında yılda 1–2 olay; ilk yaşlarda bir olay.
  int _eventCountFor(int age) {
    if (age < 3) return 1;
    return _random.nextInt(100) < 55 ? 1 : 2;
  }
}
