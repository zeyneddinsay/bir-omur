import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../content/content_loader.dart';
import '../../engine/engine.dart';
import '../../engine/life_record.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../models/models.dart';
import '../l10n_names.dart';
import '../providers.dart';

/// Hayat Albümü: biten hayatlar ve hayatlar boyunca biriken rozetler.
class AlbumScreen extends ConsumerWidget {
  const AlbumScreen({super.key, required this.content});

  final GameContent content;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.albumTitle),
          bottom: TabBar(
            tabs: [
              Tab(text: l10n.albumTabLives),
              Tab(text: l10n.albumTabBadges),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _LivesTab(content: content),
            _BadgesTab(book: content.achievements ?? AchievementBook.empty),
          ],
        ),
      ),
    );
  }
}

class _LivesTab extends ConsumerWidget {
  const _LivesTab({required this.content});

  final GameContent content;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final lives = ref.watch(albumProvider).value ?? const <LifeRecord>[];
    if (lives.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(l10n.albumEmpty, textAlign: TextAlign.center),
        ),
      );
    }
    final newestFirst = lives.reversed.toList();
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: newestFirst.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, i) {
        final life = newestFirst[i];
        final nickname = switch (life.nicknameValue) {
          final n? => l10n.nicknameName(n),
          null => life.nickname,
        };
        final background = FamilyBackground.fromId(life.background);
        final career = content.careers.byId(life.careerId ?? '');
        final careerLine = career == null || life.careerTier == null
            ? null
            : l10n.jobTier(career.name, career.tier(life.careerTier!).name);
        return ListTile(
          key: Key('album_life_$i'),
          leading: CircleAvatar(child: Text(life.name.characters.first)),
          title: Text(life.name),
          subtitle: Text(
            [
              l10n.albumLifeLine(life.deathAge, nickname),
              [
                life.hometown,
                ?careerLine,
                if (background != null) l10n.backgroundName(background),
              ].join(' · '),
            ].join('\n'),
          ),
          isThreeLine: true,
        );
      },
    );
  }
}

class _BadgesTab extends ConsumerWidget {
  const _BadgesTab({required this.book});

  final AchievementBook book;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final progress =
        ref.watch(badgeProgressProvider).value ??
        const <String, AchievementProgress>{};
    final earnedCount = book.all
        .where((a) => progress.containsKey(a.id))
        .length;
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: Text(
            l10n.badgesSummary(earnedCount, book.all.length),
            key: const Key('badges_summary'),
            style: theme.textTheme.titleMedium,
          ),
        ),
        for (final a in book.all)
          _BadgeTile(achievement: a, progress: progress[a.id]),
      ],
    );
  }
}

class _BadgeTile extends StatelessWidget {
  const _BadgeTile({required this.achievement, this.progress});

  final Achievement achievement;
  final AchievementProgress? progress;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final earned = progress != null;
    final color = switch (achievement.rarity) {
      Rarity.siradan => theme.colorScheme.primary,
      Rarity.nadir => theme.colorScheme.tertiary,
      Rarity.efsane => const Color(0xFFD4A017),
    };
    return Opacity(
      opacity: earned ? 1 : 0.5,
      child: Card(
        child: ListTile(
          key: Key('badge_${achievement.id}'),
          leading: Icon(
            earned ? Icons.military_tech : Icons.lock_outline,
            color: earned ? color : null,
          ),
          title: Text(achievement.name),
          subtitle: Text(achievement.description),
          trailing: Text(
            earned ? l10n.badgeCount(progress!.count) : l10n.badgeLocked,
            style: theme.textTheme.labelSmall,
            textAlign: TextAlign.end,
          ),
        ),
      ),
    );
  }
}
