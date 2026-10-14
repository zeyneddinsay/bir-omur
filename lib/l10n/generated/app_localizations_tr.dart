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
