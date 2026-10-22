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

  /// No description provided for @outdatedSaveTitle.
  ///
  /// In tr, this message translates to:
  /// **'Yarım kalan hayat sürdürülemiyor'**
  String get outdatedSaveTitle;

  /// No description provided for @outdatedSaveBody.
  ///
  /// In tr, this message translates to:
  /// **'Bu hayat oyunun eski bir sürümünden kaldı. Bir Ömür artık insanlarla, anılarla ve yeni olaylarla işliyor; eski hayat bu düzene taşınamıyor. Albümün ve rozetlerin yerinde.'**
  String get outdatedSaveBody;

  /// No description provided for @outdatedSaveDismiss.
  ///
  /// In tr, this message translates to:
  /// **'Anladım, yeni hayata başla'**
  String get outdatedSaveDismiss;

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

  /// No description provided for @rollLuck.
  ///
  /// In tr, this message translates to:
  /// **'Şans'**
  String get rollLuck;

  /// No description provided for @rollBadge.
  ///
  /// In tr, this message translates to:
  /// **'Zar: {stat}'**
  String rollBadge(String stat);

  /// No description provided for @rollBadgeTooltip.
  ///
  /// In tr, this message translates to:
  /// **'Bu seçeneğin sonucu zara ve {stat} değerine bağlı; tutmayabilir.'**
  String rollBadgeTooltip(String stat);

  /// No description provided for @rollResultLine.
  ///
  /// In tr, this message translates to:
  /// **'{stat} zarı: {result}'**
  String rollResultLine(String stat, String result);

  /// No description provided for @actionsTitle.
  ///
  /// In tr, this message translates to:
  /// **'Bu yıl ne yapacaksın?'**
  String get actionsTitle;

  /// No description provided for @timeLeft.
  ///
  /// In tr, this message translates to:
  /// **'{count, plural, =0{Bu yılın vakti bitti} other{Vakit: {count}}}'**
  String timeLeft(int count);

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

  /// No description provided for @actionBlocked_vakit.
  ///
  /// In tr, this message translates to:
  /// **'Bu yılın vakti yetmiyor'**
  String get actionBlocked_vakit;

  /// No description provided for @actionBlocked_para.
  ///
  /// In tr, this message translates to:
  /// **'Paran yetmiyor'**
  String get actionBlocked_para;

  /// No description provided for @actionBlocked_buYil.
  ///
  /// In tr, this message translates to:
  /// **'Bu yıl yaptın'**
  String get actionBlocked_buYil;

  /// No description provided for @actionBlocked_isYok.
  ///
  /// In tr, this message translates to:
  /// **'Bu yaşta başvurabileceğin bir iş kalmadı'**
  String get actionBlocked_isYok;

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

  /// No description provided for @deathCauseEarly.
  ///
  /// In tr, this message translates to:
  /// **'Hayatı erken bitti. Geride bıraktıkları onu hep anacak.'**
  String get deathCauseEarly;

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

  /// No description provided for @momentChoice.
  ///
  /// In tr, this message translates to:
  /// **'Seçimin: {label}'**
  String momentChoice(String label);

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

  /// No description provided for @settingsTitle.
  ///
  /// In tr, this message translates to:
  /// **'Ayarlar'**
  String get settingsTitle;

  /// No description provided for @settingsSound.
  ///
  /// In tr, this message translates to:
  /// **'Ses'**
  String get settingsSound;

  /// No description provided for @settingsSoundHint.
  ///
  /// In tr, this message translates to:
  /// **'Kart, zar, terfi, rozet ve veda sesleri'**
  String get settingsSoundHint;

  /// No description provided for @settingsHaptics.
  ///
  /// In tr, this message translates to:
  /// **'Titreşim'**
  String get settingsHaptics;

  /// No description provided for @settingsHapticsHint.
  ///
  /// In tr, this message translates to:
  /// **'Kart kaydırırken ve önemli anlarda'**
  String get settingsHapticsHint;

  /// No description provided for @settingsLicenses.
  ///
  /// In tr, this message translates to:
  /// **'Lisanslar'**
  String get settingsLicenses;

  /// No description provided for @settingsAnalytics.
  ///
  /// In tr, this message translates to:
  /// **'Kullanım verisi paylaş'**
  String get settingsAnalytics;

  /// No description provided for @settingsAnalyticsHint.
  ///
  /// In tr, this message translates to:
  /// **'Oyunu dengelemek için; adın ya da iletişim bilgilerin gönderilmez'**
  String get settingsAnalyticsHint;

  /// No description provided for @settingsCrashNote.
  ///
  /// In tr, this message translates to:
  /// **'Uygulama çökerse, hatayı bulabilmemiz için anonim bir çökme kaydı gönderilir.'**
  String get settingsCrashNote;

  /// No description provided for @consentTitle.
  ///
  /// In tr, this message translates to:
  /// **'Oyunu birlikte geliştirelim'**
  String get consentTitle;

  /// No description provided for @consentBody.
  ///
  /// In tr, this message translates to:
  /// **'Bir hayatın ne kadar sürdüğünü, hangi rozetlerin kazanıldığını ve oyunun nerede zorlaştığını görmek için kullanım verisi toplamak istiyoruz. Adını ya da iletişim bilgilerini toplamayız. Kararını istediğin zaman Ayarlar\'dan değiştirebilirsin.'**
  String get consentBody;

  /// No description provided for @consentAccept.
  ///
  /// In tr, this message translates to:
  /// **'Olur'**
  String get consentAccept;

  /// No description provided for @consentDecline.
  ///
  /// In tr, this message translates to:
  /// **'Hayır, teşekkürler'**
  String get consentDecline;

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
  /// **'Öğrenci'**
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

  /// No description provided for @ledgerTitle.
  ///
  /// In tr, this message translates to:
  /// **'Para hareketleri'**
  String get ledgerTitle;

  /// No description provided for @ledgerThisYear.
  ///
  /// In tr, this message translates to:
  /// **'Bu yıl ({age} yaş)'**
  String ledgerThisYear(int age);

  /// No description provided for @ledgerLastYear.
  ///
  /// In tr, this message translates to:
  /// **'Geçen yıl ({age} yaş)'**
  String ledgerLastYear(int age);

  /// No description provided for @ledgerEmpty.
  ///
  /// In tr, this message translates to:
  /// **'Para hareketi yok.'**
  String get ledgerEmpty;

  /// No description provided for @ledgerTotal.
  ///
  /// In tr, this message translates to:
  /// **'Toplam'**
  String get ledgerTotal;

  /// No description provided for @money_maas.
  ///
  /// In tr, this message translates to:
  /// **'Maaş'**
  String get money_maas;

  /// No description provided for @money_emekliAyligi.
  ///
  /// In tr, this message translates to:
  /// **'Emekli aylığı'**
  String get money_emekliAyligi;

  /// No description provided for @money_harclik.
  ///
  /// In tr, this message translates to:
  /// **'Aileden harçlık'**
  String get money_harclik;

  /// No description provided for @money_araIs.
  ///
  /// In tr, this message translates to:
  /// **'Ara işler, yevmiyeler'**
  String get money_araIs;

  /// No description provided for @money_burs.
  ///
  /// In tr, this message translates to:
  /// **'Burs'**
  String get money_burs;

  /// No description provided for @money_yarimZamanli.
  ///
  /// In tr, this message translates to:
  /// **'Yarı zamanlı iş'**
  String get money_yarimZamanli;

  /// No description provided for @money_aileDestegi.
  ///
  /// In tr, this message translates to:
  /// **'Ailenin 18 yaş desteği'**
  String get money_aileDestegi;

  /// No description provided for @money_kira.
  ///
  /// In tr, this message translates to:
  /// **'Kira'**
  String get money_kira;

  /// No description provided for @money_yasamGideri.
  ///
  /// In tr, this message translates to:
  /// **'Yaşam gideri'**
  String get money_yasamGideri;

  /// No description provided for @money_kredi.
  ///
  /// In tr, this message translates to:
  /// **'Kredi taksidi'**
  String get money_kredi;

  /// No description provided for @money_araba.
  ///
  /// In tr, this message translates to:
  /// **'Araba masrafı'**
  String get money_araba;

  /// No description provided for @money_enflasyon.
  ///
  /// In tr, this message translates to:
  /// **'Enflasyon nakitten eritti'**
  String get money_enflasyon;

  /// No description provided for @money_terfi.
  ///
  /// In tr, this message translates to:
  /// **'Terfi için yatırım'**
  String get money_terfi;

  /// No description provided for @money_olay.
  ///
  /// In tr, this message translates to:
  /// **'Seçimin: “{label}”'**
  String money_olay(String label);

  /// No description provided for @money_is.
  ///
  /// In tr, this message translates to:
  /// **'İş: {what}'**
  String money_is(String what);

  /// No description provided for @money_varlik.
  ///
  /// In tr, this message translates to:
  /// **'{what}'**
  String money_varlik(String what);

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

  /// No description provided for @tabMe.
  ///
  /// In tr, this message translates to:
  /// **'Ben'**
  String get tabMe;

  /// No description provided for @tabPeople.
  ///
  /// In tr, this message translates to:
  /// **'İnsanlar'**
  String get tabPeople;

  /// No description provided for @tabSchoolWork.
  ///
  /// In tr, this message translates to:
  /// **'Okul / İş'**
  String get tabSchoolWork;

  /// No description provided for @tabAssets.
  ///
  /// In tr, this message translates to:
  /// **'Varlıklar'**
  String get tabAssets;

  /// No description provided for @tabActivities.
  ///
  /// In tr, this message translates to:
  /// **'Aktiviteler'**
  String get tabActivities;

  /// No description provided for @noActionsHere.
  ///
  /// In tr, this message translates to:
  /// **'Bu yaşta burada yapacak bir şey yok.'**
  String get noActionsHere;

  /// No description provided for @journalTitle.
  ///
  /// In tr, this message translates to:
  /// **'Bu yılın günlüğü'**
  String get journalTitle;

  /// No description provided for @journalEmpty.
  ///
  /// In tr, this message translates to:
  /// **'Sakin bir yıl. Kimseden ses yok.'**
  String get journalEmpty;

  /// No description provided for @journalChoice.
  ///
  /// In tr, this message translates to:
  /// **'Seçimin: “{label}”'**
  String journalChoice(String label);

  /// No description provided for @news_kardesDogdu.
  ///
  /// In tr, this message translates to:
  /// **'{name} doğdu. Artık bir kardeşin var.'**
  String news_kardesDogdu(String name);

  /// No description provided for @news_yeniSinif_ilkokul.
  ///
  /// In tr, this message translates to:
  /// **'İlkokul başladı. Öğretmenin {name}; yeni bir sınıfın var.'**
  String news_yeniSinif_ilkokul(String name);

  /// No description provided for @news_yeniSinif_ortaokul.
  ///
  /// In tr, this message translates to:
  /// **'Ortaokul başladı. Yeni sınıf, yeni öğretmen: {name}.'**
  String news_yeniSinif_ortaokul(String name);

  /// No description provided for @news_yeniSinif_lise.
  ///
  /// In tr, this message translates to:
  /// **'Lise başladı. Yeni sınıf, yeni öğretmen: {name}.'**
  String news_yeniSinif_lise(String name);

  /// No description provided for @news_evlendi.
  ///
  /// In tr, this message translates to:
  /// **'{name} evlendi.'**
  String news_evlendi(String name);

  /// No description provided for @news_tasindi.
  ///
  /// In tr, this message translates to:
  /// **'{name} taşındı. Yeni şehri: {city}.'**
  String news_tasindi(String name, String city);

  /// No description provided for @news_isBuldu.
  ///
  /// In tr, this message translates to:
  /// **'{name} iş buldu: {job}.'**
  String news_isBuldu(String name, String job);

  /// No description provided for @news_emekliOldu.
  ///
  /// In tr, this message translates to:
  /// **'{name} emekli oldu.'**
  String news_emekliOldu(String name);

  /// No description provided for @news_vefat.
  ///
  /// In tr, this message translates to:
  /// **'{name} vefat etti.'**
  String news_vefat(String name);

  /// No description provided for @group_aile.
  ///
  /// In tr, this message translates to:
  /// **'Aile'**
  String get group_aile;

  /// No description provided for @group_okul.
  ///
  /// In tr, this message translates to:
  /// **'Okul'**
  String get group_okul;

  /// No description provided for @group_arkadaslar.
  ///
  /// In tr, this message translates to:
  /// **'Arkadaşlar'**
  String get group_arkadaslar;

  /// No description provided for @group_mahalle.
  ///
  /// In tr, this message translates to:
  /// **'Mahalle'**
  String get group_mahalle;

  /// No description provided for @group_eski.
  ///
  /// In tr, this message translates to:
  /// **'Eski tanıdıklar'**
  String get group_eski;

  /// No description provided for @group_vefat.
  ///
  /// In tr, this message translates to:
  /// **'Kaybettiklerin'**
  String get group_vefat;

  /// No description provided for @peopleEmpty.
  ///
  /// In tr, this message translates to:
  /// **'Henüz kimseyi tanımıyorsun.'**
  String get peopleEmpty;

  /// No description provided for @role_siraArkadasi.
  ///
  /// In tr, this message translates to:
  /// **'Sıra arkadaşın'**
  String get role_siraArkadasi;

  /// No description provided for @role_sinifArkadasi.
  ///
  /// In tr, this message translates to:
  /// **'Sınıf arkadaşın'**
  String get role_sinifArkadasi;

  /// No description provided for @role_ogretmen.
  ///
  /// In tr, this message translates to:
  /// **'Öğretmenin'**
  String get role_ogretmen;

  /// No description provided for @role_odaArkadasi.
  ///
  /// In tr, this message translates to:
  /// **'Oda arkadaşın'**
  String get role_odaArkadasi;

  /// No description provided for @role_bolukArkadasi.
  ///
  /// In tr, this message translates to:
  /// **'Bölük arkadaşın'**
  String get role_bolukArkadasi;

  /// No description provided for @role_patron.
  ///
  /// In tr, this message translates to:
  /// **'Patronun'**
  String get role_patron;

  /// No description provided for @role_mudur.
  ///
  /// In tr, this message translates to:
  /// **'Müdürün'**
  String get role_mudur;

  /// No description provided for @role_isArkadasi.
  ///
  /// In tr, this message translates to:
  /// **'İş arkadaşın'**
  String get role_isArkadasi;

  /// No description provided for @role_calisan.
  ///
  /// In tr, this message translates to:
  /// **'Çalışanın'**
  String get role_calisan;

  /// No description provided for @role_musteri.
  ///
  /// In tr, this message translates to:
  /// **'Müşterin'**
  String get role_musteri;

  /// No description provided for @role_ortak.
  ///
  /// In tr, this message translates to:
  /// **'Ortağın'**
  String get role_ortak;

  /// No description provided for @role_rakip.
  ///
  /// In tr, this message translates to:
  /// **'Rakibin'**
  String get role_rakip;

  /// No description provided for @role_komsu.
  ///
  /// In tr, this message translates to:
  /// **'Komşun'**
  String get role_komsu;

  /// No description provided for @role_bakkal.
  ///
  /// In tr, this message translates to:
  /// **'Mahallenin bakkalı'**
  String get role_bakkal;

  /// No description provided for @role_muhtar.
  ///
  /// In tr, this message translates to:
  /// **'Muhtar'**
  String get role_muhtar;

  /// No description provided for @role_evSahibi.
  ///
  /// In tr, this message translates to:
  /// **'Ev sahibin'**
  String get role_evSahibi;

  /// No description provided for @role_kiraci.
  ///
  /// In tr, this message translates to:
  /// **'Kiracın'**
  String get role_kiraci;

  /// No description provided for @role_doktor.
  ///
  /// In tr, this message translates to:
  /// **'Doktorun'**
  String get role_doktor;

  /// No description provided for @relationSide.
  ///
  /// In tr, this message translates to:
  /// **'{kin} ({side})'**
  String relationSide(String kin, String side);

  /// No description provided for @side_anne.
  ///
  /// In tr, this message translates to:
  /// **'anne tarafı'**
  String get side_anne;

  /// No description provided for @side_baba.
  ///
  /// In tr, this message translates to:
  /// **'baba tarafı'**
  String get side_baba;

  /// No description provided for @relationFormer.
  ///
  /// In tr, this message translates to:
  /// **'Eskiden: {role}'**
  String relationFormer(String role);

  /// No description provided for @bond_tanidik.
  ///
  /// In tr, this message translates to:
  /// **'Tanıdık'**
  String get bond_tanidik;

  /// No description provided for @bond_arkadas.
  ///
  /// In tr, this message translates to:
  /// **'Arkadaşın'**
  String get bond_arkadas;

  /// No description provided for @bond_yakinArkadas.
  ///
  /// In tr, this message translates to:
  /// **'Yakın arkadaşın'**
  String get bond_yakinArkadas;

  /// No description provided for @bond_flort.
  ///
  /// In tr, this message translates to:
  /// **'Flörtün'**
  String get bond_flort;

  /// No description provided for @bond_sevgili.
  ///
  /// In tr, this message translates to:
  /// **'Sevgilin'**
  String get bond_sevgili;

  /// No description provided for @bond_nisanli.
  ///
  /// In tr, this message translates to:
  /// **'Nişanlın'**
  String get bond_nisanli;

  /// No description provided for @bond_eskiSevgili.
  ///
  /// In tr, this message translates to:
  /// **'Eski sevgilin'**
  String get bond_eskiSevgili;

  /// No description provided for @bond_eskiEs.
  ///
  /// In tr, this message translates to:
  /// **'Eski eşin'**
  String get bond_eskiEs;

  /// No description provided for @color_dost.
  ///
  /// In tr, this message translates to:
  /// **'Dost'**
  String get color_dost;

  /// No description provided for @color_kiskancYakin.
  ///
  /// In tr, this message translates to:
  /// **'Sever ama kıskanır'**
  String get color_kiskancYakin;

  /// No description provided for @color_tanidik.
  ///
  /// In tr, this message translates to:
  /// **'Tanıdık'**
  String get color_tanidik;

  /// No description provided for @color_dusman.
  ///
  /// In tr, this message translates to:
  /// **'Husumetli'**
  String get color_dusman;

  /// No description provided for @trait_kiskanc.
  ///
  /// In tr, this message translates to:
  /// **'Kıskanç'**
  String get trait_kiskanc;

  /// No description provided for @trait_comert.
  ///
  /// In tr, this message translates to:
  /// **'Cömert'**
  String get trait_comert;

  /// No description provided for @trait_cikarci.
  ///
  /// In tr, this message translates to:
  /// **'Çıkarcı'**
  String get trait_cikarci;

  /// No description provided for @trait_vefali.
  ///
  /// In tr, this message translates to:
  /// **'Vefalı'**
  String get trait_vefali;

  /// No description provided for @trait_dedikoducu.
  ///
  /// In tr, this message translates to:
  /// **'Dedikoducu'**
  String get trait_dedikoducu;

  /// No description provided for @trait_gamsiz.
  ///
  /// In tr, this message translates to:
  /// **'Gamsız'**
  String get trait_gamsiz;

  /// No description provided for @personAge.
  ///
  /// In tr, this message translates to:
  /// **'{age} yaşında'**
  String personAge(int age);

  /// No description provided for @personDiedAt.
  ///
  /// In tr, this message translates to:
  /// **'{age} yaşında vefat etti'**
  String personDiedAt(int age);

  /// No description provided for @personMet.
  ///
  /// In tr, this message translates to:
  /// **'{age} yaşındayken tanıştınız'**
  String personMet(int age);

  /// No description provided for @personLastContact.
  ///
  /// In tr, this message translates to:
  /// **'{years, plural, =0{Bu yıl görüştünüz} =1{Geçen yıl görüştünüz} other{{years} yıldır görüşmüyorsunuz}}'**
  String personLastContact(int years);

  /// No description provided for @personArchived.
  ///
  /// In tr, this message translates to:
  /// **'Uzun süredir görüşmüyorsunuz; rehberinde duruyor.'**
  String get personArchived;

  /// No description provided for @closenessLabel.
  ///
  /// In tr, this message translates to:
  /// **'Yakınlık'**
  String get closenessLabel;

  /// No description provided for @hostilityLabel.
  ///
  /// In tr, this message translates to:
  /// **'Husumet'**
  String get hostilityLabel;

  /// No description provided for @traitsTitle.
  ///
  /// In tr, this message translates to:
  /// **'Kişiliği'**
  String get traitsTitle;

  /// No description provided for @memoriesTitle.
  ///
  /// In tr, this message translates to:
  /// **'Seninle ilgili hatırladıkları'**
  String get memoriesTitle;

  /// No description provided for @memoriesEmpty.
  ///
  /// In tr, this message translates to:
  /// **'Henüz ortak bir anınız yok.'**
  String get memoriesEmpty;

  /// No description provided for @memoryAge.
  ///
  /// In tr, this message translates to:
  /// **'{age} yaşında'**
  String memoryAge(int age);

  /// No description provided for @memoryMine.
  ///
  /// In tr, this message translates to:
  /// **'Senin aklında kalan'**
  String get memoryMine;

  /// No description provided for @memoryHealed.
  ///
  /// In tr, this message translates to:
  /// **'Yumuşadı'**
  String get memoryHealed;

  /// No description provided for @interactionsTitle.
  ///
  /// In tr, this message translates to:
  /// **'Ne yapacaksın?'**
  String get interactionsTitle;

  /// No description provided for @interactionsAfterCards.
  ///
  /// In tr, this message translates to:
  /// **'Önce bu yılın olaylarını bitir.'**
  String get interactionsAfterCards;

  /// No description provided for @interaction_bulus.
  ///
  /// In tr, this message translates to:
  /// **'Buluş'**
  String get interaction_bulus;

  /// No description provided for @interaction_ara.
  ///
  /// In tr, this message translates to:
  /// **'Ara'**
  String get interaction_ara;

  /// No description provided for @interaction_hediye.
  ///
  /// In tr, this message translates to:
  /// **'Hediye al'**
  String get interaction_hediye;

  /// No description provided for @interaction_dertles.
  ///
  /// In tr, this message translates to:
  /// **'Dertleş'**
  String get interaction_dertles;

  /// No description provided for @interaction_borcIste.
  ///
  /// In tr, this message translates to:
  /// **'Borç iste'**
  String get interaction_borcIste;

  /// No description provided for @interaction_borcOde.
  ///
  /// In tr, this message translates to:
  /// **'Borcunu öde'**
  String get interaction_borcOde;

  /// No description provided for @interaction_lafSok.
  ///
  /// In tr, this message translates to:
  /// **'Laf sok'**
  String get interaction_lafSok;

  /// No description provided for @interaction_uzaklas.
  ///
  /// In tr, this message translates to:
  /// **'Uzaklaş'**
  String get interaction_uzaklas;

  /// No description provided for @interaction_yemegiOv.
  ///
  /// In tr, this message translates to:
  /// **'Yemeğini öv'**
  String get interaction_yemegiOv;

  /// No description provided for @interaction_macIzle.
  ///
  /// In tr, this message translates to:
  /// **'Maç izle'**
  String get interaction_macIzle;

  /// No description provided for @interaction_eliniOp.
  ///
  /// In tr, this message translates to:
  /// **'Elini öp'**
  String get interaction_eliniOp;

  /// No description provided for @interaction_kardesleOyna.
  ///
  /// In tr, this message translates to:
  /// **'Birlikte oyna'**
  String get interaction_kardesleOyna;

  /// No description provided for @interaction_cayaGit.
  ///
  /// In tr, this message translates to:
  /// **'Çaya git'**
  String get interaction_cayaGit;

  /// No description provided for @interactionCost.
  ///
  /// In tr, this message translates to:
  /// **'{time, plural, =1{1 vakit} other{{time} vakit}}'**
  String interactionCost(int time);

  /// No description provided for @interactionCostMoney.
  ///
  /// In tr, this message translates to:
  /// **'{time, plural, =1{1 vakit} other{{time} vakit}} · {money}'**
  String interactionCostMoney(int time, String money);

  /// No description provided for @blocked_vakit.
  ///
  /// In tr, this message translates to:
  /// **'Bu yılın vakti bitti'**
  String get blocked_vakit;

  /// No description provided for @blocked_yas.
  ///
  /// In tr, this message translates to:
  /// **'Bunun için çok küçüksün'**
  String get blocked_yas;

  /// No description provided for @blocked_karsiYas.
  ///
  /// In tr, this message translates to:
  /// **'O bunun için çok küçük'**
  String get blocked_karsiYas;

  /// No description provided for @blocked_para.
  ///
  /// In tr, this message translates to:
  /// **'Paran yetmiyor'**
  String get blocked_para;

  /// No description provided for @blocked_uzak.
  ///
  /// In tr, this message translates to:
  /// **'Başka şehirde yaşıyor'**
  String get blocked_uzak;

  /// No description provided for @blocked_yakinlikDusuk.
  ///
  /// In tr, this message translates to:
  /// **'Bunu konuşacak kadar yakın değilsiniz'**
  String get blocked_yakinlikDusuk;

  /// No description provided for @blocked_buYil.
  ///
  /// In tr, this message translates to:
  /// **'Bu yıl zaten yaptın'**
  String get blocked_buYil;

  /// No description provided for @blocked_borcVar.
  ///
  /// In tr, this message translates to:
  /// **'Önce eski borç ödenmeli'**
  String get blocked_borcVar;

  /// No description provided for @blocked_aniYok.
  ///
  /// In tr, this message translates to:
  /// **'Bu tonda konuşacak bir anınız yok'**
  String get blocked_aniYok;

  /// No description provided for @blocked_kirginlikYok.
  ///
  /// In tr, this message translates to:
  /// **'Özür dileyecek bir kırgınlık yok'**
  String get blocked_kirginlikYok;

  /// No description provided for @callTitle.
  ///
  /// In tr, this message translates to:
  /// **'Nasıl konuşacaksın?'**
  String get callTitle;

  /// No description provided for @callPickMemory.
  ///
  /// In tr, this message translates to:
  /// **'Hangi anıyı açacaksın?'**
  String get callPickMemory;

  /// No description provided for @tone_halHatir.
  ///
  /// In tr, this message translates to:
  /// **'Hal hatır sor'**
  String get tone_halHatir;

  /// No description provided for @tone_nostalji.
  ///
  /// In tr, this message translates to:
  /// **'Eski günleri an'**
  String get tone_nostalji;

  /// No description provided for @tone_ozur.
  ///
  /// In tr, this message translates to:
  /// **'Özür dile'**
  String get tone_ozur;

  /// No description provided for @tone_igne.
  ///
  /// In tr, this message translates to:
  /// **'İğnele'**
  String get tone_igne;

  /// No description provided for @tone_halHatir_hint.
  ///
  /// In tr, this message translates to:
  /// **'Küçük ama sıcak bir yakınlık'**
  String get tone_halHatir_hint;

  /// No description provided for @tone_nostalji_hint.
  ///
  /// In tr, this message translates to:
  /// **'Ortak bir anıyı açarsın'**
  String get tone_nostalji_hint;

  /// No description provided for @tone_ozur_hint.
  ///
  /// In tr, this message translates to:
  /// **'Eski bir kırgınlığı kapatmayı denersin'**
  String get tone_ozur_hint;

  /// No description provided for @tone_igne_hint.
  ///
  /// In tr, this message translates to:
  /// **'Eski bir meseleyi yüzüne vurursun'**
  String get tone_igne_hint;

  /// No description provided for @lastInteractionTitle.
  ///
  /// In tr, this message translates to:
  /// **'Son görüşmeniz'**
  String get lastInteractionTitle;
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
