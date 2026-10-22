# Bir Ömür — Proje Rehberi

Bu dosya her kodlama oturumunun başında okunur. Oyunun tasarımının tamamı `docs/GDD.md` dosyasındadır. Bir özelliğe başlamadan önce ilgili bölümü oku.

Canlı tasarım dokümanı: https://claude.ai/code/artifact/5e791558-0c95-419c-a419-5e21c3a1d7a7
`docs/GDD.md` bu dokümanın dışa aktarılmış kopyasıdır. İkisi çelişirse canlı doküman geçerlidir; kullanıcıya hangisinin güncel olduğunu sor.

## Proje

- Türkiye'de geçen, mizahi ama sevecen, kart tabanlı bir hayat simülasyonu (BitLife ve Reigns karışımı).
- Flutter ile tek kod tabanı; hedef Android ve iOS.
- Dil Türkçe. İngilizce sürüm daha sonra eklenecek, bu yüzden arayüz metinleri en baştan ARB dosyalarında tutulur.
- Geliştirici hem Windows hem Mac kullanıyor. Android geliştirme Windows'ta, iOS derlemesi Mac'te Xcode ile yapılır, test iPhone'da.

## Kesinleşmiş tasarım kararları

- **Tur = 1 yaş.** Her yıl 1–3 olay kartı gelir. Kart sola ya da sağa kaydırılarak seçilir; nadir kartlarda yukarı kaydırma üçüncü seçenektir.
- **Vakit:** Her yıl bir vakit puanı vardır; aksiyonlar ve kişilerle etkileşimler vakit harcar (tatil 2, diğerleri 1). Vakit: 0–5 yaş 0, 6–10 yaş 2, öğrenci 5, maaşlı çalışan 3, kendi işinin başında 2, iş ve işletme birlikte 1, işsiz 5, emekli 6 (22 Ekim 2026; eski "yıllık hak" kararının yerine). Bazı aksiyonlar para da ister (örnek: spor 500 TL, tatil 25.000 TL).
- **Göstergeler:** Sağlık, Mutluluk, Bilgi, İtibar ve Aile Bağı 0–100 arasındadır. Para TL cinsindendir, üst sınırı yoktur.
- **Gizli değerler:** mizaç (Sakin, Asabi, Hayalperest, Hesapçı), şans, memleket, futbol takımı ve kalıcı bayraklar (`ev_sahibi`, `askerligini_yapti` gibi).
- **Ölüm:** Yalnızca Sağlık 0 olunca ya da yaşa bağlı ölüm ihtimali gerçekleşince ölünür. Mutluluk ya da Para 0 olursa oyun bitmez, bir "zor dönem" kart zinciri başlar.
- **Evreler:**

  | Evre | Yaş |
  | --- | --- |
  | Bebeklik | 0–6 |
  | İlkokul | 7–10 |
  | Ortaokul | 11–14 |
  | Lise | 15–18 |
  | Genç yetişkin | 19–29 |
  | Yetişkin | 30–49 |
  | Olgun | 50–64 |
  | Yaşlılık | 65+ |

- **MVP'deki kariyerler:** Memur, Esnaf, Plaza çalışanı.
- **Görseller:** Katmanlı SVG parçalarından birleşen portreler (`flutter_svg`). Yaş evresi değiştikçe saç ve yüz katmanı değişir.
- **Para kazanma:** Oyun ücretsiz.
  - Ödüllü reklam: hayat başına en fazla 3.
  - Geçiş reklamı: yalnızca ölüm ekranından sonra, hayat başına en fazla 1.
  - Reklamsız paket ve meslek paketleri.
  - Paylaşım karşılığında oyun içi ödül verilmez.

## Teknik kurallar

