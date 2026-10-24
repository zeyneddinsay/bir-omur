import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../engine/engine.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../models/models.dart';
import '../providers.dart';

/// Varlıklar sekmesinde nerede yaşadığın: ev türü, şehir, yıllık gider ve
/// başka şehre taşınma.
class HomeCard extends ConsumerWidget {
  const HomeCard({super.key, required this.state});

  final LifeState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final c = state.character;
    final rent = Economy.rentDue(c);
    final living = Economy.livingCostOf(c);
    return Card(
      key: const Key('home_card'),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              c.home == HomeKind.aile && !Economy.parentInCity(c)
                  ? l10n.home_aileEvi
                  : homeName(l10n, c.home),
              key: const Key('home_kind'),
              style: theme.textTheme.titleMedium,
            ),
            Text(
              l10n.homeCity(c.city, cityTypeName(l10n, Cities.typeOf(c.city))),
            ),
            if (rent > 0 || living > 0)
              Text(
                l10n.homeCosts(l10n.money(rent), l10n.money(living)),
                style: theme.textTheme.bodySmall,
              ),
            if (c.age >= Housing.minAge) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  key: const Key('move_button'),
                  onPressed: state.phase == YearPhase.actions
                      ? () => showModalBottomSheet<void>(
                          context: context,
                          showDragHandle: true,
                          isScrollControlled: true,
                          builder: (_) => const MoveSheet(),
                        )
                      : null,
                  icon: const Icon(Icons.local_shipping_outlined),
                  label: Text(l10n.moveButton),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

String homeName(AppLocalizations l10n, HomeKind home) => switch (home) {
  HomeKind.aile => l10n.home_aile,
  HomeKind.yurt => l10n.home_yurt,
  HomeKind.evArkadasi => l10n.home_evArkadasi,
  HomeKind.kira => l10n.home_kira,
  HomeKind.kendiEvi => l10n.home_kendiEvi,
  HomeKind.cocukYaninda => l10n.home_cocukYaninda,
};

String cityTypeName(AppLocalizations l10n, CityType type) => switch (type) {
  CityType.buyuk => l10n.cityType_buyuk,
  CityType.orta => l10n.cityType_orta,
  CityType.kucuk => l10n.cityType_kucuk,
};

String moveBlockedReason(AppLocalizations l10n, MoveBlocked blocked) =>
    switch (blocked) {
      MoveBlocked.vakit => l10n.moveBlocked_vakit,
      MoveBlocked.para => l10n.moveBlocked_para,
      MoveBlocked.yas => l10n.moveBlocked_yas,
      MoveBlocked.ogrenci => l10n.moveBlocked_ogrenci,
      MoveBlocked.evSahibi => l10n.moveBlocked_evSahibi,
      MoveBlocked.ayniSehir => l10n.moveBlocked_ayniSehir,
      MoveBlocked.gelir => l10n.moveBlocked_gelir,
    };

/// Şehir seçimi. Ailenin yaşadığı şehirde "ailemin yanına" da seçilebilir.
class MoveSheet extends ConsumerWidget {
  const MoveSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final controller = ref.read(lifeProvider.notifier);
    final c = ref.watch(lifeProvider)?.character;
    if (c == null) return const SizedBox.shrink();
    final options = controller.engine.moveOptions();
    final parentCities = {
      for (final p in c.people.bornBy(c.age))
        if (p.isAlive && (p.kin == Kinship.anne || p.kin == Kinship.baba))
          p.city,
    };

    Future<void> choose(String city) async {
      var withFamily = false;
      if (parentCities.contains(city)) {
        final answer = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text(l10n.moveWithFamilyTitle),
            actions: [
              TextButton(
                key: const Key('move_rent'),
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: Text(l10n.moveRent),
              ),
              FilledButton(
                key: const Key('move_with_family'),
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: Text(l10n.moveWithFamily),
              ),
            ],
          ),
        );
        if (answer == null) return;
        withFamily = answer;
      }
      controller.moveTo(city, withFamily: withFamily);
      if (context.mounted) Navigator.of(context).pop();
    }

    return SafeArea(
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        children: [
          Text(l10n.moveTitle, style: theme.textTheme.titleLarge),
          if (c.job != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                l10n.moveJobWarning,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ),
          for (final (city, blocked, cost) in options)
            if (blocked != MoveBlocked.ayniSehir)
              ListTile(
                key: Key('move_$city'),
                contentPadding: EdgeInsets.zero,
                enabled: blocked == null,
                title: Text(
                  l10n.homeCity(city, cityTypeName(l10n, Cities.typeOf(city))),
                ),
                subtitle: Text(
                  blocked == null
                      ? l10n.moveCost(l10n.money(cost))
                      : moveBlockedReason(l10n, blocked),
                ),
                trailing: parentCities.contains(city)
                    ? const Icon(Icons.family_restroom)
                    : null,
                onTap: blocked == null ? () => choose(city) : null,
              ),
        ],
      ),
    );
  }
}
