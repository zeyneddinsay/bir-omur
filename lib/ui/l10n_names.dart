import '../content/turkish.dart';
import '../engine/engine.dart';
import '../l10n/generated/app_localizations.dart';
import '../models/models.dart';

/// Motorun döndürdüğü kimlikleri ARB metinlerine çevirir.
extension L10nNames on AppLocalizations {
  String rollOddsName(RollOdds odds) => switch (odds) {
    RollOdds.yuksek => rollOdds_yuksek,
    RollOdds.orta => rollOdds_orta,
    RollOdds.dusuk => rollOdds_dusuk,
  };

  String themeName(EventTheme theme) => switch (theme) {
    EventTheme.aile => themeName_aile,
    EventTheme.okul => themeName_okul,
    EventTheme.ask => themeName_ask,
    EventTheme.isHayati => themeName_isHayati,
    EventTheme.para => themeName_para,
    EventTheme.mahalle => themeName_mahalle,
    EventTheme.saglik => themeName_saglik,
    EventTheme.genel => themeName_genel,
  };

  /// Sıradan kartta etiket yok.
  String? rarityName(Rarity rarity) => switch (rarity) {
    Rarity.siradan => null,
    Rarity.nadir => rarityNadir,
    Rarity.efsane => rarityEfsane,
  };

  String statName(StatKind kind) => switch (kind) {
    StatKind.health => statHealth,
    StatKind.happiness => statHappiness,
    StatKind.knowledge => statKnowledge,
    StatKind.reputation => statReputation,
    StatKind.family => statFamily,
  };

  String stageName(LifeStage stage) => switch (stage) {
    LifeStage.bebek => stageBebek,
    LifeStage.ilkokul => stageIlkokul,
    LifeStage.ortaokul => stageOrtaokul,
    LifeStage.lise => stageLise,
    LifeStage.genc => stageGenc,
    LifeStage.yetiskin => stageYetiskin,
    LifeStage.olgun => stageOlgun,
    LifeStage.yasli => stageYasli,
  };

  /// Aksiyon kimlikleri koddaki listeden gelir; karşılığı yoksa null döner
  /// (testler her aksiyonun bir adı olduğunu denetler).
  String? actionName(String id) => switch (id) {
    'oyun_oyna' => action_oyun_oyna,
    'ders_calis' => action_ders_calis,
    'fazla_mesai' => action_fazla_mesai,
    'kitap_oku' => action_kitap_oku,
    'spor' => action_spor,
    'doktor_kontrolu' => action_doktor_kontrolu,
    'yuruyus' => action_yuruyus,
    'tatil' => action_tatil,
    'altin_al' => action_altin_al,
    'altin_sat' => action_altin_sat,
    'ara_is' => action_ara_is,
    'yarim_zamanli' => action_yarim_zamanli,
    'evden_cik' => action_evden_cik,
    'ev_arkadasi' => action_ev_arkadasi,
    'aileye_don' => action_aileye_don,
    'ev_al' => action_ev_al,
    'ev_sat' => action_ev_sat,
    'araba_al' => action_araba_al,
    'araba_sat' => action_araba_sat,
    'kpss' => action_kpss,
    'yazilim_kursu' => action_yazilim_kursu,
    'tanis' => action_tanis,
    _ => null,
  };

  /// Zarın baktığı değerin adı: "Bilgi", "Şans"…
  String rollStatName(RollStat stat) => switch (stat.statKind) {
    final kind? => statName(kind),
    null => rollLuck,
  };

  String actionBlockedReason(ActionBlocked blocked) => switch (blocked) {
    ActionBlocked.vakit => actionBlocked_vakit,
    ActionBlocked.para => actionBlocked_para,
    ActionBlocked.buYil => actionBlocked_buYil,
    ActionBlocked.isYok => actionBlocked_isYok,
    ActionBlocked.kredi => actionBlocked_kredi,
    ActionBlocked.gelir => actionBlocked_gelir,
  };

  String backgroundName(FamilyBackground background) => switch (background) {
    FamilyBackground.varlikli => background_varlikli,
    FamilyBackground.orta => background_orta,
    FamilyBackground.dar => background_dar,
  };

  String nicknameName(Nickname nickname) => switch (nickname) {
    Nickname.asirlikCinar => nickname_asirlikCinar,
    Nickname.mahalleninZengini => nickname_mahalleninZengini,
    Nickname.evSahibi => nickname_evSahibi,
    Nickname.sozuDinlenen => nickname_sozuDinlenen,
    Nickname.bayramlarinBasKosesi => nickname_bayramlarinBasKosesi,
    Nickname.mahalleninProfesoru => nickname_mahalleninProfesoru,
    Nickname.hepGulen => nickname_hepGulen,
    Nickname.borcYigidinKamcisi => nickname_borcYigidinKamcisi,
    Nickname.bizimBolukte => nickname_bizimBolukte,
    Nickname.patron => nickname_patron,
    Nickname.herkesinDostu => nickname_herkesinDostu,
    Nickname.gurbetciRuhlu => nickname_gurbetciRuhlu,
    Nickname.mahalleninBildikYuzu => nickname_mahalleninBildikYuzu,
  };

  /// Ölüm metni; 50 yaşından önce "huzur içinde, zamanı geldiğinde" denmez.
  String deathCauseText(DeathCause cause, {required int age}) =>
      switch (cause) {
        DeathCause.health => deathCauseHealth,
        DeathCause.natural when age < earlyDeathAge => deathCauseEarly,
        DeathCause.natural => deathCauseNatural,
      };

  static const int earlyDeathAge = 50;
}

/// Türkçe büyük harf: `toUpperCase()` "i" harfini "I" yapar; Türkçede
/// "İ" olmalı (ve "ı" → "I").
extension TurkishCase on String {
  String toUpperTr() => upperTr(this);
}
