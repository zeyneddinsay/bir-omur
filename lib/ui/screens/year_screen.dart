import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../content/content_registry.dart';
import '../../content/event_text.dart';
import '../../engine/engine.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../models/models.dart';
import '../l10n_names.dart';
import '../providers.dart';
import 'home_tabs.dart';
import 'settings_screen.dart';
import '../portrait/portrait.dart';
import '../portrait/portrait_spec.dart';
import '../widgets/education_card.dart' show noteLine;
import '../widgets/life_status.dart';
import '../widgets/stats_bar.dart';
import '../widgets/outcome_panel.dart';
import '../widgets/swipe_card.dart';

/// Bir yıl: üstte göstergeler, altta ya kart ya da aksiyon menüsü.
class YearScreen extends ConsumerStatefulWidget {
  const YearScreen({super.key, required this.state, required this.registry});

  final LifeState state;
  final ContentRegistry registry;

  @override
  ConsumerState<YearScreen> createState() => _YearScreenState();
}

class _YearScreenState extends ConsumerState<YearScreen> {
  ChoiceSide? _lean;

  /// Geçen yıl şeridinin kapatıldığı yaş; yeni yılda şerit yine görünür.
  int? _closedSummaryAge;

  /// Serbest zamanda açık sekme; yıllar arasında korunur.
  HomeTab _tab = HomeTab.me;

  /// Kapatılan sonuç paneli; yeni bir seçimde panel yine görünür.
  ChoiceOutcome? _closedOutcome;

  /// Kapatılan aksiyon sonucu.
  ActionResult? _closedAction;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = widget.state;
    final c = state.character;
    final engine = ref.read(lifeProvider.notifier).engine;

    final leaning = switch ((state.currentEvent, _lean)) {
      (final event?, final side?) => event.card.choice(side),
      _ => null,
    };

