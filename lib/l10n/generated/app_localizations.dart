import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_tr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('tr')];

  /// Uygulamanın adı
  ///
  /// In tr, this message translates to:
  /// **'Bir Ömür'**
  String get appTitle;

  /// No description provided for @loadingCards.
  ///
  /// In tr, this message translates to:
  /// **'Kartlar karılıyor…'**
  String get loadingCards;

  /// No description provided for @contentError.
  ///
  /// In tr, this message translates to:
  /// **'Kartlar yüklenemedi.\n{details}'**
  String contentError(String details);

  /// No description provided for @birthTitle.
  ///
  /// In tr, this message translates to:
  /// **'Yeni bir hayat'**
  String get birthTitle;

  /// No description provided for @birthSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Türkiye\'de bir yerde, bir ailede doğmak üzeresin.'**
  String get birthSubtitle;

  /// No description provided for @birthNameLabel.
  ///
  /// In tr, this message translates to:
  /// **'İsim'**
  String get birthNameLabel;

  /// No description provided for @birthNameHint.
  ///
  /// In tr, this message translates to:
  /// **'Boş bırakırsan ailen seçer'**
  String get birthNameHint;

  /// No description provided for @birthGenderLabel.
  ///
  /// In tr, this message translates to:
  /// **'Cinsiyet'**
  String get birthGenderLabel;

  /// No description provided for @genderMale.
  ///
  /// In tr, this message translates to:
  /// **'Erkek'**
  String get genderMale;

  /// No description provided for @genderFemale.
  ///
  /// In tr, this message translates to:
  /// **'Kadın'**
  String get genderFemale;

  /// No description provided for @genderRandom.
  ///
  /// In tr, this message translates to:
  /// **'Rastgele'**
  String get genderRandom;

  /// No description provided for @birthButton.
  ///
  /// In tr, this message translates to:
  /// **'Doğ'**
  String get birthButton;

  /// No description provided for @resumeTitle.
  ///
  /// In tr, this message translates to:
  /// **'Yarım kalan bir hayat var'**
  String get resumeTitle;

  /// No description provided for @resumeLine.
  ///
  /// In tr, this message translates to:
  /// **'{name}, {age} yaşında'**
  String resumeLine(String name, int age);

  /// No description provided for @resumeButton.
  ///
  /// In tr, this message translates to:
  /// **'Kaldığın yerden devam et'**
  String get resumeButton;

  /// No description provided for @resumeOrNew.
  ///
  /// In tr, this message translates to:
  /// **'Ya da yeni bir hayata başla; yarım kalan hayat silinir.'**
  String get resumeOrNew;

  /// No description provided for @resumeFailed.
  ///
  /// In tr, this message translates to:
  /// **'Kayıt açılamadı. Yeni bir hayata başlayabilirsin.'**
  String get resumeFailed;

  /// No description provided for @statHealth.
  ///
  /// In tr, this message translates to:
  /// **'Sağlık'**
  String get statHealth;

  /// No description provided for @statHappiness.
  ///
  /// In tr, this message translates to:
  /// **'Mutluluk'**
  String get statHappiness;

  /// No description provided for @statKnowledge.
  ///
  /// In tr, this message translates to:
  /// **'Bilgi'**
  String get statKnowledge;

  /// No description provided for @statReputation.
  ///
  /// In tr, this message translates to:
  /// **'İtibar'**
  String get statReputation;

  /// No description provided for @statFamily.
  ///
  /// In tr, this message translates to:
  /// **'Aile Bağı'**
  String get statFamily;

  /// No description provided for @statMoney.
  ///
  /// In tr, this message translates to:
  /// **'Para'**
  String get statMoney;

  /// No description provided for @money.
  ///
  /// In tr, this message translates to:
  /// **'{amount} TL'**
  String money(int amount);

  /// No description provided for @ageLabel.
  ///
  /// In tr, this message translates to:
  /// **'{age} yaş'**
  String ageLabel(int age);

  /// No description provided for @stageBebek.
  ///
  /// In tr, this message translates to:
  /// **'Bebeklik'**
  String get stageBebek;

  /// No description provided for @stageIlkokul.
  ///
  /// In tr, this message translates to:
  /// **'İlkokul'**
  String get stageIlkokul;

  /// No description provided for @stageOrtaokul.
  ///
  /// In tr, this message translates to:
  /// **'Ortaokul'**
  String get stageOrtaokul;

  /// No description provided for @stageLise.
  ///
  /// In tr, this message translates to:
  /// **'Lise'**
  String get stageLise;

  /// No description provided for @stageGenc.
  ///
  /// In tr, this message translates to:
  /// **'Genç yetişkin'**
  String get stageGenc;

  /// No description provided for @stageYetiskin.
  ///
  /// In tr, this message translates to:
  /// **'Yetişkin'**
  String get stageYetiskin;

  /// No description provided for @stageOlgun.
  ///
  /// In tr, this message translates to:
  /// **'Olgun'**
  String get stageOlgun;

  /// No description provided for @stageYasli.
  ///
  /// In tr, this message translates to:
  /// **'Yaşlılık'**
  String get stageYasli;

  /// No description provided for @background_varlikli.
  ///
  /// In tr, this message translates to:
  /// **'Varlıklı aile'**
  String get background_varlikli;

  /// No description provided for @background_orta.
  ///
  /// In tr, this message translates to:
  /// **'Orta halli aile'**
  String get background_orta;

  /// No description provided for @background_dar.
  ///
  /// In tr, this message translates to:
  /// **'Dar gelirli aile'**
  String get background_dar;

  /// No description provided for @hometownLine.
  ///
  /// In tr, this message translates to:
  /// **'{hometown} · {team}'**
  String hometownLine(String hometown, String team);

  /// No description provided for @cardsLeft.
  ///
  /// In tr, this message translates to:
  /// **'Bu yıl {count, plural, =1{son kart} other{{count} kart daha}}'**
  String cardsLeft(int count);

  /// No description provided for @swipeHint.
  ///
  /// In tr, this message translates to:
  /// **'Kartı sola ya da sağa kaydır'**
  String get swipeHint;

  /// No description provided for @swipeUpHint.
  ///
  /// In tr, this message translates to:
  /// **'Yukarı kaydır: {label}'**
  String swipeUpHint(String label);

  /// No description provided for @rollSuccess.
  ///
  /// In tr, this message translates to:
  /// **'Şans yüzüne güldü.'**
  String get rollSuccess;

  /// No description provided for @rollFail.
  ///
  /// In tr, this message translates to:
  /// **'Bu sefer olmadı.'**
  String get rollFail;

  /// No description provided for @actionsTitle.
  ///
  /// In tr, this message translates to:
  /// **'Bu yıl ne yapacaksın?'**
  String get actionsTitle;

  /// No description provided for @actionsLeft.
  ///
  /// In tr, this message translates to:
  /// **'{count, plural, =0{Bu yılın hakları bitti} =1{1 hakkın kaldı} other{{count} hakkın kaldı}}'**
  String actionsLeft(int count);

  /// No description provided for @actionFree.
  ///
  /// In tr, this message translates to:
  /// **'Ücretsiz'**
  String get actionFree;

  /// No description provided for @moneyGain.
  ///
  /// In tr, this message translates to:
  /// **'+{amount} TL'**
  String moneyGain(int amount);

  /// No description provided for @ageUpButton.
  ///
  /// In tr, this message translates to:
  /// **'Yaşlan'**
  String get ageUpButton;

  /// No description provided for @action_oyun_oyna.
  ///
  /// In tr, this message translates to:
  /// **'Oyun oyna'**
  String get action_oyun_oyna;

  /// No description provided for @action_ders_calis.
  ///
  /// In tr, this message translates to:
  /// **'Ders çalış'**
  String get action_ders_calis;

  /// No description provided for @action_fazla_mesai.
  ///
  /// In tr, this message translates to:
  /// **'Fazla mesai'**
  String get action_fazla_mesai;

  /// No description provided for @action_aileyle_vakit.
  ///
  /// In tr, this message translates to:
  /// **'Ailenle vakit geçir'**
  String get action_aileyle_vakit;

  /// No description provided for @action_arkadaslarla_bulus.
  ///
  /// In tr, this message translates to:
  /// **'Arkadaşlarınla buluş'**
  String get action_arkadaslarla_bulus;

  /// No description provided for @action_kitap_oku.
  ///
  /// In tr, this message translates to:
  /// **'Kitap oku'**
  String get action_kitap_oku;

  /// No description provided for @action_spor.
  ///
  /// In tr, this message translates to:
  /// **'Spor yap'**
  String get action_spor;

  /// No description provided for @action_doktor_kontrolu.
  ///
  /// In tr, this message translates to:
  /// **'Doktor kontrolü'**
  String get action_doktor_kontrolu;

  /// No description provided for @action_yuruyus.
  ///
  /// In tr, this message translates to:
  /// **'Sahilde yürüyüş'**
  String get action_yuruyus;

  /// No description provided for @action_memleket_ziyareti.
  ///
  /// In tr, this message translates to:
  /// **'Memleketi ziyaret et'**
  String get action_memleket_ziyareti;

  /// No description provided for @action_tatil.
  ///
  /// In tr, this message translates to:
  /// **'Tatile çık'**
  String get action_tatil;

  /// No description provided for @action_altin_al.
  ///
  /// In tr, this message translates to:
  /// **'10 gram altın al'**
  String get action_altin_al;

  /// No description provided for @action_altin_sat.
  ///
  /// In tr, this message translates to:
  /// **'10 gram altın sat'**
  String get action_altin_sat;

  /// No description provided for @action_is_ara.
  ///
  /// In tr, this message translates to:
  /// **'İş ara'**
  String get action_is_ara;

  /// No description provided for @jobFound.
  ///
  /// In tr, this message translates to:
  /// **'İş buldun: {career}'**
  String jobFound(String career);

  /// No description provided for @jobNotFound.
  ///
  /// In tr, this message translates to:
  /// **'Bu yıl iş çıkmadı. Belki seneye.'**
  String get jobNotFound;

  /// No description provided for @deathTitle.
  ///
  /// In tr, this message translates to:
  /// **'{name}'**
  String deathTitle(String name);

  /// No description provided for @deathLifespan.
  ///
  /// In tr, this message translates to:
  /// **'{age} yıllık bir ömür'**
  String deathLifespan(int age);

  /// No description provided for @deathCauseHealth.
  ///
  /// In tr, this message translates to:
  /// **'Bedeni daha fazla dayanamadı. Sevdikleri yanındaydı.'**
  String get deathCauseHealth;

  /// No description provided for @deathCauseNatural.
  ///
  /// In tr, this message translates to:
  /// **'Zamanı geldiğinde, huzur içinde gözlerini yumdu.'**
  String get deathCauseNatural;

  /// No description provided for @nicknameTitle.
  ///
  /// In tr, this message translates to:
  /// **'Mahalle onu şöyle hatırlıyor'**
  String get nicknameTitle;

  /// No description provided for @biggestMomentTitle.
  ///
  /// In tr, this message translates to:
  /// **'En büyük an'**
  String get biggestMomentTitle;

  /// No description provided for @biggestMomentAge.
  ///
  /// In tr, this message translates to:
  /// **'{age} yaşında'**
  String biggestMomentAge(int age);

  /// No description provided for @cardsSeenLine.
  ///
  /// In tr, this message translates to:
  /// **'{count} karar, bir ömür'**
  String cardsSeenLine(int count);

  /// No description provided for @seedLine.
  ///
  /// In tr, this message translates to:
  /// **'Hayat tohumu: {seed}'**
  String seedLine(int seed);

  /// No description provided for @rebirthButton.
  ///
  /// In tr, this message translates to:
  /// **'Yeniden doğ'**
  String get rebirthButton;

  /// No description provided for @deathNetWorth.
  ///
  /// In tr, this message translates to:
  /// **'Net servet: {amount}'**
  String deathNetWorth(String amount);

  /// No description provided for @shareButton.
  ///
  /// In tr, this message translates to:
  /// **'Hayatını paylaş'**
  String get shareButton;

  /// No description provided for @deathBadgesTitle.
  ///
  /// In tr, this message translates to:
  /// **'Bu hayatta kazanılan rozetler'**
  String get deathBadgesTitle;

  /// No description provided for @badgeNew.
  ///
  /// In tr, this message translates to:
  /// **'Yeni!'**
  String get badgeNew;

  /// No description provided for @albumButton.
  ///
  /// In tr, this message translates to:
  /// **'Hayat Albümü'**
  String get albumButton;

  /// No description provided for @albumTitle.
  ///
  /// In tr, this message translates to:
  /// **'Hayat Albümü'**
  String get albumTitle;

  /// No description provided for @albumTabLives.
  ///
  /// In tr, this message translates to:
  /// **'Hayatlar'**
  String get albumTabLives;

  /// No description provided for @albumTabBadges.
  ///
  /// In tr, this message translates to:
  /// **'Rozetler'**
  String get albumTabBadges;

  /// No description provided for @albumEmpty.
  ///
  /// In tr, this message translates to:
  /// **'Henüz biten bir hayat yok. İlk hayatın burada duracak.'**
  String get albumEmpty;

  /// No description provided for @albumLifeLine.
  ///
  /// In tr, this message translates to:
  /// **'{age} yaş · {nickname}'**
  String albumLifeLine(int age, String nickname);

  /// No description provided for @badgeCount.
  ///
  /// In tr, this message translates to:
  /// **'{count, plural, =1{1 kez kazanıldı} other{{count} kez kazanıldı}}'**
  String badgeCount(int count);

  /// No description provided for @badgeLocked.
  ///
  /// In tr, this message translates to:
  /// **'Henüz kazanılmadı'**
  String get badgeLocked;

  /// No description provided for @badgesSummary.
  ///
  /// In tr, this message translates to:
  /// **'{earned} / {total} rozet'**
  String badgesSummary(int earned, int total);

  /// No description provided for @sharePreviewTitle.
  ///
  /// In tr, this message translates to:
  /// **'Hayat özeti'**
  String get sharePreviewTitle;

  /// No description provided for @shareAction.
  ///
  /// In tr, this message translates to:
  /// **'Paylaş'**
  String get shareAction;

  /// No description provided for @shareText.
  ///
  /// In tr, this message translates to:
  /// **'Bir Ömür\'de {age} yıllık bir hayat yaşadım. Sen nasıl bir ömür yaşardın?'**
  String shareText(int age);

  /// No description provided for @shareFailed.
  ///
  /// In tr, this message translates to:
  /// **'Paylaşım açılamadı.'**
  String get shareFailed;

  /// No description provided for @shareNumbersTitle.
  ///
  /// In tr, this message translates to:
  /// **'Hayatın sayıları'**
  String get shareNumbersTitle;

  /// No description provided for @shareFooter.
  ///
  /// In tr, this message translates to:
  /// **'Bir Ömür · Türkiye\'de bir hayat'**
  String get shareFooter;

  /// No description provided for @numMoves.
  ///
  /// In tr, this message translates to:
  /// **'{count, plural, =1{1 kez taşındı} other{{count} kez taşındı}}'**
  String numMoves(int count);

  /// No description provided for @numRent.
  ///
  /// In tr, this message translates to:
  /// **'{amount} kira ödedi'**
  String numRent(String amount);

  /// No description provided for @numGold.
  ///
  /// In tr, this message translates to:
  /// **'{grams} gram altın takıldı'**
  String numGold(int grams);

  /// No description provided for @numPromotions.
  ///
  /// In tr, this message translates to:
  /// **'{count, plural, =1{1 kez terfi aldı} other{{count} kez terfi aldı}}'**
  String numPromotions(int count);

  /// No description provided for @numYearsWorked.
  ///
  /// In tr, this message translates to:
  /// **'{years} yıl çalıştı'**
  String numYearsWorked(int years);

  /// No description provided for @numNetWorth.
  ///
  /// In tr, this message translates to:
  /// **'Geride {amount} bıraktı'**
  String numNetWorth(String amount);

  /// No description provided for @amountMillion.
  ///
  /// In tr, this message translates to:
  /// **'{value} milyon TL'**
  String amountMillion(String value);

  /// No description provided for @amountThousand.
  ///
  /// In tr, this message translates to:
  /// **'{value} bin TL'**
  String amountThousand(String value);

  /// No description provided for @jobNone.
  ///
  /// In tr, this message translates to:
  /// **'İşsiz'**
  String get jobNone;

  /// No description provided for @jobStudent.
  ///
  /// In tr, this message translates to:
  /// **'Üniversite öğrencisi'**
  String get jobStudent;

  /// No description provided for @jobRetired.
  ///
  /// In tr, this message translates to:
  /// **'Emekli'**
  String get jobRetired;

  /// No description provided for @jobChild.
  ///
  /// In tr, this message translates to:
  /// **'Okul çağında'**
  String get jobChild;

  /// No description provided for @jobTier.
  ///
  /// In tr, this message translates to:
  /// **'{career} · {tier}'**
  String jobTier(String career, String tier);

  /// No description provided for @assetsButton.
  ///
  /// In tr, this message translates to:
  /// **'Varlıklar'**
  String get assetsButton;

  /// No description provided for @assetsTitle.
  ///
  /// In tr, this message translates to:
  /// **'Varlıkların'**
  String get assetsTitle;

  /// No description provided for @assetCash.
  ///
  /// In tr, this message translates to:
  /// **'Nakit'**
  String get assetCash;

  /// No description provided for @assetGold.
  ///
  /// In tr, this message translates to:
  /// **'Altın'**
  String get assetGold;

  /// No description provided for @assetGoldValue.
  ///
  /// In tr, this message translates to:
  /// **'{grams} gr · {value}'**
  String assetGoldValue(int grams, String value);

  /// No description provided for @assetHouse.
  ///
  /// In tr, this message translates to:
  /// **'Ev'**
  String get assetHouse;

  /// No description provided for @assetHouseValue.
  ///
  /// In tr, this message translates to:
  /// **'{count} ev · {value}'**
  String assetHouseValue(int count, String value);

  /// No description provided for @assetCar.
  ///
  /// In tr, this message translates to:
  /// **'Araba'**
  String get assetCar;

  /// No description provided for @assetCarValue.
  ///
  /// In tr, this message translates to:
  /// **'{count} araba · {value}'**
  String assetCarValue(int count, String value);

  /// No description provided for @assetRent.
  ///
  /// In tr, this message translates to:
  /// **'Yıllık kira'**
  String get assetRent;

  /// No description provided for @assetLoan.
  ///
  /// In tr, this message translates to:
  /// **'Kredi'**
  String get assetLoan;

  /// No description provided for @assetLoanValue.
  ///
  /// In tr, this message translates to:
  /// **'{payment} × {years} yıl'**
  String assetLoanValue(String payment, int years);

  /// No description provided for @assetPension.
  ///
  /// In tr, this message translates to:
  /// **'Emekli aylığı (yıllık)'**
  String get assetPension;

  /// No description provided for @assetNetWorth.
  ///
  /// In tr, this message translates to:
  /// **'Net servet'**
  String get assetNetWorth;

  /// No description provided for @assetGoldPrice.
  ///
  /// In tr, this message translates to:
  /// **'Altının gramı: {price}'**
  String assetGoldPrice(String price);

  /// No description provided for @assetNone.
  ///
  /// In tr, this message translates to:
  /// **'Yok'**
  String get assetNone;

  /// No description provided for @lastYearTitle.
  ///
  /// In tr, this message translates to:
  /// **'Geçen yıl'**
  String get lastYearTitle;

  /// No description provided for @lastYearIncome.
  ///
  /// In tr, this message translates to:
  /// **'Gelir {amount}'**
  String lastYearIncome(String amount);

  /// No description provided for @lastYearRent.
  ///
  /// In tr, this message translates to:
  /// **'Kira {amount}'**
  String lastYearRent(String amount);

  /// No description provided for @lastYearLoan.
  ///
  /// In tr, this message translates to:
  /// **'Kredi {amount}'**
  String lastYearLoan(String amount);

  /// No description provided for @lastYearInflation.
  ///
  /// In tr, this message translates to:
  /// **'Enflasyon %{percent}; nakdinden {amount} eridi'**
  String lastYearInflation(int percent, String amount);

  /// No description provided for @lastYearPromoted.
  ///
  /// In tr, this message translates to:
  /// **'Terfi aldın!'**
  String get lastYearPromoted;

  /// No description provided for @lastYearRetired.
  ///
  /// In tr, this message translates to:
  /// **'Emekli oldun.'**
  String get lastYearRetired;

  /// No description provided for @closeTooltip.
  ///
  /// In tr, this message translates to:
  /// **'Kapat'**
  String get closeTooltip;

  /// No description provided for @nickname_asirlikCinar.
  ///
  /// In tr, this message translates to:
  /// **'Asırlık Çınar'**
  String get nickname_asirlikCinar;

  /// No description provided for @nickname_mahalleninZengini.
  ///
  /// In tr, this message translates to:
  /// **'Mahallenin Zengini'**
  String get nickname_mahalleninZengini;

  /// No description provided for @nickname_evSahibi.
  ///
  /// In tr, this message translates to:
  /// **'Kirasını Kendine Ödeyen'**
  String get nickname_evSahibi;

  /// No description provided for @nickname_sozuDinlenen.
  ///
  /// In tr, this message translates to:
  /// **'Sözü Dinlenen'**
  String get nickname_sozuDinlenen;

  /// No description provided for @nickname_bayramlarinBasKosesi.
  ///
  /// In tr, this message translates to:
  /// **'Bayramların Baş Köşesi'**
  String get nickname_bayramlarinBasKosesi;

  /// No description provided for @nickname_mahalleninProfesoru.
  ///
  /// In tr, this message translates to:
  /// **'Mahallenin Profesörü'**
  String get nickname_mahalleninProfesoru;

  /// No description provided for @nickname_hepGulen.
  ///
  /// In tr, this message translates to:
  /// **'Hep Gülen'**
  String get nickname_hepGulen;

  /// No description provided for @nickname_borcYigidinKamcisi.
  ///
  /// In tr, this message translates to:
  /// **'Borç Yiğidin Kamçısı'**
  String get nickname_borcYigidinKamcisi;

  /// No description provided for @nickname_bizimBolukte.
  ///
  /// In tr, this message translates to:
  /// **'Bizim Bölükte'**
  String get nickname_bizimBolukte;

  /// No description provided for @nickname_mahalleninBildikYuzu.
  ///
  /// In tr, this message translates to:
  /// **'Mahallenin Bildik Yüzü'**
  String get nickname_mahalleninBildikYuzu;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['tr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'tr':
      return AppLocalizationsTr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
