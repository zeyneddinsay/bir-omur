import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../engine/engine.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../models/models.dart';
import '../providers.dart';

String businessTypeName(AppLocalizations l10n, String type) => switch (type) {
  'simit' => l10n.business_simit,
  'berber' => l10n.business_berber,
  'oto_yikama' => l10n.business_oto_yikama,
  'yazilim' => l10n.business_yazilim,
  'yazilim_ekip' => l10n.business_yazilim_ekip,
  _ => type,
};

String businessMoneyWhat(AppLocalizations l10n, String what) => switch (what) {
  'kar' => l10n.bizMoney_kar,
  'kredi' => l10n.bizMoney_kredi,
  'kurulus' => l10n.bizMoney_kurulus,
  'reklam' => l10n.bizMoney_reklam,
  'sube' => l10n.bizMoney_sube,
  'ortak' => l10n.bizMoney_ortak,
  'satis' => l10n.bizMoney_satis,
  'kapanis' => l10n.bizMoney_kapanis,
  'iflas' => l10n.bizMoney_iflas,
  _ => what,
};

String businessBlockedReason(AppLocalizations l10n, BusinessBlocked b) =>
    switch (b) {
      BusinessBlocked.yas => l10n.businessBlocked_yas,
      BusinessBlocked.sart => l10n.businessBlocked_sart,
      BusinessBlocked.para => l10n.businessBlocked_para,
      BusinessBlocked.zatenVar => l10n.businessBlocked_zatenVar,
      BusinessBlocked.cokFazla => l10n.businessBlocked_cokFazla,
      BusinessBlocked.iflas => l10n.businessBlocked_iflas,
      BusinessBlocked.vakit => l10n.businessBlocked_vakit,
      BusinessBlocked.askerde => l10n.businessBlocked_askerde,
    };

String priceName(AppLocalizations l10n, PriceLevel p) => switch (p) {
  PriceLevel.ucuz => l10n.price_ucuz,
  PriceLevel.normal => l10n.price_normal,
  PriceLevel.pahali => l10n.price_pahali,
};

/// Okul / İş sekmesinde kendi işin: işletmeler ve "İşletme aç".
class BusinessSection extends ConsumerWidget {
  const BusinessSection({super.key, required this.state});

  final LifeState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final c = state.character;
    if (c.age < 16) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final b in c.businesses) _BusinessCard(state: state, business: b),
        if (c.businesses.length < BusinessRules.maxBusinesses)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: OutlinedButton.icon(
              key: const Key('business_open'),
              onPressed: state.phase == YearPhase.actions
                  ? () => showModalBottomSheet<void>(
                      context: context,
                      showDragHandle: true,
                      isScrollControlled: true,
                      builder: (_) => const OpenBusinessSheet(),
                    )
                  : null,
              icon: const Icon(Icons.storefront_outlined),
              label: Text(l10n.businessOpenTitle),
            ),
          ),
      ],
    );
  }
}

class _BusinessCard extends ConsumerWidget {
  const _BusinessCard({required this.state, required this.business});

  final LifeState state;
  final Business business;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final controller = ref.read(lifeProvider.notifier);
    final engine = controller.engine;
    final c = state.character;
    final b = business;
    final type = BusinessTypes.require(b.type);
    final canAct = state.phase == YearPhase.actions;
    final partner = b.partnerId == null ? null : c.people[b.partnerId!];
    final candidates = engine.partnerCandidates(b.id);
    String tl(int v) => v < 0 ? '−${l10n.money(-v)}' : l10n.money(v);