- `lib/engine/` saf Dart'tır ve Flutter import etmez. Oyun mantığının tamamı buradadır ve `test/engine/` altında birim testleri vardır.
- Rastgelelik tohumlu (`Random(seed)`) çalışır: aynı tohum aynı hayatı üretir. Testler sabit tohum kullanır.
- İçerik veridir. Olaylar `assets/cards/*.json` dosyalarındadır ve yeni olay eklemek için kod değiştirilmez. Şema ve örnek: `assets/cards/README.md` (rol yuvaları, kişi etkileri, iplikler); kurallar canlı dokümanın "Derin hayat" sekmesinde, "Hikâye motoru" bölümünde.
- Kartlar yüklenirken doğrulanır. `tools/card_lint` tüm kart dosyalarını şu açılardan kontrol eder (ayrıca kırmızı çizgilere giren kelimeler için uyarı verir; incelenen kullanımlar `registry.json` → `reviewedTerms`):
  - eksik alanlar
  - bilinmeyen bayrak ya da etki adları
  - kart metni en fazla 140 (en uzun adla), seçenek metni en fazla 24 karakter
  - tanımsız rol yuvası, bilinmeyen yer tutucu alanı, elle yazılmış ek (`{ad|e}` yazılmalı)
  - iplik hedefi ve taşınan yuvalar, Aile Bağı'nı doğrudan değiştiren etki, 18 yaş altı romantik bağ
  - tekrar eden kimlikler
