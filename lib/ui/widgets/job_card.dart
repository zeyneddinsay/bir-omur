import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../content/person_text.dart';
import '../../engine/engine.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../models/models.dart';
import '../l10n_names.dart';
import '../providers.dart';
import 'choice_preview.dart';
import 'life_status.dart';

String tempoName(AppLocalizations l10n, Tempo tempo) => switch (tempo) {
  Tempo.rahat => l10n.tempo_rahat,
  Tempo.normal => l10n.tempo_normal,
  Tempo.yukle => l10n.tempo_yukle,
};

String listingBlockedReason(AppLocalizations l10n, ListingBlocked b) =>
    switch (b) {
      ListingBlocked.sart => l10n.listingBlocked_sart,
      ListingBlocked.yas => l10n.listingBlocked_yas,
      ListingBlocked.ogrenci => l10n.listingBlocked_ogrenci,
      ListingBlocked.ayniSirket => l10n.listingBlocked_ayniSirket,
      ListingBlocked.basvuruldu => l10n.listingBlocked_basvuruldu,
      ListingBlocked.vakit => l10n.listingBlocked_vakit,
      ListingBlocked.deneyim => l10n.listingBlocked_deneyim,
      ListingBlocked.emekli => l10n.listingBlocked_emekli,
      ListingBlocked.askerde => l10n.listingBlocked_askerde,
    };

/// Okul / İş sekmesinde şu anki iş: unvan, şirket, maaş, performans,
/// tempo; terfi ve zam isteme, istifa, erken emeklilik.
class JobCard extends ConsumerWidget {
  const JobCard({super.key, required this.state});

  final LifeState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final controller = ref.read(lifeProvider.notifier);
    final engine = controller.engine;
    final c = state.character;
    final job = c.job;
    if (job == null) return const SizedBox.shrink();
    final career = engine.careers.byId(job.careerId);
    if (career == null) return const SizedBox.shrink();
    final title = careerLine(l10n, career, job.tier);
    final salary = Careers.salaryFor(c, job, career);
    final canPromote = engine.canRequest(promotion: true);
    final canRaise = engine.canRequest(promotion: false);
    // Askerdeki yıl iş askıda: yalnızca bilgi, düğme yok.
    if (Military.inService(c)) {
      return Card(
        key: const Key('job_card'),
        child: ListTile(
          leading: const Icon(Icons.military_tech_outlined),
          title: Text(title),
          subtitle: Text(l10n.jobMilitaryHint),
        ),
      );
    }
    final trend = Careers.expectedPerformanceChange(c, job.tempo);
    final lowKnowledge = c.stats.knowledge < 50;

