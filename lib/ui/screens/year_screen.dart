import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../content/content_registry.dart';
import '../../engine/engine.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../models/models.dart';
import '../l10n_names.dart';
import '../providers.dart';
import 'settings_screen.dart';
import '../portrait/portrait.dart';
import '../portrait/portrait_spec.dart';
import '../widgets/life_status.dart';
import '../widgets/stats_bar.dart';
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = widget.state;
    final c = state.character;
    final engine = ref.read(lifeProvider.notifier).engine;

    final rolled = state.lastOutcome?.rollSucceeded;
    final leaning = switch ((state.currentCard, _lean)) {
      (final card?, final side?) => card.choice(side),
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
              '${l10n.ageLabel(c.age)} · ${l10n.stageName(c.stage)} · '
              '${jobLabel(l10n, c, engine.careers)}',
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
                onClose: () => setState(() => _closedSummaryAge = c.age),
              ),
            // Son kartın zar sonucu; alttaki düğmeleri örtmesin diye
            // SnackBar yerine burada durur.
            if (rolled != null)
              Container(
                key: const Key('roll_result'),
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 6),
                color: rolled
                    ? Theme.of(context).colorScheme.primaryContainer
                    : Theme.of(context).colorScheme.errorContainer,
                child: Text(
                  rolled ? l10n.rollSuccess : l10n.rollFail,
                  textAlign: TextAlign.center,
                ),
              ),
            Expanded(
              child: switch (state.phase) {
                YearPhase.cards => _cardPhase(state, l10n),
                _ => _ActionMenu(state: state),
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _cardPhase(LifeState state, AppLocalizations l10n) {
    final card = state.currentCard!;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(l10n.cardsLeft(state.pendingCards.length)),
        ),
        Expanded(
          child: SwipeCard(
            // Her yeni kart sıfırdan başlasın.
            key: ValueKey('${state.character.age}-${card.id}'),
            card: card,
            speakerName: widget.registry.speakers[card.speaker],
            portrait: switch (card.speaker) {
              final id? => PortraitDesigner.forSpeaker(
                id,
                playerAge: state.character.age,
              ),
              null => PortraitDesigner.forCharacter(state.character),
            },
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

class _ActionMenu extends ConsumerWidget {
  const _ActionMenu({required this.state});

  final LifeState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final controller = ref.read(lifeProvider.notifier);
    final actions = controller.engine.availableActions();
    final theme = Theme.of(context);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
          child: Text(l10n.actionsTitle, style: theme.textTheme.titleLarge),
        ),
        Text(
          l10n.actionsLeft(state.actionsLeft),
          key: const Key('actions_left'),
        ),
        if (controller.engine.lastJobSearch case final search?)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Text(
              switch (search.careerId) {
                final id? => l10n.jobFound(
                  controller.engine.careers.byId(id)?.name ?? id,
                ),
                null => l10n.jobNotFound,
              },
              key: const Key('job_search_result'),
              textAlign: TextAlign.center,
              style: theme.textTheme.titleSmall?.copyWith(
                color: search.found
                    ? theme.colorScheme.primary
                    : theme.colorScheme.error,
              ),
            ),
          ),
        const SizedBox(height: 8),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            children: [
              for (final (action, enabled) in actions)
                Card(
                  child: ListTile(
                    key: Key('action_${action.id}'),
                    enabled: enabled,
                    leading: Icon(_categoryIcon(action.category)),
                    title: Text(l10n.actionName(action.id) ?? action.id),
                    subtitle: Text(switch (action.moneyChange(
                      controller.engine.market,
                    )) {
                      0 => l10n.actionFree,
                      < 0 && final change => l10n.money(-change),
                      final change => l10n.moneyGain(change),
                    }),
                    trailing: state.actionsUsed.contains(action.id)
                        ? const Icon(Icons.check)
                        : null,
                    onTap: enabled
                        ? () => controller.doAction(action.id)
                        : null,
                  ),
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              key: const Key('age_up'),
              onPressed: controller.advanceYear,
              icon: const Icon(Icons.cake),
              label: Text(l10n.ageUpButton),
            ),
          ),
        ),
      ],
    );
  }

  static IconData _categoryIcon(ActionCategory category) => switch (category) {
    ActionCategory.okulIs => Icons.work_outline,
    ActionCategory.iliskiler => Icons.people_outline,
    ActionCategory.para => Icons.savings_outlined,
    ActionCategory.saglik => Icons.health_and_safety_outlined,
    ActionCategory.memleket => Icons.home_work_outlined,
    ActionCategory.eglence => Icons.celebration_outlined,
  };
}