- Durum yönetimi Riverpod ile, kayıt yerel olarak Hive ile yapılır.
- Platforma özgü her şey (reklam, satın alma, paylaşım, titreşim, analitik) `lib/services/` altında bir arayüzün arkasında durur. Motor hangi platformda çalıştığını bilmez.
- Arayüz metinleri `lib/l10n/` altındaki ARB dosyalarındadır. Kart metinleri Türkçe olarak JSON dosyalarında durur.
- Hedef platform sürümleri:
  - Android: minSdk 24, targetSdk 36 (Google Play 31 Ağustos 2026'dan beri API 36 istiyor).
  - iOS: 15 ve üzeri. Derleme Xcode 26 ile yapılır (App Store 28 Nisan 2026'dan beri istiyor).

## Klasör yapısı

```
lib/
  engine/      # YearTick, EventDeck, EffectResolver, ScheduleQueue, DeathCheck, SummaryBuilder
  models/      # Character, Stats, Card, Choice, Effect, Career, Asset
  content/     # JSON yükleyici ve doğrulayıcı
  ui/          # ekranlar: doğum, yıl, kart, aksiyon, ölüm, albüm
  services/    # kayıt, reklam, satın alma, analitik, paylaşım (arayüz + platform uygulaması)
  l10n/        # ARB dosyaları
assets/
  cards/       # evre ve kariyer bazında JSON kart dosyaları
  portraits/   # SVG portre parçaları
test/
  engine/      # motor birim testleri
tools/
  card_lint/   # kart dosyası denetleyicisi
docs/
  GDD.md       # oyun tasarım dokümanı
```

## Kart yazım kuralları

- Mizah gözleme dayanır ve sevecendir. Oyuncu "bu benim annem" diyerek gülmeli, "bu bana hakaret" dememeli.
- Konuşan karakter kendi ağzıyla konuşur: anne, kayınvalide, ev sahibi, bakkal.
- Kartın iki seçeneği de mantıklı olmalı. "Doğru cevap"ı belli olan kart sıkıcıdır.
- Hastalık, ölüm ve boşanma gibi ağır olaylarda şaka yapılmaz; ton şefkatli ve kısadır.
- Şu konular oyunda hiç yer almaz:
  - gerçek siyasetçiler, partiler, seçimler
  - etnik köken, din, mezhep ya da bölge üzerinden alay
  - cinsiyet, engellilik ya da cinsel yönelim aşağılaması
  - intihar, kendine zarar, ağır şiddet, çocuk istismarı
  - kumar simülasyonu ve gerçek marka adları
- Futbol takımları kurgusaldır.

## Komutlar

```
flutter pub get
flutter analyze
flutter test
flutter run
dart run tools/card_lint/bin/card_lint.dart
dart run tools/life_report/bin/life_report.dart [hayat sayısı]   # denge raporu
flutter build appbundle        # Android (Windows)
flutter build ipa              # iOS (yalnızca Mac)
```

## Çalışma şekli

- Her görevde önce kısa bir plan yaz ve kullanıcının onayını bekle. Sonra küçük adımlarla ilerle.
- `flutter analyze` ve `flutter test` temiz çıkmadan bir adımı bitmiş sayma.
- Kod GitHub üzerinden Windows ile Mac arasında taşınır. Platforma özgü bir şeye dokunduğunda (`android/`, `ios/` klasörleri, izinler, `Info.plist`) bunu kullanıcıya açıkça söyle ki iki platformda da denesin.
- Commit mesajları Türkçe ve kısa olsun.

## Tamamlanan aşamalar

- **F0 — Motor prototipi** (14 Ekim 2026): Android telefonda ve iPhone'da bir hayat baştan sona çökmeden oynandı.
- **F1 — Dikey dilim** (14 Ekim 2026): kayda hazır motor, ekonomi (altın, ev, araba, kira, kredi, enflasyon), 3 meslek, aile durumu, Hive kaydı, 150 kart, `life_report`. Kullanıcı kendi telefonunda denedi. 5 kişilik dış test kapısı kullanıcının kararıyla ertelendi: dağıtım uygulama bitince, F3'teki kapalı testle birlikte yapılacak.
- F1 denge kararları: altın yıllık %−15 / %+15; kira en fazla 240 bin; göstergelerde 50'nin üstünde azalan kazanç; itibar ve mutluluk her yıl ortaya uzaklıklarının onda biri kadar kayar; lakapta en belirgin özellik kazanır, itibar iki kat sayılır.
- **F2 — Cila ve paylaşım** (15 Ekim 2026): hayatın sayıları, 9:16 paylaşım kartı, 18 rozet ve Hayat Albümü, katmanlı SVG portreler, Nunito ve sıcak tema, ses ve titreşim (yer tutucu sesler), Firebase Analytics ve Crashlytics. Kapı: kullanıcı analitik olaylarının konsola aktığını doğruladı.
- F2 kararları: portre parçalarını Claude çizdi (`assets/portraits/README.md`, illüstratör aynı adlarla değiştirebilir); gerçek sesleri kullanıcı bulacak (`assets/sounds/README.md`); Nunito gömülü (OFL). Firebase projesi `biromur-d0006`; analitik oyuncu onay verene kadar kapalı (doğum ekranında bir kez sorulur, Ayarlar'dan değişir), karakter adı gönderilmez; Crashlytics anonim ve debug sürümünde kapalı. iOS dSYM yükleme betiği F3'e kaldı.

## Mevcut aşama: D — Derin hayat (tasarım)

Karar (22 Ekim 2026): Oyun "her yıl kart kaydır" yapısından; kişilerin, hafızanın, işlerin ve işletmelerin birbirine bağlandığı sekmeli bir hayat simülasyonuna dönüşüyor. Tasarım, canlı dokümanın "Derin hayat (taslak)" sekmesinde. Kod, kullanıcı taslağı onaylamadan yazılmaz. Sıra: D0 taslak onayı → D1 kişiler ve İnsanlar sekmesi → D2 eğitim ve meslekler → D3 işletmeler → D4a iplikler ve zor gün → D4b aşk, evlilik, çocuklar → D5 denge ve cila. Sonra F3a'nın kalan iki adımı, F4 ve F3b.

Bu aşamada alınan kararlar (22 Ekim 2026):

- Temel kural: ilişkiler oyuncunun arkasından değişmez. Yakınlık ve husumet ancak oyuncunun bir seçimiyle değişir; kişilik özellikleri davranışı değiştirir, çubuğu değil.
- Ekonomi gerçek 2026 rakamlarına çekilir (mevcut tutarlar yaklaşık × 3,3; ayrıntı dokümanın "Ekonomi ölçeği" bölümünde).
- Oyuncu romantik ilişkide cinsiyet seçebilir. 18 yaşından önce romantik bağ yalnızca platonik ve en fazla 1 yaş farkla olur.
- Yıllık vakit puanı eski aksiyon hakkının yerine geçti (yukarıda "Vakit"); yarı zamanlı iş, fazla mesai ve kendi işi D2 ve D3'te eklenir.
- İlk sürüm kapsamı dar başlar: 6 kişilik özelliği; 4 işletme (simit, berber, oto yıkama, yazılım; fabrika yalnızca aileden devralma); alan başına 1 meslek. Kalanlar güncellemelerle gelir.
- Mevcut Esnaf mesleği kaldırılacak; "kendi dükkânı" işletme sistemine geçer.
- Eski 150 kart taşınmaz; olaylar yeni formatta sıfırdan yazılır. Oyun mantığı (karakter, yıl döngüsü, olaylar, card_lint, ana ekran) baştan yazılır; altyapı (tohumlu rastgelelik, kayıt, servisler, portre, tema) kalır.

D1 adımları (kişiler ve İnsanlar sekmesi):

- [x] Türkçe ek motoru: `lib/content/turkish.dart` (`{ad|e}` gibi ekler, hitaplar, şablon denetimi)
- [x] Kişi ve hafıza modeli: `lib/models/person.dart`, `lib/engine/relationships.dart` (yakınlık ve husumet anılardan hesaplanır)
- [x] Aile profilleri ve doğum: `assets/families.json`, `assets/names.json` (ad kuşakları), `lib/engine/family_generator.dart`
- [x] Kişilerin yılı: `lib/engine/people_tick.dart` (kendi hayatı, haberler, sınıflar, aynı evde soğumama, arşiv)
- [x] Vakit puanı: `ActionCatalog.timeFor`, aksiyonların vakit bedeli (`timeCost`)
- [x] Etkileşimler ve Ara sohbeti: `lib/engine/interactions.dart`, metinler `assets/interactions.json` (yükleyici denetler), `lib/content/person_text.dart`
- [x] Yeni olay formatı ve card_lint; eski kartlar silindi (şema `assets/cards/README.md`). Eski kartlara bağlı üç rozet (Dipten döndü, Akrabayla iş olur mu, Dört kuşak) geçici olarak kaldırıldı; D3, D4a ve D4b'de yeni sistemlerle dönecek. Aile Bağı artık ailenin yakınlığından hesaplanır; "Aileyle vakit", "Arkadaşlarla buluş" ve "Memleket ziyareti" aksiyonları kalktı (memleket D2'de şehirle döner).
- [x] D1 içeriği: 69 olay, 6 dosya (`assets/cards/`): dönemeçler (ilkokul, LGS, YKS, askerlik, cenazeler), iplikler (mezuna kalma, mezuniyet, kardeşin borcu), çocukluk, okul, aile profilleri, yetişkin aile ve mahalle. Vefat yuvası (`deceased`), `{oyuncu.hitap.evlat}` ve abla/ağabey sözcükleri eklendi. Gerçek içerikle 300 hayat testi `test/content/real_cards_test.dart`. Askerliğin bölük arkadaşları, tercih ekranı ve kadınlar için eşdeğer yol D2'de. Bekleyen içerik notları: D4b'de evlilik gelince `dugunde_soru` ve `baba_ogudu` kartlarına "evli değil" koşulu eklenmeli; `sameCity` şimdilik memlekete bakıyor, D2'de oyuncunun yaşadığı şehre bakmalı (`annenin_kaplari`, `gozum_yollarda`); D2 ekonomi ölçeğinde bedelli ve ehliyet tutarları da büyütülmeli.
- [x] Kayıt sürüm 2: `LifeEngine.snapshotVersion = 2`, `canRestore`. Sürüm 1 kayıtları dönüştürülemez; doğum ekranı açıklayıp siler (albüm ve rozetler kalır).
- [x] Arayüz: kartlardan sonra beş sekme (Ben, İnsanlar, Okul / İş, Varlıklar, Aktiviteler; `lib/ui/screens/home_tabs.dart`), İnsanlar listesi ve kişi ekranı (`lib/ui/people/`), Ara sohbeti (ton, anı), Ben sekmesinde yıl günlüğü (haberler ve seçimler)
- [x] 300 hayat simülasyonu ve `life_report`: test oyuncusu ve rapor artık kişilerle de etkileşir (`LifeEngine.possibleInteractions`); rapora kişi, hafıza ve olay akışı ölçümleri eklendi. D5 denge notu: rastgele oyuncuda Aile Bağı ölümde ortalama 97, "Bayramların Baş Köşesi" lakabı %79 ve "Her Bayram Elini Öptü" rozeti %87; aile tabanı (anne 70) ve olumlu anıların toplanması yakınlığı çabuk doyuruyor. Ev, araba ve kira olayları D2 ile gelecek (şimdi %0).
- [ ] Telefonda deneme (D1 kapısı). Kullanıcı ilk denemede şunları buldu: kaynağı görünmeyen para (yaşam gideri yok, gelir dökümü yok), peş peşe gelen kartlar, işteyken "Ders çalış", ad ile cinsiyet uyuşmazlığı (düzeltildi), açıklamasız zar sonucu (düzeltildi).

Karar (22 Ekim 2026): Kullanıcı ara kapıları kaldırdı. D2, D3, D4a, D4b ve D5 adım adım onay beklenmeden sırayla bitirilecek; kullanıcı en sonda telefonda test edip hataları bildirecek. Her aşamanın sonunda bağımsız bir mantık denetimi yapılır.

D2 adımları (eğitim, meslekler, ekonomi; telefon denemesi ve denetim bulguları dahil):

- [x] D2.0 Hızlı düzeltmeler: aksiyonların yaş, iş ve öğrenci şartları; vakit bedeli ve kapalılık sebebi; bebek ve aynı evdekiyle etkileşim; iş etiketi; kart tekrarı (tazelik ağırlığı, ömür boyu sınır); kart mantık düzeltmeleri; genç ölüm metni; dönemeçlere nadirlik
- [x] D2.1 Para dökümü: her para hareketinin kaynağı; Varlıklar sekmesinde bu yılın ve geçen yılın dökümü
- [x] D2.2 Ekonomi 2026 rakamları ve yaşam gideri: ölçek × 3,3 (ev 5 milyon tek fiyat, araba 1,8 milyon, kira orta şehirde 330 bin, altın 6.500); yaşam gideri aileyle 0, yurtta 60 bin, diğerlerinde 150 bin; lise cep harçlığı 6 bin (dar aile 0), üniversite harçlığı aileye ve anne-babayla yakınlığa göre; 18 yaş desteği varlıklı 1,32 milyon, orta 330 bin. Karar: işsize kendiliğinden gelir yok, "Ara işlere git" aksiyonu (2 vakit, 200 bin). Emekli aylığı en az 15 yıl çalışana (taban 240 bin); çalışmamış 65 yaş üstüne 60 bin yaşlılık aylığı
- [x] D2.3 Şehir ve ev: `Character.city` ve `home` (`lib/models/home.dart`), 3 şehir türü (`lib/engine/cities.dart`, kira ve maaş çarpanı), Varlıklar sekmesinde evden çık, ev arkadaşı, aileye dön, ev ve araba al-sat (peşinat %20, kalanı kredi), başka şehre taşın (2 vakit, işi bırakır); ev sahibi ve ev arkadaşı kişi olarak gelir; taşınınca mahalle değişir, emekli ya da vefat eden komşu ve bakkalın yerine yenisi gelir (`lib/engine/housing.dart`). `kiraci` ve `tasindi` artık motorun türettiği bayraklar
- [x] D2.4 Eğitim yolu: `Character.education` (`lib/models/education.dart`), kurallar `lib/engine/education.dart`. 15 yaşında lise türü (LGS iyi → Anadolu, bilgi yüksekse fen; kaçıran lise seçimi kartında düz ya da meslek lisesi). 18 yaşında kartlardan sonra YKS puanı (bilgi, lise, sınav sabahı, şans); Okul / İş sekmesinde tercih: 7 bölüm (bilgisayar, iktisat, hemşirelik, işletme, kamu yönetimi, tarih, açıköğretim) ve şehir (büyükşehir taban +25, küçük −20); ya da mezuna kal, çalış, çırak. Tercih yapmadan yaşlanan çalışmayı seçmiş sayılır. Başka şehirde okuyan yurda taşınır; 5 sınıf ve 1 oda arkadaşı. Her yıl ders geçme zarı (en fazla 2 yıl uzar), burs (dar aile KYK 42 bin, 420+ puana 100 bin), yarı zamanlı iş aksiyonu (2 vakit, 150 bin). Mezuniyette motor mezuniyet olayını planlar, yurttaki ailesinin yanına döner. Öğrenci ve mezun bayrakları motorun. Staj D2.7 ilanlarıyla gelir; yıl günlüğünde oyuncunun kendi notları (`LifeNote`)
- [x] D2.5 Askerlik: celp kartında "yaparak" seçen o yılı askerde geçirir (`askerde`, vakit 0); yaşlanınca 3 bölük arkadaşı (biri arkadaş) gelir, `askerligini_yapti` ve `asker_anilari` açılır (`lib/engine/military.dart`). Bedelli bu yılı yaşamaz. Kadınlar için eşdeğer bağ kaynakları yurt ve oda arkadaşı (D2.4) ile iş yerinin ekibi (D2.7); askerlik rozetinin eşdeğeri D5'te
- [x] D2.6 Meslekler: memur (KPSS ile), hemşire (hemşirelik), yazılımcı (bilgisayar ya da yazılım kursu), plaza çalışanı (her mezun), oto tamircisi (meslek lisesi ya da çıraklık), garson, emlakçı (oynak gelir); Esnaf ve "Zincirin Sahibi" rozeti kalktı (D3'te işletmeyle döner). Meslek dosyaları giriş şartı, ilan şirketleri, ilan cümleleri ve mülakat sorularını taşır. İşte performans (tempo: rahat / normal / yüklen; yüklenmek vakti 1 azaltır), terfi ve zam oyuncunun isteğiyle (yılda bir, 1 vakit), performans 20'nin altına inerse kovulma, 25 yıl çalışıp 55 yaşında erken emeklilik, maaş şehir çarpanıyla
- [x] D2.7 İlanlar, mülakat, torpil, İş sekmesi: her yıl şehir türüne göre 3–6 ilan (%25 üst pozisyon, deneyim ister), mülakatta iki cevaplı soru (cevap hangi değere zar atacağını belirler), o meslekte çalışan yakın tanıdık aracı olabilir (60+ yakınlıkta doğrudan alınır, itibar −3). İşe girince patron ve üç iş arkadaşı gelir; ayrılınca "eski" olurlar (`lib/engine/jobs.dart`). "İş ara" aksiyonu kalktı; KPSS ve yazılım kursu aksiyon
- [x] D2.8 D2 olayları: 25 yeni olay (`genclik.json`, `is_yeri.json`): meslek lisesi stajı, deneme sınavı, yurt ve ev arkadaşı, vize gecesi, proje grubu, kulüp, staj (`staj_yapti` mülakata +8), harçlık, bölükten arama, işsiz mezun; iş yerinde cuma e-postası, çay ocağı, yılbaşı çekilişi, rapor, "biz bir aileyiz", fikir hırsızlığı, ulaşım, akraba torpili; kira zammı, kombi, yeni komşunun keki, kredi kartı, altın günü, bakkalın önünde maç. Kart şemasına `performance` etkisi (yalnız iş koşullu olaylarda)
- [ ] D2.9 300 hayat testi, `life_report`, bağımsız mantık denetimi

## Bekleyen aşama: F3a — Dağıtıma hazırlık

Sıra kararı (15 Ekim 2026): GDD'deki F3 → F4 sırası yerine F3a (dağıtıma hazırlık) → F4 (reklam ve satın alma) → F3b (kapalı beta: Google Play kapalı testi ve TestFlight). Kullanıcı dış dağıtımı uygulama bitince yapmak istiyor. 22 Ekim 2026'da D aşaması öne alındı; kalan iki adım D5'ten sonra yapılır.

Adımlar:

- [x] Hassas kart taraması: kırmızı çizgilere göre 150 kart; card_lint'e incelenecek kelime denetimi
- [x] Uygulama ikonu ve açılış ekranı: portre yüzlü ikon (`tools/app_icon`, elle çalıştırılır), Android uyarlanabilir ikon, kâğıt rengi açılış
- [x] Android release imzası: `android/key.properties` (depoya girmez), yoksa debug imzası; anahtar oluşturma ve yedek `docs/RELEASE.md`
- [ ] iOS dSYM yükleme betiği: adımlar `docs/RELEASE.md`; kullanıcı Mac'te Xcode'da ekleyip `flutter build ipa` ile doğrulayacak
- [ ] Gizlilik politikası taslağı; Play Data safety ve App Store gizlilik etiketi cevapları

Sonraki aşamalar `docs/GDD.md` dosyasındaki "MVP kapsamı ve yol haritası" bölümünde.
