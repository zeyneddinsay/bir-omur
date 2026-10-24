import 'dart:convert';
import 'dart:math';

import '../../engine/seeded_random.dart';
import '../../models/models.dart';

/// Portrenin yaş görünümü; saç, yüz ve aksesuarları belirler.
enum AgeLook { bebek, cocuk, genc, yetiskin, olgun, yasli }

/// Ağız ifadesi.
enum Mood { happy, neutral, sad }

/// Bir portrenin tarifi: hangi parçalar hangi sırayla, hangi renklerle.
class PortraitSpec {
  const PortraitSpec({required this.layers, required this.colors});

  /// `assets/portraits/<ad>.svg` dosya adları, alttan üste.
  final List<String> layers;

  /// Yer tutucu renk → gerçek renk (bkz. `assets/portraits/README.md`).
  final Map<String, String> colors;
}

/// Yer tutucu renkler; parça dosyalarında birebir bu yazımla geçer.
abstract final class PortraitTokens {
  static const String skin = '#E8B98F';
  static const String skinShadow = '#CC9A72';
  static const String hair = '#3B2A20';
  static const String shirt = '#4A6FA5';
  static const String background = '#EFE6DA';
  static const String accessory = '#9C4A5A';
}

/// Bir konuşmacının sabit görünümü.
class SpeakerLook {
  const SpeakerLook(
    this.gender,
    this.age, {
    this.mustache = false,
    this.cap = false,
    this.headscarf = false,
    this.glasses = false,
  });

  final Gender gender;
  final AgeLook age;
  final bool mustache;
  final bool cap;
  final bool headscarf;
  final bool glasses;
}

/// Karakterden ve konuşmacıdan portre tarifi üretir. Aynı girdi her zaman
/// aynı yüzü verir.
abstract final class PortraitDesigner {
  static const List<String> allParts = [
    'bg', 'body', 'ears', 'cheeks', 'wrinkles', //
    'face_oval', 'face_round', 'face_long',
    'eyes_dot', 'eyes_round', 'eyes_tired',
    'brows_flat', 'brows_arched', 'brows_thick',
    'nose_small', 'nose_button',
    'mouth_smile', 'mouth_neutral', 'mouth_sad', 'mouth_baby',
    'hair_baby_tuft', 'hair_short', 'hair_side_part', 'hair_buzz',
    'hair_curly', 'hair_long_back', 'hair_long_front', 'hair_bob_back',
    'hair_bun', 'hair_bald_sides',
    'mustache', 'beard', 'glasses_round', 'glasses_square',
    'headscarf', 'cap_flat',
  ];

  static const _skinTones = [
    ('#F5D5B8', '#D9AE8C'),
    ('#E8B98F', '#CC9A72'),
    ('#C9946A', '#A8744D'),
    ('#8D5A3B', '#6E4329'),
  ];
  static const _hairColors = [
    '#1E1410',
    '#3B2A20',
    '#5C3A21',
    '#7A4A26',
    '#B98B4E',
    '#A33A1F',
  ];
  static const _greyHair = '#9E9E9E';
  static const _whiteHair = '#E3E3E3';
  static const _shirts = [
    '#4A6FA5',
    '#5E8C61',
    '#C0392B',
    '#8E6C8A',
    '#D9A441',
    '#4F5D75',
    '#2E86AB',
  ];
  static const _backgrounds = [
    '#EFE6DA',
    '#E3EDF2',
    '#F3E3E6',
    '#E6F0E3',
    '#F2ECD9',
  ];
  static const _scarves = ['#9C4A5A', '#3E6E8E', '#6B8E4E', '#8E6C3E'];

