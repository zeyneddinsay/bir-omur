// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class AppLocalizationsTr extends AppLocalizations {
  AppLocalizationsTr([String locale = 'tr']) : super(locale);

  @override
  String get appTitle => 'Bir Ömür';

  @override
  String get loadingCards => 'Kartlar karılıyor…';

  @override
  String contentError(String details) {
    return 'Kartlar yüklenemedi.\n$details';
  }

  @override
  String get birthTitle => 'Yeni bir hayat';

  @override
  String get birthSubtitle =>
      'Türkiye\'de bir yerde, bir ailede doğmak üzeresin.';

  @override
  String get birthNameLabel => 'İsim';

  @override
  String get birthNameHint => 'Boş bırakırsan ailen seçer';

  @override
  String get birthGenderLabel => 'Cinsiyet';

  @override
  String get genderMale => 'Erkek';

  @override
  String get genderFemale => 'Kadın';

  @override
  String get genderRandom => 'Rastgele';

  @override
  String get birthButton => 'Doğ';

  @override
  String get resumeTitle => 'Yarım kalan bir hayat var';

  @override
  String resumeLine(String name, int age) {
    return '$name, $age yaşında';
  }

  @override
  String get resumeButton => 'Kaldığın yerden devam et';

  @override
  String get resumeOrNew =>
      'Ya da yeni bir hayata başla; yarım kalan hayat silinir.';

  @override
  String get resumeFailed =>
      'Kayıt açılamadı. Yeni bir hayata başlayabilirsin.';

  @override
  String get statHealth => 'Sağlık';

  @override
  String get statHappiness => 'Mutluluk';

  @override
  String get statKnowledge => 'Bilgi';

  @override
  String get statReputation => 'İtibar';

  @override
  String get statFamily => 'Aile Bağı';

  @override
  String get statMoney => 'Para';

  @override
  String money(int amount) {
    final intl.NumberFormat amountNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String amountString = amountNumberFormat.format(amount);

    return '$amountString TL';
  }

  @override
  String ageLabel(int age) {
    return '$age yaş';
  }

  @override
  String get stageBebek => 'Bebeklik';

  @override
  String get stageIlkokul => 'İlkokul';

  @override
  String get stageOrtaokul => 'Ortaokul';

  @override
  String get stageLise => 'Lise';

  @override
  String get stageGenc => 'Genç yetişkin';

  @override
  String get stageYetiskin => 'Yetişkin';

  @override
  String get stageOlgun => 'Olgun';

  @override
  String get stageYasli => 'Yaşlılık';

  @override
  String get background_varlikli => 'Varlıklı aile';

  @override
  String get background_orta => 'Orta halli aile';

  @override
  String get background_dar => 'Dar gelirli aile';

  @override
  String hometownLine(String hometown, String team) {
    return '$hometown · $team';
  }

  @override
  String cardsLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count kart daha',
      one: 'son kart',
    );
    return 'Bu yıl $_temp0';
  }

  @override
  String get swipeHint => 'Kartı sola ya da sağa kaydır';

  @override
  String swipeUpHint(String label) {
    return 'Yukarı kaydır: $label';
  }

  @override
  String get rollSuccess => 'Şans yüzüne güldü.';

  @override
  String get rollFail => 'Bu sefer olmadı.';

  @override
  String get actionsTitle => 'Bu yıl ne yapacaksın?';

  @override
  String actionsLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count hakkın kaldı',
      one: '1 hakkın kaldı',
      zero: 'Bu yılın hakları bitti',
    );
    return '$_temp0';
  }

  @override
  String get actionFree => 'Ücretsiz';

  @override
  String moneyGain(int amount) {
    final intl.NumberFormat amountNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String amountString = amountNumberFormat.format(amount);

    return '+$amountString TL';
  }

  @override
  String get ageUpButton => 'Yaşlan';

  @override
  String get action_oyun_oyna => 'Oyun oyna';

  @override
  String get action_ders_calis => 'Ders çalış';

  @override
  String get action_fazla_mesai => 'Fazla mesai';

  @override
  String get action_aileyle_vakit => 'Ailenle vakit geçir';

  @override
  String get action_arkadaslarla_bulus => 'Arkadaşlarınla buluş';

  @override
  String get action_kitap_oku => 'Kitap oku';

  @override
  String get action_spor => 'Spor yap';

  @override
  String get action_doktor_kontrolu => 'Doktor kontrolü';

  @override
  String get action_yuruyus => 'Sahilde yürüyüş';

  @override
  String get action_memleket_ziyareti => 'Memleketi ziyaret et';

  @override
  String get action_tatil => 'Tatile çık';

  @override
  String get action_altin_al => '10 gram altın al';

  @override
  String get action_altin_sat => '10 gram altın sat';

  @override
  String get action_is_ara => 'İş ara';

  @override
  String jobFound(String career) {
    return 'İş buldun: $career';
  }

  @override
  String get jobNotFound => 'Bu yıl iş çıkmadı. Belki seneye.';

  @override
  String deathTitle(String name) {
    return '$name';
  }

  @override
  String deathLifespan(int age) {
    return '$age yıllık bir ömür';
  }

  @override
  String get deathCauseHealth =>
      'Bedeni daha fazla dayanamadı. Sevdikleri yanındaydı.';

  @override
  String get deathCauseNatural =>
      'Zamanı geldiğinde, huzur içinde gözlerini yumdu.';

  @override
  String get nicknameTitle => 'Mahalle onu şöyle hatırlıyor';

  @override
  String get biggestMomentTitle => 'En büyük an';

  @override
  String momentChoice(String label) {
    return 'Seçimin: $label';
  }

  @override
  String biggestMomentAge(int age) {
    return '$age yaşında';
  }

  @override
  String cardsSeenLine(int count) {
    return '$count karar, bir ömür';
  }

  @override
  String seedLine(int seed) {
    return 'Hayat tohumu: $seed';
  }

  @override
  String get rebirthButton => 'Yeniden doğ';

  @override
  String get settingsTitle => 'Ayarlar';

  @override
  String get settingsSound => 'Ses';

  @override
  String get settingsSoundHint => 'Kart, zar, terfi, rozet ve veda sesleri';

  @override
  String get settingsHaptics => 'Titreşim';

  @override
  String get settingsHapticsHint => 'Kart kaydırırken ve önemli anlarda';

  @override
  String get settingsLicenses => 'Lisanslar';

  @override
  String deathNetWorth(String amount) {
    return 'Net servet: $amount';
  }

  @override
  String get shareButton => 'Hayatını paylaş';

  @override
  String get deathBadgesTitle => 'Bu hayatta kazanılan rozetler';

  @override
  String get badgeNew => 'Yeni!';

  @override
  String get albumButton => 'Hayat Albümü';

  @override
  String get albumTitle => 'Hayat Albümü';

  @override
  String get albumTabLives => 'Hayatlar';

  @override
  String get albumTabBadges => 'Rozetler';

  @override
  String get albumEmpty =>
      'Henüz biten bir hayat yok. İlk hayatın burada duracak.';

  @override
  String albumLifeLine(int age, String nickname) {
    return '$age yaş · $nickname';
  }

  @override
  String badgeCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count kez kazanıldı',
      one: '1 kez kazanıldı',
    );
    return '$_temp0';
  }

  @override
  String get badgeLocked => 'Henüz kazanılmadı';

  @override
  String badgesSummary(int earned, int total) {
    return '$earned / $total rozet';
  }

  @override
  String get sharePreviewTitle => 'Hayat özeti';

  @override
  String get shareAction => 'Paylaş';

  @override
  String shareText(int age) {
    return 'Bir Ömür\'de $age yıllık bir hayat yaşadım. Sen nasıl bir ömür yaşardın?';
  }

  @override
  String get shareFailed => 'Paylaşım açılamadı.';

  @override
  String get shareNumbersTitle => 'Hayatın sayıları';

  @override
  String get shareFooter => 'Bir Ömür · Türkiye\'de bir hayat';

  @override
  String numMoves(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count kez taşındı',
      one: '1 kez taşındı',
    );
    return '$_temp0';
  }

  @override
  String numRent(String amount) {
    return '$amount kira ödedi';
  }

  @override
  String numGold(int grams) {
    return '$grams gram altın takıldı';
  }

  @override
  String numPromotions(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count kez terfi aldı',
      one: '1 kez terfi aldı',
    );
    return '$_temp0';
  }

  @override
  String numYearsWorked(int years) {
    return '$years yıl çalıştı';
  }

  @override
  String numNetWorth(String amount) {
    return 'Geride $amount bıraktı';
  }

  @override
  String amountMillion(String value) {
    return '$value milyon TL';
  }

  @override
  String amountThousand(String value) {
    return '$value bin TL';
  }

  @override
  String get jobNone => 'İşsiz';

  @override
  String get jobStudent => 'Üniversite öğrencisi';

  @override
  String get jobRetired => 'Emekli';

  @override
  String get jobChild => 'Okul çağında';

  @override
  String jobTier(String career, String tier) {
    return '$career · $tier';
  }

  @override
  String get assetsButton => 'Varlıklar';

  @override
  String get assetsTitle => 'Varlıkların';

  @override
  String get assetCash => 'Nakit';

  @override
  String get assetGold => 'Altın';

  @override
  String assetGoldValue(int grams, String value) {
    return '$grams gr · $value';
  }

  @override
  String get assetHouse => 'Ev';

  @override
  String assetHouseValue(int count, String value) {
    return '$count ev · $value';
  }

  @override
  String get assetCar => 'Araba';

  @override
  String assetCarValue(int count, String value) {
    return '$count araba · $value';
  }

  @override
  String get assetRent => 'Yıllık kira';

  @override
  String get assetLoan => 'Kredi';

  @override
  String assetLoanValue(String payment, int years) {
    return '$payment × $years yıl';
  }

  @override
  String get assetPension => 'Emekli aylığı (yıllık)';

  @override
  String get assetNetWorth => 'Net servet';

  @override
  String assetGoldPrice(String price) {
    return 'Altının gramı: $price';
  }

  @override
  String get assetNone => 'Yok';

  @override
  String get lastYearTitle => 'Geçen yıl';

  @override
  String lastYearIncome(String amount) {
    return 'Gelir $amount';
  }

  @override
  String lastYearRent(String amount) {
    return 'Kira $amount';
  }

  @override
  String lastYearLoan(String amount) {
    return 'Kredi $amount';
  }

  @override
  String lastYearInflation(int percent, String amount) {
    return 'Enflasyon %$percent; nakdinden $amount eridi';
  }

  @override
  String get lastYearPromoted => 'Terfi aldın!';

  @override
  String get lastYearRetired => 'Emekli oldun.';

  @override
  String get closeTooltip => 'Kapat';

  @override
  String get nickname_asirlikCinar => 'Asırlık Çınar';

  @override
  String get nickname_mahalleninZengini => 'Mahallenin Zengini';

  @override
  String get nickname_evSahibi => 'Kirasını Kendine Ödeyen';

  @override
  String get nickname_sozuDinlenen => 'Sözü Dinlenen';

  @override
  String get nickname_bayramlarinBasKosesi => 'Bayramların Baş Köşesi';

  @override
  String get nickname_mahalleninProfesoru => 'Mahallenin Profesörü';

  @override
  String get nickname_hepGulen => 'Hep Gülen';

  @override
  String get nickname_borcYigidinKamcisi => 'Borç Yiğidin Kamçısı';

  @override
  String get nickname_bizimBolukte => 'Bizim Bölükte';

  @override
  String get nickname_mahalleninBildikYuzu => 'Mahallenin Bildik Yüzü';
}
