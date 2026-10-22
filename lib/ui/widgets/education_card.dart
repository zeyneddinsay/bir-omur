import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../engine/engine.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../models/models.dart';
import '../providers.dart';
import 'home_card.dart';

String departmentName(AppLocalizations l10n, String? id) => switch (id) {
  'bilgisayar' => l10n.dept_bilgisayar,
  'iktisat' => l10n.dept_iktisat,
  'hemsirelik' => l10n.dept_hemsirelik,
  'isletme' => l10n.dept_isletme,
  'kamu_yonetimi' => l10n.dept_kamu_yonetimi,
  'tarih' => l10n.dept_tarih,
  'acikogretim' => l10n.dept_acikogretim,
  _ => id ?? '',
};

String schoolName(AppLocalizations l10n, HighSchool school) => switch (school) {
  HighSchool.duz => l10n.school_duz,
  HighSchool.anadolu => l10n.school_anadolu,
  HighSchool.fen => l10n.school_fen,
  HighSchool.meslek => l10n.school_meslek,
};

/// Yıl günlüğünde oyuncunun kendi notu.
String noteLine(AppLocalizations l10n, LifeNote note) {
  final d = note.detail ?? '';
  return switch (note.kind) {
    NoteKind.lise => l10n.note_lise(
      schoolName(l10n, HighSchool.fromId(d) ?? HighSchool.duz),
    ),
    NoteKind.yksPuani => l10n.note_yksPuani(d),
    NoteKind.yerlesti => () {
      final colon = d.indexOf(':');
      return l10n.note_yerlesti(
        departmentName(l10n, colon < 0 ? d : d.substring(0, colon)),
        colon < 0 ? '' : d.substring(colon + 1),
      );
    }(),
    NoteKind.mezunaKaldi => l10n.note_mezunaKaldi,
    NoteKind.cirakOldu => l10n.note_cirakOldu,
    NoteKind.calismayiSecti => l10n.note_calismayiSecti,
    NoteKind.dersKaldi => l10n.note_dersKaldi,
    NoteKind.mezunOldu => l10n.note_mezunOldu(departmentName(l10n, d)),
    NoteKind.eveDondu => l10n.note_eveDondu(d),
    NoteKind.askerlik => l10n.note_askerlik,
  };
}

/// Okul / İş sekmesinde eğitim: lise, YKS, üniversite ve tercih.
class EducationCard extends ConsumerWidget {
  const EducationCard({super.key, required this.state});

  final LifeState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final c = state.character;
    final e = c.education;
    final pending = c.hasFlag(EducationRules.pendingFlag);
    final lines = <String>[
      if (e.highSchool case final school?) schoolName(l10n, school),
      if (e.yksScore case final score?) l10n.eduYks(score),
      if (e.isStudent && e.openEducation) l10n.eduOpen,
      if (e.isStudent && !e.openEducation)
        l10n.eduUni(
          departmentName(l10n, e.department),
          e.uniCity ?? c.city,
          c.age - e.uniStartAge! + 1,
        ),
      if (e.isGraduate) l10n.eduGraduate(departmentName(l10n, e.department)),
      if (e.isStudent && e.scholarship > 0)
        l10n.eduScholarship(l10n.money(e.scholarship)),
      if (e.apprentice) l10n.eduApprentice,
    ];
    if (lines.isEmpty && !pending) return const SizedBox.shrink();
    return Card(
      key: const Key('education_card'),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.eduTitle, style: theme.textTheme.titleMedium),
            for (final line in lines) Text(line),
            if (pending) ...[
              const SizedBox(height: 8),
              Text(l10n.tercihPending, style: theme.textTheme.bodySmall),
              const SizedBox(height: 8),
              FilledButton.icon(
                key: const Key('tercih_button'),
                onPressed: () => showModalBottomSheet<void>(
                  context: context,
                  showDragHandle: true,
                  isScrollControlled: true,
                  builder: (_) => const TercihSheet(),
                ),
                icon: const Icon(Icons.school_outlined),
                label: Text(l10n.tercihButton),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// YKS tercihi: puanın yettiği bölümler, sonra şehir; ya da başka bir yol.
class TercihSheet extends ConsumerStatefulWidget {
  const TercihSheet({super.key});

  @override
  ConsumerState<TercihSheet> createState() => _TercihSheetState();
}

class _TercihSheetState extends ConsumerState<TercihSheet> {
  String? _department;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final controller = ref.read(lifeProvider.notifier);
    final c = ref.watch(lifeProvider)?.character;
    if (c == null) return const SizedBox.shrink();
    final placements = controller.engine.tercihPlacements();
    final byDepartment = <String, List<(Department, String)>>{};
    for (final p in placements) {
      byDepartment.putIfAbsent(p.$1.id, () => []).add(p);
    }

    void done(void Function() action) {
      action();
      Navigator.of(context).pop();
    }

    final selected = _department;
    final children = <Widget>[
      Text(
        l10n.tercihTitle(c.education.yksScore ?? 0),
        style: theme.textTheme.titleLarge,
      ),
      const SizedBox(height: 4),
      Text(
        placements.isEmpty ? l10n.tercihNone : l10n.tercihPrompt,
        style: theme.textTheme.bodySmall,
      ),
      if (selected == null)
        for (final MapEntry(key: id, value: options) in byDepartment.entries)
          ListTile(
            key: Key('tercih_$id'),
            contentPadding: EdgeInsets.zero,
            title: Text(departmentName(l10n, id)),
            subtitle: Text(
              options.first.$1.open
                  ? l10n.eduOpen
                  : l10n.tercihCities(options.length),
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => options.first.$1.open
                ? done(() => controller.enroll(id, c.city))
                : setState(() => _department = id),
          )
      else
        for (final (d, city)
            in byDepartment[selected] ?? const <(Department, String)>[])
          ListTile(
            key: Key('tercih_city_$city'),
            contentPadding: EdgeInsets.zero,
            title: Text(
              l10n.tercihCity(
                city,
                cityTypeName(l10n, Cities.typeOf(city)),
                d.scoreIn(city),
              ),
            ),
            subtitle: Text(city == c.city ? l10n.tercihHome : l10n.tercihDorm),
            onTap: () => done(() => controller.enroll(d.id, city)),
          ),
      const Divider(height: 24),
      Text(l10n.tercihOthers, style: theme.textTheme.titleSmall),
      for (final (kind, label) in [
        (TercihKind.mezunaKal, l10n.tercih_mezunaKal),
        (TercihKind.calis, l10n.tercih_calis),
        (TercihKind.cirak, l10n.tercih_cirak),
      ])
        ListTile(
          key: Key('tercih_${kind.name}'),
          contentPadding: EdgeInsets.zero,
          title: Text(label),
          onTap: () => done(() => controller.declineTercih(kind)),
        ),
    ];

    return SafeArea(
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        children: children,
      ),
    );
  }
}
