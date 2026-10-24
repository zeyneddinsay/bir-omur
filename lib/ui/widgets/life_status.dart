import 'dart:math';

import 'package:flutter/material.dart';

import '../../engine/engine.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../models/models.dart';
import '../l10n_names.dart';
import 'business_card.dart';

/// "Memur · Şef"; kademe adı meslek adıyla aynıysa yalnızca biri
/// ("Memur · Memur" değil "Memur").
String careerLine(AppLocalizations l10n, Career career, int tier) {
  final tierName = career.tier(tier).name;
  if (tierName == career.name) return career.name;
  return l10n.jobTier(career.name, tierName);
}

/// Karakterin iş durumu: "Memur · Şef", "İşsiz", "Emekli"…
/// Meslek ve kademe adları içerikten (meslek dosyalarından) gelir.
String jobLabel(AppLocalizations l10n, Character c, CareerBook careers) {
  if (c.isRetired) return l10n.jobRetired;
  if (Military.inService(c)) return l10n.jobMilitary;
  if (c.job case final job?) {
    final career = careers.byId(job.careerId);
    if (career == null) return job.careerId;
    return careerLine(l10n, career, job.tier);
  }
  if (c.hasFlag(ActionCatalog.studentFlag)) return l10n.jobStudent;
  // İşi olmayan işletme sahibi: kendi işinin başında.
  if (c.businesses.isNotEmpty) return l10n.jobOwnBusiness;
  // Okul öncesinde iş satırı yok; okul çağında "Öğrenci".
  if (c.age < 7) return '';
  if (c.age < EngineFlags.hardshipMinAge) return l10n.jobChild;
  return l10n.jobNone;
}

/// Başlıktaki evre adı: liseyi bitirip üniversiteye ya da işe geçen 18
/// yaşındaki "Lise · Üniversite öğrencisi" değil "Genç yetişkin" görünür.
String stageLabel(AppLocalizations l10n, Character c, CareerBook careers) {
  final job = jobLabel(l10n, c, careers);
  if (c.stage == LifeStage.lise && job.isNotEmpty && job != l10n.jobChild) {
    return l10n.stageName(LifeStage.genc);
  }
  return l10n.stageName(c.stage);
}

/// Son iş: ölüm özeti için; hiç çalışmadıysa null.
String? lastJobLabel(AppLocalizations l10n, Character c, CareerBook careers) {
  final job = c.careerJob;
  if (job == null) return null;
  final career = careers.byId(job.careerId);
  if (career == null) return job.careerId;
  return careerLine(l10n, career, job.tier);
}

/// Üst çubuktaki cüzdan düğmesi; varlıklar panelini açar.
class AssetsButton extends StatelessWidget {
  const AssetsButton({super.key, required this.engine});

  final LifeEngine engine;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      key: const Key('assets_button'),
      tooltip: AppLocalizations.of(context).assetsButton,
      onPressed: () => showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        isScrollControlled: true,
        builder: (_) => AssetsSheet(engine: engine),
      ),
      icon: const Icon(Icons.account_balance_wallet_outlined),
    );
  }
}

/// Varlıklar paneli (üst çubuktaki cüzdandan açılır).
class AssetsSheet extends StatelessWidget {
  const AssetsSheet({super.key, required this.engine});

  final LifeEngine engine;

  @override
  Widget build(BuildContext context) => SafeArea(
    child: SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: AssetsSummary(engine: engine),
    ),
  );
}

/// Varlıklar: nakit, altın, ev, araba, kira, kredi, net servet. Hem panelde
/// hem Varlıklar sekmesinde kullanılır.
class AssetsSummary extends StatelessWidget {
  const AssetsSummary({super.key, required this.engine});

  final LifeEngine engine;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final c = engine.state.character;
    final a = c.assets;
    final market = engine.market;
    String tl(int v) => l10n.tl(v);

