import '../../content/person_text.dart';
import '../../engine/engine.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../models/models.dart';
import 'people_view.dart';

/// Kişilerle ilgili motor kimliklerini ARB metinlerine çevirir.
extension PeopleNames on AppLocalizations {
  String groupName(PeopleGroup group) => switch (group) {
    PeopleGroup.aile => group_aile,
    PeopleGroup.okul => group_okul,
    PeopleGroup.arkadaslar => group_arkadaslar,
    PeopleGroup.mahalle => group_mahalle,
    PeopleGroup.eski => group_eski,
    PeopleGroup.vefat => group_vefat,
  };

  String roleName(RoleKind kind) => switch (kind) {
    RoleKind.siraArkadasi => role_siraArkadasi,
    RoleKind.sinifArkadasi => role_sinifArkadasi,
    RoleKind.ogretmen => role_ogretmen,
    RoleKind.odaArkadasi => role_odaArkadasi,
    RoleKind.evArkadasi => role_evArkadasi,
    RoleKind.bolukArkadasi => role_bolukArkadasi,
    RoleKind.patron => role_patron,
    RoleKind.mudur => role_mudur,
    RoleKind.isArkadasi => role_isArkadasi,
    RoleKind.calisan => role_calisan,
    RoleKind.musteri => role_musteri,
    RoleKind.ortak => role_ortak,
    RoleKind.rakip => role_rakip,
    RoleKind.komsu => role_komsu,
    RoleKind.bakkal => role_bakkal,
    RoleKind.muhtar => role_muhtar,
    RoleKind.evSahibi => role_evSahibi,
    RoleKind.kiraci => role_kiraci,
    RoleKind.doktor => role_doktor,
  };

  String bondName(Bond bond) => switch (bond) {
    Bond.tanidik => bond_tanidik,
    Bond.arkadas => bond_arkadas,
    Bond.yakinArkadas => bond_yakinArkadas,
    Bond.flort => bond_flort,
    Bond.sevgili => bond_sevgili,
    Bond.nisanli => bond_nisanli,
    Bond.eskiSevgili => bond_eskiSevgili,
    Bond.eskiEs => bond_eskiEs,
  };

  String colorName(RelationColor color) => switch (color) {
    RelationColor.dost => color_dost,
    RelationColor.kiskancYakin => color_kiskancYakin,
    RelationColor.tanidik => color_tanidik,
    RelationColor.dusman => color_dusman,
  };

  String traitName(Trait trait) => switch (trait) {
    Trait.kiskanc => trait_kiskanc,
    Trait.comert => trait_comert,
    Trait.cikarci => trait_cikarci,
    Trait.vefali => trait_vefali,
    Trait.dedikoducu => trait_dedikoducu,
    Trait.gamsiz => trait_gamsiz,
  };

  String interactionName(InteractionKind kind) => switch (kind) {
    InteractionKind.bulus => interaction_bulus,
    InteractionKind.ara => interaction_ara,
    InteractionKind.hediye => interaction_hediye,
    InteractionKind.dertles => interaction_dertles,
    InteractionKind.borcIste => interaction_borcIste,
    InteractionKind.borcOde => interaction_borcOde,
    InteractionKind.lafSok => interaction_lafSok,
    InteractionKind.uzaklas => interaction_uzaklas,
    InteractionKind.yemegiOv => interaction_yemegiOv,
    InteractionKind.macIzle => interaction_macIzle,
    InteractionKind.eliniOp => interaction_eliniOp,
    InteractionKind.kardesleOyna => interaction_kardesleOyna,
    InteractionKind.cayaGit => interaction_cayaGit,
  };

  String blockedReason(Blocked blocked) => switch (blocked) {
    Blocked.vakit => blocked_vakit,
    Blocked.yas => blocked_yas,
    Blocked.karsiYas => blocked_karsiYas,
    Blocked.para => blocked_para,
    Blocked.uzak => blocked_uzak,
    Blocked.yakinlikDusuk => blocked_yakinlikDusuk,
    Blocked.buYil => blocked_buYil,
    Blocked.borcVar => blocked_borcVar,
    Blocked.aniYok => blocked_aniYok,
    Blocked.kirginlikYok => blocked_kirginlikYok,
  };

  String toneName(CallTone tone) => switch (tone) {
    CallTone.halHatir => tone_halHatir,
    CallTone.nostalji => tone_nostalji,
    CallTone.ozur => tone_ozur,
    CallTone.igne => tone_igne,
  };

  String toneHint(CallTone tone) => switch (tone) {
    CallTone.halHatir => tone_halHatir_hint,
    CallTone.nostalji => tone_nostalji_hint,
    CallTone.ozur => tone_ozur_hint,
    CallTone.igne => tone_igne_hint,
  };

  /// Kişinin seninle bağı: "Annen", "Sınıf arkadaşın", "Eskiden: Öğretmenin".
  String relationOf(Person p) {
    if (PersonText.kinWord(p) case final kin?) {
      final word = PersonText.capitalizeFirst(kin);
      // "Deden" iki taraf için aynı; nine (anneanne, babaanne) zaten ayrı.
      return switch ((p.kin, p.side)) {
        (Kinship.dede, Side.anne) => relationSide(word, side_anne),
        (Kinship.dede, Side.baba) => relationSide(word, side_baba),
        _ => word,
      };
    }
    if (PeopleView.friendBonds.contains(p.bond)) return bondName(p.bond!);
    if (PeopleView.mainRole(p) case final role?) {
      final name = roleName(role.kind);
      return role.active ? name : relationFormer(name);
    }
    return bondName(p.bond ?? Bond.tanidik);
  }

  /// Yıl günlüğünde bir haber. Akrabaysa "Deden", değilse adıyla anılır.
  String newsLine(
    PersonNews news,
    Character c, {
    required Map<String, String> occupations,
  }) {
    final p = c.people[news.personId];
    if (p == null) return '';
    final name = switch (PersonText.kinWord(p)) {
      final kin? => PersonText.capitalizeFirst(kin),
      null => p.name,
    };
    final fullName = '${p.name} ${p.surname}'.trim();
    return switch (news.kind) {
      NewsKind.kardesDogdu => news_kardesDogdu(p.name),
      NewsKind.yeniSinif => switch (news.detail) {
        'ilkokul' => news_yeniSinif_ilkokul(fullName),
        'ortaokul' => news_yeniSinif_ortaokul(fullName),
        _ => news_yeniSinif_lise(fullName),
      },
      NewsKind.evlendi => news_evlendi(name),
      NewsKind.tasindi => news_tasindi(name, news.detail ?? p.city),
      NewsKind.isBuldu => news_isBuldu(
        name,
        occupations[news.detail] ?? news.detail ?? '',
      ),
      NewsKind.emekliOldu => news_emekliOldu(name),
      NewsKind.vefat => news_vefat(name),
    };
  }
}
