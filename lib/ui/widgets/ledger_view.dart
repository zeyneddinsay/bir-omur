import 'package:flutter/material.dart';

import '../../content/event_text.dart';
import '../../engine/engine.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../models/models.dart';
import '../l10n_names.dart';
import '../people/people_text.dart';
import 'business_card.dart';

/// Varlıklar sekmesinde bu yılın ve geçen yılın para hareketleri: paranın
/// nereden gelip nereye gittiği.
class LedgerView extends StatelessWidget {
  const LedgerView({super.key, required this.character, required this.deck});

  final Character character;
  final EventDeck deck;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final c = character;
    Widget section(String title, int age) {
      final entries = [
        for (final e in c.ledger)
          if (e.age == age) e,
      ];
      final total = entries.fold(0, (sum, e) => sum + e.amount);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 4),
            child: Text(title, style: theme.textTheme.titleSmall),
          ),
          if (entries.isEmpty)
            Text(l10n.ledgerEmpty, style: theme.textTheme.bodySmall)
          else ...[
            for (final e in entries)
              _Row(label: describeMoney(l10n, e, c, deck), amount: e.amount),
            const Divider(height: 12),
            _Row(label: l10n.ledgerTotal, amount: total, bold: true),
          ],
        ],
      );
    }

    return Card(
      key: const Key('ledger'),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.ledgerTitle, style: theme.textTheme.titleMedium),
            if (c.ledger.any((e) => e.source == MoneySource.enflasyon))
              Text(l10n.ledgerInflationHint, style: theme.textTheme.bodySmall),
            section(l10n.ledgerThisYear(c.age), c.age),
            if (c.age > 0) section(l10n.ledgerLastYear(c.age - 1), c.age - 1),
          ],
        ),
      ),
    );
  }
}

/// Bir para hareketinin oyuncuya okunan adı.
String describeMoney(
  AppLocalizations l10n,
  MoneyEntry e,
  Character c,
  EventDeck deck,
) => switch (e.source) {
  MoneySource.maas => l10n.money_maas,
  MoneySource.emekliAyligi => l10n.money_emekliAyligi,
  MoneySource.yasliAyligi => l10n.money_yasliAyligi,
  MoneySource.harclik => l10n.money_harclik,
  MoneySource.araIs => l10n.money_araIs,
  MoneySource.burs => l10n.money_burs,
  MoneySource.yarimZamanli => l10n.money_yarimZamanli,
  MoneySource.aileDestegi => l10n.money_aileDestegi,
  MoneySource.kira => l10n.money_kira,
  MoneySource.yasamGideri => l10n.money_yasamGideri,
  MoneySource.kredi => l10n.money_kredi,
  MoneySource.araba => l10n.money_araba,
  MoneySource.enflasyon => l10n.money_enflasyon,
  MoneySource.terfi => l10n.money_terfi,
  MoneySource.olay => l10n.money_olay(_choiceLabel(e.ref, c, deck)),
  MoneySource.aksiyon => l10n.actionName(e.ref ?? '') ?? e.ref ?? '',
  MoneySource.etkilesim => switch (InteractionKind.values.asNameMap()[e.ref]) {
    final kind? => l10n.interactionName(kind),
    null => e.ref ?? '',
  },
  MoneySource.is_ => l10n.money_is(e.ref ?? ''),
  MoneySource.tasinma => l10n.money_tasinma(e.ref ?? ''),
  MoneySource.isletme => () {
    final ref = e.ref ?? ':';
    final colon = ref.indexOf(':');
    return l10n.money_isletme(
      businessTypeName(l10n, ref.substring(0, colon)),
      businessMoneyWhat(l10n, ref.substring(colon + 1)),
    );
  }(),
  MoneySource.varlik => l10n.money_varlik(e.ref ?? ''),
};

/// `kart:taraf` → seçilen seçeneğin yazısı.
String _choiceLabel(String? ref, Character c, EventDeck deck) {
  if (ref == null) return '';
  final colon = ref.lastIndexOf(':');
  final card = deck.byId(ref.substring(0, colon));
  final side = ChoiceSide.values.asNameMap()[ref.substring(colon + 1)];
  if (card == null || side == null) return ref;
  if (side == ChoiceSide.up && card.up == null) return ref;
  return EventText.render(card.choice(side).label, const {}, c);
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.amount, this.bold = false});

  final String label;
  final int amount;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final style =
        (bold ? theme.textTheme.titleSmall : theme.textTheme.bodyMedium)
            ?.copyWith(
              color: amount < 0
                  ? theme.colorScheme.error
                  : Colors.green.shade700,
            );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Text(label)),
          const SizedBox(width: 8),
          Text(
            amount < 0 ? '−${l10n.money(-amount)}' : l10n.moneyGain(amount),
            style: style,
          ),
        ],
      ),
    );
  }
}