  /// Kart konuşmacılarının görünümü. Listede olmayan konuşmacının
  /// cinsiyeti ve yaşı kimliğinden türetilir.
  static const Map<String, SpeakerLook> speakers = {
    'anne': SpeakerLook(Gender.kadin, AgeLook.yetiskin),
    'baba': SpeakerLook(Gender.erkek, AgeLook.yetiskin, mustache: true),
    'dede': SpeakerLook(Gender.erkek, AgeLook.yasli, cap: true),
    'babaanne': SpeakerLook(Gender.kadin, AgeLook.yasli, headscarf: true),
    'bakkal': SpeakerLook(Gender.erkek, AgeLook.olgun, mustache: true),
    'ev_sahibi': SpeakerLook(Gender.erkek, AgeLook.olgun, glasses: true),
    'kayinvalide': SpeakerLook(Gender.kadin, AgeLook.olgun, glasses: true),
    'kayinpeder': SpeakerLook(Gender.erkek, AgeLook.yasli, mustache: true),
    'patron': SpeakerLook(Gender.erkek, AgeLook.yetiskin),
    'mudur': SpeakerLook(Gender.kadin, AgeLook.yetiskin, glasses: true),
    'usta': SpeakerLook(Gender.erkek, AgeLook.olgun, mustache: true),
    'ik_uzmani': SpeakerLook(Gender.kadin, AgeLook.genc),
    'doktor': SpeakerLook(Gender.kadin, AgeLook.yetiskin, glasses: true),
    'eski_komsu': SpeakerLook(Gender.erkek, AgeLook.yasli, cap: true),
    'torun': SpeakerLook(Gender.kadin, AgeLook.cocuk),
    'banka': SpeakerLook(Gender.erkek, AgeLook.genc),
    'kuyumcu': SpeakerLook(Gender.erkek, AgeLook.olgun, mustache: true),
    'galerici': SpeakerLook(Gender.erkek, AgeLook.yetiskin, mustache: true),
    'amca': SpeakerLook(Gender.erkek, AgeLook.olgun, mustache: true),
    'komsu_teyze': SpeakerLook(Gender.kadin, AgeLook.yasli, headscarf: true),
    'teyze': SpeakerLook(Gender.kadin, AgeLook.olgun),
    'tamirci': SpeakerLook(Gender.erkek, AgeLook.yetiskin),
    'vatandas': SpeakerLook(Gender.erkek, AgeLook.olgun, glasses: true),
    'zabita': SpeakerLook(Gender.erkek, AgeLook.yetiskin),
    'yegen': SpeakerLook(Gender.erkek, AgeLook.genc),
    'koc': SpeakerLook(Gender.erkek, AgeLook.yetiskin),
    'ogretmen': SpeakerLook(Gender.kadin, AgeLook.yetiskin),
    'rehber_ogretmen': SpeakerLook(
      Gender.erkek,
      AgeLook.yetiskin,
      glasses: true,
    ),
    'ehliyet_hocasi': SpeakerLook(Gender.erkek, AgeLook.olgun),
    'komsu_oglu': SpeakerLook(Gender.erkek, AgeLook.genc),
  };

  /// Yaşıt olan konuşmacılar (arkadaş, kuzen) oyuncunun yaşında görünür.
  static const Set<String> peerSpeakers = {'arkadas', 'kuzen'};

  static AgeLook ageLookFor(int age) => switch (age) {
    < 7 => AgeLook.bebek,
    < 15 => AgeLook.cocuk,
    < 30 => AgeLook.genc,
    < 50 => AgeLook.yetiskin,
    < 65 => AgeLook.olgun,
    _ => AgeLook.yasli,
  };

  static Mood moodFor(int happiness) => switch (happiness) {
    >= 65 => Mood.happy,
    >= 35 => Mood.neutral,
    _ => Mood.sad,
  };

  /// Oyuncunun portresi. Yüz isim, memleket ve cinsiyetten gelir; yaş ve
  /// mutluluk değiştikçe saç ve ifade değişir.
  static PortraitSpec forCharacter(Character c) => forPerson(
    name: c.name,
    hometown: c.hometown,
    gender: c.gender,
    age: c.age,
    mood: moodFor(c.stats.happiness),
  );

  /// Albümdeki gibi yalnızca kimlik bilgisi olan biri için.
  static PortraitSpec forPerson({
    required String name,
    required String hometown,
    required Gender gender,
    required int age,
    Mood mood = Mood.neutral,
  }) => build(
    seed: stableHash('$name|$hometown|${gender.id}'),
    gender: gender,
    age: ageLookFor(age),
    mood: mood,
  );

  /// Oyuncunun hayatındaki bir kişi: yüzü ömür boyu aynı tohumdan gelir,
  /// yaşı ilerledikçe saçı grileşir, yüzü yaşlanır. [family] verilirse kan
  /// bağı olan akrabanın ten rengi ailenin tonundan gelir; dede ve nine her
  /// zaman yaşlı görünür.
  static PortraitSpec ofPerson(
    Person p, {
    required int playerAge,
    Character? family,
  }) {
    var age = ageLookFor(max(0, p.ageAt(playerAge)));
    if ((p.kin == Kinship.dede || p.kin == Kinship.nine) &&
        age.index < AgeLook.yasli.index) {
      age = AgeLook.yasli;
    }
    return build(
      seed: p.portraitSeed,
      gender: p.gender,
      age: age,
      mood: Mood.neutral,
      skinTone: family == null ? null : familyTone(family, p),
    );
  }

  /// Oyuncunun ten tonu (sıra numarası); [forCharacter] ile aynı tohum.
  static int playerTone(Character c) =>
      _toneOf(stableHash('${c.name}|${c.hometown}|${c.gender.id}'));

  /// Tohumdan seçilen ten tonu: [build] tonu ilk çekilişte seçer.
  static int _toneOf(int seed) => SeededRandom(seed).nextInt(_skinTones.length);

