import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../content/event_text.dart';
import '../../content/person_text.dart';
import '../../content/turkish.dart';
import '../../engine/engine.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../models/models.dart';
import '../people/people_text.dart';
import '../providers.dart';
import 'home_card.dart';
import 'business_card.dart';
import 'life_status.dart';

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
String noteLine(
  AppLocalizations l10n,
  LifeNote note,
  CareerBook careers, {
  EventDeck? deck,
  Character? character,
}) {
  final d = note.detail ?? '';
  final parts = d.split('|');
  String title(String careerId, String tier) {
    final career = careers.byId(careerId);
    final t = int.tryParse(tier) ?? 1;
    if (career == null || t < 1 || t > career.maxTier) return careerId;
    return careerLine(l10n, career, t);
  }

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
    NoteKind.isBuldun when parts.length == 3 => l10n.note_isBuldun(
      parts[0],
      title(parts[1], parts[2]),
    ),
    NoteKind.isBuldun => d,
    NoteKind.mulakatOlmadi => l10n.note_mulakatOlmadi(d),
    NoteKind.terfi when parts.length == 2 => l10n.note_terfi(
      title(parts[0], parts[1]),
    ),
    NoteKind.terfi => d,
    NoteKind.terfiReddi => l10n.note_terfiReddi,
    NoteKind.terfiZamaniDegil => l10n.note_terfiZamaniDegil,
    NoteKind.zam => l10n.note_zam,
    NoteKind.zamReddi => l10n.note_zamReddi,
    NoteKind.zamZamaniDegil => l10n.note_zamZamaniDegil,
    NoteKind.tekEbeveyn => switch (d) {
      'anne|vefat' => l10n.note_tekEbeveyn_anneVefat,
      'baba|vefat' => l10n.note_tekEbeveyn_babaVefat,
      'anne|ayrilik' => l10n.note_tekEbeveyn_anneAyrilik,
      _ => l10n.note_tekEbeveyn_babaAyrilik,
    },
    NoteKind.cocugunYaninda => l10n.note_cocugunYaninda(
      _hostWord(character, d),
    ),
    NoteKind.yeniEvSahibi => l10n.note_yeniEvSahibi(
      character?.people[d]?.name ?? '',
    ),
    NoteKind.kovuldun => l10n.note_kovuldun,
    NoteKind.istifa => l10n.note_istifa,
    NoteKind.emekliOldun => l10n.note_emekliOldun,
    NoteKind.kpssGecti => l10n.note_kpssGecti,
    NoteKind.kpssKaldi => l10n.note_kpssKaldi,
    NoteKind.yazilimKursu => l10n.note_yazilimKursu,
    NoteKind.isletmeAcildi => l10n.note_isletmeAcildi(
      businessTypeName(l10n, d),
    ),
    NoteKind.isletmeYili when parts.length == 2 => () {
      final amount = int.tryParse(parts[1]) ?? 0;
      final name = businessTypeName(l10n, parts[0]);
      return amount >= 0
          ? l10n.note_isletmeKar(name, l10n.money(amount))
          : l10n.note_isletmeZarar(name, l10n.money(-amount));
    }(),
    NoteKind.isletmeYili => d,
    NoteKind.isletmeBatti => l10n.note_isletmeBatti(businessTypeName(l10n, d)),
    NoteKind.isletmeSatildi => l10n.note_isletmeSatildi(
      businessTypeName(l10n, d),
    ),
    NoteKind.isletmeKapandi => l10n.note_isletmeKapandi(
      businessTypeName(l10n, d),
    ),
    NoteKind.subeAcildi => l10n.note_subeAcildi(businessTypeName(l10n, d)),
    NoteKind.isletmeBuyudu => l10n.note_isletmeBuyudu(
      businessTypeName(l10n, d),
    ),
    NoteKind.ortakAlindi when parts.length == 2 => l10n.note_ortakAlindi(
      parts[1],
      businessTypeName(l10n, parts[0]),
    ),
    NoteKind.ortakAlindi => d,
    NoteKind.iseAldin when parts.length == 2 => l10n.note_iseAldin(
      parts[1],
      businessTypeName(l10n, parts[0]),
    ),
    NoteKind.iseAldin => d,
    NoteKind.iplikKapandi => _closingLine(l10n, parts, deck, character),
    NoteKind.dunyaKucuk => _worldSmallLine(l10n, parts, character),
    NoteKind.evlendin => l10n.note_evlendin(character?.people[d]?.name ?? ''),
    NoteKind.bebek => l10n.note_bebek(character?.people[d]?.name ?? ''),
    NoteKind.zorGun => switch (parts.first) {
      'borc' => l10n.note_zorGun_borc,
      'kovuldun' => l10n.note_zorGun_kovuldun,
      'iflas' => l10n.note_zorGun_iflas,
      'vefat' => l10n.note_zorGun_vefat(
        _personWord(character, parts.length > 1 ? parts[1] : ''),
      ),
      _ => l10n.note_zorGun_bunalim,
    },
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
        placements.every((p) => p.$1.open)
            ? l10n.tercihNone
            : l10n.tercihPrompt,
        style: theme.textTheme.bodySmall,
      ),
      if (EducationRules.nextGoal(c) case (final d, final need))
        Text(
          l10n.tercihNext(departmentName(l10n, d.id), need),
          key: const Key('tercih_next'),
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
            subtitle: Text(
              city != c.city
                  ? l10n.tercihDorm
                  : c.home == HomeKind.aile
                  ? l10n.tercihHome
                  : l10n.tercihHomeOwn,
            ),
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

/// Kişisi giden ipliğin kapanış cümlesi: kartta yazılıysa o, yoksa vefat ya
/// da ayrılık cümlesi.
String _closingLine(
  AppLocalizations l10n,
  List<String> parts,
  EventDeck? deck,
  Character? c,
) {
  final people = {
    for (final p in parts.skip(1))
      if (p.indexOf('=') case final i when i > 0)
        p.substring(0, i): p.substring(i + 1),
  };
  if (c == null || people.isEmpty) return '';
  final closing = deck?.byId(parts.first)?.closing;
  if (closing != null) return EventText.render(closing, people, c);
  final person = c.people[people.values.first];
  if (person == null) return '';
  return person.isAlive
      ? l10n.note_iplikAyrildi(PersonText.labelOf(person))
      : l10n.note_iplikVefat(PersonText.labelOf(person));
}

/// "Dünya küçük: Kerem artık patronun. Onu okuldan tanıyorsun."
String _worldSmallLine(
  AppLocalizations l10n,
  List<String> parts,
  Character? c,
) {
  if (c == null || parts.length != 2) return '';
  final p = c.people[parts[0]];
  final kind = RoleKind.values.asNameMap()[parts[1]];
  if (p == null || kind == null) return '';
  // Müdür oyuncunun işletmesinin müdürüdür; "müdürün" amir gibi okunur.
  final role = kind == RoleKind.mudur
      ? l10n.worldSmall_mudur
      : l10n.roleName(kind);
  final lower = role.isEmpty ? role : role[0].toLowerCase() + role.substring(1);
  return l10n.note_dunyaKucuk(p.name, lower, l10n.originSince(p.origin));
}

/// Akrabaysa akrabalık sözcüğü ("Annen"), değilse adı.
String _personWord(Character? c, String id) {
  final p = c?.people[id];
  if (p == null) return '';
  final kin = PersonText.kinWord(p);
  return kin == null ? p.name : PersonText.capitalizeFirst(kin);
}

/// Cümle içinde akrabanın anılışı: "kızın Selin".
String _hostWord(Character? c, String id) {
  final p = c?.people[id];
  if (p == null) return '';
  final label = PersonText.labelOf(p);
  return lowerTr(label[0]) + label.substring(1);
}
