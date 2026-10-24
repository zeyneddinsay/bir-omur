import 'dart:math';

import '../models/models.dart';

/// İki çubuğun birleşiminden okunan ilişki rengi.
enum RelationColor {
  /// Yakınlık yüksek, husumet düşük: arar, yardım eder.
  dost,

  /// İkisi de yüksek: sever ama başarına içten içe bozulur.
  kiskancYakin,

  /// İkisi de düşük: selam verir, ihtiyaçta hatırlar.
  tanidik,

  /// Yakınlık düşük, husumet yüksek: iftira atar, rakip olur.
  dusman,
}

/// Yakınlık ve husumet hesabı. Çubuklar saklanmaz; her seferinde kişinin
/// anılarından, tabanından ve son görüşmeden hesaplanır. Böylece geçmiş
/// hiçbir zaman kaybolmaz ve zaman tek başına küsleri barıştırmaz.
abstract final class Relationships {
  /// Akrabanın eşi (oyuncunun gözünden): dede–nine aynı taraftan, anne–baba,
  /// kayınvalide–kayınpeder.
  static const Map<Kinship, Kinship> _spouseKin = {
    Kinship.dede: Kinship.nine,
    Kinship.nine: Kinship.dede,
    Kinship.anne: Kinship.baba,
    Kinship.baba: Kinship.anne,
    Kinship.kayinvalide: Kinship.kayinpeder,
    Kinship.kayinpeder: Kinship.kayinvalide,
  };

  /// Eşini son bir yıl içinde kaybetmiş akraba: yas yılında neşeli olaylarda
  /// rol almaz (babaanne öldüğü yıl dedenin "askerde kar" hikâyesi gelmez).
  static bool widowedRecently(Character c, Person p) {
    final partner = _spouseKin[p.kin];
    if (partner == null) return false;
    return c.people.all.any(
      (o) =>
          o.kin == partner &&
          o.side == p.side &&
          o.diedAt != null &&
          c.age - o.diedAt! <= 1,
    );
  }

  /// Aynı akrabalıkta (aynı cinsiyetten) biri son bir yıl içinde vefat etti:
  /// öbür dede o yıl neşeli olaylarda rol almaz ("Deden artık yok"un
  /// ardından "Deden yine askerlik hikâyesini anlatıyor" gelmez).
  static bool namesakeMourned(Character c, Person p) {
    if (p.kin == null) return false;
    return c.people.all.any(
      (o) =>
          o.id != p.id &&
          o.kin == p.kin &&
          o.gender == p.gender &&
          o.diedAt != null &&
          c.age - o.diedAt! <= 1,
    );
  }

  /// Şiddete göre anının ilk ağırlığı.
  static const Map<int, int> severityPoints = {1: 10, 2: 30, 3: 50};

  /// Bu özelliklerdeki kişilerde olumsuz anılar 1,5 kat sayılır.
  static const Set<Trait> grudgeTraits = {Trait.kiskanc};
  static const double grudgeMultiplier = 1.5;

  /// Barışmayla yumuşamış olumsuz anının ağırlık oranı.
  static const double healedShare = 0.5;

  /// Şiddete göre yıllık solma payı ve taban (ilk ağırlığın oranı olarak).
  /// Şiddet 1: 5 yılda biter. Şiddet 2: 12 yılda %20'ye iner, orada
  /// kalır. Şiddet 3: 10 yılda %50'ye iner, orada kalır.
  static const Map<int, ({double rate, double floor})> fading = {
    1: (rate: 0.2, floor: 0),
    2: (rate: 1 / 15, floor: 0.2),
    3: (rate: 0.05, floor: 0.5),
  };

  /// Genel izlenim her yıl bu oranda kalır (%10 solar).
  static const double impressionKeep = 0.9;

  /// Görüşülmeyen ilişki bu kadar yıl sonra soğumaya başlar, sonra her
  /// yıl [coolingPerYear] puan, toplamda en fazla [maxCooling].
  static const int coolingGrace = 2;
  static const int coolingPerYear = 2;
  static const int maxCooling = 30;

