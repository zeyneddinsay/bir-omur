import 'character.dart';
import 'json_reader.dart';
import 'person.dart';

/// Bir olayın ihtiyaç duyduğu kişi: "rol yuvası". Olay seçilirken
/// çevredeki uygun kişilerden biri yuvaya bağlanır; uygun kişi yoksa olay
/// gelmez.
///
/// Yaş, yakınlık ve husumet sınırları dahildir (`minAge: 7, maxAge: 14`
/// 7 ve 14'ü kapsar).
class RoleSlot {
  const RoleSlot({
    required this.name,
    this.kin = const {},
    this.roles = const {},
    this.formerRoles = const {},
    this.bonds = const {},
    this.gender,
    this.side,
    this.minAge,
    this.maxAge,
    this.minGap,
    this.maxGap,
    this.minCloseness,
    this.maxCloseness,
    this.minHostility,
    this.maxHostility,
    this.traits = const {},
    this.notTraits = const {},
    this.memory,
    this.noMemory,
    this.sameCity,
    this.offstage = false,
    this.deceased = false,
  });

  /// Metinde `{kerem.ad}` gibi kullanılan ad.
  final String name;

  /// Boş değilse kişinin akrabalığı bunlardan biri olmalı.
  final Set<Kinship> kin;

  /// Boş değilse kişinin bunlardan biri süren rolü olmalı.
  final Set<RoleKind> roles;

  /// Boş değilse kişinin bunlardan biri bitmiş rolü olmalı ("eski sınıf
  /// arkadaşı").
  final Set<RoleKind> formerRoles;

  /// Boş değilse kişinin bağı bunlardan biri olmalı.
  final Set<Bond> bonds;
  final Gender? gender;
  final Side? side;

  /// Kişinin yaşı.
  final int? minAge;
  final int? maxAge;

  /// Kişinin oyuncudan yaş farkı (büyükse artı).
  final int? minGap;
  final int? maxGap;
  final int? minCloseness;
  final int? maxCloseness;
  final int? minHostility;
  final int? maxHostility;

  /// Hepsi olmalı.
  final Set<Trait> traits;

  /// Hiçbiri olmamalı.
  final Set<Trait> notTraits;

  /// Kişinin hafızasında bu türde bir anı olmalı / olmamalı.
  final String? memory;
  final String? noMemory;

  /// true: oyuncuyla aynı şehirde; false: başka şehirde; null: fark etmez.
  final bool? sameCity;

  /// Kişi sahnede değil (hakkında konuşuluyor): olay görüşme sayılmaz.
  final bool offstage;

  /// Yalnızca son bir yıl içinde vefat etmiş kişiyle eşleşir (cenaze,
  /// taziye). Her vefat için bir kez eşleşir; böyle bir yuva her zaman
  /// sahne dışıdır.
  final bool deceased;

  static const Set<String> knownKeys = {
    'kin',
    'roles',
    'formerRoles',
    'bond',
    'gender',
    'side',
    'minAge',
    'maxAge',
    'minGap',
    'maxGap',
    'minCloseness',
    'maxCloseness',
    'minHostility',
    'maxHostility',
    'traits',
    'notTraits',
    'memory',
    'noMemory',
    'sameCity',
    'offstage',
    'deceased',
  };

