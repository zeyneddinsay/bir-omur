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

  /// Serbest zamanda açık sekme; yıllar arasında korunur.
  HomeTab _tab = HomeTab.me;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = widget.state;
    final c = state.character;
    final engine = ref.read(lifeProvider.notifier).engine;

    final rolled = state.lastOutcome?.rollSucceeded;
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
      bottomNavigationBar: state.phase == YearPhase.actions
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          l10n.timeLeft(state.timeLeft),
                          key: const Key('actions_left'),
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                      ),
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
                _ => HomeTabs(state: state, tab: _tab),
              },
            ),
          ],
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
          padding: const EdgeInsets.only(top: 8),
          child: Text(l10n.cardsLeft(state.pendingCards.length)),
        ),
        Expanded(
          child: SwipeCard(
            // Her yeni kart sıfırdan başlasın.
            key: ValueKey('${state.character.age}-${card.id}'),
            card: card,
            text: EventText.render(card.text, event.people, c),
            speakerName: EventText.speakerName(card, event.people, c),
            portrait: speaker == null
                ? PortraitDesigner.forCharacter(c)
                : PortraitDesigner.ofPerson(speaker, playerAge: c.age),
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