  /// Etiketler için eşikler.
  static const int colorThreshold = 50;
  static const int hostileLabelMin = 60;
  static const int hostileLabelMaxCloseness = 30;

  /// Kişiliğe göre solma hızı çarpanı: Vefalı yavaş, Gamsız hızlı unutur.
  /// Soğuma da aynı çarpanla işler.
  static double paceOf(Person p) {
    if (p.hasTrait(Trait.vefali)) return 0.5;
    if (p.hasTrait(Trait.gamsiz)) return 2.0;
    return 1.0;
  }

  /// [years] yıl geçmiş, [severity] şiddetinde bir anının kalan oranı.
  static double fadeFactor(int severity, int years, {double pace = 1.0}) {
    final f = fading[severity]!;
    final t = max(0, years);
    return max(f.floor, 1 - f.rate * pace * t);
  }

  /// Anının oyuncu [now] yaşındayken ağırlığı. Oyuncunun anıları için de
  /// hesaplanır (en zayıf anıyı seçmekte kullanılır) ama çubuklara girmez.
  static double weightOf(Memory m, Person p, int now) {
    var w = severityPoints[m.severity]! * m.bonus;
    w *= fadeFactor(m.severity, now - m.age, pace: paceOf(p));
    if (m.tone == MemoryTone.olumsuz) {
      if (m.healed) w *= healedShare;
      if (p.traits.any(grudgeTraits.contains)) w *= grudgeMultiplier;
    }
    return w;
  }

  /// Genel izlenimin [now] yaşındaki değeri.
  static Impression impressionAt(Impression i, int now) {
    if (i.isEmpty) return Impression(since: now);
    final keep = pow(impressionKeep, max(0, now - i.since)).toDouble();
    return Impression(
      warmth: i.warmth * keep,
      grudge: i.grudge * keep,
      since: now,
    );
  }

  /// Görüşmemekten gelen yakınlık kaybı.
  static int coolingOf(Person p, int now) {
    final idle = now - p.lastContactAt - coolingGrace;
    if (idle <= 0) return 0;
    return min(maxCooling, (idle * coolingPerYear * paceOf(p)).round());
  }

  /// Yakınlık bu değerin üstünde yarı hızla artar: çok yakın olmak emek
  /// ister, yakınlık kolay doymaz.
  static const int softCap = 70;

  /// Yakınlık (0–100): taban + olumlu anılar + izlenim − soğuma; [softCap]
  /// üstü yarı hızla.
  static int closeness(Person p, int now) {
    var sum = p.base.toDouble();
    for (final m in p.memories) {
      if (m.affectsBars && m.tone == MemoryTone.olumlu) {
        sum += weightOf(m, p, now);
      }
    }
    if (sum > softCap) sum = softCap + (sum - softCap) / 2;
    sum += impressionAt(p.impression, now).warmth;
    sum -= coolingOf(p, now);
    return sum.round().clamp(0, 100);
  }

  /// Husumet (0–100): olumsuz anılar + izlenim.
  static int hostility(Person p, int now) {
    var sum = 0.0;
    for (final m in p.memories) {
      if (m.affectsBars && m.tone == MemoryTone.olumsuz) {
        sum += weightOf(m, p, now);
      }
    }
    sum += impressionAt(p.impression, now).grudge;
    return sum.round().clamp(0, 100);
  }

  static RelationColor colorOf(Person p, int now) {
    final close = closeness(p, now) >= colorThreshold;
    final hostile = hostility(p, now) >= colorThreshold;
    return switch ((close, hostile)) {
      (true, false) => RelationColor.dost,
      (true, true) => RelationColor.kiskancYakin,
      (false, false) => RelationColor.tanidik,
      (false, true) => RelationColor.dusman,
    };
  }