    return Card(
      key: const Key('job_card'),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.jobCardTitle, style: theme.textTheme.titleMedium),
            Text(
              job.company == null
                  ? title
                  : l10n.jobTitleLine(title, job.company!),
              key: const Key('job_title'),
            ),
            Text(l10n.jobSalary(l10n.tl(salary))),
            if (_salaryParts(l10n, c, job) case final parts?)
              Text(
                parts,
                key: const Key('job_salary_parts'),
                style: theme.textTheme.bodySmall,
              ),
            const SizedBox(height: 8),
            Row(
              children: [
                SizedBox(width: 92, child: Text(l10n.jobPerformance)),
                Expanded(
                  child: LinearProgressIndicator(
                    key: const Key('job_performance'),
                    value: job.performance / 100,
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                SizedBox(
                  width: 36,
                  child: Text('${job.performance}', textAlign: TextAlign.end),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                trend < 0
                    ? l10n.jobTrendDown(-trend, lowKnowledge ? 'low' : 'ok')
                    : trend > 0
                    ? l10n.jobTrendUp(trend)
                    : l10n.jobTrendFlat,
                key: const Key('job_trend'),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: trend < 0 ? theme.colorScheme.error : null,
                ),
              ),
            ),
            if (job.performance < 30)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  l10n.jobFiredRisk,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              ),
            const SizedBox(height: 12),
            Text(l10n.jobTempo, style: theme.textTheme.titleSmall),
            const SizedBox(height: 4),
            SegmentedButton<Tempo>(
              key: const Key('job_tempo'),
              showSelectedIcon: false,
              segments: [
                for (final t in Tempo.values)
                  ButtonSegment(
                    value: t,
                    label: Text(tempoName(l10n, t)),
                    enabled: t == job.tempo || controller.engine.canSetTempo(t),
                  ),
              ],
              selected: {job.tempo},
              onSelectionChanged: state.phase == YearPhase.actions
                  ? (s) => controller.setTempo(s.single)
                  : null,
            ),
            Text(l10n.tempoHint, style: theme.textTheme.bodySmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                OutlinedButton(
                  key: const Key('job_promotion'),
                  onPressed: canPromote ? controller.requestPromotion : null,
                  child: Text(l10n.jobPromotion),
                ),
                OutlinedButton(
                  key: const Key('job_raise'),
                  onPressed: canRaise ? controller.requestRaise : null,
                  child: Text(l10n.jobRaise),
                ),
                TextButton(
                  key: const Key('job_quit'),
                  onPressed: state.phase == YearPhase.actions
                      ? () => _confirmQuit(context, controller)
                      : null,
                  child: Text(l10n.jobQuit),
                ),
                if (JobMarket.canRetireEarly(c))
                  TextButton(
                    key: const Key('job_retire'),
                    onPressed: controller.retireEarly,
                    child: Text(l10n.jobRetire),
                  ),
              ],
            ),
            if (engine.requestBlocked(promotion: true) case final r?
                when r != RequestBlocked.isYok)
              Text(
                l10n.jobPromotionBlocked(
                  r == RequestBlocked.sart
                      ? _shortfallText(l10n, c, engine.careers) ??
                            requestBlockedText(l10n, r, 0)
                      : requestBlockedText(
                          l10n,
                          r,
                          JobMarket.yearsToPromotion(c, engine.careers),
                          minPerformance:
                              career.tier(job.tier).promotion?.minPerformance ??
                              0,
                          performance: job.performance,
                        ),
                ),
                style: theme.textTheme.bodySmall,
              ),
            if (engine.requestBlocked(promotion: false) case final r?
                when r != RequestBlocked.isYok)
              Text(
                l10n.jobRaiseBlocked(
                  requestBlockedText(
                    l10n,
                    r,
                    0,
                    minPerformance: JobMarket.raiseMinPerformance,
                    performance: job.performance,
                  ),
                ),
                style: theme.textTheme.bodySmall,
              ),
          ],
        ),
      ),
    );
  }

  /// Maaşın zamları: "Kıdem 12 yıl: +%18 · Asgari ücret zamları: +%9".
  static String? _salaryParts(AppLocalizations l10n, Character c, Job job) {
    final seniority = ((Careers.seniorityFactor(job) - 1) * 100).round();
    final wage = ((c.wageIndex - 1) * 100).round();
    final parts = [
      if (job.yearsInJob > 0) l10n.jobSeniority(job.yearsInJob, seniority),
      if (wage > 0) l10n.jobWageIndex(wage),
    ];
    return parts.isEmpty ? null : parts.join(' · ');
  }

  /// Terfi şartında eksik göstergeler: "Bilgi en az 40 olmalı (şu an 29)".
  static String? _shortfallText(
    AppLocalizations l10n,
    Character c,
    CareerBook careers,
  ) {
    final missing = JobMarket.promotionShortfall(c, careers);
    if (missing.isEmpty) return null;
    return [
      for (final MapEntry(key: kind, value: min) in missing.entries)
        l10n.request_statMin(l10n.statName(kind), min, c.stats[kind]),
    ].join(', ');
  }

  static Future<void> _confirmQuit(
    BuildContext context,
    LifeController controller,
  ) async {
    final l10n = AppLocalizations.of(context);
    final yes = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        content: Text(l10n.jobQuitConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialog).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            key: const Key('job_quit_yes'),
            onPressed: () => Navigator.of(dialog).pop(true),
            child: Text(l10n.jobQuitYes),
          ),
        ],
      ),
    );
    if (yes ?? false) controller.quitJob();
  }
}

/// Bu yılın iş ilanları; başvurulabilenlere dokununca mülakat açılır.
class ListingsCard extends ConsumerWidget {
  const ListingsCard({super.key, required this.state});

  final LifeState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final engine = ref.read(lifeProvider.notifier).engine;
    final c = state.character;
    if (c.age < 18 || c.isRetired) return const SizedBox.shrink();
    final options = engine.listingOptions();
    return Card(
      key: const Key('listings_card'),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.listingsTitle, style: theme.textTheme.titleMedium),
            if (options.isEmpty) Text(l10n.listingsEmpty),
            for (final (i, (listing, blocked)) in options.indexed)
              _ListingTile(
                key: Key('listing_$i'),
                listing: listing,
                blocked: blocked,
                character: c,
                careers: engine.careers,
              ),
          ],
        ),
      ),
    );
  }
}