    return Scaffold(
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.all(8),
          child: Portrait(
            key: const Key('player_portrait'),
            spec: PortraitDesigner.forCharacter(c),
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(c.name),
            Text(
              [
                l10n.ageLabel(c.age),
                stageLabel(l10n, c, engine.careers),
                jobLabel(l10n, c, engine.careers),
              ].where((s) => s.isNotEmpty).join(' · '),
              key: const Key('age_line'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        actions: [
          AssetsButton(engine: engine),
          SettingsScreen.button(context),
        ],
      ),
      bottomNavigationBar: state.phase == YearPhase.actions
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: Row(
                    children: [
                      // Dokununca vaktin ne olduğu anlatılır.
                      Expanded(
                        child: Tooltip(
                          message: l10n.timeInfoTooltip,
                          child: InkWell(
                            key: const Key('time_info'),
                            borderRadius: BorderRadius.circular(12),
                            onTap: () => _showTimeInfo(state),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.hourglass_bottom,
                                    size: 18,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .primary,
                                  ),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      // Hiç vakti olmayan yaşta (0–5 ve
                                      // askerlik) "bitti" denmez.
                                      state.timeSpent + state.timeLeft == 0
                                          ? l10n.timeNone
                                          : l10n.timeLeft(state.timeLeft),
                                      key: const Key('actions_left'),
                                      maxLines: 2,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleSmall,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(
                                    Icons.info_outline,
                                    size: 16,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.5),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Temada düğmeler tam genişlik ister; satırda sınır.
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 180),
                        child: FilledButton.icon(
                          key: const Key('age_up'),
                          onPressed: ref
                              .read(lifeProvider.notifier)
                              .advanceYear,
                          icon: const Icon(Icons.cake),
                          label: Text(l10n.ageUpButton),
                        ),
                      ),
                    ],
                  ),
                ),
                HomeNavigation(
                  tab: _tab,
                  onTab: (tab) => setState(() => _tab = tab),
                ),
              ],
            )
          : null,
      body: SafeArea(
        child: Column(
          children: [
            StatsBar(
              stats: c.stats,
              highlight: leaning == null ? const {} : affectedStats(leaning),
              highlightMoney: leaning != null && affectsMoney(leaning),
            ),
            const Divider(height: 1),
            if (engine.lastEconomy case final economy?
                when _closedSummaryAge != c.age)
              LastYearBanner(
                economy: economy,
                career: engine.lastCareer,
                scholarship: c.ledger
                    .where(
                      (e) => e.age == c.age && e.source == MoneySource.burs,
                    )
                    .fold(0, (sum, e) => sum + e.amount),
                business: c.ledger
                    .where(
                      (e) => e.age == c.age && e.source == MoneySource.isletme,
                    )
                    .fold(0, (sum, e) => sum + e.amount),
                onClose: () => setState(() => _closedSummaryAge = c.age),
              ),
            // Son seçimin sonucu; alttaki düğmeleri örtmesin diye SnackBar
            // yerine burada durur.
            // Son aksiyonun sonucu, son kartınkinden yenidir.
            if (ref.watch(lastActionProvider) case final action?
                when !identical(action, _closedAction))
              ActionResultPanel(
                title: action.note != null
                    ? noteLine(
                        l10n,
                        action.note!,
                        engine.careers,
                        deck: engine.deck,
                        character: c,
                      )
                    : l10n.actionName(action.actionId) ?? action.actionId,
                before: action.before,
                after: action.after,
                onClose: () => setState(() => _closedAction = action),
              )
            // Ben sekmesinde günlük aynı cümleyi zaten gösterir; tekrar etmez.
            else if (state.lastOutcome case final outcome?
                when !identical(outcome, _closedOutcome) &&
                    (state.phase == YearPhase.cards || _tab != HomeTab.me))
              OutcomePanel(
                outcome: outcome,
                character: c,
                onClose: () => setState(() => _closedOutcome = outcome),
              ),
            Expanded(
              child: switch (state.phase) {
                YearPhase.cards => _cardPhase(state, l10n),
                _ => HomeTabs(state: state, tab: _tab),
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Vaktin ne olduğunu, bu yılki hakkı ve yaşa göre tabloyu anlatır.
  void _showTimeInfo(LifeState state) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(
            key: const Key('time_info_sheet'),
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l10n.timeInfoTitle, style: theme.textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(l10n.timeInfoBody),
              const SizedBox(height: 12),
              Text(
                l10n.timeInfoYours(state.timeSpent + state.timeLeft),
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 12),
              Text(l10n.timeInfoTableTitle, style: theme.textTheme.labelLarge),
              const SizedBox(height: 4),
              Text(
                l10n.timeInfoTable,
                style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(l10n.timeInfoClose),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _cardPhase(LifeState state, AppLocalizations l10n) {
    final event = state.currentEvent!;
    final card = event.card;
    final c = state.character;
    final speakerId = card.speaker == null ? null : event.people[card.speaker];
    final speaker = speakerId == null ? null : c.people[speakerId];
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Text(
            l10n.cardsLeft(state.pendingCards.length - 1),
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface
                  .withValues(alpha: 0.6),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Expanded(
          child: SwipeCard(
            // Her yeni kart sıfırdan başlasın. Aynı olay aynı yıl iki kez
            // gelebilir (zor günde iki arayan); kalan kart sayısı ayırır.
            // Yoksa ikinci kart öncekinin "seçildi" durumunda donar.
            key: ValueKey(
              '${state.character.age}-${card.id}-${state.pendingCards.length}',
            ),
            card: card,
            text: EventText.render(
              EventText.cardText(card, c),
              event.people,
              c,
            ),
            speakerName: EventText.speakerName(card, event.people, c),
            portrait: speaker == null
                ? PortraitDesigner.forCharacter(c)
                : PortraitDesigner.ofPerson(
                    speaker,
                    playerAge: c.age,
                    family: c,
                  ),
            character: c,
            people: event.people,
            render: (template) => EventText.render(template, event.people, c),
            remaining: state.pendingCards.length - 1,
            onLean: (side) => setState(() => _lean = side),
            onChoose: (side) {
              setState(() => _lean = null);
              ref.read(lifeProvider.notifier).choose(side);
            },
          ),
        ),
      ],
    );
  }
}

/// Seçeneğin dokunabileceği göstergeler (zarın iki dalı dahil).
Set<StatKind> affectedStats(Choice choice) => {
  for (final effect in choice.allEffects) ...effect.stats.keys,
};

bool affectsMoney(Choice choice) => choice.allEffects.any((e) => e.money != 0);
