import '../../engine/engine.dart';
import '../../models/models.dart';

/// İnsanlar sekmesindeki bölümler, gösterim sırasıyla.
enum PeopleGroup { aile, okul, arkadaslar, isEv, mahalle, eski, vefat }

/// Kişiyi İnsanlar sekmesinde nereye koyacağımız. Saf hesap; arayüz yalnızca
/// metne çevirir.
abstract final class PeopleView {
  static const Set<RoleKind> schoolRoles = {
    RoleKind.siraArkadasi,
    RoleKind.sinifArkadasi,
    RoleKind.ogretmen,
  };

  static const Set<RoleKind> neighbourhoodRoles = {
    RoleKind.komsu,
    RoleKind.bakkal,
    RoleKind.muhtar,
  };

  /// İş ve ev hayatındaki roller: patron, iş arkadaşı, ev sahibi…
  static const Set<RoleKind> workHomeRoles = {
    RoleKind.patron,
    RoleKind.amir,
    RoleKind.usta,
    RoleKind.mudur,
    RoleKind.isArkadasi,
    RoleKind.calisan,
    RoleKind.musteri,
    RoleKind.ortak,
    RoleKind.rakip,
    RoleKind.evSahibi,
    RoleKind.kiraci,
    RoleKind.evArkadasi,
    RoleKind.odaArkadasi,
  };

  /// Askerden dönüşten sonra bu kadar yıl bölük arkadaşları "Arkadaşlar"da.
  static const int recentComradeYears = 3;

  static const Set<Bond> friendBonds = {
    Bond.arkadas,
    Bond.yakinArkadas,
    Bond.flort,
    Bond.sevgili,
    Bond.nisanli,
  };

  static PeopleGroup groupOf(Person p, {int? now}) {
    if (!p.isAlive) return PeopleGroup.vefat;
    if (p.kin != null) return PeopleGroup.aile;
    if (p.archived) return PeopleGroup.eski;
    if (friendBonds.contains(p.bond)) return PeopleGroup.arkadaslar;
    if (_hasActive(p, schoolRoles)) return PeopleGroup.okul;
    if (_hasActive(p, workHomeRoles)) return PeopleGroup.isEv;
    if (_hasActive(p, neighbourhoodRoles)) return PeopleGroup.mahalle;
    // Yeni dönülen askerlikten bölük arkadaşları hemen "eski" sayılmaz.
    if (now != null &&
        p.origin == Origin.askerlik &&
        now - p.metAt <= recentComradeYears) {
      return PeopleGroup.arkadaslar;
    }
    return PeopleGroup.eski;
  }

  static bool _hasActive(Person p, Set<RoleKind> kinds) =>
      p.roles.any((r) => r.active && kinds.contains(r.kind));

  /// Doğmuş herkes, bölümlerine ayrılmış. Boş bölüm yoktur. Aile akrabalık
  /// sırasıyla, diğerleri yakınlığa göre (en yakın üstte) sıralanır.
  static Map<PeopleGroup, List<Person>> grouped(Character c) {
    final now = c.age;
    final groups = <PeopleGroup, List<Person>>{};
    for (final p in c.people.bornBy(now)) {
      groups.putIfAbsent(groupOf(p, now: now), () => []).add(p);
    }
    for (final MapEntry(key: group, value: people) in groups.entries) {
      if (group == PeopleGroup.aile) {
        people.sort((a, b) {
          final byKin = a.kin!.index.compareTo(b.kin!.index);
          return byKin != 0 ? byKin : a.bornAt.compareTo(b.bornAt);
        });
      } else if (group == PeopleGroup.vefat) {
        people.sort((a, b) => b.diedAt!.compareTo(a.diedAt!));
      } else {
        people.sort(
          (a, b) => Relationships.closeness(
            b,
            now,
          ).compareTo(Relationships.closeness(a, now)),
        );
      }
    }
    return {for (final group in PeopleGroup.values) group: ?groups[group]};
  }

  /// Kişinin seninle şu anki rolü: önce süren rol, yoksa bitmiş en son rol.
  static ({RoleKind kind, bool active})? mainRole(Person p) {
    for (final r in p.roles.reversed) {
      if (r.active) return (kind: r.kind, active: true);
    }
    if (p.roles.isEmpty) return null;
    return (kind: p.roles.last.kind, active: false);
  }

  /// Bu yılın seçimleri: yıl günlüğü için (kart kimliği ve seçilen taraf).
  static List<CardRecord> choicesThisYear(Character c) => [
    for (final r in c.history)
      if (r.age == c.age) r,
  ];
}