  factory RoleSlot.fromJson(String name, JsonReader r) {
    r.rejectUnknownKeys(knownKeys);
    Set<T> enums<T extends Enum>(String key, List<T> values) {
      final byName = values.asNameMap();
      return {
        for (final id in r.optionalStringList(key))
          byName[id] ??
              (throw CardFormatException(
                '${r.path}.$key',
                'bilinmeyen değer "$id"',
              )),
      };
    }

    T? one<T extends Enum>(String key, List<T> values) {
      final id = r.optionalString(key);
      if (id == null) return null;
      return values.asNameMap()[id] ??
          (throw CardFormatException(
            '${r.path}.$key',
            'bilinmeyen değer "$id"',
          ));
    }

    int? bounded(String key, int min, int max) {
      final v = r.optionalInt(key);
      if (v != null && (v < min || v > max)) {
        throw CardFormatException(
          '${r.path}.$key',
          '$min–$max arasında olmalı',
        );
      }
      return v;
    }

    final slot = RoleSlot(
      name: name,
      kin: enums('kin', Kinship.values),
      roles: enums('roles', RoleKind.values),
      formerRoles: enums('formerRoles', RoleKind.values),
      bonds: enums('bond', Bond.values),
      gender: r.has('gender')
          ? (Gender.fromId(r.requireString('gender')) ??
                (throw CardFormatException(
                  '${r.path}.gender',
                  'bilinmeyen cinsiyet',
                )))
          : null,
      side: one('side', Side.values),
      minAge: bounded('minAge', 0, 120),
      maxAge: bounded('maxAge', 0, 120),
      minGap: bounded('minGap', -120, 120),
      maxGap: bounded('maxGap', -120, 120),
      minCloseness: bounded('minCloseness', 0, 100),
      maxCloseness: bounded('maxCloseness', 0, 100),
      minHostility: bounded('minHostility', 0, 100),
      maxHostility: bounded('maxHostility', 0, 100),
      traits: enums('traits', Trait.values),
      notTraits: enums('notTraits', Trait.values),
      memory: r.optionalString('memory'),
      noMemory: r.optionalString('noMemory'),
      sameCity: r.has('sameCity') ? r.optionalBool('sameCity') : null,
      offstage: r.optionalBool('offstage') || r.optionalBool('deceased'),
      deceased: r.optionalBool('deceased'),
    );
    for (final (lo, hi, label) in [
      (slot.minAge, slot.maxAge, 'yaş'),
      (slot.minGap, slot.maxGap, 'yaş farkı'),
      (slot.minCloseness, slot.maxCloseness, 'yakınlık'),
      (slot.minHostility, slot.maxHostility, 'husumet'),
    ]) {
      if (lo != null && hi != null && lo > hi) {
        throw CardFormatException(r.path, '$label aralığı ters ($lo > $hi)');
      }
    }
    return slot;
  }
}

/// Seçeneğin bir kişiye yazdığı anı.
class MemorySpec {
  const MemorySpec({
    required this.kind,
    required this.label,
    required this.tone,
    required this.severity,
    this.owner = MemoryOwner.ikisi,
  });

  final String kind;

  /// Kişinin gözünden kısa etiket: "Sınıfın ortasında rezil etti".
  final String label;
  final MemoryTone tone;
  final int severity;
  final MemoryOwner owner;

  Memory at(int age) => Memory(
    kind: kind,
    label: label,
    age: age,
    tone: tone,
    severity: severity,
    owner: owner,
  );

  factory MemorySpec.fromJson(JsonReader r) {
    r.rejectUnknownKeys(const {'kind', 'label', 'tone', 'severity', 'owner'});
    final tone = MemoryTone.values.asNameMap()[r.requireString('tone')];
    if (tone == null) {
      throw CardFormatException(
        '${r.path}.tone',
        'olumlu ya da olumsuz olmalı',
      );
    }
    final severity = r.requireInt('severity');
    if (severity < 1 || severity > 3) {
      throw CardFormatException('${r.path}.severity', '1–3 arasında olmalı');
    }
    final ownerId = r.optionalString('owner') ?? MemoryOwner.ikisi.name;
    final owner = MemoryOwner.values.asNameMap()[ownerId];
    if (owner == null) {
      throw CardFormatException(
        '${r.path}.owner',
        'kisi, oyuncu ya da ikisi olmalı',
      );
    }
    return MemorySpec(
      kind: r.requireString('kind'),
      label: r.requireString('label'),
      tone: tone,
      severity: severity,
      owner: owner,
    );
  }
}

/// Seçeneğin rol yuvasındaki kişiye etkisi.
class PersonEffect {
  const PersonEffect({this.memory, this.heal, this.bond, this.archive = false});

  final MemorySpec? memory;

  /// Yumuşatılacak olumsuz anının türü; `*` en ağır olumsuz anı.
  final String? heal;

  /// Bağın yeni basamağı (arkadaş, yakın arkadaş…).
  final Bond? bond;

  /// Kişi "eski tanıdıklar"a düşer.
  final bool archive;

  /// En ağır olumsuz anıyı yumuşatma işareti.
  static const String healHeaviest = '*';

  factory PersonEffect.fromJson(JsonReader r) {
    r.rejectUnknownKeys(const {'memory', 'heal', 'bond', 'archive'});
    final memory = r.optionalObject('memory');
    final bondId = r.optionalString('bond');
    Bond? bond;
    if (bondId != null) {
      bond =
          Bond.values.asNameMap()[bondId] ??
          (throw CardFormatException(
            '${r.path}.bond',
            'bilinmeyen bağ "$bondId"',
          ));
    }
    final effect = PersonEffect(
      memory: memory == null ? null : MemorySpec.fromJson(memory),
      heal: r.optionalString('heal'),
      bond: bond,
      archive: r.optionalBool('archive'),
    );
    if (effect.memory == null &&
        effect.heal == null &&
        effect.bond == null &&
        !effect.archive) {
      throw CardFormatException(r.path, 'boş kişi etkisi');
    }
    return effect;
  }
}
