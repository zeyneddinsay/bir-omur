import 'dart:math';

import '../models/models.dart';
import 'birth.dart';
import 'death_check.dart';
import 'effect_resolver.dart';
import 'event_deck.dart';
import 'life_action.dart';
import 'schedule_queue.dart';
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
    this.actionsLeft = 0,
    this.actionsUsed = const {},
    this.lastOutcome,
    this.summary,
  });

  final Character character;
  final YearPhase phase;
  final ScheduleQueue queue;

  /// Bu yıl henüz kaydırılmamış kartlar; ilki ekrandaki karttır.
  final List<EventCard> pendingCards;
  final int actionsLeft;

  /// Bu yıl yapılmış aksiyonlar; aynı aksiyon yılda bir kez yapılır.
  final Set<String> actionsUsed;

  /// Son kart seçiminin sonucu (arayüzde zar sonucunu göstermek için).
  final ChoiceOutcome? lastOutcome;
  final LifeSummary? summary;

  EventCard? get currentCard =>
      pendingCards.isEmpty ? null : pendingCards.first;

  bool get isOver => phase == YearPhase.dead;
}

/// Oyun motorunun cephesi. Bir hayatı doğumdan ölüme yürütür.
///
/// Bütün rastgelelik tek bir `Random(seed)` üzerinden gelir: aynı tohum ve
/// aynı seçimler aynı hayatı üretir.
class LifeEngine {
  LifeEngine({required this.deck, required this.seed}) : _random = Random(seed);

  final EventDeck deck;
  final int seed;
  final Random _random;

  late final EffectResolver _resolver = EffectResolver(_random);
  late final DeathCheck _deathCheck = DeathCheck(_random);
  late final SummaryBuilder _summaryBuilder = SummaryBuilder(deck);
  static const YearTick _yearTick = YearTick();

  late LifeState _state;

  LifeState get state => _state;

  /// Yeni bir hayat başlatır ve 0 yaşının kartlarını çeker.
  LifeState startLife({String? name, Gender? gender}) {
    final character = BirthGenerator(_random)
        .generate(name: name, gender: gender);
    return _state = _beginYear(character, const ScheduleQueue());
  }

  /// Ekrandaki kartı [side] yönüne kaydırır.
  LifeState choose(ChoiceSide side) {
    final card = _state.currentCard;
    if (_state.phase != YearPhase.cards || card == null) {
      throw StateError('Şu an seçilecek kart yok (${_state.phase})');
    }
    if (side == ChoiceSide.up && card.up == null) {
      throw StateError('${card.id} kartında yukarı seçeneği yok');
    }

    final outcome = _resolver.resolve(_state.character, card, side);
    final character = YearTick.updateHardshipFlags(outcome.character);
    var queue = _state.queue;
    for (final scheduled in outcome.scheduled) {
      queue = queue.add(
        scheduled.cardId,
        atAge: character.age + scheduled.inYears,
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
      );
    }
    return _state = _actionsPhase(character, queue, lastOutcome: storedOutcome);
  }

  /// Bu yıl yapılabilecek aksiyonlar ve yapılıp yapılamayacakları.
  List<(LifeAction action, bool enabled)> availableActions() {
    final c = _state.character;
    final canAct = _state.phase == YearPhase.actions && _state.actionsLeft > 0;
    return [
      for (final action in ActionCatalog.availableFor(c))
        (
          action,
          canAct &&
              action.canAfford(c) &&
              !_state.actionsUsed.contains(action.id),
        ),
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
    if (_state.actionsLeft <= 0) {
      throw StateError('Bu yılın aksiyon hakkı bitti');
    }
    if (!action.isAvailableAt(c.age)) {
      throw StateError('$actionId bu yaşta yapılamaz');
    }
    if (!action.canAfford(c)) {
      throw StateError('$actionId için para yetmiyor');
    }
    if (_state.actionsUsed.contains(actionId)) {
      throw StateError('$actionId bu yıl zaten yapıldı');
    }

    var character = EffectResolver.applyEffect(c, Effect(money: -action.cost));
    character = EffectResolver.applyEffect(character, action.effect);
    character = YearTick.updateHardshipFlags(character);
    return _state = LifeState(
      character: character,
      phase: YearPhase.actions,
      queue: _state.queue,
      actionsLeft: _state.actionsLeft - 1,
      actionsUsed: {..._state.actionsUsed, actionId},
      lastOutcome: _state.lastOutcome,
    );
  }

  /// "Yaşlan": yıl sonu ölüm kontrolü, sonra bir sonraki yaş ve kartları.
  LifeState advanceYear() {
    if (_state.phase != YearPhase.actions) {
      throw StateError('Yaşlanmadan önce kartlar bitmeli (${_state.phase})');
    }
    final cause = _deathCheck.check(_state.character);
    if (cause != null) {
      final dead = _state.character.copyWith(isAlive: false);
      return _state = LifeState(
        character: dead,
        phase: YearPhase.dead,
        queue: _state.queue,
        summary: _summaryBuilder.build(dead, cause),
      );
    }
    return _state = _beginYear(_yearTick.apply(_state.character), _state.queue);
  }

  LifeState _beginYear(Character character, ScheduleQueue queue) {
    final (dueIds, rest) = queue.takeDue(character.age);
    final chained = [
      for (final id in dueIds)
        if (_chainCard(id) case final card?
            when card.conditions.isMetBy(character))
          card,
    ];
    final drawn = deck.draw(
      character,
      _random,
      count: max(0, _cardCountFor(character.age) - chained.length),
      exclude: {for (final card in chained) card.id},
    );
    final cards = [...chained, ...drawn];
    if (cards.isEmpty) return _actionsPhase(character, rest);
    return LifeState(
      character: character,
      phase: YearPhase.cards,
      queue: rest,
      pendingCards: List.unmodifiable(cards),
    );
  }

  EventCard? _chainCard(String id) {
    final card = deck.byId(id);
    if (card == null) throw StateError('Zincir kartı bulunamadı: $id');
    return card;
  }

  LifeState _actionsPhase(
    Character character,
    ScheduleQueue queue, {
    ChoiceOutcome? lastOutcome,
  }) {
    return LifeState(
      character: character,
      phase: YearPhase.actions,
      queue: queue,
      actionsLeft: ActionCatalog.allowanceFor(character),
      lastOutcome: lastOutcome,
    );
  }

  /// Yılda 1–3 kart; ilk yaşlarda tek kart.
  int _cardCountFor(int age) {
    if (age < 3) return 1;
    final roll = _random.nextInt(100);
    if (roll < 35) return 1;
    if (roll < 80) return 2;
    return 3;
  }
}
