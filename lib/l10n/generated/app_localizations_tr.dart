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
  String get outdatedSaveTitle => 'Yarım kalan hayat sürdürülemiyor';

  @override
  String get outdatedSaveBody =>
      'Bu hayat oyunun eski bir sürümünden kaldı. Bir Ömür artık insanlarla, anılarla ve yeni olaylarla işliyor; eski hayat bu düzene taşınamıyor. Albümün ve rozetlerin yerinde.';

  @override
  String get outdatedSaveDismiss => 'Anladım, yeni hayata başla';

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
  String get rollLuck => 'Şans';

  @override
  String rollBadge(String stat) {
    return 'Zar: $stat';
  }

  @override
  String rollBadgeTooltip(String stat) {
    return 'Bu seçeneğin sonucu zara ve $stat değerine bağlı; tutmayabilir.';
  }

  @override
  String rollResultLine(String stat, String result) {
    return '$stat zarı: $result';
  }

  @override
  String get actionsTitle => 'Bu yıl ne yapacaksın?';

  @override
  String timeLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Vakit: $count',
      zero: 'Bu yılın vakti bitti',
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
  String get actionBlocked_vakit => 'Bu yılın vakti yetmiyor';

  @override
  String get actionBlocked_para => 'Paran yetmiyor';

  @override
  String get actionBlocked_buYil => 'Bu yıl yaptın';

  @override
  String get actionBlocked_isYok => 'Bu yaşta başvurabileceğin bir iş kalmadı';

  @override
  String get ageUpButton => 'Yaşlan';

  @override
  String get action_oyun_oyna => 'Oyun oyna';

  @override
  String get action_ders_calis => 'Ders çalış';

  @override
  String get action_fazla_mesai => 'Fazla mesai';

  @override
  String get action_kitap_oku => 'Kitap oku';

  @override
  String get action_spor => 'Spor yap';

  @override
  String get action_doktor_kontrolu => 'Doktor kontrolü';

  @override
  String get action_yuruyus => 'Sahilde yürüyüş';

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
  String get deathCauseEarly =>
      'Hayatı erken bitti. Geride bıraktıkları onu hep anacak.';

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
  String get settingsAnalytics => 'Kullanım verisi paylaş';

  @override
  String get settingsAnalyticsHint =>
      'Oyunu dengelemek için; adın ya da iletişim bilgilerin gönderilmez';

  @override
  String get settingsCrashNote =>
      'Uygulama çökerse, hatayı bulabilmemiz için anonim bir çökme kaydı gönderilir.';

  @override
  String get consentTitle => 'Oyunu birlikte geliştirelim';

  @override
  String get consentBody =>
      'Bir hayatın ne kadar sürdüğünü, hangi rozetlerin kazanıldığını ve oyunun nerede zorlaştığını görmek için kullanım verisi toplamak istiyoruz. Adını ya da iletişim bilgilerini toplamayız. Kararını istediğin zaman Ayarlar\'dan değiştirebilirsin.';

  @override
  String get consentAccept => 'Olur';

  @override
  String get consentDecline => 'Hayır, teşekkürler';

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
  String get jobChild => 'Öğrenci';

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

  @override
  String get tabMe => 'Ben';

  @override
  String get tabPeople => 'İnsanlar';

  @override
  String get tabSchoolWork => 'Okul / İş';

  @override
  String get tabAssets => 'Varlıklar';

  @override
  String get tabActivities => 'Aktiviteler';

  @override
  String get noActionsHere => 'Bu yaşta burada yapacak bir şey yok.';

  @override
  String get journalTitle => 'Bu yılın günlüğü';

  @override
  String get journalEmpty => 'Sakin bir yıl. Kimseden ses yok.';

  @override
  String journalChoice(String label) {
    return 'Seçimin: “$label”';
  }

  @override
  String news_kardesDogdu(String name) {
    return '$name doğdu. Artık bir kardeşin var.';
  }

  @override
  String news_yeniSinif_ilkokul(String name) {
    return 'İlkokul başladı. Öğretmenin $name; yeni bir sınıfın var.';
  }

  @override
  String news_yeniSinif_ortaokul(String name) {
    return 'Ortaokul başladı. Yeni sınıf, yeni öğretmen: $name.';
  }

  @override
  String news_yeniSinif_lise(String name) {
    return 'Lise başladı. Yeni sınıf, yeni öğretmen: $name.';
  }

  @override
  String news_evlendi(String name) {
    return '$name evlendi.';
  }

  @override
  String news_tasindi(String name, String city) {
    return '$name taşındı. Yeni şehri: $city.';
  }

  @override
  String news_isBuldu(String name, String job) {
    return '$name iş buldu: $job.';
  }

  @override
  String news_emekliOldu(String name) {
    return '$name emekli oldu.';
  }

  @override
  String news_vefat(String name) {
    return '$name vefat etti.';
  }

  @override
  String get group_aile => 'Aile';

  @override
  String get group_okul => 'Okul';

  @override
  String get group_arkadaslar => 'Arkadaşlar';

  @override
  String get group_mahalle => 'Mahalle';

  @override
  String get group_eski => 'Eski tanıdıklar';

  @override
  String get group_vefat => 'Kaybettiklerin';

  @override
  String get peopleEmpty => 'Henüz kimseyi tanımıyorsun.';

  @override
  String get role_siraArkadasi => 'Sıra arkadaşın';

  @override
  String get role_sinifArkadasi => 'Sınıf arkadaşın';

  @override
  String get role_ogretmen => 'Öğretmenin';

  @override
  String get role_odaArkadasi => 'Oda arkadaşın';

  @override
  String get role_bolukArkadasi => 'Bölük arkadaşın';

  @override
  String get role_patron => 'Patronun';

  @override
  String get role_mudur => 'Müdürün';

  @override
  String get role_isArkadasi => 'İş arkadaşın';

  @override
  String get role_calisan => 'Çalışanın';

  @override
  String get role_musteri => 'Müşterin';

  @override
  String get role_ortak => 'Ortağın';

  @override
  String get role_rakip => 'Rakibin';

  @override
  String get role_komsu => 'Komşun';

  @override
  String get role_bakkal => 'Mahallenin bakkalı';

  @override
  String get role_muhtar => 'Muhtar';

  @override
  String get role_evSahibi => 'Ev sahibin';

  @override
  String get role_kiraci => 'Kiracın';

  @override
  String get role_doktor => 'Doktorun';

  @override
  String relationSide(String kin, String side) {
    return '$kin ($side)';
  }

  @override
  String get side_anne => 'anne tarafı';

  @override
  String get side_baba => 'baba tarafı';

  @override
  String relationFormer(String role) {
    return 'Eskiden: $role';
  }

  @override
  String get bond_tanidik => 'Tanıdık';

  @override
  String get bond_arkadas => 'Arkadaşın';

  @override
  String get bond_yakinArkadas => 'Yakın arkadaşın';

  @override
  String get bond_flort => 'Flörtün';

  @override
  String get bond_sevgili => 'Sevgilin';

  @override
  String get bond_nisanli => 'Nişanlın';

  @override
  String get bond_eskiSevgili => 'Eski sevgilin';

  @override
  String get bond_eskiEs => 'Eski eşin';

  @override
  String get color_dost => 'Dost';

  @override
  String get color_kiskancYakin => 'Sever ama kıskanır';

  @override
  String get color_tanidik => 'Tanıdık';

  @override
  String get color_dusman => 'Husumetli';

  @override
  String get trait_kiskanc => 'Kıskanç';

  @override
  String get trait_comert => 'Cömert';

  @override
  String get trait_cikarci => 'Çıkarcı';

  @override
  String get trait_vefali => 'Vefalı';

  @override
  String get trait_dedikoducu => 'Dedikoducu';

  @override
  String get trait_gamsiz => 'Gamsız';

  @override
  String personAge(int age) {
    return '$age yaşında';
  }

  @override
  String personDiedAt(int age) {
    return '$age yaşında vefat etti';
  }

  @override
  String personMet(int age) {
    return '$age yaşındayken tanıştınız';
  }

  @override
  String personLastContact(int years) {
    String _temp0 = intl.Intl.pluralLogic(
      years,
      locale: localeName,
      other: '$years yıldır görüşmüyorsunuz',
      one: 'Geçen yıl görüştünüz',
      zero: 'Bu yıl görüştünüz',
    );
    return '$_temp0';
  }

  @override
  String get personArchived =>
      'Uzun süredir görüşmüyorsunuz; rehberinde duruyor.';

  @override
  String get closenessLabel => 'Yakınlık';

  @override
  String get hostilityLabel => 'Husumet';

  @override
  String get traitsTitle => 'Kişiliği';

  @override
  String get memoriesTitle => 'Seninle ilgili hatırladıkları';

  @override
  String get memoriesEmpty => 'Henüz ortak bir anınız yok.';

  @override
  String memoryAge(int age) {
    return '$age yaşında';
  }

  @override
  String get memoryMine => 'Senin aklında kalan';

  @override
  String get memoryHealed => 'Yumuşadı';

  @override
  String get interactionsTitle => 'Ne yapacaksın?';

  @override
  String get interactionsAfterCards => 'Önce bu yılın olaylarını bitir.';

  @override
  String get interaction_bulus => 'Buluş';

  @override
  String get interaction_ara => 'Ara';

  @override
  String get interaction_hediye => 'Hediye al';

  @override
  String get interaction_dertles => 'Dertleş';

  @override
  String get interaction_borcIste => 'Borç iste';

  @override
  String get interaction_borcOde => 'Borcunu öde';

  @override
  String get interaction_lafSok => 'Laf sok';

  @override
  String get interaction_uzaklas => 'Uzaklaş';

  @override
  String get interaction_yemegiOv => 'Yemeğini öv';

  @override
  String get interaction_macIzle => 'Maç izle';

  @override
  String get interaction_eliniOp => 'Elini öp';

  @override
  String get interaction_kardesleOyna => 'Birlikte oyna';

  @override
  String get interaction_cayaGit => 'Çaya git';

  @override
  String interactionCost(int time) {
    String _temp0 = intl.Intl.pluralLogic(
      time,
      locale: localeName,
      other: '$time vakit',
      one: '1 vakit',
    );
    return '$_temp0';
  }

  @override
  String interactionCostMoney(int time, String money) {
    String _temp0 = intl.Intl.pluralLogic(
      time,
      locale: localeName,
      other: '$time vakit',
      one: '1 vakit',
    );
    return '$_temp0 · $money';
  }

  @override
  String get blocked_vakit => 'Bu yılın vakti bitti';

  @override
  String get blocked_yas => 'Bunun için çok küçüksün';

  @override
  String get blocked_karsiYas => 'O bunun için çok küçük';

  @override
  String get blocked_para => 'Paran yetmiyor';

  @override
  String get blocked_uzak => 'Başka şehirde yaşıyor';

  @override
  String get blocked_yakinlikDusuk => 'Bunu konuşacak kadar yakın değilsiniz';

  @override
  String get blocked_buYil => 'Bu yıl zaten yaptın';

  @override
  String get blocked_borcVar => 'Önce eski borç ödenmeli';

  @override
  String get blocked_aniYok => 'Bu tonda konuşacak bir anınız yok';

  @override
  String get blocked_kirginlikYok => 'Özür dileyecek bir kırgınlık yok';

  @override
  String get callTitle => 'Nasıl konuşacaksın?';

  @override
  String get callPickMemory => 'Hangi anıyı açacaksın?';

  @override
  String get tone_halHatir => 'Hal hatır sor';

  @override
  String get tone_nostalji => 'Eski günleri an';

  @override
  String get tone_ozur => 'Özür dile';

  @override
  String get tone_igne => 'İğnele';

  @override
  String get tone_halHatir_hint => 'Küçük ama sıcak bir yakınlık';

  @override
  String get tone_nostalji_hint => 'Ortak bir anıyı açarsın';

  @override
  String get tone_ozur_hint => 'Eski bir kırgınlığı kapatmayı denersin';

  @override
  String get tone_igne_hint => 'Eski bir meseleyi yüzüne vurursun';

  @override
  String get lastInteractionTitle => 'Son görüşmeniz';
}
