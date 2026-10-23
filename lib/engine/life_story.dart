import '../models/models.dart';
import 'business_types.dart';
import 'hard_day.dart';
import 'relationships.dart';

/// Kurulan bir işin sonu.
enum BusinessEnd {
  /// Ölürken hâlâ açıktı.
  acik,

  /// Satıldı ya da kapatıldı.
  birakildi,
  batti,
}

/// İleri yaşta evlenenin mirası nasıl bölüşüldü.
enum Inheritance {
  /// Vasiyet vardı; sessizce bölüşüldü.
  vasiyet,

  /// Eşle çocuklar arasında kavga çıktı.
  kavga,
}

/// Hayat özetinin kişileri (canlı doküman, "Hayatın sonu"): kim yanındaydı,
/// kim geldi, kim gerçek dosttu. Ölüm anındaki karakterden hesaplanır.
class LifeStory {
  LifeStory(this.c);

  final Character c;

  int get _now => c.age;

  /// Ölüm anında hayatta olan, doğmuş kişiler.
  late final List<Person> _alive = [
    for (final p in c.people.bornBy(_now))
      if (p.isAlive) p,
  ];

  int _closeness(Person p) => Relationships.closeness(p, _now);

  /// En yakın üç kişi (yakınlık 40 ve üstü).
  late final List<Person> closest = () {
    final sorted = [
      for (final p in _alive)
        if (_closeness(p) >= 40) p,
    ]..sort((a, b) => _closeness(b).compareTo(_closeness(a)));
    return sorted.take(3).toList();
  }();

  /// Son gününde yanında olan: önce eş ve çocuklar, sonra en yakın kişi
  /// (yakınlık 50 ve üstü); aynı şehirdekiler önce.
  late final Person? bedside = () {
    int score(Person p) => _closeness(p) + (p.city == c.city ? 100 : 0);
    final near = [
      for (final p in _alive)
        if (_closeness(p) >= 50) p,
    ]..sort((a, b) => score(b).compareTo(score(a)));
    for (final p in near) {
      if (p.kin == Kinship.es || p.kin == Kinship.cocuk) return p;
    }
    return near.firstOrNull;
  }();

  /// Zor gününde arayıp dertleştiğin, hayatta olanlar.
  late final List<Person> trueFriends = [
    for (final p in HardDay.trueFriends(c))
      if (p.isAlive) p,
  ];

  /// Cenazeye gelenler: yakınlığı 40 ve üstü olanlar (husumetliler gelmez),
  /// gerçek dostlar ve küs olduğu hâlde gelen.
  late final List<Person> mourners = {
    for (final p in _alive)
      if ((_closeness(p) >= 40 || _family(p)) &&
          Relationships.hostility(p, _now) < 40)
        p,
    ...trueFriends,
    ?cameAnyway,
  }.toList();

  /// Eş ve yetişkin çocuklar, yakınlık düşük olsa da cenazeye gelir;
  /// yalnızca küslük (husumet) onları uzak tutar.
  bool _family(Person p) =>
      p.kin == Kinship.es || (p.kin == Kinship.cocuk && p.ageAt(_now) >= 18);

  /// Küs olduğu hâlde gelen: husumeti yüksek ama arada sevgi de kalmış.
  late final Person? cameAnyway = () {
    for (final p in _alive) {
      if (Relationships.hostility(p, _now) >= 40 && _closeness(p) >= 30) {
        return p;
      }
    }
    return null;
  }();

  /// Hayattaki eş; yoksa null.
  late final Person? spouse = _alive
      .where((p) => p.kin == Kinship.es)
      .firstOrNull;

  /// Cenazeye gelmeyen yetişkin çocuklar: aradaki kırgınlık ağır bastı.
  late final List<Person> absentChildren = [
    for (final p in _alive)
      if (p.kin == Kinship.cocuk &&
          p.ageAt(_now) >= 18 &&
          !mourners.contains(p))
        p,
  ];

  /// İleri yaşta evlenenin ardından miras. Vasiyet yazdıysa sessizce
  /// bölüşülür; yazmadıysa ve çocuklarla arası açıksa ya da evi eşinin
  /// üzerine yaptıysa eşle çocuklar arasında kavga çıkar. Eşi ya da yetişkin
  /// çocuğu yoksa miras konusu açılmaz.
  late final Inheritance? inheritance = () {
    if (!c.hasFlag(lateMarriageFlag)) return null;
    final spouse = this.spouse;
    final children = [
      for (final p in _alive)
        if (p.kin == Kinship.cocuk && p.ageAt(_now) >= 18) p,
    ];
    if (spouse == null || children.isEmpty) return null;
    if (c.hasFlag(willFlag)) return Inheritance.vasiyet;
    final rift =
        absentChildren.isNotEmpty ||
        c.hasFlag(houseToSpouseFlag) ||
        children.any((p) => Relationships.hostility(p, _now) >= 30);
    return rift ? Inheritance.kavga : null;
  }();

  /// İleri yaşta evlendi; vasiyet yazdı; evi eşinin üzerine yaptı (kart
  /// bayrakları).
  static const String lateMarriageFlag = 'gec_evlendi';
  static const String willFlag = 'vasiyet_yazdi';
  static const String houseToSpouseFlag = 'ev_esin_uzerine';

  /// Seni en çok özleyecek kişi: yakınlık ve olumlu anıların toplamı.
  late final Person? mostMissed = () {
    Person? best;
    var bestScore = 0;
    for (final p in _alive) {
      final good = p.memories.where((m) => m.tone == MemoryTone.olumlu);
      final score = _closeness(p) + 5 * good.length;
      if (_closeness(p) >= 50 && score > bestScore) {
        best = p;
        bestScore = score;
      }
    }
    return best;
  }();

  /// Kurulan işler ve sonları (tür kimliği → son). Büyüyen yazılım ekipli
  /// şirket olarak görünür.
  late final Map<String, BusinessEnd> businesses = {
    for (final type in c.bankruptcies.keys) type: BusinessEnd.batti,
    for (final type in c.businessExits.keys)
      if (!c.bankruptcies.containsKey(type) ||
          c.businessExits[type]! > c.bankruptcies[type]!)
        type: BusinessEnd.birakildi,
    for (final b in c.businesses) b.type: BusinessEnd.acik,
  }..removeWhere((type, _) => BusinessTypes.byId(type) == null);

  /// "Patron" lakabı: bir işletmeyi 10 yıl yaşattı ya da 3 şubeye çıkardı.
  bool get boss =>
      c.hasFlag('zincir_sahibi') ||
      c.businesses.any((b) => _now - b.openedAt >= 10);

  /// "Herkesin Dostu": akraba olmayan en az 5 yakın (60+) tanıdık.
  bool get everyonesFriend =>
      _alive.where((p) => p.kin == null && _closeness(p) >= 60).length >= 5;
}
