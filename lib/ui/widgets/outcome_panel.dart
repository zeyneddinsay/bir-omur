import 'package:flutter/material.dart';

import '../../content/event_text.dart';
import '../../engine/engine.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../models/models.dart';
import '../l10n_names.dart';
import '../share/life_share_card.dart' show compactMoney;
import 'choice_preview.dart';
import 'stats_bar.dart';

/// Son seçimin sonucu: ne olduğunu anlatan cümle ve göstergelerde gerçekten
/// ne değiştiği. Zarlı seçimde zarın tutup tutmadığı rengiyle belli olur.
class OutcomePanel extends StatelessWidget {
  const OutcomePanel({
    super.key,
    required this.outcome,
    required this.character,
    required this.onClose,
  });

  final ChoiceOutcome outcome;

  /// Şimdiki karakter; kişilerin adları buradan okunur.
  final Character character;
  final VoidCallback onClose;

  /// Seçimden önce ve sonra arasındaki fark: göstergeler ve para.
  static List<PreviewItem> changes(
    AppLocalizations l10n,
    Character before,
    Character after,
  ) => [
    for (final kind in StatKind.values)
      if (after.stats[kind] - before.stats[kind] case final d when d != 0)
        PreviewItem(
          icon: StatsBar.icons[kind]!,
          positive: d > 0,
          text: '${d > 0 ? '+' : '−'}${d.abs()}',
          tooltip: l10n.statName(kind),
        ),
    if (after.stats.money - before.stats.money case final d when d != 0)
      PreviewItem(
        icon: Icons.payments_outlined,
        positive: d > 0,
        text: '${d > 0 ? '+' : '−'}${compactMoney(l10n, d.abs())}',
        tooltip: '${d > 0 ? '+' : '−'}${compactMoney(l10n, d.abs())}',
      ),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final rolled = outcome.rollSucceeded;
    final choice = outcome.choice;
    final template = choice.resultFor(rolled);
    final people = outcome.event?.people ?? const <String, String>{};
    final sentence = template == null
        ? EventText.render(choice.label, people, character)
        : EventText.render(template, people, character);
    final changed = switch (outcome.before) {
      final before? => changes(l10n, before, outcome.character),
      null => const <PreviewItem>[],
    };
    final accent = switch (rolled) {
      true => PreviewChip.tone(context, true),
      false => PreviewChip.tone(context, false),
      null => scheme.onSurface.withValues(alpha: 0.55),
    };
    // Zarsız seçimde panel nötr: kart renginde, ince çerçeveli.
    final plain = rolled == null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: Container(
        key: const Key('outcome_panel'),
        decoration: BoxDecoration(
          color: plain ? theme.cardTheme.color : accent.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: plain
                ? scheme.onSurface.withValues(alpha: 0.12)
                : accent.withValues(alpha: 0.28),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 1),
              child: Icon(
                switch (rolled) {
                  true => Icons.casino,
                  false => Icons.casino_outlined,
                  null => Icons.auto_stories_outlined,
                },
                size: 20,
                color: accent,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (choice.roll case final roll?)
                    Text(
                      l10n.rollResultLine(
                        l10n.rollStatName(roll.stat),
                        rolled == true ? l10n.rollSuccess : l10n.rollFail,
                      ),
                      key: const Key('roll_result'),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: accent,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  Text(
                    sentence,
                    key: const Key('outcome_text'),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      height: 1.35,
                    ),
                  ),
                  if (changed.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    PreviewChips(items: changed, dense: true),
                  ],
                ],
              ),
            ),
            IconButton(
              key: const Key('outcome_close'),
              tooltip: l10n.outcomeClose,
              visualDensity: VisualDensity.compact,
              iconSize: 18,
              onPressed: onClose,
              icon: const Icon(Icons.close),
            ),
          ],
        ),
      ),
    );
  }
}
