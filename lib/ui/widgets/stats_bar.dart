import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../models/models.dart';
import '../l10n_names.dart';

/// Beş gösterge ve para. [highlight] içindeki göstergelerin altında bir
/// nokta yanar: kart bir yöne eğildiğinde hangi göstergenin etkileneceğini
/// ima eder, miktarı söylemez.
class StatsBar extends StatelessWidget {
  const StatsBar({
    super.key,
    required this.stats,
    this.highlight = const {},
    this.highlightMoney = false,
  });

  final Stats stats;
  final Set<StatKind> highlight;
  final bool highlightMoney;

  static const Map<StatKind, IconData> icons = {
    StatKind.health: Icons.favorite,
    StatKind.happiness: Icons.sentiment_satisfied_alt,
    StatKind.knowledge: Icons.menu_book,
    StatKind.reputation: Icons.groups,
    StatKind.family: Icons.family_restroom,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Column(
        children: [
          Row(
            children: [
              for (final kind in StatKind.values)
                Expanded(
                  child: _Gauge(
                    icon: icons[kind]!,
                    label: l10n.statName(kind),
                    value: stats[kind],
                    highlighted: highlight.contains(kind),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.payments_outlined, size: 18, color: scheme.primary),
              const SizedBox(width: 6),
              Text(
                l10n.money(stats.money),
                key: const Key('money'),
                style: Theme.of(context).textTheme.titleSmall
                    ?.copyWith(color: stats.money < 0 ? scheme.error : null),
              ),
              _Dot(visible: highlightMoney),
            ],
          ),
        ],
      ),
    );
  }
}

class _Gauge extends StatelessWidget {
  const _Gauge({
    required this.icon,
    required this.label,
    required this.value,
    required this.highlighted,
  });

  final IconData icon;
  final String label;
  final int value;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = value <= 15 ? scheme.error : scheme.primary;
    return Semantics(
      label: '$label $value',
      child: Column(
        children: [
          SizedBox(
            width: 40,
            height: 40,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: value / Stats.max,
                  strokeWidth: 4,
                  color: color,
                  backgroundColor: scheme.surfaceContainerHighest,
                ),
                Icon(icon, size: 18, color: color),
              ],
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          _Dot(visible: highlighted),
        ],
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.visible});

  final bool visible;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: visible ? 1 : 0,
      duration: const Duration(milliseconds: 150),
      child: Container(
        margin: const EdgeInsets.all(3),
        width: 6,
        height: 6,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.tertiary,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
