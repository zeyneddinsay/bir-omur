import 'package:flutter/material.dart';

import '../../content/person_text.dart';
import '../../engine/engine.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../models/models.dart';
import '../l10n_names.dart';
import '../share/life_share_card.dart' show compactMoney;
import 'stats_bar.dart';

/// Bir seçimin dokunduğu tek şey: bir gösterge, para, bir kişi, iş…
class PreviewItem {
  const PreviewItem({
    required this.icon,
    required this.positive,
    required this.tooltip,
    this.text,
    this.strong = false,
  });

  final IconData icon;

  /// Oyuncunun lehine mi (yeşil) aleyhine mi (kırmızı).
  final bool positive;

  /// İkonun yanındaki kısa yazı (tutar, kişinin adı); göstergelerde yok.
  final String? text;

  /// Büyük değişiklik: çift ok.
  final bool strong;
  final String tooltip;
}

/// Etkinin oyuncuya gösterilen özeti. Göstergelerde yalnızca yön ve
/// büyüklük (tek ya da çift ok) görünür; para tutarıyla görünür.
List<PreviewItem> previewItems(
  AppLocalizations l10n,
  Effect effect, {
  Character? character,
  Map<String, String> people = const {},
}) {
  final items = <PreviewItem>[];
  for (final kind in StatKind.values) {
    final delta = effect.stats[kind] ?? 0;
    if (delta == 0) continue;
    final name = l10n.statName(kind);
    items.add(
      PreviewItem(
        icon: StatsBar.icons[kind]!,
        positive: delta > 0,
        strong: delta.abs() >= 5,
        tooltip: delta > 0
            ? l10n.previewStatUp(name)
            : l10n.previewStatDown(name),
      ),
    );
  }
  if (effect.money != 0) {
    final amount = compactMoney(l10n, effect.money.abs());
    items.add(
      PreviewItem(
        icon: Icons.payments_outlined,
        positive: effect.money > 0,
        text: '${effect.money > 0 ? '+' : '−'}$amount',
        tooltip: '${effect.money > 0 ? '+' : '−'}$amount',
      ),
    );
  }
  for (final (delta, icon, tip) in [
    (effect.gold, Icons.toll_outlined, l10n.previewGold),
    (effect.house, Icons.home_outlined, l10n.previewHouse),
    (effect.car, Icons.directions_car_outlined, l10n.previewCar),
    (effect.performance, Icons.work_outline, l10n.previewWork),
    (effect.business, Icons.storefront_outlined, l10n.previewBusiness),
  ]) {
    if (delta == 0) continue;
    items.add(
      PreviewItem(
        icon: icon,
        positive: delta > 0,
        tooltip: delta > 0
            ? l10n.previewStatUp(tip)
            : l10n.previewStatDown(tip),
      ),
    );
  }
  for (final MapEntry(key: slot, value: change) in effect.people.entries) {
    final memory = change.memory;
    // Yalnızca kişinin hafızasına giren anı ilişkiyi değiştirir.
    final felt = memory != null && memory.owner != MemoryOwner.oyuncu;
    if (!felt && change.heal == null) continue;
    final person = switch (people[slot]) {
      final id? => character?.people[id],
      null => null,
    };
    if (person == null) continue;
    final positive = felt ? memory.tone == MemoryTone.olumlu : true;
    // Akraba adıyla değil akrabalığıyla anılır: "Babaannen", "Eşin".
    final kin = PersonText.kinWord(person);
    items.add(
      PreviewItem(
        icon: positive ? Icons.favorite_border : Icons.heart_broken_outlined,
        positive: positive,
        text: kin == null ? person.name : PersonText.capitalizeFirst(kin),
        strong: felt && memory.severity >= 3,
        tooltip: l10n.previewMemoryTooltip(
          kin == null
              ? person.name
              : '${PersonText.capitalizeFirst(kin)} ${person.name}',
        ),
      ),
    );
  }
  if (effect.schedule != null) {
    items.add(
      PreviewItem(
        icon: Icons.hourglass_bottom,
        positive: true,
        text: l10n.previewThread,
        tooltip: l10n.previewThreadTooltip,
      ),
    );
  }
  return items;
}

/// Önizleme çiplerinin satırı.
class PreviewChips extends StatelessWidget {
  const PreviewChips({super.key, required this.items, this.dense = false});

  final List<PreviewItem> items;
  final bool dense;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 4,
    runSpacing: 4,
    children: [for (final item in items) PreviewChip(item: item, dense: dense)],
  );
}

class PreviewChip extends StatelessWidget {
  const PreviewChip({super.key, required this.item, this.dense = false});

  final PreviewItem item;
  final bool dense;

  /// Lehte ve aleyhte renkler; iki temada da okunur.
  static Color tone(BuildContext context, bool positive) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return positive
        ? (dark ? const Color(0xFF7DCB8E) : const Color(0xFF2E7D4F))
        : (dark ? const Color(0xFFF08A7E) : const Color(0xFFB3261E));
  }

  @override
  Widget build(BuildContext context) {
    final color = tone(context, item.positive);
    final arrow = item.positive ? Icons.arrow_drop_up : Icons.arrow_drop_down;
    final size = dense ? 14.0 : 16.0;
    return Tooltip(
      message: item.tooltip,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: dense ? 5 : 6, vertical: 2),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(item.icon, size: size, color: color),
            if (item.text case final text?) ...[
              const SizedBox(width: 3),
              Text(
                text,
                style: Theme.of(context).textTheme.labelSmall
                    ?.copyWith(color: color, fontWeight: FontWeight.w800),
              ),
            ] else ...[
              Icon(arrow, size: size + 2, color: color),
              if (item.strong)
                Transform.translate(
                  offset: const Offset(-8, 0),
                  child: Icon(arrow, size: size + 2, color: color),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Zarlı seçenekte zarın baktığı değer ve (karakter biliniyorsa) kaba
/// ihtimal: "Şans zarı · İhtimal orta".
class RollLine extends StatelessWidget {
  const RollLine({super.key, required this.roll, this.character});

  final Roll roll;
  final Character? character;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final stat = l10n.rollStatName(roll.stat);
    final odds = character == null
        ? null
        : RollOdds.of(EffectResolver.rollChance(character!, roll));
    final oddsColor = switch (odds) {
      RollOdds.yuksek => PreviewChip.tone(context, true),
      RollOdds.dusuk => PreviewChip.tone(context, false),
      _ => theme.colorScheme.onSurface.withValues(alpha: 0.7),
    };
    return Tooltip(
      message: l10n.rollBadgeTooltip(stat),
      child: Row(
        key: const Key('roll_badge'),
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.casino_outlined,
            size: 15,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              l10n.rollBadge(stat),
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (odds != null) ...[
            const SizedBox(width: 6),
            Container(
              key: Key('roll_odds_${odds.name}'),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: oddsColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                l10n.rollOddsName(odds),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: oddsColor,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