  /// Kan bağı olan akrabanın ten tonu; değilse (eş, kayın, tanıdık) null.
  /// Baba tarafı oyuncunun tonundadır, anne tarafı ondan en fazla bir ton
  /// farklıdır; oyuncunun çocukları onunla eşinin arasındadır.
  static int? familyTone(Character c, Person p) {
    final player = playerTone(c);
    final paternal = player;
    final shift =
        SeededRandom(stableHash('aile|${c.name}|${c.hometown}')).nextInt(3) - 1;
    final maternal = (player + shift).clamp(0, _skinTones.length - 1);
    int bySide(int fallback) => switch (p.side) {
      Side.anne => maternal,
      Side.baba => paternal,
      null => fallback,
    };
    switch (p.kin) {
      case Kinship.anne || Kinship.dayi || Kinship.teyze:
        return maternal;
      case Kinship.baba || Kinship.amca || Kinship.hala:
        return paternal;
      case Kinship.dede || Kinship.nine:
        return bySide(paternal);
      case Kinship.kuzen:
        return bySide(player);
      case Kinship.kardes || Kinship.yegen || Kinship.torun:
        return player;
      case Kinship.cocuk:
        final spouse = c.people.all
            .where((s) => s.kin == Kinship.es)
            .firstOrNull;
        if (spouse == null) return player;
        final other = _toneOf(spouse.portraitSeed);
        // İki tonun arası; tek basamak farkta kardeşler ikisine dağılır.
        final low = min(player, other);
        final high = max(player, other);
        return low + (high - low + (p.portraitSeed.isEven ? 1 : 0)) ~/ 2;
      default:
        return null;
    }
  }

  static PortraitSpec forSpeaker(String speakerId, {required int playerAge}) {
    final seed = stableHash('konusmaci|$speakerId');
    final look = speakers[speakerId];
    if (look != null) {
      return build(seed: seed, gender: look.gender, age: look.age, look: look);
    }
    final gender = seed.isEven ? Gender.kadin : Gender.erkek;
    final age = peerSpeakers.contains(speakerId)
        ? ageLookFor(playerAge)
        : AgeLook.yetiskin;
    return build(seed: seed, gender: gender, age: age);
  }