  /// "Husumetli" etiketi: ayrı bir bağ değil, çubuklardan okunur.
  static bool isHostile(Person p, int now) =>
      hostility(p, now) >= hostileLabelMin &&
      closeness(p, now) < hostileLabelMaxCloseness;

  /// Anı ekler. Anı sayısı [Person.maxMemories] sınırını aşarsa o an en
  /// zayıf anı genel izlenime katılır; oyuncunun anısıysa yalnızca düşer
  /// (oyuncunun anıları çubukları etkilemez).
  static Person addMemory(Person p, Memory memory, {required int now}) {
    final memories = [...p.memories, memory];
    if (memories.length <= Person.maxMemories) {
      return p.copyWith(memories: memories);
    }
    var weakest = 0;
    var weakestWeight = double.infinity;
    for (var i = 0; i < memories.length; i++) {
      final w = weightOf(memories[i], p, now);
      if (w < weakestWeight) {
        weakest = i;
        weakestWeight = w;
      }
    }
    final dropped = memories.removeAt(weakest);
    var impression = impressionAt(p.impression, now);
    if (dropped.affectsBars) {
      impression = dropped.tone == MemoryTone.olumlu
          ? Impression(
              warmth: impression.warmth + weakestWeight,
              grudge: impression.grudge,
              since: now,
            )
          : Impression(
              warmth: impression.warmth,
              grudge: impression.grudge + weakestWeight,
              since: now,
            );
    }
    return p.copyWith(memories: memories, impression: impression);
  }

  /// Olumsuz anıları yumuşatır (özür, barışma). [kind] verilirse yalnızca
  /// o türdeki anılar; verilmezse en ağır olumsuz anı. Oyuncunun kendi
  /// anıları yumuşamaz: o hatırlamaya devam eder.
  static Person heal(Person p, {String? kind, required int now}) {
    final candidates = [
      for (var i = 0; i < p.memories.length; i++)
        if (p.memories[i].tone == MemoryTone.olumsuz &&
            p.memories[i].affectsBars &&
            !p.memories[i].healed &&
            (kind == null || p.memories[i].kind == kind))
          i,
    ];
    if (candidates.isEmpty) return p;
    final targets = kind != null
        ? candidates
        : [
            candidates.reduce(
              (a, b) =>
                  weightOf(p.memories[a], p, now) >=
                      weightOf(p.memories[b], p, now)
                  ? a
                  : b,
            ),
          ];
    final memories = [
      for (var i = 0; i < p.memories.length; i++)
        targets.contains(i) ? p.memories[i].heal() : p.memories[i],
    ];
    return p.copyWith(memories: memories);
  }

  /// Görüşme yapıldı: soğuma sıfırlanır.
  static Person touch(Person p, int now) => p.copyWith(lastContactAt: now);

  /// Aile Bağı göstergesinin kaynağı olan akrabalar.
  static const Set<Kinship> familyBondKin = {
    Kinship.anne,
    Kinship.baba,
    Kinship.kardes,
    Kinship.es,
    Kinship.cocuk,
  };

  /// Aile Bağı: anne, baba, kardeşler, eş ve çocukların (doğmuş, hayatta)
  /// yakınlık ortalaması. Böyle kimse kalmadıysa null.
  static int? familyBond(Character c) {
    final members = [
      for (final p in c.people.bornBy(c.age))
        if (p.isAlive && familyBondKin.contains(p.kin)) p,
    ];
    if (members.isEmpty) return null;
    final sum = members.fold(0, (s, p) => s + closeness(p, c.age));
    return (sum / members.length).round();
  }

  /// Aile Bağı göstergesini ailenin yakınlığına eşitler. Gösterge artık
  /// olaylarla doğrudan değişmez; kimse kalmadıysa son değerinde kalır.
  static Character syncFamilyBond(Character c) {
    final bond = familyBond(c);
    if (bond == null || bond == c.stats.family) return c;
    return c.copyWith(stats: c.stats.copyWith(family: bond));
  }
}
