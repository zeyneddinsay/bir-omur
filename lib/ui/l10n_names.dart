import '../content/turkish.dart';
import '../engine/engine.dart';
import '../l10n/generated/app_localizations.dart';
import '../models/models.dart';

/// Motorun döndürdüğü kimlikleri ARB metinlerine çevirir.
extension L10nNames on AppLocalizations {
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
    'is_ara' => action_is_ara,
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
