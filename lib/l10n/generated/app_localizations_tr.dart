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
  String get birthButton => 'Doğ';

  @override
  String get birthTagline => 'Bir hayat, binlerce küçük karar';

  @override
  String get birthPickGender => 'Başlamak için cinsiyet seç';

  @override
  String get albumSubtitle => 'Önceki hayatların ve rozetlerin';

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
  String get rollSuccess => 'Şans yüzüne güldü.';

  @override
  String get rollFail => 'Bu sefer olmadı.';

  @override
  String get rollLuck => 'Şans';

  @override
  String get rollOdds_yuksek => 'İhtimal yüksek';

  @override
  String get rollOdds_orta => 'İhtimal orta';

  @override
  String get rollOdds_dusuk => 'İhtimal düşük';

  @override
  String rollChoiceLine(String stat) {
    return '$stat zarı';
  }

  @override
  String get previewIfSuccess => 'Tutarsa';

  @override
  String get previewIfFail => 'Tutmazsa';

  @override
  String get previewThread => 'Devamı var';

  @override
  String get previewThreadTooltip => 'Bu seçimin devamı ileride gelecek.';

  @override
  String previewMemoryTooltip(String name) {
    return '$name bunu hatırlayacak';
  }

  @override
  String previewStatUp(String stat) {
    return '$stat artar';
  }

  @override
  String previewStatDown(String stat) {
    return '$stat azalır';
  }

  @override
  String get previewWork => 'İşteki performans';

  @override
  String get previewBusiness => 'İşletmenin itibarı';

  @override
  String get previewGold => 'Altın';

  @override
  String get previewHouse => 'Ev';

  @override
  String get previewCar => 'Araba';

  @override
  String get themeName_aile => 'Aile';

  @override
  String get themeName_okul => 'Okul';

  @override
  String get themeName_ask => 'Aşk';

  @override
  String get themeName_isHayati => 'İş';

  @override
  String get themeName_para => 'Para';

  @override
  String get themeName_mahalle => 'Mahalle';

  @override
  String get themeName_saglik => 'Sağlık';

  @override
  String get themeName_genel => 'Hayat';

  @override
  String get rarityNadir => 'Nadir';

  @override
  String get rarityEfsane => 'Efsane';

  @override
  String get outcomeClose => 'Kapat';

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
  String get actionBlocked_kredi =>
      'Kredi çıkmıyor: taksit gelirinin yarısını geçer';

  @override
  String get actionBlocked_gelir =>
      'Gelirin kirayı ve geçimi karşılamıyor (önce iş ya da birikim)';

  @override
  String get moveBlocked_gelir =>
      'Orada ailen yok; gelirin kirayı ve geçimi karşılamıyor';

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
  String get action_kpss => 'KPSS\'ye gir';

  @override
  String get action_yazilim_kursu => 'Yazılım kursuna yazıl';

  @override
  String get action_tanis => 'Biriyle tanış';

  @override
  String get action_ara_is => 'Ara işlere git';

  @override
  String get action_yarim_zamanli => 'Yarı zamanlı çalış';

  @override
  String get action_evden_cik => 'Evden çık, kiraya geç';

  @override
  String get action_ev_arkadasi => 'Ev arkadaşıyla otur';

  @override
  String get action_aileye_don => 'Aile evine dön';

  @override
  String get action_ev_al => 'Ev al (peşinat, kalanı kredi)';

  @override
  String get action_ev_sat => 'Evi sat';

  @override
  String get action_araba_al => 'Araba al (peşinat, kalanı kredi)';

  @override
  String get action_araba_sat => 'Arabayı sat';

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
  String get settingsNewLife => 'Yeni hayat başlat';

  @override
  String get settingsNewLifeHint => 'Bu hayatı bırakıp doğum ekranına dön';

  @override
  String get newLifeConfirmTitle => 'Yeni bir hayata mı başlıyorsun?';

  @override
  String get newLifeConfirmBody =>
      'Bu hayat yarıda kalır; albüme ve rozetlere sayılmaz.';

  @override
  String get newLifeConfirm => 'Yeni hayat';

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
  String get jobOwnBusiness => 'Kendi işinde';

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
  String get home_aile => 'Ailenle yaşıyorsun';

  @override
  String get home_aileEvi => 'Aile evinde yaşıyorsun';

  @override
  String get home_yurt => 'Yurtta kalıyorsun';

  @override
  String get home_evArkadasi => 'Ev arkadaşınla kirada';

  @override
  String get home_kira => 'Kirada yaşıyorsun';

  @override
  String get home_kendiEvi => 'Kendi evinde yaşıyorsun';

  @override
  String homeCity(String city, String type) {
    return '$city ($type)';
  }

  @override
  String get cityType_buyuk => 'büyükşehir';

  @override
  String get cityType_orta => 'orta şehir';

  @override
  String get cityType_kucuk => 'küçük şehir';

  @override
  String homeCosts(String rent, String living) {
    return 'Yıllık kira $rent · yaşam gideri $living';
  }

  @override
  String get moveButton => 'Başka şehre taşın';

  @override
  String get moveTitle => 'Nereye taşınacaksın?';

  @override
  String moveCost(String money) {
    return 'Nakliye ve depozito $money · 2 vakit';
  }

  @override
  String get moveJobWarning => 'Taşınınca şu anki işinden ayrılırsın.';

  @override
  String get moveWithFamilyTitle => 'Ailen bu şehirde';

  @override
  String get moveWithFamily => 'Ailemin yanına';

  @override
  String get moveRent => 'Kendime ev tutarım';

  @override
  String get moveBlocked_vakit => 'Bu yılın vakti yetmiyor';

  @override
  String get moveBlocked_para => 'Paran yetmiyor';

  @override
  String get moveBlocked_yas => '18 yaşından önce taşınamazsın';

  @override
  String get moveBlocked_ogrenci => 'Okurken okulunun şehrinden taşınamazsın';

  @override
  String get moveBlocked_evSahibi => 'Önce evini satmalısın';

  @override
  String get moveBlocked_ayniSehir => 'Zaten burada yaşıyorsun';

  @override
  String get ledgerTitle => 'Para hareketleri';

  @override
  String ledgerThisYear(int age) {
    return 'Bu yıl ($age yaş)';
  }

  @override
  String ledgerLastYear(int age) {
    return 'Geçen yıl ($age yaş)';
  }

  @override
  String get ledgerEmpty => 'Para hareketi yok.';

  @override
  String get ledgerInflationHint =>
      'Nakit her yıl enflasyonun yarısı kadar erir; altın ve ev değerini korur.';

  @override
  String get ledgerTotal => 'Toplam';

  @override
  String get money_maas => 'Maaş';

  @override
  String get money_tazminat => 'Kıdem tazminatı';

  @override
  String get money_esGeliri => 'Eşinin hane bütçesine katkısı';

  @override
  String get money_cocuk => 'Çocukların gideri';

  @override
  String get money_faiz => 'Borcun faizi';

  @override
  String get money_emekliAyligi => 'Emekli aylığı';

  @override
  String get money_yasliAyligi => '65 yaş aylığı';

  @override
  String get money_harclik => 'Aileden harçlık';

  @override
  String get money_araIs => 'Ara işler, yevmiyeler';

  @override
  String get money_burs => 'Burs';

  @override
  String get money_yarimZamanli => 'Yarı zamanlı iş';

  @override
  String get money_aileDestegi => 'Ailenin 18 yaş desteği';

  @override
  String get money_kira => 'Kira';

  @override
  String get money_yasamGideri => 'Yaşam gideri';

  @override
  String get money_kredi => 'Kredi taksidi';

  @override
  String get money_araba => 'Araba masrafı';

  @override
  String get money_enflasyon => 'Enflasyon nakitten eritti';

  @override
  String get money_terfi => 'Terfi için yatırım';

  @override
  String money_olay(String label) {
    return 'Seçimin: “$label”';
  }

  @override
  String money_is(String what) {
    return 'İş: $what';
  }

  @override
  String money_tasinma(String city) {
    return 'Taşınma: $city';
  }

  @override
  String money_varlik(String what) {
    return '$what';
  }

  @override
  String get lastYearTitle => 'Yıl başı';

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
  String get nickname_patron => 'Patron';

  @override
  String get nickname_herkesinDostu => 'Herkesin Dostu';

  @override
  String get nickname_gurbetciRuhlu => 'Gurbetçi Ruhlu';

  @override
  String get storyTitle => 'Hayatındaki insanlar';

  @override
  String storyBedside(String relation, String name) {
    return 'Son gününde $relation $name yanındaydı.';
  }

  @override
  String get storyAlone => 'Son gününü sessizce, kendi köşesinde geçirdi.';

  @override
  String storyFuneral(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Cenazene $count kişi geldi.',
      zero: 'Cenaze sessiz geçti.',
    );
    return '$_temp0';
  }

  @override
  String storyFuneralFriends(String names) {
    return 'En önde $names vardı.';
  }

  @override
  String storyCameAnyway(String name) {
    return 'Küs olduğun $name bile gelmiş, en arkada durmuş.';
  }

  @override
  String get storyStrangers => 'Hiç tanımadığın üç akraba da oradaydı.';

  @override
  String storyClosest(String names) {
    return 'En yakınların: $names';
  }

  @override
  String storyTrueFriend(String name) {
    return 'Herkes gitti, $name kaldı.';
  }

  @override
  String storyMissed(String name) {
    return 'Seni en çok $name özleyecek.';
  }

  @override
  String storyBusinesses(String list) {
    return 'Kurduğun işler: $list';
  }

  @override
  String businessEnd_acik(String name) {
    return '$name (hâlâ açık)';
  }

  @override
  String businessEnd_birakildi(String name) {
    return '$name (devrettin)';
  }

  @override
  String businessEnd_batti(String name) {
    return '$name (battı)';
  }

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
  String get dept_bilgisayar => 'Bilgisayar Mühendisliği';

  @override
  String get dept_iktisat => 'İktisat';

  @override
  String get dept_hemsirelik => 'Hemşirelik';

  @override
  String get dept_isletme => 'İşletme';

  @override
  String get dept_kamu_yonetimi => 'Kamu Yönetimi';

  @override
  String get dept_tarih => 'Tarih';

  @override
  String get dept_acikogretim => 'Açıköğretim İşletme';

  @override
  String get school_duz => 'Mahalledeki lise';

  @override
  String get school_anadolu => 'Anadolu lisesi';

  @override
  String get school_fen => 'Fen lisesi';

  @override
  String get school_meslek => 'Meslek lisesi';

  @override
  String get eduTitle => 'Okul';

  @override
  String eduYks(int score) {
    return 'YKS puanın: $score';
  }

  @override
  String eduUni(String dept, String city, int year) {
    return '$dept · $city · $year. sınıf';
  }

  @override
  String eduGraduate(String dept) {
    return '$dept mezunu';
  }

  @override
  String eduScholarship(String money) {
    return 'Burs: yılda $money';
  }

  @override
  String get eduApprentice => 'Bir ustanın yanında çıraksın.';

  @override
  String get eduOpen => 'Açıköğretimle evden okuyorsun.';

  @override
  String get tercihButton => 'Tercihini yap';

  @override
  String get tercihPending =>
      'YKS sonucun açıklandı. Okul / İş sekmesinden tercihini yap; yapmadan yaşlanırsan okumadan çalışmayı seçmiş sayılırsın.';

  @override
  String tercihTitle(int score) {
    return 'YKS tercihi: $score puan';
  }

  @override
  String get tercihPrompt =>
      'Puanının yettiği bölümler. Bir bölüme, sonra şehre dokun.';

  @override
  String get tercihNone => 'Puanın bu yıl hiçbir bölüme yetmedi.';

  @override
  String tercihCities(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count şehirde',
      one: '1 şehirde',
    );
    return '$_temp0 yerleşebilirsin';
  }

  @override
  String tercihCity(String city, String type, int score) {
    return '$city ($type) · taban $score';
  }

  @override
  String get tercihHome => 'Memleketinde: ailenin yanında okursun';

  @override
  String get tercihHomeOwn => 'Bu şehirde: kendi evinden okursun';

  @override
  String get tercihDorm => 'Yurtta kalırsın (yılda 60.000 TL)';

  @override
  String get tercihOthers => 'Ya da';

  @override
  String get tercih_mezunaKal => 'Mezuna kal, seneye yeniden gir';

  @override
  String get tercih_calis => 'Okumayacağım, çalışacağım';

  @override
  String get tercih_cirak => 'Bir ustanın yanına çırak gir';

  @override
  String note_lise(String school) {
    return '$school başladın.';
  }

  @override
  String note_yksPuani(String score) {
    return 'YKS puanın: $score.';
  }

  @override
  String note_yerlesti(String dept, String city) {
    return '$dept bölümüne yerleştin: $city.';
  }

  @override
  String get note_mezunaKaldi => 'Mezuna kaldın; seneye yeniden gireceksin.';

  @override
  String get note_cirakOldu => 'Bir ustanın yanına çırak girdin.';

  @override
  String get note_calismayiSecti => 'Okumak yerine çalışmayı seçtin.';

  @override
  String get note_dersKaldi => 'Bir ders alttan kaldı; okul bir yıl uzadı.';

  @override
  String note_mezunOldu(String dept) {
    return '$dept bölümünden mezun oldun.';
  }

  @override
  String note_eveDondu(String city) {
    return 'Okul bitti; $city şehrine, ailenin yanına döndün.';
  }

  @override
  String get note_askerlik =>
      'Askerlik bitti. Bölük arkadaşların artık İnsanlar sekmesinde.';

  @override
  String get jobCardTitle => 'İşin';

  @override
  String jobTitleLine(String title, String company) {
    return '$title · $company';
  }

  @override
  String jobSalary(String money) {
    return 'Yıllık maaş: $money';
  }

  @override
  String get jobPerformance => 'Performans';

  @override
  String get jobTempo => 'Çalışma temposu';

  @override
  String get tempo_rahat => 'Rahat';

  @override
  String get tempo_normal => 'Normal';

  @override
  String get tempo_yukle => 'Yüklen';

  @override
  String get tempoHint =>
      'Yüklenmek performansı hızla artırır; vakti 1 azaltır, sağlığı yorar. Rahat çalışan keyiflidir ama performansı düşer.';

  @override
  String get jobPromotion => 'Terfi iste (1 vakit)';

  @override
  String get jobRaise => 'Zam iste (1 vakit)';

  @override
  String get jobQuit => 'İstifa et';

  @override
  String get jobRetire => 'Emekli ol';

  @override
  String jobPromotionBlocked(String reason) {
    return 'Terfi: $reason';
  }

  @override
  String jobRaiseBlocked(String reason) {
    return 'Zam: $reason';
  }

  @override
  String get request_sonKademe => 'en üst kademedesin';

  @override
  String request_erken(int years) {
    String _temp0 = intl.Intl.pluralLogic(
      years,
      locale: localeName,
      other: '$years yıl daha beklemelisin',
      one: '1 yıl daha beklemelisin',
    );
    return '$_temp0';
  }

  @override
  String get request_sart => 'diploma ya da belge şartı eksik';

  @override
  String get request_performans => 'performansın yetmiyor';

  @override
  String get request_para => 'terfinin bedeline paran yetmiyor';

  @override
  String get request_tavan => 'bu kademede zam tavanı doldu';

  @override
  String get request_buYil => 'bu yıl sordun';

  @override
  String get request_vakit => 'vaktin yok';

  @override
  String get jobQuitConfirm =>
      'İstifa edersen maaşın kesilir; iş arkadaşların eski iş arkadaşın olur.';

  @override
  String get jobQuitYes => 'İstifa ediyorum';

  @override
  String get cancel => 'Vazgeç';

  @override
  String get jobFiredRisk =>
      'Performansın çok düşük; böyle giderse kovulabilirsin.';

  @override
  String get listingsTitle => 'İş ilanları';

  @override
  String get listingsEmpty => 'Bu yıl şehrinde ilan yok.';

  @override
  String listingSalary(String money) {
    return 'Yaklaşık $money / yıl';
  }

  @override
  String get listingSenior => 'Üst pozisyon';

  @override
  String get listingBlocked_sart => 'Bölümün, belgen ya da okulun tutmuyor';

  @override
  String get listingBlocked_yas => 'Yaş şartı tutmuyor';

  @override
  String get listingBlocked_ogrenci => 'Okul bitmeden tam zamanlı çalışamazsın';

  @override
  String get listingBlocked_ayniSirket => 'Zaten burada çalışıyorsun';

  @override
  String get listingBlocked_basvuruldu => 'Bu yıl başvurdun';

  @override
  String get listingBlocked_vakit => 'Bu yılın vakti bitti';

  @override
  String get listingBlocked_deneyim => 'Bu meslekte deneyimin yok';

  @override
  String get listingBlocked_emekli => 'Emeklisin';

  @override
  String get listingBlocked_askerde => 'Askerdesin';

  @override
  String interviewTitle(String company) {
    return 'Mülakat: $company';
  }

  @override
  String interviewReference(String name) {
    return '$name aracı olsun';
  }

  @override
  String get interviewReferenceHint =>
      'Tanıdığın biri bu işte çalışıyor. Torpille girersen itibarın biraz düşer.';

  @override
  String note_isBuldun(String company, String title) {
    return '$company işe aldı: $title.';
  }

  @override
  String note_mulakatOlmadi(String company) {
    return '$company mülakatından olumsuz döndün.';
  }

  @override
  String note_terfi(String title) {
    return 'Terfi aldın: $title.';
  }

  @override
  String get note_terfiReddi => 'Terfi istedin; \'Şimdilik değil\' dediler.';

  @override
  String get note_terfiZamaniDegil =>
      'Terfi için erken: kademede biraz daha durmalı, performansını ve bilgini artırmalısın.';

  @override
  String get note_zam => 'Zam aldın; maaşın yüzde 10 arttı.';

  @override
  String get note_zamReddi => 'Zam istedin; \'Bütçe yok\' dediler.';

  @override
  String get note_zamZamaniDegil => 'Zam için performansın yetmedi.';

  @override
  String get note_kovuldun =>
      'İşten çıkarıldın. Performansın uzun süredir düşüktü.';

  @override
  String get note_istifa => 'İstifa ettin.';

  @override
  String get note_emekliOldun => 'Emekli oldun.';

  @override
  String get note_kpssGecti =>
      'KPSS\'yi geçtin; memur ilanlarına başvurabilirsin.';

  @override
  String get note_kpssKaldi => 'KPSS bu yıl olmadı.';

  @override
  String get note_yazilimKursu =>
      'Yazılım kursunu bitirdin; yazılımcı ilanlarına başvurabilirsin.';

  @override
  String get business_simit => 'Simit ve çay tezgâhı';

  @override
  String get business_berber => 'Berber salonu';

  @override
  String get business_oto_yikama => 'Oto yıkama';

  @override
  String get business_yazilim => 'Yazılım şirketi (tek başına)';

  @override
  String get business_yazilim_ekip => 'Yazılım şirketi (ekiple)';

  @override
  String get businessTitle => 'Kendi işin';

  @override
  String businessSign(String surname, String type) {
    return '$surname · $type';
  }

  @override
  String get businessOpenTitle => 'İşletme aç';

  @override
  String get businessOpenHint =>
      'Paran yetmezse kuruluşun %70\'ine kadar kredi çekilir (5 yıl). İşi olan ya da itibarı 50 ve üstü olana kredi verilir.';

  @override
  String businessSetup(String money, String profit) {
    return 'Kuruluş $money · normal yılda yaklaşık $profit kâr';
  }

  @override
  String get businessBlocked_yas => 'Yaşın tutmuyor';

  @override
  String get businessBlocked_sart =>
      'Yazılımcı olarak çalışmış ya da bilgisayar mezunu olmalısın';

  @override
  String get businessBlocked_para => 'Peşinata bile paran yetmiyor';

  @override
  String get businessBlocked_zatenVar => 'Bu işletmen zaten var';

  @override
  String get businessBlocked_cokFazla => 'En fazla iki işletme';

  @override
  String get businessBlocked_iflas => 'Bu işte batalı iki yıl olmadı';

  @override
  String get businessBlocked_yeniKapandi => 'Bu işi bırakalı iki yıl olmadı';

  @override
  String get businessBlocked_kredi =>
      'Peşinat var ama kredi çıkmaz: bir iş ya da 50 itibar gerekir';

  @override
  String get businessBlocked_vakit => 'Bu yılın vakti yetmiyor (2 vakit)';

  @override
  String get businessBlocked_askerde => 'Askerdesin';

  @override
  String businessLastProfit(String money) {
    return 'Geçen yıl: $money';
  }

  @override
  String businessExpected(String money) {
    return 'Bu yıl beklenen: $money';
  }

  @override
  String get businessReputation => 'İtibar';

  @override
  String businessFacts(int branches, int staff, int rivals) {
    return '$branches şube · $staff çalışan · yakında $rivals rakip';
  }

  @override
  String get businessPresent => 'Başındayım';

  @override
  String get businessManaged => 'Müdürde';

  @override
  String get businessLaborHint => 'Emek işi: başında durmazsan müşteri azalır.';

  @override
  String businessManagedHint(String money) {
    return 'Başında durmak vaktini 2\'ye (işin de varsa 1\'e) indirir; müdüre bırakmak yılda $money maaş ister.';
  }

  @override
  String get price_ucuz => 'Ucuz';

  @override
  String get price_normal => 'Normal';

  @override
  String get price_pahali => 'Pahalı';

  @override
  String businessAdvertise(String money) {
    return 'Reklam ver · $money · 1 vakit';
  }

  @override
  String businessExpand(String money) {
    return 'Şube aç · $money · 2 vakit';
  }

  @override
  String businessUpgrade(String money) {
    return 'Ekip kur · $money · 2 vakit';
  }

  @override
  String get businessPartner => 'Ortak al';

  @override
  String businessPartnerOffer(String name, String money) {
    return '$name: $money koyar, kârın %30\'u onun';
  }

  @override
  String businessPartnerNow(String name) {
    return 'Ortağın: $name';
  }

  @override
  String businessSell(String money) {
    return 'Sat · $money';
  }

  @override
  String businessClose(String money) {
    return 'Kapat · $money';
  }

  @override
  String get businessDisposeConfirm =>
      'Emin misin? Çalışanların eski çalışanın olur.';

  @override
  String get businessDisposeYes => 'Evet';

  @override
  String note_isletmeAcildi(String name) {
    return '$name açıldı. Hayırlı olsun!';
  }

  @override
  String note_isletmeKar(String name, String money) {
    return '$name bu yıl $money kâr etti.';
  }

  @override
  String note_isletmeZarar(String name, String money) {
    return '$name bu yıl $money zarar etti.';
  }

  @override
  String note_isletmeBatti(String name) {
    return '$name battı. Kepenkler indi; borçlar kaldı.';
  }

  @override
  String note_isletmeSatildi(String name) {
    return '$name satıldı.';
  }

  @override
  String note_isletmeKapandi(String name) {
    return '$name kapandı.';
  }

  @override
  String note_subeAcildi(String name) {
    return '$name yeni bir şube açtı.';
  }

  @override
  String note_isletmeBuyudu(String name) {
    return '$name artık bir ekip.';
  }

  @override
  String note_ortakAlindi(String person, String name) {
    return '$person işine ortak oldu: $name.';
  }

  @override
  String note_iplikVefat(String name) {
    return '$name vefat etti; aranızda yarım kalan mesele de onunla kapandı.';
  }

  @override
  String note_iplikAyrildi(String name) {
    return '$name artık hayatında değil; aranızdaki o mesele yarım kaldı.';
  }

  @override
  String note_dunyaKucuk(String name, String role, String since) {
    return 'Dünya küçük: $name artık $role. Onu $since tanıyorsun.';
  }

  @override
  String get worldSmall_mudur => 'işletmenin müdürü';

  @override
  String get since_aile => 'aileden';

  @override
  String get since_okul => 'okuldan';

  @override
  String get since_universite => 'üniversiteden';

  @override
  String get since_askerlik => 'askerden';

  @override
  String get since_isYeri => 'eski bir işten';

  @override
  String get since_mahalle => 'mahalleden';

  @override
  String get since_tesaduf => 'bir tesadüften';

  @override
  String get since_araci => 'bir tanıdık sayesinde';

  @override
  String get since_kendin => 'eskiden';

  @override
  String get note_zorGun_borc =>
      'Zor bir yıl: borca battın. Kim aradı, kim aramadı; unutmayacaksın.';

  @override
  String get note_zorGun_kovuldun =>
      'Zor bir yıl: işten çıkarıldın. Kim aradı, kim aramadı; unutmayacaksın.';

  @override
  String get note_zorGun_iflas =>
      'Zor bir yıl: işletmen battı. Kim aradı, kim aramadı; unutmayacaksın.';

  @override
  String note_zorGun_vefat(String name) {
    return 'Zor bir yıl: $name artık yok. Kim aradı, kim aramadı; unutmayacaksın.';
  }

  @override
  String get note_zorGun_bunalim =>
      'Zor bir yıl: içinden hiçbir şey gelmiyor. Kim aradı, kim aramadı; unutmayacaksın.';

  @override
  String note_evlendin(String name) {
    return '$name ile evlendiniz.';
  }

  @override
  String note_bebek(String name) {
    return 'Bebeğinizin adı $name oldu.';
  }

  @override
  String note_iseAldin(String person, String name) {
    return '$person, $name işinde çalışmaya başladı.';
  }

  @override
  String get businessHire => 'Tanıdığını işe al (1 vakit)';

  @override
  String get businessHireHint =>
      'Tanıdık güvenilir ama kovması zor: bir çalışanın yerine geçer.';

  @override
  String money_isletme(String name, String what) {
    return '$name: $what';
  }

  @override
  String get bizMoney_kar => 'yılın kârı';

  @override
  String get bizMoney_kredi => 'kredi taksidi';

  @override
  String get bizMoney_kurulus => 'kuruluş';

  @override
  String get bizMoney_reklam => 'reklam';

  @override
  String get bizMoney_sube => 'büyüme';

  @override
  String get bizMoney_ortak => 'ortağın sermayesi';

  @override
  String get bizMoney_satis => 'satış';

  @override
  String get bizMoney_kapanis => 'kapanış';

  @override
  String get bizMoney_iflas => 'batış, ekipman satıldı';

  @override
  String get journalTitle => 'Bu yılın günlüğü';

  @override
  String get journalEmpty => 'Sakin bir yıl. Kimseden ses yok.';

  @override
  String journalChoice(String label) {
    return 'Seçimin: “$label”';
  }

  @override
  String journalChoiceWith(String event, String label) {
    return '$event → “$label”';
  }

  @override
  String news_kardesDogdu(String name) {
    return '$name doğdu. Artık bir kardeşin var.';
  }

  @override
  String news_kardesDogduYine(String name) {
    return 'Bir kardeşin daha oldu: $name.';
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
  String news_yegenDogdu(String name) {
    return 'Yeğenin $name dünyaya geldi.';
  }

  @override
  String news_torunDogdu(String name) {
    return 'Torunun $name dünyaya geldi!';
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
  String get role_evArkadasi => 'Ev arkadaşın';

  @override
  String get role_bolukArkadasi => 'Bölük arkadaşın';

  @override
  String get role_patron => 'Patronun';

  @override
  String get role_amir => 'Amirin';

  @override
  String get role_usta => 'Ustan';

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
  String get interaction_acil => 'Duygularını açıkla';

  @override
  String get interaction_ciddi => 'Ciddiyim, de';

  @override
  String get interaction_bosan => 'Boşan';

  @override
  String divorceConfirm(String amount) {
    return 'Boşanırsan birikimin yarısı ($amount) ona kalır. Emin misin?';
  }

  @override
  String breakUpConfirm(String name) {
    return '$name ile ayrılmak istediğine emin misin?';
  }

  @override
  String get breakUpYes => 'Evet, ayrılıyorum';

  @override
  String get interaction_teklif => 'Evlenme teklif et';

  @override
  String get interaction_ayril => 'Ayrıl';

  @override
  String get interaction_cocukIste => 'Çocuk isteyelim mi?';

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
  String get blocked_erken => 'Daha erken; birbirinizi biraz daha tanıyın';

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