  /// [skinTone] verilirse ten tonu (sıra numarası) odur: ailede kan bağı
  /// olanlar aynı tondan gelir.
  ///
  /// Kişinin kimliği (ten, saç rengi, yüz, saç modeli, gözlük ve bıyık
  /// eğilimi) tohumdan yaşa bakmadan, hep aynı sırayla çekilir; yaş yalnızca
  /// grileşmeyi, kırışıkları, kelleşmeyi, başörtüsü ve kasketi, bebek ve
  /// çocuk görünümünü değiştirir. Böylece aynı kişi her yaşta aynı saçla
  /// tanınır.
  static PortraitSpec build({
    required int seed,
    required Gender gender,
    required AgeLook age,
    Mood mood = Mood.happy,
    SpeakerLook? look,
    int? skinTone,
  }) {
    final r = SeededRandom(seed);
    T pick<T>(List<T> items) => items[r.nextInt(items.length)];
    final male = gender == Gender.erkek;
    final baby = age == AgeLook.bebek;
    final child = baby || age == AgeLook.cocuk;
    final old = age == AgeLook.yasli;

    // Kimlik: her çekiliş her yaşta yapılır, sıra hiç değişmez.
    final toneDraw = r.nextInt(_skinTones.length);
    final baseHair = pick(_hairColors);
    final adultFace = pick(['face_oval', 'face_round', 'face_long']);
    final adultEyes = pick(['eyes_dot', 'eyes_round']);
    final brows = pick(['brows_flat', 'brows_arched', 'brows_thick']);
    final nose = pick(['nose_small', 'nose_button']);
    final maleStyle = pick([
      'hair_short',
      'hair_side_part',
      'hair_curly',
      'hair_buzz',
    ]);
    final femaleStyle = pick(['long', 'bob', 'bun', 'curly']);
    final facialRoll = r.nextDouble();
    final glassesRoll = r.nextDouble();
    final glassesType = pick(['glasses_round', 'glasses_square']);
    final headwearRoll = r.nextDouble();
    final greyRoll = r.nextDouble();
    final baldRoll = r.nextDouble();
    final shirt = pick(_shirts);
    final background = pick(_backgrounds);
    final scarf = pick(_scarves);

    final (skin, skinShadow) =
        _skinTones[(skinTone ?? toneDraw).clamp(0, _skinTones.length - 1)];
    // Olgun yaşta çoğunlukla kır, yaşlıda gri ya da beyaz saç.
    final hairColor = switch (age) {
      AgeLook.olgun => greyRoll < 0.75 ? _greyHair : baseHair,
      AgeLook.yasli => greyRoll < 0.5 ? _whiteHair : _greyHair,
      _ => baseHair,
    };

    final face = baby ? 'face_round' : adultFace;
    final eyes = child ? 'eyes_round' : adultEyes;
    final mouth = baby
        ? 'mouth_baby'
        : switch (mood) {
            Mood.happy => 'mouth_smile',
            Mood.neutral => 'mouth_neutral',
            Mood.sad => 'mouth_sad',
          };

    // Saç: arka parça (uzun saç) yüzün arkasına, ön parça yüzün üstüne.
    String? hairBack;
    String hairFront;
    if (baby) {
      hairFront = 'hair_baby_tuft';
    } else if (male) {
      // Yaşla kelleşme; yaşlıda kıvırcık kısa saça döner.
      final balding = switch (age) {
        AgeLook.olgun => baldRoll < 0.25,
        AgeLook.yasli => baldRoll < 0.45,
        _ => false,
      };
      hairFront = balding
          ? 'hair_bald_sides'
          : old && maleStyle == 'hair_curly'
          ? 'hair_short'
          : maleStyle;
    } else {
      // Yaşlı kadında uzun saç topuz olur; diğer modeller kalır.
      final style = old && femaleStyle == 'long' ? 'bun' : femaleStyle;
      (hairBack, hairFront) = switch (style) {
        'long' => ('hair_long_back', 'hair_long_front'),
        'bob' => ('hair_bob_back', 'hair_long_front'),
        'bun' => (null, 'hair_bun'),
        // Kıvırcık kadın saçı arkadan hacimli; erkeklerin kısa kıvırcığıyla
        // karışmasın.
        _ => ('hair_bob_back', 'hair_curly'),
      };
    }

    final facialHair = male && !child && age != AgeLook.genc
        ? (look?.mustache ?? false)
              ? 'mustache'
              : facialRoll < 0.12
              ? 'beard'
              : facialRoll < 0.34
              ? 'mustache'
              : null
        : null;
    final glassesChance = switch (age) {
      AgeLook.genc => 0.1,
      AgeLook.yetiskin => 0.15,
      AgeLook.olgun => 0.4,
      AgeLook.yasli => 0.55,
      _ => 0.0,
    };
    // Aynı eşik: gençken gözlüklü olan yaşlanınca da gözlüklüdür.
    final glasses = (look?.glasses ?? false) || glassesRoll < glassesChance
        ? glassesType
        : null;
    final headscarf =
        !male && ((look?.headscarf ?? false) || (old && headwearRoll < 0.3));
    final cap = male && ((look?.cap ?? false) || (old && headwearRoll < 0.3));

    final layers = <String>[
      'bg',
      if (hairBack != null && !headscarf) hairBack,
      'body',
      'ears',
      face,
      if (child) 'cheeks',
      if (age == AgeLook.yasli) 'wrinkles',
      eyes,
      if (!baby) brows,
      nose,
      mouth,
      ?facialHair,
      if (!headscarf) hairFront,
      ?glasses,
      if (headscarf) 'headscarf',
      if (cap) 'cap_flat',
    ];
    return PortraitSpec(
      layers: List.unmodifiable(layers),
      colors: {
        PortraitTokens.skin: skin,
        PortraitTokens.skinShadow: skinShadow,
        PortraitTokens.hair: hairColor,
        PortraitTokens.shirt: shirt,
        PortraitTokens.background: background,
        PortraitTokens.accessory: scarf,
      },
    );
  }

  /// Sürümden sürüme değişmeyen karma (FNV-1a, 32 bit). `String.hashCode`
  /// kalıcılık garantisi vermez.
  static int stableHash(String text) {
    var hash = 0x811C9DC5;
    for (final byte in utf8.encode(text)) {
      hash ^= byte;
      hash = (hash * 0x01000193) & 0xFFFFFFFF;
    }
    return hash;
  }
}

/// Parçaları tek bir SVG metninde birleştirir ve yer tutucu renkleri
/// değiştirir. [parts]: parça adı → dosya içeriği.
String composePortraitSvg(PortraitSpec spec, Map<String, String> parts) {
  final body = StringBuffer();
  for (final layer in spec.layers) {
    final svg = parts[layer];
    if (svg == null) continue;
    final start = svg.indexOf('>', svg.indexOf('<svg')) + 1;
    final end = svg.lastIndexOf('</svg>');
    if (start <= 0 || end < start) continue;
    body.write(svg.substring(start, end));
  }
  // Tek geçişte değiştirilir; yeni renk başka bir yer tutucuya denk gelse
  // bile ikinci kez değişmez.
  final tokens = RegExp(spec.colors.keys.map(RegExp.escape).join('|'));
  final inner = spec.colors.isEmpty
      ? body.toString()
      : body.toString().replaceAllMapped(
          tokens,
          (m) => spec.colors[m[0]!] ?? m[0]!,
        );
  return '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 200 200">'
      '$inner</svg>';
}
