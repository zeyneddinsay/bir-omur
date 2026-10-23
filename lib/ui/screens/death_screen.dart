import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../content/event_text.dart';
import '../../content/content_loader.dart';
import '../../engine/engine.dart';
import '../../l10n/generated/app_localizations.dart';
import '../l10n_names.dart';
import '../people/people_text.dart';
import '../portrait/portrait.dart';
import '../portrait/portrait_spec.dart';
import '../providers.dart';
import '../share/share_preview_screen.dart';
import '../widgets/business_card.dart';
import '../widgets/life_status.dart';

/// Ölüm ve basit hayat özeti. Paylaşım görseli F2'de gelir.
class DeathScreen extends ConsumerWidget {
  const DeathScreen({super.key, required this.state, required this.content});

  final LifeState state;
  final GameContent content;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final summary = state.summary!;
    final c = summary.character;
    final moment = summary.biggestMoment;
    final momentCard = moment == null ? null : content.deck.byId(moment.cardId);
    final controller = ref.read(lifeProvider.notifier);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Portrait(
                        spec: PortraitDesigner.forCharacter(c),
                        size: 96,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        l10n.deathTitle(c.name),
                        key: const Key('death_name'),
                        style: theme.textTheme.headlineMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.deathLifespan(summary.deathAge),
                        style: theme.textTheme.titleMedium,
                      ),
                      Text(l10n.hometownLine(c.hometown, c.team)),
                      Text(
                        l10n.backgroundName(c.background),
                        key: const Key('death_background'),
                      ),
                      if (lastJobLabel(l10n, c, content.careers)
                          case final job?)
                        Text(job, key: const Key('death_career')),
                      Text(
                        l10n.deathNetWorth(l10n.money(summary.netWorth)),
                        key: const Key('death_net_worth'),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        l10n.deathCauseText(
                          summary.cause,
                          age: summary.deathAge,
                        ),
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      const Divider(height: 40),
                      Text(
                        l10n.nicknameTitle,
                        style: theme.textTheme.labelLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.nicknameName(summary.nickname),
                        key: const Key('nickname'),
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: theme.colorScheme.primary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      _LifeStorySection(
                        story: LifeStory(c),
                        rich: summary.netWorth >= 15000000,
                      ),
                      if (moment != null && momentCard != null) ...[
                        const Divider(height: 40),
                        Text(
                          l10n.biggestMomentTitle,
                          style: theme.textTheme.labelLarge,
                        ),
                        const SizedBox(height: 4),
                        Text(l10n.biggestMomentAge(moment.age)),
                        const SizedBox(height: 8),
                        Text(
                          EventText.render(
                            EventText.cardText(
                              momentCard,
                              summary.character,
                              record: moment,
                            ),
                            moment.people,
                            summary.character,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l10n.momentChoice(
                            momentCard.choice(moment.side).label,
                          ),
                          style: theme.textTheme.titleSmall,
                        ),
                      ],
                      const Divider(height: 40),
                      Text(l10n.cardsSeenLine(summary.cardsSeen)),
                      const SizedBox(height: 4),
                      Text(
                        l10n.seedLine(controller.engine.seed),
                        style: theme.textTheme.bodySmall,
                      ),
                      const SizedBox(height: 24),
                      _EarnedBadges(
                        earned: (content.achievements ?? AchievementBook.empty)
                            .earnedBy(summary),
                      ),
                      OutlinedButton.icon(
                        key: const Key('share_button'),
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => SharePreviewScreen(
                              summary: summary,
                              content: content,
                            ),
                          ),
                        ),
                        icon: const Icon(Icons.ios_share),
                        label: Text(l10n.shareButton),
                      ),
                      const SizedBox(height: 8),
                      FilledButton.icon(
                        key: const Key('rebirth'),
                        onPressed: controller.reset,
                        icon: const Icon(Icons.replay),
                        label: Text(l10n.rebirthButton),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Bu hayatta kazanılan rozetler; ilk kez kazanılanlar "Yeni!" diye işaretli.
class _EarnedBadges extends ConsumerWidget {
  const _EarnedBadges({required this.earned});

  final List<Achievement> earned;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (earned.isEmpty) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final fresh = ref.watch(newBadgesProvider);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        children: [
          Text(l10n.deathBadgesTitle, style: theme.textTheme.labelLarge),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              for (final a in earned)
                Chip(
                  key: Key('earned_${a.id}'),
                  avatar: const Icon(Icons.military_tech, size: 18),
                  label: Text(
                    fresh.contains(a.id)
                        ? '${a.name} · ${l10n.badgeNew}'
                        : a.name,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Hayatın kişileri: veda, cenaze, en yakınlar, gerçek dost, kurulan işler.
class _LifeStorySection extends StatelessWidget {
  const _LifeStorySection({required this.story, required this.rich});

  final LifeStory story;
  final bool rich;

  static String _lowerFirst(String s) =>
      s.isEmpty ? s : s[0].toLowerCase() + s.substring(1);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final bedside = story.bedside;
    final friends = story.trueFriends;
    final mourners = story.mourners.length;
    final missed = story.mostMissed;
    final businesses = story.businesses.entries.map(
      (e) => switch (e.value) {
        BusinessEnd.acik => l10n.businessEnd_acik(
          businessTypeName(l10n, e.key),
        ),
        BusinessEnd.birakildi => l10n.businessEnd_birakildi(
          businessTypeName(l10n, e.key),
        ),
        BusinessEnd.batti => l10n.businessEnd_batti(
          businessTypeName(l10n, e.key),
        ),
      },
    );
    final lines = <String>[
      bedside == null
          ? l10n.storyAlone
          : l10n.storyBedside(
              _lowerFirst(l10n.relationOf(bedside)),
              bedside.name,
            ),
      [
        l10n.storyFuneral(mourners),
        if (friends.isNotEmpty && mourners > 0)
          l10n.storyFuneralFriends(friends.map((p) => p.name).join(', ')),
        if (story.cameAnyway case final p?) l10n.storyCameAnyway(p.name),
        if (rich && mourners > 0) l10n.storyStrangers,
      ].join(' '),
      // Tek yakın, özleyecek kişiyle aynıysa iki kez yazılmaz.
      if (story.closest.length > 1 ||
          (story.closest.isNotEmpty && story.closest.first != missed))
        l10n.storyClosest(story.closest.map((p) => p.name).join(', ')),
      if (friends.isNotEmpty) l10n.storyTrueFriend(friends.first.name),
      if (missed != null) l10n.storyMissed(missed.name),
      if (businesses.isNotEmpty) l10n.storyBusinesses(businesses.join(', ')),
    ];
    return Column(
      key: const Key('life_story'),
      children: [
        const Divider(height: 40),
        Text(l10n.storyTitle, style: theme.textTheme.labelLarge),
        const SizedBox(height: 8),
        for (final line in lines)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(line, textAlign: TextAlign.center),
          ),
      ],
    );
  }
}