    final rows = <(String, String)>[
      (l10n.assetCash, tl(c.stats.money)),
      (
        l10n.assetGold,
        a.goldGrams == 0
            ? l10n.assetNone
            : l10n.assetGoldValue(
                a.goldGrams,
                tl(a.goldGrams * market.goldPrice),
              ),
      ),
      (
        l10n.assetHouse,
        a.houses == 0
            ? l10n.assetNone
            : l10n.assetHouseValue(a.houses, tl(a.houseValue)),
      ),
      (
        l10n.assetCar,
        a.cars == 0
            ? l10n.assetNone
            : l10n.assetCarValue(a.cars, tl(a.carValue)),
      ),
      // İşletmeler net servete satış ya da kapanış değeriyle girer.
      for (final b in c.businesses)
        (
          businessTypeName(l10n, b.type),
          tl(BusinessRules.exitValue(b, sell: BusinessRules.canSell(b))),
        ),
      if (c.home.paysRent) (l10n.assetRent, tl(a.rent)),
      if (a.hasLoan)
        (
          l10n.assetLoan,
          l10n.assetLoanValue(tl(a.loanPayment), a.loanYearsLeft),
        ),
      if (c.isRetired) (l10n.assetPension, tl(c.pension)),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.assetsTitle, style: theme.textTheme.titleLarge),
        Text(
          '${l10n.hometownLine(c.hometown, c.team)} · '
          '${l10n.backgroundName(c.background)}',
          key: const Key('sheet_background'),
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: 12),
        for (final (label, value) in rows)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                Expanded(child: Text(label)),
                Text(value, style: theme.textTheme.titleSmall),
              ],
            ),
          ),
        const Divider(height: 24),
        Row(
          children: [
            Expanded(
              child: Text(
                l10n.assetNetWorth,
                style: theme.textTheme.titleMedium,
              ),
            ),
            Text(
              tl(Economy.netWorth(c, market)),
              key: const Key('net_worth'),
              // Kırmızı yalnızca eksi servete: artıda hata gibi görünmesin.
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: Economy.netWorth(c, market) < 0
                    ? theme.colorScheme.error
                    : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          l10n.assetGoldPrice(tl(market.goldPrice)),
          style: theme.textTheme.bodySmall,
        ),
      ],
    );
  }
}

/// Yaşlandıktan sonra geçen yılın kısa dökümü. Kapatılabilir.
class LastYearBanner extends StatelessWidget {
  const LastYearBanner({
    super.key,
    required this.economy,
    required this.career,
    required this.onClose,
    this.scholarship = 0,
  });

  final EconomyReport economy;
  final CareerReport? career;

  /// Bu yılın bursu (KYK ya da başarı bursu); gelire eklenir.
  final int scholarship;
  final VoidCallback onClose;

  /// Maaşa (asgari ücret ve kıdem) ya da emekli aylığına gelen zam, bir
  /// ondalıkla ("2,4"); zam yoksa null.
  static String? _raisePercent(EconomyReport economy, CareerReport? career) {
    // Emekli olunan yıl aylık yeni bağlanır; zam değildir.
    if (career == null || career.income <= 0 || career.retired) return null;
    final paid =
        career.source == MoneySource.maas ||
        career.source == MoneySource.emekliAyligi;
    if (!paid) return null;
    final raise = (1 + economy.wageRaise) * (1 + career.seniorityRaise) - 1;
    final tenths = (raise * 1000).round();
    if (tenths <= 0) return null;
    return tenths % 10 == 0
        ? '${tenths ~/ 10}'
        : '${tenths ~/ 10},${tenths % 10}';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    String tl(int v) => l10n.tl(v);
    // Ayrıntılı döküm Varlıklar sekmesinde; burada yalnızca toplamlar.
    final spouse = economy.spouseIncome;
    final income = (career?.income ?? 0) + max<int>(0, spouse) + scholarship;
    final int expenses =
        economy.rentPaid +
        economy.loanPaid +
        economy.livingCost +
        economy.childCost +
        economy.carCost +
        economy.debtInterest +
        max(0, -spouse);
    final parts = [
      if (career case final c? when c.fired)
        c.severance > 0
            ? l10n.lastYearFiredSeverance(tl(c.severance))
            : l10n.lastYearFired,
      if (income > 0) l10n.lastYearIncome('+${tl(income)}'),
      if (_raisePercent(economy, career) case final p?)
        career?.source == MoneySource.emekliAyligi
            ? l10n.lastYearPensionRaise(p)
            : l10n.lastYearRaise(p),
      if (expenses > 0) l10n.lastYearExpenses('−${tl(expenses)}'),
      if (economy.cashEroded > 0)
        l10n.lastYearInflation(
          (economy.inflation * 100).round(),
          tl(economy.cashEroded),
        ),
      if (career?.promoted ?? false) l10n.lastYearPromoted,
      if (career?.retired ?? false) l10n.lastYearRetired,
    ];
    if (parts.isEmpty) return const SizedBox.shrink();

    return Container(
      key: const Key('last_year_banner'),
      margin: const EdgeInsets.fromLTRB(12, 4, 12, 0),
      padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.12),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              '${l10n.lastYearTitle}: ${parts.join(' · ')}',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall,
            ),
          ),
          IconButton(
            key: const Key('last_year_close'),
            tooltip: l10n.closeTooltip,
            visualDensity: VisualDensity.compact,
            onPressed: onClose,
            icon: const Icon(Icons.close, size: 18),
          ),
        ],
      ),
    );
  }
}
