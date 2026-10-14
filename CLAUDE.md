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
- **Aksiyon menüsü:** Yıllık hak sayısı hayat evresine göre değişir: çocuk 2, öğrenci 4, çalışan 2, emekli 4. Bazı aksiyonlar para da ister (örnek: spor 500 TL, tatil 25.000 TL).
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
- İçerik veridir. Kartlar `assets/cards/*.json` dosyalarındadır ve yeni kart eklemek için kod değiştirilmez. Şema için `docs/GDD.md` dosyasındaki "Kart veri formatı" bölümüne bak.
- Kartlar yüklenirken doğrulanır. `tools/card_lint` tüm kart dosyalarını şu açılardan kontrol eder:
  - eksik alanlar
  - bilinmeyen bayrak ya da etki adları
  - kart metni en fazla 140, seçenek metni en fazla 24 karakter
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

## Mevcut aşama: F2 — Cila ve paylaşım (6.–7. hafta)

Bu aşamanın kapısı: çökme yok, analitik olayları akıyor.

Kararlar (14 Ekim 2026):

- Portre SVG parçalarını Claude çizer (düz, basit). Parça biçimi sabittir; ileride illüstratör çizimleri aynı dosya adlarıyla yerine konabilir.
- Telifsiz sesleri kullanıcı bulur ve lisansını kontrol eder; kod yer tutucu seslerle hazırlanır.
- Yazı tipi uygulamaya gömülür (OFL lisanslı, Türkçe karakterleri tam).
- Firebase en sona kalır; proje ve yapılandırma dosyaları kullanıcıdan gelir. Analitik onay ekranının zamanı o adımda konuşulur.

Adımlar:

- [x] Hayatın sayıları: ömür boyu sayaçlar (taşınma, ödenen kira, takılan altın, terfi, çalışılan yıl, borç dönemleri)
- [ ] Paylaşım kartı: 9:16 hayat özeti görseli, `share_plus` ile paylaşım (ödülsüz)
- [ ] Başarımlar (`assets/achievements.json`) ve Hayat Albümü ekranı
- [ ] Görsel stil ve katmanlı SVG portreler
- [ ] Ses ve titreşim (`lib/services/`, ayarlardan kapatılabilir)
- [ ] Firebase Analytics ve Crashlytics (`lib/services/` arkasında)

Sonraki aşamalar `docs/GDD.md` dosyasındaki "MVP kapsamı ve yol haritası" bölümünde.
