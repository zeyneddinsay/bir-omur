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
  | Bebeklik | 0–2 |
  | Erken çocukluk | 3–6 |
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
  - her seçeneğin sonuç cümlesi (`result`; zarlıda `successResult` ve `failResult`, en fazla 110 karakter)
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
- Karar (23 Ekim 2026, kullanıcı): oyunda eşcinsel içerik hiç yer almaz; romantik ilişki yalnızca karşı cinsle kurulur (22 Ekim'deki "cinsiyet seçebilir" kararının yerine). 18 yaşından önce romantik bağ yalnızca platonik ve en fazla 1 yaş farkla olur.
- Karar (23 Ekim 2026, kullanıcı): aynı olay bir hayatta iki kez gelmez. Kişi, genel, yer ve tesadüf olayları `"once"`; tekrar yalnızca dönemeç (cenaze) ve iplikte, onlarda da metin çeşitleriyle (`variants`). card_lint denetler.
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
- [x] D2.9 Bağımsız mantık denetimi (17 bulgu) ve düzeltmeler:
  - Vakit artık harcanandan hesaplanır (`LifeState.timeSpent`). Tempo ve başında durma düğmesiyle vakit kazanılmaz.
  - İş okuldan önce gelir: çalışan açıköğretimli 3 vakit alır, yarı zamanlı iş yapamaz.
  - Lisede (YKS yılı dahil) ilan yok. Örgün öğrenciliğe yerleşen işinden ayrılır.
  - Askerdeki yıl maaş, kıdem, yaşam gideri ve yaşa bağlı ölüm yok. Celpten sonra o yılın uymayan olayları düşer.
  - Taşınan ya da işinden ayrılan oyuncunun patronu ve iş arkadaşları "eski" olur. Yere bağlı rolü olan kişi taşınmaz, emekli patronun rolü biter, patron en fazla 62 yaşında.
  - Yurtta komşu yok; okul yüzünden şehir değişince mahalle de değişir.
  - Anne ve baba yoksa aile evinde yaşam gideri ödenir ("Aile evinde yaşıyorsun").
  - Kamu işi (`public`): kovulma yok, maaş her şehirde aynı, torpil yok. Amir rolleri: patron, amir, usta (meslek dosyasında `boss`).
  - Kovulan yarım yılın maaşını ve kıdem tazminatını alır.
  - Ev ve araba: para yetiyorsa peşin alınır. Taksit düzenli gelirin yarısını geçemez. Satış önce krediyi kapatır. Ev fiyatı şehre göre değişir ve evin değeri saklanır.
  - Torpil eşiği düşürür (yakın biri −20, uzak biri −10), kimseyi doğrudan işe aldırmaz.
  - Terfi şansı en fazla %85. Terfi ve zam düğmesinin altında neden kapalı olduğu yazar.
  - Kart koşullarına meslek listesi (`careers`) ve aynı evde yaşama (`livesTogether`) eklendi; ofis kartları ve aynı evdeki aileyle çelişen kartlar düzeltildi.
  - Hoş geldin kartları yalnızca taşınma yılında gelir (`yeni_tasindi`).
  - Emekli aylığı son işin maaşına göre hesaplanır.

D3 adımları (kendi işin):

- [x] İşletmeler: simit, berber, oto yıkama, yazılım (büyüyünce ekipli). Kurallar `lib/engine/business.dart`, türler `lib/engine/business_types.dart`.
  - Kuruluş için para yetmezse %30 peşinat, kalanı 5 yıllık kredi.
  - Başında durmak ya da müdüre bırakmak; ek şubeyi müdür yönetir. Fiyat, reklam, şube (en fazla 3), ortak, tanıdığını işe alma, satma ve kapatma.
  - Nakit eksiye düşüp zarar eden işletme batar; aynı türü 2 yıl açamaz.
  - İtibar her yıl ortaya kayar. Kâr dokümandaki aralıklara ayarlandı (`life_report`).
  - Çalışanlar, müdür, ortak ve rakipler kişi olarak gelir.
- [x] İş sekmesinde "Kendi işin" kartı ve "İşletme aç" ekranı (`lib/ui/widgets/business_card.dart`). Deftere `isletme` kalemi, günlüğe işletme notları.
- [x] İşletme olayları (`assets/cards/isletme.json`, 17 olay): zabıta, yağmur, müşteri, rakip, çalışan, nazarlık, veresiye, dükkân kirası, akraba çalışan. Kart şemasına `business` koşulu ve etkisi eklendi.
- [x] Aile fabrikası: fabrikatör ailenin çocuğuna 22–30 yaş arasında babasından teklif gelir (`aile_fabrikasi` mesleği, ilansız).
- [x] Rozetler: Zincirin Sahibi (üç şube) ve Akrabayla İş Olur mu? (akraba ortak); motor bayrakları `zincir_sahibi`, `akraba_ortak`, `isletme_acti`.
- [x] D3 bağımsız mantık denetimi (19 bulgu) ve düzeltmeler:
  - Reklam yalnızca o yılın cirosuna %10 ekler; itibara katkısı +3. Pahalı fiyatta itibar duyarlılığı ×1,5.
  - Satış değeri kâr geçmişine bağlı (1 yıl 0, 2 yıl 1, 3 yıl 2 kat). Zarardaki işletme satılamaz, yalnızca kapatılır. Satılan ya da kapatılan tür 2 yıl açılamaz.
  - Ortak çıkışta en az sermayesini alır; eski ortak yeniden ortak olamaz. Net servet işletmeleri sayar.
  - Yalnızca bir işletmenin başında durulur. Başka şehirde ya da askerdeyken işletme müdürde sayılır. İşi olan, işletmeyi müdürle açar.
  - Ölen ya da emekli olan çalışanın ve müdürün yerine yenisi gelir; ölen ortağın ortaklığı biter. Kapanışta rakipler rakip olmaktan çıkar.
  - Tanıdık yalnızca yabancı bir çalışanın yerine alınır.
  - Kredi 18 yaştan itibaren. Ekipli ve tek kişilik yazılım aynı koldur.
  - Kart koşullarına `businessTypes` ve `atBusiness` eklendi.
  - Emek işinde ek şubeyi usta yönetir (müdür maaşı yok). Müdür maaşı 340 bin; oto yıkama cirosu 1,4 milyon.
- D5 denge notları: test oyuncusu neredeyse her hayatta işletme açıyor, bu yüzden medyan servet yaklaşık 10 milyon. Varlıklı ailenin medyan serveti ortadan düşük çıkıyor (örneklem küçük, %5).

D4a adımları (iplikler, dünya küçük, zor gün):

- [x] İplik kapanışı: taşınan kişi vefat ettiyse ya da çevreden ayrıldıysa olay gelmez, günlüğe kapanış cümlesi yazılır (kartta `closing`, yoksa genel cümle).
- [x] Dünya küçük kuralı: yeni patron, amir, usta, ev sahibi, işletme müdürü ve rakip %35 ihtimalle uygun bir tanıdıktan seçilir (`PersonFactory.addOrReuse`). Günlükte "Dünya küçük: Kerem artık patronun. Onu okuldan tanıyorsun."
- [x] Zor gün yılı (`lib/engine/hard_day.dart`):
  - Sebepler: borca düşmek, kovulmak, işletmenin batması, yakının (çekirdek aile ya da 60+ yakınlık) vefatı, bunalım.
  - O yıl en çok 3 kişi arar, her biri bir olay olarak gelir (`zor_gun_aradi`). Açıp dertleşilen "gerçek dost" olur.
  - Arkadaşın olup aramayana "Zor günümde aramadı" anısı yazılır. Para gelince "Zor günümde neredeydin?" olayı, yıllar sonra "O zor yıl" olayı gelir.
- [x] Hayatın sonu (`lib/engine/life_story.dart`, ölüm ekranında "Hayatındaki insanlar"): son gününde yanındaki, cenazeye gelenler (gerçek dostlar önde, küs olup gelen, zenginse tanımadığın akrabalar), en yakın üç kişi, seni en çok özleyecek kişi, kurduğun işler. Yeni lakaplar: Patron, Herkesin Dostu, Gurbetçi Ruhlu.
- [x] D4a bağımsız mantık denetimi (12 bulgu) ve düzeltmeler:
  - Vefatta zor gün yalnızca çekirdek aile ya da 80+ yakın dost için. Borç zor günü −100 bin altında ve öğrenci ya da aileyle yaşayan değilse. Karşılaştırma yılın başıyla.
  - Olay olarak en çok 2 arayan gelir; arama isteyen herkes "aradı" sayılır. "Aramadı" anısı yalnızca 40+ yakın arkadaşa, aynı kişiye 5 yılda bir yazılır. Arama olayı yalnız zor gün yılında gelir.
  - Dünya küçük kuralı: süren rolü, sevgilisi ya da eski eşi olan, aynı rolü daha önce üstlenmiş ya da mesleği uymayan tanıdık seçilmez; servet değişmez. İşletme müdürü günlükte "işletmenin müdürü".
  - Ölüm ekranı: gerçek dostlar ve küs olup gelen cenazeye katılır; yanındaki kişide aynı şehir önce.
  - Rol yuvasına `memoryYears` (anı en az kaç yıllık) eklendi.

D4b adımları (aşk, evlilik, çocuklar; `lib/engine/romance.dart`):

- [x] 13–14 yaş dönemeci `ilk_hoslanti_erkek` / `ilk_hoslanti_kiz`: karşı cinsten iki sınıf arkadaşından hangisinden hoşlandığın (platonik; yıllar sonra `sinif_bulusmasi` olayıyla döner). Romantik bağ yalnızca karşı cinsle, 18+ ve yaş kuralıyla (küçük olan büyüğün yarısı artı 7).
- [x] Aktiviteler'de "Biriyle tanış": ilgi duyulan cinsiyetten, yaşı uyan, bekâr biri arkadaş olarak gelir.
- [x] İnsanlar'da yeni etkileşimler: duygularını açıkla (50+), ciddi düşünüyorum (60+, flörtten en az 1 yıl sonra), evlenme teklifi (75+, 20 yaş), ayrıl ya da boşan (nakit yarı yarıya), çocuk isteyelim mi (60+, 20–45 yaş, en fazla 4 çocuk, iki yıl arayla).
- [x] Teklif kabul edilince gelecek yıl kız isteme (oyuncu erkekse damat, kadınsa gelin tarafı), ondan sonraki yıl düğün. Düğünde eş olur, kayınvalide ve kayınpeder gelir, aile evinde yaşayan kiraya çıkar.
- [x] Doğum: adı kayın taraf, annen ya da siz koyarsınız. Eş ve 18 yaşından küçük çocuklar aynı evde sayılır ve taşınınca birlikte taşınır.
- [x] Hane bütçesi: çalışan eş +300 bin, çalışmayan eş −150 bin, evdeki her çocuk −100 bin (deftere ayrı kalemler).
- [x] Çocuklar 24 yaşından sonra evlenir; evli çocuğun torunu olur. Rozetler geri döndü: Dört Kuşak Bir Fotoğrafta (`dort_kusak`), Dipten Döndü (`dipten_dondu`).
- [x] Olaylar (`assets/cards/ask.json`, 21 olay): yıl dönümü, kıskançlık, ilk tatil, "annen beni sevmedi", bayram kimde, kayınvalide ziyareti, ev işleri, ilk adım, veli toplantısı, okul maçı, ergen, eşin ve evladın cenazesi. `dugunde_soru` ve `baba_ogudu` evlilere gelmez.
- [x] D4b bağımsız mantık denetimi (12 bulgu) ve düzeltmeler:
  - Çocuk adı önerisi büyüklerin ve bugünün adlarından, kardeşlerin ve eşin adı tekrar önerilmez.
  - Boşanınca ve yeniden evlenince eski kayın aile kayın olmaktan çıkar. Boşanınca planlı doğum, ayrılınca kız isteme ve düğün iptal olur.
  - Eş ve küçük çocuklar okul yüzünden şehir değişince de oyuncuyla gelir; yurtta evlenen kiraya çıkar.
  - Sevgili ve nişanlı arşive düşmez, onlarla "Uzaklaş" yok. Teklif 70 yaşına kadar.
  - Eşte düğme "Boşan"; ayrılık ve boşanma onay ister (bölünecek birikim gösterilir).
  - Düğünde ucuz seçenek: belediyede nikâh (30 bin). Askerdeyken aşk olayları bir yıl bekler. Kapanış cümlesi yalnızca yazılmış ipliklerde.
  - Emekli eş bütçeyi eksiltmez. Erkek oyuncu ya da erkek eş için çocuk kararında üst yaş 55.
  - Bayram kimde olayı kayın aile ve anne yaşıyorsa gelir. "Evlen" baskısı sevgilisi olana ve evlenmiş olana gelmez (`iliskide`, `evlenmis` bayrakları).
- D5 notları: test oyuncusunda evlenen %93, boşanan %6, hayat başına 2,7 çocuk, medyan evlilik yaşı 34. "Patron" lakabı %51 (test oyuncusu neredeyse her hayatta işletme açıyor). Zor gün hayat başına 4,1 yıl.

D5 adımları (denge, mantık taraması, hikâye akışı, cila):

- [x] Denge: yakınlık 70 üstü yarı hızla (Aile Bağı ölümde ortalama 65–76), aile tabanları düştü, itibar üst kademe ve itibarlı işletmeyle beslenir, Sözü Dinlenen eşiği 70, berber cirosu 1,1 milyon.
- [x] Bağımsız tam oyun taraması: arşivdekiler de yaşlanır ve vefat eder (en geç 105); eksi bakiyeye %15 faiz; gelir kirayı karşılamıyorsa evden çıkılamaz ve ailesiz şehre taşınılamaz; kirada borca batana "kira borcu" olayı; emeklinin yaşam gideri 100 bin; en büyük an dönüm noktalarından seçilir; uzak akrabanın vefatı yalnızca günlükte, kardeşin ayrı cenaze kartı; istifa ve satışla vakit kazanılmaz; askerde YKS yok; yılbaşı durumu kayda girer.
- [x] Hikâye akışı (`life_report hikaye TOHUM` ile yıl yıl döküm): cümle başında büyük harf; geri dönüş olayları (çocukluk ve okul anıları yıllar sonra döner) ve yeni iplikler (girişim, komşu gencine borç, eski sevgilinin düğünü); yaşlılık, torun, yeğen, çocukluk ve yetişkinlik olayları; eş ve akraba yanlış rolde çıkmaz; eş vefatından sonra 2 yıl yas; oyuncunun adı başkasına verilmez; tekrar eden esprilere ömür sınırı; günlükte seçimler olayın kısa hâliyle.
- [x] Cila: kendi işindeki oyuncu "Kendi işinde", Varlıklar'da işletme satırları, işletme açılamama sebebi (kredi), ölüm ekranında tekrar eden satır yok, rozet adı "Bir Şehrin Çocuğu".
- [x] Telefon bulguları (23 Ekim 2026): romantik içerik yalnızca karşı cinsle (14 yaş dönemeci sınıftan iki adla); kişi, genel, yer ve tesadüf olayları bir hayatta bir kez (card_lint denetler); 0–6 yaşa 20 yeni olay (`bebeklik.json`), her hayat farklı başlar; doğumda "Rastgele" cinsiyet kalktı (seçilmeden düğme kapalı); Ayarlar'da "Yeni hayat başlat" (onaylı, yarım hayat albüme girmez); aynı ailede iki kişi aynı adı taşımaz.
- [x] Kullanıcının ilk notları (23 Ekim 2026): ilgi seçimi kaldırıldı; aynı kart tekrar gelmez (50 yaş üstüne 36 yeni olay, yaşlılıkta boş yıl azaldı); soru eki `{ad|mi}`; bir olayda aynı adlı iki kişi seçilmez; cenaze, bebek ve zor gün aramasında metin çeşitleri.
- [x] Seçimin sonucu ve kart tasarımı (23 Ekim 2026): her seçeneğe sonuç cümlesi (226 olay, yaklaşık 500 cümle); seçimden sonra üstte sonuç paneli (cümle ve göstergelerde gerçekten ne değiştiği), yıl günlüğünde seçim yerine sonuç. Seçenekler kartın altında satır: yön, etiket, neye dokunacağı (gösterge yönü, para tutarı, anı yazılan kişi, "devamı var"), zarlıda "Tutarsa / Tutmazsa" ve kaba ihtimal (yüksek / orta / düşük, `EffectResolver.rollChance`). Kart yeni tasarımda: tema ve nadirlik etiketi, oyun kartı boyu, arkada deste.
- [x] Dershane (23 Ekim 2026, kullanıcı kararı): 16 yaşında herkese gelen dönemeç, aile durumuna göre üç kart. Varlıklı ailede masraf sorun değil; orta ailede aile öder; dar ailede aile karşılarsa mutluluk ve anne ya da babayla yakınlık düşer, borç bulursa (dede, nine, dayı, amca, hala, teyze) `dershane_borcu` bayrağı açılır ve işe girince geri ödeme dönemeci gelir (90 bin), ertelenirse 2 yıl sonra faiziyle (110 bin) ya da hiç ödenmez ve akrabayla arası soğur.
- [x] Hitap ve bağlam denetimi (23 Ekim 2026): okulda "Sinan Öğretmen"; komşu ve bakkala sesleniş yaş farkına göre (20+ amca/teyze, 4+ abi/abla, değilse Bey/Hanım); yer tutucudan sonra elle "de/da/mi" yazmak card_lint hatası; 12 yaş altına çocuk buluşma metinleri; 35 yaş üstünün işi ve ev hanımlığı haber olmaz; kartların koşulları metinle uyumlu hâle getirildi (ofis, işletme türü, yaş, cinsiyet).
- [x] Geç aşk (23 Ekim 2026, kullanıcı kararı): 70 yaştan sonra tanışma ve flört açık; teklif yaş sınırı kalktı, 70 yaştan sonra kabul edilen teklifte kız isteme ve düğün yerine ertesi yıl sade nikâh (`gec_nikah`, `Romance.lateWeddingEvent`). `assets/cards/gec_ask.json`: yaşlılık flörtü (park, torun, rakip, çocuğun itirazı, gece telefonu), gizli nikâh, çocukların kırgınlığı, genç eş ve miras dedikodusu (vasiyet), birikimi eşle paylaşmak. Ölüm ekranı: eş ve yetişkin çocuklar yakınlık düşük olsa da cenazeye gelir, yalnızca küs olan gelmez ("cenazene gelmedi"); ileri yaşta evlenenin mirası vasiyetle sessizce bölüşülür ya da eşle çocuklar arasında kavga çıkar (`LifeStory.inheritance`).
- [x] Emülatör testi düzeltmeleri (24 Ekim 2026; kullanıcı kararları: kumbara erimez, annesiz aile doğumda anlatılır, bebeklik ikiye bölünür): askere gidilen yıl celpten sonra olay gelmez, askerde başlık "Askerde" ve iş kartı yalnız bilgi; iş kartında performansın gidişi (tempo + bilgi) ve uyarı, kovulma yıl başı şeridinde; yeni kişilere hayattaki tanıdıkların adı verilmez; açıköğretim her puana açık, tercihte "bir sonraki basamak"; eşini bu yıl kaybeden akraba neşeli olaylarda rol almaz; günlükte akraba olmayan kişi rolüyle ("Komşun Fatma"); kart sayacı düzeldi; tek ebeveynli ailede doğum notu; 18 yaş altı nakit erimez; Bebeklik 0–2, Erken çocukluk 3–6; çocuk ve ergen aktiviteleri (resim, top, bilgisayar oyunu, arkadaşlarla takılmak, enstrüman) ve aksiyon sonucu paneli; 3–29 yaşta yılda çoğunlukla iki olay, 48 yeni olay (`buyume.json`); yaşa uymayan etkileşimler gizli, akraba için "Aranız iyi" gibi etiketler, "İş ve ev" grubu, nötr renkler; portrelerde aile içi ten tonu, yaşla değişmeyen saç ve yaşlı görünen büyükler.
- [x] Orta yaş olayları (24 Ekim 2026): 45–64 yaşa 34 olay (`orta_yas.json`): boş yuva, çocuğun askere ve ilk evine gidişi, torun baskısı ve bakımı, yaşlanan anne-baba, miras tarlası, genç müdür, yirminci yıl, emeklilik, ikinci balayı, sağlık ve hobi. Olaysız yıl 50'lerde %11'den %0'a, genel %1.
- [x] İleri yaş olayları ve borç (24 Ekim 2026): 78–110 yaşa 34 olay (`ileri_yas.json`; torun ve torun çocukları, dört kuşak, ilaç ve işitme cihazı, yürüteç, huzurevi ve bakıcı, yaşıtın cenazesi, eşyaların paylaştırılması, yüz yaş). Olaysız yıl 80'lerde ve 90'larda yok denecek kadar az. Eksi bakiyeye faiz en fazla 1 milyonluk borca işler (yılda en çok 150 bin): gelirsiz yaşlılıkta borç katlanmaz. Kapsam testi nadir kartlar için ek tohum dener.
- [x] Borçlanan yaşlı (24 Ekim 2026, kullanıcı kararı): 65 yaş üstü, kirada ve borcu 500 bini aşan oyuncuyu hayattaki yetişkin bir çocuğu yanına alır (önce aynı şehirdeki, sonra en yakını; `HomeKind.cocukYaninda`, `Housing.moveInWithChild`). Kira ve gider biter, aylık borcu kapatır; eş de gelir, çocuğun hafızasına anı, günlüğe not. Ev sahibi çocuk vefat ederse öbür çocuk alır, kimse kalmadıysa kiraya çıkar. Çocuğu olmayanda borç faizi tavanı geçerli.
- [ ] Telefonda deneme (kullanıcı)

## Bekleyen aşama: F3a — Dağıtıma hazırlık

Sıra kararı (15 Ekim 2026): GDD'deki F3 → F4 sırası yerine F3a (dağıtıma hazırlık) → F4 (reklam ve satın alma) → F3b (kapalı beta: Google Play kapalı testi ve TestFlight). Kullanıcı dış dağıtımı uygulama bitince yapmak istiyor. 22 Ekim 2026'da D aşaması öne alındı; kalan iki adım D5'ten sonra yapılır.

Adımlar:

- [x] Hassas kart taraması: kırmızı çizgilere göre 150 kart; card_lint'e incelenecek kelime denetimi
- [x] Uygulama ikonu ve açılış ekranı: portre yüzlü ikon (`tools/app_icon`, elle çalıştırılır), Android uyarlanabilir ikon, kâğıt rengi açılış
- [x] Android release imzası: `android/key.properties` (depoya girmez), yoksa debug imzası; anahtar oluşturma ve yedek `docs/RELEASE.md`
- [ ] iOS dSYM yükleme betiği: adımlar `docs/RELEASE.md`; kullanıcı Mac'te Xcode'da ekleyip `flutter build ipa` ile doğrulayacak
- [ ] Gizlilik politikası taslağı; Play Data safety ve App Store gizlilik etiketi cevapları

Sonraki aşamalar `docs/GDD.md` dosyasındaki "MVP kapsamı ve yol haritası" bölümünde.
