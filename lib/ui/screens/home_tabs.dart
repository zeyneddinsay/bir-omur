import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../content/event_text.dart';
import '../../engine/engine.dart';
import '../../l10n/generated/app_localizations.dart';
import '../l10n_names.dart';
import '../people/people_tab.dart';
import '../people/people_text.dart';
import '../people/people_view.dart';
import '../providers.dart';
import '../widgets/ledger_view.dart';
import '../widgets/life_status.dart';

/// Ana ekranın beş sekmesi (yılın olayları bittikten sonra).
enum HomeTab { me, people, work, assets, activities }

/// Kartlardan sonra yılın serbest zamanı: sekmeler, vakit ve Yaşlan.
class HomeTabs extends ConsumerWidget {
  const HomeTabs({super.key, required this.state, required this.tab});

  final LifeState state;
  final HomeTab tab;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(lifeProvider.notifier);
    final engine = controller.engine;
    return switch (tab) {
      HomeTab.me => _MeTab(state: state),
      HomeTab.people => PeopleTab(character: state.character),
      HomeTab.work => _ActionsTab(
        state: state,
        categories: const {ActionCategory.okulIs},
        header: _WorkHeader(engine: engine),
      ),
      HomeTab.assets => _ActionsTab(
        state: state,
        categories: const {ActionCategory.para},
        header: Padding(
          padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AssetsSummary(engine: engine),
              const SizedBox(height: 12),
              LedgerView(character: state.character, deck: engine.deck),
            ],
          ),
        ),
      ),
      HomeTab.activities => _ActionsTab(
        state: state,
        categories: const {ActionCategory.saglik, ActionCategory.eglence},
      ),
    };
  }
}

/// Alt çubuk: sekmeler.
class HomeNavigation extends StatelessWidget {
  const HomeNavigation({super.key, required this.tab, required this.onTab});

  final HomeTab tab;
  final ValueChanged<HomeTab> onTab;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    NavigationDestination item(HomeTab t, IconData icon, String label) =>
        NavigationDestination(
          key: Key('tab_${t.name}'),
          icon: Icon(icon),
          label: label,
        );
    return NavigationBar(
      selectedIndex: tab.index,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      onDestinationSelected: (i) => onTab(HomeTab.values[i]),
      destinations: [
        item(HomeTab.me, Icons.person_outline, l10n.tabMe),
        item(HomeTab.people, Icons.groups_outlined, l10n.tabPeople),
        item(HomeTab.work, Icons.work_outline, l10n.tabSchoolWork),
        item(
          HomeTab.assets,
          Icons.account_balance_wallet_outlined,
          l10n.tabAssets,
        ),
        item(HomeTab.activities, Icons.directions_run, l10n.tabActivities),
      ],
    );
  }
}

/// Ben: yılın günlüğü ve kimlik bilgileri.
class _MeTab extends ConsumerWidget {
  const _MeTab({required this.state});

  final LifeState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final c = state.character;
    final engine = ref.read(lifeProvider.notifier).engine;
    final occupations =
        ref.watch(contentProvider).value?.families.occupations ?? const {};
    final news = [
      for (final n in state.news) l10n.newsLine(n, c, occupations: occupations),
    ].where((line) => line.isNotEmpty).toList();
    final choices = [
      for (final r in PeopleView.choicesThisYear(c))
        if (engine.deck.byId(r.cardId) case final card?)
          l10n.journalChoice(
            EventText.render(card.choice(r.side).label, r.people, c),
          ),
    ];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          key: const Key('journal'),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.journalTitle, style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                if (news.isEmpty && choices.isEmpty) Text(l10n.journalEmpty),
                for (final line in news)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text('• $line'),
                  ),
                for (final line in choices)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(line, style: theme.textTheme.bodySmall),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        ListTile(
          leading: const Icon(Icons.home_outlined),
          title: Text(l10n.hometownLine(c.hometown, c.team)),
          subtitle: Text(
            [
              l10n.backgroundName(c.background),
              jobLabel(l10n, c, engine.careers),
            ].where((s) => s.isNotEmpty).join(' · '),
          ),
        ),
      ],
    );
  }
}

/// Okul / İş sekmesinin başlığı: şu anki iş ve son iş arama sonucu.
class _WorkHeader extends StatelessWidget {
  const _WorkHeader({required this.engine});

  final LifeEngine engine;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final c = engine.state.character;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 12, 4, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            jobLabel(l10n, c, engine.careers),
            key: const Key('work_status'),
            style: theme.textTheme.titleMedium,
          ),
          Text(l10n.stageName(c.stage), style: theme.textTheme.bodySmall),
          if (engine.lastJobSearch case final search?)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                switch (search.careerId) {
                  final id? => l10n.jobFound(
                    engine.careers.byId(id)?.name ?? id,
                  ),
                  null => l10n.jobNotFound,
                },
                key: const Key('job_search_result'),
                style: theme.textTheme.titleSmall?.copyWith(
                  color: search.found
                      ? theme.colorScheme.primary
                      : theme.colorScheme.error,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Bir sekmenin aksiyonları; başlık isteğe bağlı.
class _ActionsTab extends ConsumerWidget {
  const _ActionsTab({
    required this.state,
    required this.categories,
    this.header,
  });

  final LifeState state;
  final Set<ActionCategory> categories;
  final Widget? header;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final controller = ref.read(lifeProvider.notifier);
    final actions = [
      for (final entry in controller.engine.actionOptions())
        if (categories.contains(entry.$1.category)) entry,
    ];
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      children: [
        ?header,
        if (actions.isEmpty)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(l10n.noActionsHere, textAlign: TextAlign.center),
          ),
        for (final (action, blocked) in actions)
          Card(
            child: ListTile(
              key: Key('action_${action.id}'),
              enabled: blocked == null,
              leading: Icon(_categoryIcon(action.category)),
              title: Text(l10n.actionName(action.id) ?? action.id),
              subtitle: Text(
                blocked == null
                    ? '${switch (action.moneyChange(controller.engine.market)) {
                        0 => l10n.actionFree,
                        < 0 && final change => l10n.money(-change),
                        final change => l10n.moneyGain(change),
                      }} · ${l10n.interactionCost(action.timeCost)}'
                    : l10n.actionBlockedReason(blocked),
              ),
              trailing: state.actionsUsed.contains(action.id)
                  ? const Icon(Icons.check)
                  : null,
              onTap: blocked == null
                  ? () => controller.doAction(action.id)
                  : null,
            ),
          ),
      ],
    );
  }

  static IconData _categoryIcon(ActionCategory category) => switch (category) {
    ActionCategory.okulIs => Icons.work_outline,
    ActionCategory.para => Icons.savings_outlined,
    ActionCategory.saglik => Icons.health_and_safety_outlined,
    ActionCategory.eglence => Icons.celebration_outlined,
  };
}
