import 'dart:math';

import '../models/models.dart';
import 'birth.dart';
import 'careers.dart';
import 'cities.dart';
import 'death_check.dart';
import 'economy.dart';
import 'education.dart';
import 'effect_resolver.dart';
import 'event_deck.dart';
import 'housing.dart';
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
    this.timeLeft = 0,
    this.actionsUsed = const {},
    this.lastOutcome,
    this.summary,
    this.news = const [],
    this.interactionsUsed = const {},
    this.lastInteraction,
    this.notes = const [],
  });

  final Character character;
  final YearPhase phase;
  final ScheduleQueue queue;

  /// Bu yıl henüz kaydırılmamış olaylar; ilki ekrandaki olaydır.
  final List<PendingEvent> pendingCards;
  final int timeLeft;

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

  LifeState copyWith({
    Character? character,
    int? timeLeft,
    Set<String>? actionsUsed,
    List<PersonNews>? news,
    Set<String>? interactionsUsed,
    InteractionResult? lastInteraction,
    List<LifeNote>? notes,
  }) => LifeState(
    character: character ?? this.character,
    phase: phase,
    queue: queue,
    pendingCards: pendingCards,
    timeLeft: timeLeft ?? this.timeLeft,
    actionsUsed: actionsUsed ?? this.actionsUsed,
    lastOutcome: lastOutcome,
    summary: summary,
    news: news == null ? this.news : List.unmodifiable(news),
    interactionsUsed: interactionsUsed ?? this.interactionsUsed,
    lastInteraction: lastInteraction ?? this.lastInteraction,
    notes: notes == null ? this.notes : List.unmodifiable(notes),
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

  JobSearchResult? _lastJobSearch;

  /// Bu yılki "İş ara" aksiyonunun sonucu; yapılmadıysa null. Kaydedilmez.
  JobSearchResult? get lastJobSearch => _lastJobSearch;

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

    final remaining = _state.pendingCards.sublist(1);
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
      );
    }
    return _state = _actionsPhase(
      character,
      queue,
      lastOutcome: storedOutcome,
      notes: _state.notes,
    ).withNews(_state.news);
  }

  /// Bu yıl yapılabilecek aksiyonlar ve yapılıp yapılamayacakları.
  List<(LifeAction action, bool enabled)> availableActions() => [
    for (final (action, blocked) in actionOptions()) (action, blocked == null),
  ];

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
      if (action.searchesJob && !hasOpenCareer(c, careers)) {
        return ActionBlocked.isYok;
      }
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

    var character = switch (action.special) {
      final special? => _applySpecial(special, c),
      null => EffectResolver.applyEffect(
        c,
        action.totalEffect(_market),
        careers: careers,
      ),
    };
    if (action.searchesJob) {
      final (hired, result) = searchJob(
        character,
        careers,
        (roll) => _resolver.rollSucceeds(character, roll),
      );
      character = hired;
      _lastJobSearch = result;
    }
    character = YearTick.updateHardshipFlags(
      _booked(c, character, MoneySource.aksiyon, ref: actionId),
    );
    return _state = _state.copyWith(
      character: character,
      timeLeft: _state.timeLeft - action.timeCost,
      actionsUsed: {..._state.actionsUsed, actionId},
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
      timeLeft: _state.phase == YearPhase.actions ? _state.timeLeft : 0,
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
      timeLeft: _state.timeLeft - option.timeCost,
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
        source: MoneySource.terfi,
        amount: paid.stats.money - aged.stats.money - careerReport.income,
      ),
    ]);
    _lastJobSearch = null;
    final (studied, notes, queue) = _schoolYear(afterCareer, _state.queue);
    final soldier = Military.inService(studied);
    final served = Military.returnHome(studied, _factory);
    if (soldier) notes.add(const LifeNote(NoteKind.askerlik));
    final (character, news) = PeopleTick(
      _random,
      families,
      cities: BirthGenerator.hometowns,
    ).apply(Economy.syncDerivedFlags(YearTick.updateHardshipFlags(served)));
    return _state = _beginYear(
      Relationships.syncFamilyBond(
        Housing.ensureNeighbours(character, _factory),
      ),
      queue,
      notes: notes,
    ).withNews(news);
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
    final next = EducationRules.enroll(c, placement.$1, city, _factory);
    return _state = _state.copyWith(
      character: next,
      notes: [
        ..._state.notes,
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
    final next = EducationRules.decline(c, kind);
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
    final moved = Housing.moveTo(
      c.job == null ? c : c.copyWith(clearJob: true),
      city,
      _factory,
      withFamily: withFamily,
    );
    return _state = _state.copyWith(
      character: YearTick.updateHardshipFlags(
        _booked(c, moved, MoneySource.tasinma, ref: city),
      ),
      timeLeft: _state.timeLeft - moveTimeCost,
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
    'timeLeft': _state.timeLeft,
    'actionsUsed': _state.actionsUsed.toList(),
    'cause': _state.summary?.cause.name,
    'news': [for (final n in _state.news) n.toJson()],
    'notes': [for (final n in _state.notes) n.toJson()],
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
        timeLeft: snapshot['timeLeft'] as int,
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
      timeLeft: ActionCatalog.timeFor(c),
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