class _ListingTile extends ConsumerWidget {
  const _ListingTile({
    super.key,
    required this.listing,
    required this.blocked,
    required this.character,
    required this.careers,
  });

  final JobListing listing;
  final ListingBlocked? blocked;
  final Character character;
  final CareerBook careers;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final career = careers.byId(listing.careerId);
    if (career == null) return const SizedBox.shrink();
    final title = careerLine(l10n, career, listing.tier);
    final salary = Careers.salaryFor(
      character,
      Job(careerId: career.id, tier: listing.tier),
      career,
    );
    final reason = blocked;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      enabled: reason == null,
      isThreeLine: true,
      title: Text(l10n.jobTitleLine(title, listing.company)),
      subtitle: Text(
        [
          '“${listing.ad}”',
          [
            l10n.listingSalary(l10n.tl(salary)),
            if (listing.tier > 1) l10n.listingSenior,
          ].join(' · '),
          if (reason != null) listingBlockedReason(l10n, reason),
        ].join('\n'),
        style: theme.textTheme.bodySmall,
      ),
      onTap: reason == null
          ? () => showModalBottomSheet<void>(
              context: context,
              showDragHandle: true,
              isScrollControlled: true,
              builder: (_) => InterviewSheet(listing: listing),
            )
          : null,
    );
  }
}

/// Mülakat: sorunun iki cevabı ve (varsa) tanıdık aracılığı.
class InterviewSheet extends ConsumerWidget {
  const InterviewSheet({super.key, required this.listing});

  final JobListing listing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final controller = ref.read(lifeProvider.notifier);
    final engine = controller.engine;
    final career = engine.careers.byId(listing.careerId);
    if (career == null) return const SizedBox.shrink();
    final question = career.interviews.isEmpty
        ? null
        : career.interviews[listing.interview % career.interviews.length];
    final references = engine.listingReferences(listing);
    final c = ref.watch(lifeProvider)?.character;

    void answer(ChoiceSide side, {String? referenceId}) {
      controller.applyFor(listing, side, referenceId: referenceId);
      Navigator.of(context).pop();
    }

    return SafeArea(
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        children: [
          Text(
            l10n.interviewTitle(listing.company),
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          if (question != null) ...[
            Text(question.question, style: theme.textTheme.bodyLarge),
            const SizedBox(height: 8),
            for (final (side, a) in [
              (ChoiceSide.left, question.left),
              (ChoiceSide.right, question.right),
            ])
              ListTile(
                key: Key('interview_${side.name}'),
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.casino_outlined),
                title: Text(a.label),
                subtitle: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: RollLine(
                    roll: Roll(stat: a.stat, threshold: 0),
                    chance: c == null
                        ? null
                        : JobMarket.interviewChance(
                            c,
                            listing,
                            engine.careers,
                            a,
                          ),
                  ),
                ),
                onTap: () => answer(side),
              ),
          ] else
            FilledButton(
              key: const Key('interview_left'),
              onPressed: () => answer(ChoiceSide.left),
              child: Text(l10n.tercihButton),
            ),
          if (references.isNotEmpty) ...[
            const Divider(height: 24),
            Text(l10n.interviewReferenceHint, style: theme.textTheme.bodySmall),
            for (final p in references)
              ListTile(
                key: Key('interview_ref_${p.id}'),
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.handshake_outlined),
                title: Text(l10n.interviewReference(PersonText.labelOf(p))),
                onTap: () => answer(ChoiceSide.left, referenceId: p.id),
              ),
          ],
        ],
      ),
    );
  }
}

String requestBlockedText(
  AppLocalizations l10n,
  RequestBlocked reason,
  int years, {
  int minPerformance = 0,
  int performance = 0,
}) => switch (reason) {
  RequestBlocked.isYok => '',
  RequestBlocked.sonKademe => l10n.request_sonKademe,
  RequestBlocked.erken => l10n.request_erken(years),
  RequestBlocked.sart => l10n.request_sart,
  RequestBlocked.performans => l10n.request_performans(
    minPerformance,
    performance,
  ),
  RequestBlocked.para => l10n.request_para,
  RequestBlocked.tavan => l10n.request_tavan,
  RequestBlocked.buYil => l10n.request_buYil,
  RequestBlocked.vakit => l10n.request_vakit,
};