    return Card(
      key: Key('business_${b.id}'),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.businessTitle, style: theme.textTheme.titleMedium),
            Text(
              l10n.businessSign(b.name, businessTypeName(l10n, b.type)),
              style: theme.textTheme.titleSmall,
            ),
            Text(
              l10n.businessFacts(
                b.branches,
                b.staff.length,
                BusinessRules.rivalCount(c, b),
              ),
              style: theme.textTheme.bodySmall,
            ),
            if (b.lastProfit case final p?)
              Text(l10n.businessLastProfit(tl(p))),
            Text(
              l10n.businessExpected(
                tl(
                  BusinessRules.expectedProfit(
                    c,
                    b,
                    inflation: engine.market.inflation,
                  ),
                ),
              ),
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                SizedBox(width: 92, child: Text(l10n.businessReputation)),
                Expanded(
                  child: LinearProgressIndicator(
                    value: b.reputation / 100,
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                SizedBox(
                  width: 36,
                  child: Text('${b.reputation}', textAlign: TextAlign.end),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SegmentedButton<bool>(
              key: Key('business_present_${b.id}'),
              showSelectedIcon: false,
              segments: [
                ButtonSegment(value: true, label: Text(l10n.businessPresent)),
                ButtonSegment(value: false, label: Text(l10n.businessManaged)),
              ],
              selected: {b.present},
              onSelectionChanged: canAct
                  ? (s) => controller.setBusinessPresent(b.id, s.single)
                  : null,
            ),
            Text(
              type.laborBound
                  ? l10n.businessLaborHint
                  : l10n.businessManagedHint(
                      l10n.money(BusinessRules.managerWage),
                    ),
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            SegmentedButton<PriceLevel>(
              key: Key('business_price_${b.id}'),
              showSelectedIcon: false,
              segments: [
                for (final p in PriceLevel.values)
                  ButtonSegment(value: p, label: Text(priceName(l10n, p))),
              ],
              selected: {b.price},
              onSelectionChanged: canAct
                  ? (s) => controller.setBusinessPrice(b.id, s.single)
                  : null,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                OutlinedButton(
                  key: Key('business_ad_${b.id}'),
                  onPressed: engine.canAdvertise(b.id)
                      ? () => controller.advertiseBusiness(b.id)
                      : null,
                  child: Text(
                    l10n.businessAdvertise(l10n.money(BusinessRules.adCost(b))),
                  ),
                ),
                OutlinedButton(
                  key: Key('business_expand_${b.id}'),
                  onPressed: engine.canExpand(b.id)
                      ? () => controller.expandBusiness(b.id)
                      : null,
                  child: Text(
                    type.upgradeTo != null
                        ? l10n.businessUpgrade(
                            l10n.money(BusinessRules.expandCost(b)),
                          )
                        : l10n.businessExpand(
                            l10n.money(BusinessRules.expandCost(b)),
                          ),
                  ),
                ),
              ],
            ),
            if (partner != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(l10n.businessPartnerNow(partner.name)),
              )
            else if (candidates.isNotEmpty && canAct) ...[
              const SizedBox(height: 4),
              Text(l10n.businessPartner, style: theme.textTheme.titleSmall),
              for (final p in candidates.take(3))
                ListTile(
                  key: Key('business_partner_${p.id}'),
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  leading: const Icon(Icons.handshake_outlined),
                  title: Text(
                    l10n.businessPartnerOffer(
                      p.name,
                      l10n.money(BusinessRules.partnerCapital(b)),
                    ),
                  ),
                  onTap: () => controller.takePartner(b.id, p.id),
                ),
            ],
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              children: [
                TextButton(
                  key: Key('business_sell_${b.id}'),
                  onPressed: canAct
                      ? () => _confirm(
                          context,
                          () => controller.disposeBusiness(b.id, sell: true),
                        )
                      : null,
                  child: Text(
                    l10n.businessSell(tl(BusinessRules.saleValue(b))),
                  ),
                ),
                TextButton(
                  key: Key('business_close_${b.id}'),
                  onPressed: canAct
                      ? () => _confirm(
                          context,
                          () => controller.disposeBusiness(b.id, sell: false),
                        )
                      : null,
                  child: Text(
                    l10n.businessClose(tl(BusinessRules.closingValue(b))),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static Future<void> _confirm(
    BuildContext context,
    VoidCallback action,
  ) async {
    final l10n = AppLocalizations.of(context);
    final yes = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        content: Text(l10n.businessDisposeConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialog).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            key: const Key('business_dispose_yes'),
            onPressed: () => Navigator.of(dialog).pop(true),
            child: Text(l10n.businessDisposeYes),
          ),
        ],
      ),
    );
    if (yes ?? false) action();
  }
}

/// Açılabilecek işletmeler: kuruluş bedeli, beklenen kâr, kapalıysa sebebi.
class OpenBusinessSheet extends ConsumerWidget {
  const OpenBusinessSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final controller = ref.read(lifeProvider.notifier);
    final c = ref.watch(lifeProvider)?.character;
    if (c == null) return const SizedBox.shrink();
    final options = controller.engine.businessOptions();
    return SafeArea(
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        children: [
          Text(l10n.businessOpenTitle, style: theme.textTheme.titleLarge),
          Text(l10n.businessOpenHint, style: theme.textTheme.bodySmall),
          for (final (type, blocked) in options)
            ListTile(
              key: Key('open_${type.id}'),
              contentPadding: EdgeInsets.zero,
              enabled: blocked == null,
              title: Text(businessTypeName(l10n, type.id)),
              subtitle: Text(
                blocked == null
                    ? l10n.businessSetup(
                        l10n.money(type.setupCost),
                        l10n.money(type.revenue - type.fixedCost - type.wages),
                      )
                    : businessBlockedReason(l10n, blocked),
              ),
              onTap: blocked == null
                  ? () {
                      controller.openBusiness(type.id);
                      Navigator.of(context).pop();
                    }
                  : null,
            ),
        ],
      ),
    );
  }
}
