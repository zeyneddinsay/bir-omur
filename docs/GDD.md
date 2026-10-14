# Bir Ömür — Oyun Tasarım Dokümanı

14 Ekim 2026 · Canlı doküman: https://claude.ai/code/artifact/5e791558-0c95-419c-a419-5e21c3a1d7a7
(Bu dosya canlı dokümanın dışa aktarımıdır. Tasarım değiştiğinde yeniden dışa aktarılır.)

## Özet

**Bir Ömür, Türkiye'de doğup bir ömrü 15 dakikada yaşadığın, mizahi ama sevecen, kart tabanlı bir hayat simülasyonudur.** Her yıl 1–3 olay kartı gelir; sağa ya da sola kaydırarak karar verirsin, aradaki aksiyon menüsüyle hayatını yönlendirirsin. Ölünce paylaşılabilir bir hayat özeti kartı çıkar.

| Başlık | Karar |
| --- | --- |
| Tür | Metin ve kart tabanlı hayat simülasyonu (BitLife + Reigns hibriti) |
| Platform | Android ve iOS, Flutter ile tek kod tabanı; geliştirme Windows ve Mac'te |
| Dil | Türkçe; İngilizce sürüm oyun Türkiye'de tutunca |
| Hedef kitle | 16–40 yaş Türk mobil oyuncular, TikTok ve Instagram kullanıcıları |
| Ton | Mizahi ama sevecen; kimseyi aşağılamayan, herkesin kendini bulduğu |
| Oturum | Bir hayat 10–20 dakika, tek elle oynanır |
| Model | Ücretsiz; ödüllü reklam, reklamsız paket ve meslek paketleri |

**Temel vaat:** "Türkiye'de bir ömrü baştan sona yaşa, sonunu arkadaşlarınla paylaş." Piyasada her meslek ayrı bir ücretli oyun olarak satılıyor; Bir Ömür hepsini tek ücretsiz oyunda, bir hayatın kariyer bölümleri olarak toplar.

## Pazar ve rakipler

**Türk temalı karar simülatörlerine ilgi var, ama ücretli modelin hacmi çok düşük; bu yüzden Bir Ömür ücretsiz olacak.** Doğrudan Türkçe rakip zayıf, yani alan boş sayılır. Veriler 14 Ekim 2026 tarihli mağaza listelerinden.

| Sinyal | Ne gördük | Bizim için anlamı |
| --- | --- | --- |
| [App Store Türkiye ücretli oyunlar](https://app.appfigures.com/top-apps/ios-app-store/turkey/iphone/games) | İlk 30'da 10'dan fazla Türk meslek simülatörü: Muhtar, Askerlik Kariyeri, Karakol Amiri, Belediye Başkanı, Emlakçı, Oto Galerici, Rent A Car Simülatör, Turkish Coffeehouse Simulator | Türk hayatı ve meslekleri teması oyuncu çekiyor |
| [Duty Court – AppGoblin](https://appgoblin.info/apps/6760950124) | Aynı listedeki bir oyun için tahmini toplam indirme yaklaşık 150 | Ücretli listede az satışla üst sıraya çıkılıyor; ücretli model büyümez |
| [Bir TC Simülasyonu – App Store](https://apps.apple.com/us/app/-/id1670750852) | Türkçe metin tabanlı hayat simülatörü; 29 değerlendirme, 2,8 puan, paketler 0,99 $ | Tek doğrudan rakip ve zayıf; kalite ile geçilebilir |
| [BitLife'ın yükselişi](https://thehighlandernews.com/16032/arts-ent/the-rise-of-bitlife/) | Metin tabanlı hayat simülasyonu yıllardır global listelerde | Tür kanıtlanmış; içerik = mizah |
| [Google Play Türkiye oyunlar](https://www.appbrain.com/stats/google-play-rankings/top_free/game/tr) | Simülasyonlar üst sıralarda: Police Chief 3., Sarı Taksi 21. | Türk oyuncu "meslek yaşama" fantezisini seviyor |

**Konumlandırma:** Rakipler tek meslek, tek oturumluk oyunlar. Bir Ömür doğumdan ölüme bir hayat bağlamı verir; meslekler bu hayatın bölümleri olur ve her biri ayrı bir paket olarak genişler.

## Temel oyun döngüsü

**Bir tur = bir yaş.** Oyuncu "Yaşlan" der, yılın kartlarını kaydırır, kalan aksiyon haklarını kullanır ve bir sonraki yaşa geçer. Ölümle hayat özeti gelir, oradan yeni bir doğum başlar.

Akış (canlı dokümanda çizim olarak var):

```
Yaşlan → Olay kartları (1–3) → Sonuçlar → Aksiyon menüsü → Öldü mü?
   ↑                                                         │ hayır: sonraki yıl
   └─────────────────────────────────────────────────────────┘
                                                             │ evet
Yeniden doğ ← Paylaş ← Hayat özeti kartı ←───────────────────┘
   └──→ yeni hayat, tekrar "Yaşlan"
```

1. **Yaşlan:** Yaş 1 artar. Pasif değişimler işler: maaş, kira, enflasyon, yaşlılığa bağlı sağlık kaybı, ilgilenilmeyen ilişkilerin soğuması.
2. **Olay kartları:** Desteden 1–3 kart çekilir. Kart bir sahne, bir karakter ve bir soru gösterir. Sola ya da sağa kaydırarak seçersin; nadir kartlarda yukarı kaydırmayla üçüncü bir seçenek vardır.
3. **Sonuçlar:** Seçim göstergeleri değiştirir, karaktere bir iz (bayrak) bırakır ve gerekirse yıllar sonra gelecek bir devam olayını sıraya koyar.
4. **Aksiyon menüsü:** Yılda, hayat evresine göre 2–4 aksiyon hakkın vardır (çocuk 2, öğrenci 4, çalışan 2, emekli 4); bazı aksiyonlar ayrıca para ister, örneğin spor 500 TL, tatil 25.000 TL. Bu yüzden çalışırken vakit az ama para var, emeklilikte vakit çok ama para az olur. Seçenekler: Okul/İş, İlişkiler, Para, Sağlık, Memleket, Eğlence.
5. **Ölüm kontrolü:** Sağlık ve yaşa göre ölüm ihtimali hesaplanır. Ölüm yoksa 1. adıma dönülür.

**Dış döngü:** Ölüm, hayat özeti kartı ve paylaşım, ardından rastgele bir şehir ve ailede yeniden doğum. Başarımlar ve "Hayat Albümü" hayatlar arasında birikir; oyuncuyu bir hayat daha oynamaya çeker.

**Sevecen başarısızlık:** Mutluluk ya da para sıfıra düştüğünde oyun bitmez; bir zor dönem zinciri başlar (bunalım, icra, aileden destek). Yalnızca sağlık sıfırı ölüm getirir.

## Karakter ve göstergeler

**Ekranda 5 gösterge ve para görünür; bunların altında karakteri benzersiz yapan gizli değerler ve bayraklar çalışır.** Göstergeler 0–100 aralığındadır, kart üzerinde hangi göstergenin etkileneceği oklarla ima edilir ama miktarı gösterilmez (Reigns'teki gibi).

| Gösterge | Aralık | Neyi etkiler | Sıfıra düşünce |
| --- | --- | --- | --- |
| Sağlık | 0–100 | Ömür, bazı meslekler, askerlik | Ölüm riski keskin artar |
| Mutluluk | 0–100 | Kart tonları, ilişkiler, verim | Bunalım zinciri; destek kartları açılır |
| Bilgi | 0–100 | Sınavlar, terfi, yatırım kararları | Sınav ve terfi şansı düşer |
| İtibar (Mahalle Ağzı) | 0–100 | Evlilik, muhtarlık, esnaflık, iş bulma | Dedikodu ve dışlanma kartları |
| Aile Bağı | 0–100 | Bayramlar, miras, zor günde destek | Bayramlar yalnız geçer, miras azalır |
| Para | TL, sınırsız | Her şey | Borç ve icra zinciri |

**Gizli değerler:**

- **Mizaç:** Doğumda rastgele atanır (Sakin, Asabi, Hayalperest, Hesapçı). Bazı kartlarda seçenek metnini ve sonucunu değiştirir.
- **Şans:** Pazarlık, sınav ve fırsat kartlarındaki zarı etkiler.
- **Memleket ve takım:** Doğum şehri ve babadan gelen futbol takımı; bayram, derbi ve emeklilik kartlarını tetikler.
- **Bayraklar:** "askerligini_yapti", "ev_sahibi", "komsuya_borc_verdi" gibi kalıcı izler. Olayların çoğu bu bayraklara bakarak gelir ya da gelmez.

**Kişiler:** Anne, baba, kardeşler, sevgili/eş, çocuklar ve en fazla 3 yakın arkadaş. Her birinin 0–100 arası bir ilişki puanı vardır; ilgilenilmeyen ilişki her yıl biraz soğur.

**Varlıklar:** TL birikim, döviz, altın, ev, araba. Enflasyon her yıl TL'yi eritir; varlık türleri kendi rastgele olaylarıyla değer kazanır ya da kaybeder. Ekonomi kurgusaldır, gerçek kur ya da politika adı geçmez.

## Hayat evreleri ve olay sistemi

**Hayat 8 evreye bölünür; her evrenin kendi kart destesi vardır ve motor her yıl yaşa, göstergelere ve bayraklara uyan kartlar arasından ağırlıklı rastgele seçim yapar.**

| Evre | Yaş | Öne çıkan olaylar |
| --- | --- | --- |
| Bebeklik | 0–6 | İsim koyma kavgası, ilk kelime ("anne" mi "baba" mı), kreş, sünnet düğünü |
| İlkokul | 7–10 | Karne, öğretmen, mahalle maçı, bakkaldan veresiye |
| Ortaokul | 11–14 | LGS, kurs, ilk aşk, telefon kavgası |
| Lise | 15–18 | YKS, tercih, ehliyet, mezuniyet balosu |
| Genç yetişkin | 19–29 | Üniversite ya da iş, askerlik, KPSS, ilk kira, kız isteme |
| Yetişkin | 30–49 | Düğün, çocuk, kredi, terfi, kayınvalide, ev almak |
| Olgun | 50–64 | Emeklilik hesabı, çocukların düğünü, sağlık kontrolleri |
| Yaşlılık | 65+ | Torunlar, memlekete dönüş, kahvehane, miras paylaşımı |

**Kartın gelme kuralları** (her kartta veri olarak tutulur):

- **Yaş aralığı:** `minAge`–`maxAge`.
- **Koşullar:** Gösterge eşikleri ("Para < 5.000"), bayraklar ("ev_sahibi değil"), cinsiyet, meslek, memleket.
- **Ağırlık:** Sıradan 10, nadir 3, efsane 1. Efsane kartlar paylaşım anı yaratmak içindir.
- **Tekrar:** `once` (hayatta bir kez) ya da `cooldown` (en az kaç yıl sonra tekrar).
- **Zorunlu kartlar:** Sınav yılları, askerlik yaşı, emeklilik gibi kilometre taşları koşul sağlanınca her zaman gelir.

**Zincir olaylar:** Bir seçim, yıllar sonra gelecek bir devam kartını sıraya koyabilir. Örnek: 24 yaşında komşunun oğluna borç verirsin; 26 yaşında "Komşunun oğlu borcu getirdi mi?" kartı gelir, sonucu şansa ve onun itibarına bağlıdır. Zincirler oyuncuya "bu hayat benim seçimlerimle şekillendi" hissini verir.

**Cinsiyet:** Oyuncu doğumda seçer ya da rastgele bırakır. Askerlik gibi yasal farklar dışında kariyer ve hayat fırsatları eşittir; kalıp yargılar ancak karakterlerin ağzından, üzerine gülünecek şekilde geçer.

## Kariyerler

**İlk sürümde 6 ücretsiz kariyer olur; sonrasında her ay bir meslek paketi eklenir.** Her kariyer 5 kademeli bir terfi merdiveni ve kendine ait 30–60 kartlık bir desteden oluşur. Terfi; Bilgi, İtibar, yıl sayısı ve kart seçimlerine bağlıdır. (MVP'de bunlardan 3'ü var: Memur, Esnaf, Plaza çalışanı.)

| Kariyer | Giriş şartı | Kademeler (örnek) | İmza olayı |
| --- | --- | --- | --- |
| Memur | KPSS başarısı | Memur → Şef → Müdür | Tayin çıktı: memleketten 1.500 km uzağa mı, istifa mı? |
| Öğretmen | Üniversite + atama | Stajyer → Kadrolu → Müdür yardımcısı | Veli toplantısında "Bizim oğlan zeki ama çalışmıyor" |
| Esnaf | Sermaye ya da miras dükkan | Tezgahtar → Dükkan sahibi → Zincir | Veresiye defteri: kime veresiye verirsin? |
| Plaza çalışanı | Üniversite | Uzman → Yönetici → Direktör | Cuma 18.00'de gelen "acil" e-posta |
| Doktor | Yüksek YKS + 6 yıl | Asistan → Uzman → Başhekim | Bayram nöbeti, akrabaların bitmeyen sağlık soruları |
| Serbest / içerik üretici | Yok | Bilinmeyen → Tanınan → Ünlü | Videon viral oldu ama yanlış sebeple |

**Meslek paketleri** (yayın sonrası, reklamla ya da satın alarak açılır): Muhtar, Emlakçı, Oto Galerici, Polis, Hakim, Taksici, Çiftçi, Futbolcu, Yazılımcı, Gurbetçi.

**Gurbetçi** özel bir yoldur: Almanya'ya gidiş, yaz izninde dolu arabayla memlekete dönüş, "Almancı" lakabı ve çocukların iki dil arasında kalması. Hem Türkiye'deki hem Avrupa'daki Türk oyunculara hitap eder.

## Türkiye'ye özgü sistemler

**Oyunu BitLife kopyası olmaktan çıkaran şey bu 7 sistemdir; her biri tanıdık bir anı bir oyun mekaniğine çevirir.**

| Sistem | Nasıl çalışır | Neden eğlenceli |
| --- | --- | --- |
| Sınavlar (LGS, YKS, KPSS) | Sınav yılında zorunlu kart. Başarı = Bilgi + çalışma aksiyonları + şans. YKS sonrası şehir ve bölüm tercih ekranı | Herkesin yaşadığı stres, bu sefer sonucu sen belirliyorsun |
| Askerlik | 20 yaşından sonra zorunlu kart: bedelli (para) ya da kısa/uzun dönem (yıl boyu askerlik kartları) | Askerlik yapan karakter ömür boyu "bizim bölükte" anlatır |
| Kira ve enflasyon | Her yıl kira artışı ve ev sahibi kartları. TL birikimi erir; altın, döviz ve ev seçenekleri | Oyuncu "keyfi" kararların bedelini hisseder |
| Düğün ve takı | Düğünde takılan altın başlangıç sermayesi olur. Kimin ne taktığı kaydedilir; onların düğününde karşılık beklenir | Takı defteri gerçek bir Türk anısı |
| Memleket | Doğum şehri bayram ziyaretlerini, yemeği, şiveli karakterleri ve emeklilikte dönüşü belirler | Oyuncu kendi memleketini seçer, sahiplenir |
| Aile ve mahalle baskısı | "Ne zaman evleneceksin?", "Komşunun oğlu doktor oldu" kartları İtibar ve Aile Bağı'nı oynatır | En çok paylaşılacak kartlar bunlar |
| Futbol takımı | Babadan miras takım; derbi kartları Mutluluk'u etkiler, kayınpederle takım çatışması çıkabilir | Kurgusal takım adları ve renkleriyle, lisans gerektirmez |

**Sınır:** Bu sistemler güncel siyasete, partilere ya da gerçek kişilere dokunmaz. Ekonomi ve kurumlar kurgusal, ama tanıdık.

## Ton ve yazım rehberi

**Kural tek cümle: Güldürmeli ama kimseyi incitmemeli; oyuncu "bu benim annem" diyerek gülmeli, "bu bana hakaret" diye değil.**

**Yazım kuralları:**

- Kart metni en fazla 140 karakter; seçenek metni en fazla 24 karakter.
- Konuşan karakter kendi ağzıyla konuşur: anne, baba, kayınvalide, ev sahibi, bakkal.
- Mizah gözleme dayanır: herkesin yaşadığı anı, beklenmedik bir açıdan göster.
- Seçenekler ikisi de mantıklı olmalı; "doğru cevap" belli olan kart sıkıcıdır.
- Şive hafif ve sevecen olur; bir şehrin insanı alay konusu değil, renk katan bir karakterdir.
- Hastalık, ölüm, boşanma gibi ağır olaylarda şaka yapılmaz; ton şefkatli ve kısa olur.

**Kırmızı çizgiler** (bu içerikler oyunda hiç yer almaz):

- Gerçek siyasetçiler, partiler, seçimler.
- Etnik köken, din, mezhep ya da bölge üzerinden alay.
- Cinsiyet, engellilik ya da cinsel yönelim aşağılaması.
- İntihar, kendine zarar, ağır şiddet ve çocuk istismarı temaları.
- Kumar simülasyonu (mağaza yaş derecesini yükseltir) ve gerçek marka adları.

| Kart | Zayıf yazım | İyi yazım |
| --- | --- | --- |
| Kayınvalide ziyareti | "Kayınvaliden çok geçimsiz biri, seni sevmiyor." | "Kayınvaliden üçüncü kez 'Yemekler biraz tuzsuz olmuş ama elinize sağlık' dedi." |
| Karne günü | "Notların kötü, baban kızgın." | "Baban karneye bakıp 'Komşunun oğlu hepsinden pekiyi almış' dedi." |
| Ev sahibi | "Ev sahibin açgözlü." | "Ev sahibi kirayı iki katına çıkarmak istiyor. Gerekçesi: 'Piyasa böyle.'" |

## Ölüm, hayat özeti ve paylaşım

**Oyunun büyüme motoru ölüm anındaki hayat özeti kartıdır: her biten hayat, paylaşılmaya hazır dikey bir görsel üretir.**

**Ölüm:** Yaş ve Sağlık'a göre her yıl bir ölüm ihtimali hesaplanır. Ton şefkatlidir; ölüm şakaya dönüştürülmez. Özel sonlar vardır: "100 yaşında, torunlarının torunlarıyla bayramlaştıktan sonra."

**Hayat özeti kartı** (9:16, Instagram hikayesi ve TikTok boyutunda):

- İsim, doğum ve ölüm yılı, memleket, meslek.
- **Lakap:** Mahallenin onu nasıl hatırladığı; seçimlerden üretilir. Örnek: "Veresiye Defterinin Efendisi", "Hiç Kira Gecikmeyen Adam", "Üç Kez İstifa Eden Memur".
- **Hayatın sayıları:** Kaç kez taşındı, ömrü boyu ödenen kira, taktığı ve takılan altın, torun sayısı.
- **En büyük an:** Hayattaki en nadir kart.
- Küçük oyun logosu ve indirme bağlantısı.

**Paylaşım akışı:** Ölüm ekranında tek dokunuşla görsel oluşur ve telefonun paylaşım menüsü açılır. Paylaşım için oyun içi ödül verilmez; sosyal platformların kuralları ödüllü paylaşımı kısıtlıyor. Paylaşımı kartın kendisi kazanmalı.

**Başarımlar ve Hayat Albümü:** Hayatlar arasında kalıcı bir koleksiyon. Örnek rozetler: "Bedelli Değil Asker", "Üç Kuşak Ev Sahibi", "Memlekete Döndü", "Her Bayram Elini Öptü". Nadir rozetler oyuncuyu yeni bir hayata başlatmak için en güçlü nedendir.

## Para kazanma modeli

**Oyun ücretsiz; gelir ödüllü reklamdan, tek seferlik reklamsız paketten ve meslek paketlerinden gelir.** Enerji duvarı, "bekle ya da öde" ve oyunu satarak kazanma yoktur; oyuncu hiç ödeme yapmadan tam bir hayat yaşayabilir.

| Kaynak | Ne verir | Sınır |
| --- | --- | --- |
| Ödüllü reklam | Ekstra aksiyon hakkı, kötü bir zarı yeniden atma, ölümden sonra son kararı geri alma | Hayat başına en fazla 3 |
| Geçiş reklamı | Yalnızca ölüm ekranından sonra | Hayat başına en fazla 1 |
| Reklamsız paket | Geçiş reklamlarını kaldırır, ödüllü reklam ödüllerini reklamsız verir | Tek seferlik |
| Meslek paketi | Yeni kariyer: 30–60 kart, kendi rozetleri ve sonları | Her biri ayrı; reklam izleyerek tek hayatlık deneme |
| Doğum seçimi | Şehir, aile durumu ve mizaç seçerek doğmak | Tek seferlik kilit açma |
| Kozmetik | Portre stilleri ve özet kartı temaları | İsteğe bağlı |

**Fiyatlama:** Mağazaların en düşük fiyat kademeleri kullanılır. Referans olarak, rakip Türk simülatörlerinin çoğu 5–10 TL'ye, Bir TC Simülasyonu paketleri 0,99 $'a satılıyor. Reklamsız paket en pahalı ürün olur, meslek paketleri ondan ucuz.

**Açık soru:** Türkiye'de reklam gelirinin oyuncu başına düşük olması bekleniyor. Kapalı betada ölçülecek: oyuncu başına izlenen ödüllü reklam sayısı ve paket satın alma oranı.

## Teknik mimari

**Oyun motoru düz Flutter'da yazılır ve tüm içerik (kartlar, kariyerler, başarımlar) JSON dosyalarında durur; yeni kart eklemek kod değişikliği gerektirmez.** Oyun motoru (Flame) gerekmez; ekranlar standart Flutter widget'ları ve animasyonlardır.

| Katman | Seçim |
| --- | --- |
| Durum yönetimi | Riverpod |
| Kart kaydırma | Özel GestureDetector + animasyon (ya da `flutter_card_swiper`) |
| Kayıt | Yerel; Hive ya da Isar üzerinde JSON durum |
| Reklam | `google_mobile_ads` |
| Satın alma | `purchases_flutter` (RevenueCat) ya da `in_app_purchase` |
| Analitik ve hata | Firebase Analytics + Crashlytics |
| Paylaşım kartı | `RepaintBoundary` ile PNG üretimi + `share_plus` |
| Çeviri | ARB dosyaları; önce Türkçe |
| İçerik güncelleme | İlk sürümde uygulama içinde; sonra Firebase Remote Config ya da indirilebilir paket |

**Portreler:** Her karakter katmanlı SVG parçalarından (`flutter_svg`) birleştirilir: yüz şekli, ten rengi, saç, kaş ve ağız ifadesi, aksesuar (gözlük, bıyık, başörtüsü, şapka). Yaş evresi değiştikçe saç ve yüz katmanı değişir, böylece karakter gözün önünde yaşlanır. İlk sürümde yaklaşık 60 parça ile binlerce farklı yüz çıkar; kart konuşmacıları (ev sahibi, bakkal, kayınvalide) aynı sistemle sabit tohumla üretilir.

**Bir yılın motor akışı:**

1. `YearTick` yaşı artırır, maaş, kira, enflasyon ve yaşlanmayı uygular.
2. `ScheduleQueue` bu yıla planlanmış zincir kartları çıkarır.
3. `EventDeck` yaş, koşul, bayrak ve bekleme süresine uyan kartları filtreler, ağırlıklı rastgele 1–3 kart seçer.
4. `EffectResolver` seçilen seçeneğin etkilerini uygular: gösterge, para, bayrak, ilişki, zincir kart.
5. `DeathCheck` ölüm ihtimalini hesaplar; ölümde `SummaryBuilder` lakap, sayılar ve en büyük anı üretir.

Rastgelelik tohumlu (seed) olur; aynı tohum aynı hayatı üretir. Bu hem hata ayıklamayı hem de ileride "arkadaşının hayatını sen yaşa" özelliğini mümkün kılar.

**Kart veri formatı:**

```json
{
  "id": "kira_zammi_01",
  "stage": "genc",
  "minAge": 19,
  "maxAge": 45,
  "rarity": "siradan",
  "cooldown": 3,
  "conditions": { "notFlags": ["ev_sahibi"], "flags": ["kiraci"] },
  "speaker": "ev_sahibi",
  "text": "Ev sahibi kirayı iki katına çıkarmak istiyor. Gerekçesi: 'Piyasa böyle.'",
  "left": {
    "label": "Taşınırım",
    "effects": { "money": -15000, "happiness": -5, "addFlags": ["tasindi"] }
  },
  "right": {
    "label": "Pazarlık ederim",
    "roll": { "stat": "luck", "threshold": 50 },
    "success": { "money": -3000, "happiness": 3 },
    "fail": { "money": -8000, "reputation": -2, "schedule": { "event": "ev_sahibi_ihtar", "inYears": 1 } }
  }
}
```

**Proje klasörleri:**

```
lib/
  engine/      # YearTick, EventDeck, EffectResolver, ScheduleQueue, DeathCheck
  models/      # Character, Stats, Card, Career, Asset
  content/     # JSON yükleyici ve doğrulayıcı
  ui/          # ekranlar: doğum, yıl, kart, aksiyon, ölüm, albüm
  services/    # kayıt, reklam, satın alma, analitik, paylaşım
assets/
  cards/       # evre ve kariyer bazında JSON kart dosyaları
  portraits/   # karakter portreleri
tools/
  card_lint/   # kart dosyalarını kontrol eden küçük betik
```

## Platformlar ve yayın hattı

**Oyun tek Flutter kod tabanından Android ve iOS'a çıkar; geliştirme Windows bilgisayarda ve Mac'te yapılır; iki mağaza hesabı da hazır ve daha önce yayın yapılmış.** Kod iki bilgisayar arasında GitHub üzerinden taşınır. iOS derlemesi Mac'te Xcode ile alınır ve iPhone'da doğrudan denenir; platforma özgü sorunlar birikmesin diye her hafta iki platformda da test edilir.

| Konu | Android | iOS |
| --- | --- | --- |
| En düşük sürüm (karar) | Android 7.0 (API 24) | iOS 15 |
| Mağaza derleme şartı | API 36 hedeflenmeli; 31 Ağustos 2026'dan beri yeni uygulama ve güncellemelerde zorunlu ([kaynak](https://developer.android.com/google/play/requirements/target-sdk)) | Xcode 26 ve iOS 26 SDK ile derlenmeli; 28 Nisan 2026'dan beri zorunlu ([kaynak](https://www.developer.apple.com/news/upcoming-requirements/)) |
| Geliştirme ve test | Windows'ta Android Studio, emülatör ve gerçek telefon | Mac'te Xcode 26, iPhone'da doğrudan test; dağıtım TestFlight ile |
| Geliştirici hesabı | Google Play Console hesabı var | Apple Developer hesabı var |
| Kapalı test | Bu hesapta şart geçerli: yayından önce en az 12 test kullanıcısıyla 14 gün kesintisiz kapalı test ([kaynak](https://support.google.com/googleplay/android-developer/answer/14151465?hl=en-GB)) | TestFlight; zorunlu süre yok |
| Reklam izni ve gizlilik | Google UMP onay ekranı, Data safety formu | Aynı UMP ekranı + App Tracking Transparency izni, gizlilik manifesti |
| Satın alma | Google Play Billing (RevenueCat üzerinden) | StoreKit (RevenueCat üzerinden) |
| Yaş derecesi | IARC anketi | App Store yaş anketi |

**Platform farklarını kodda tek yerde topla:** Titreşim, paylaşım, reklam izni ve satın alma `services/` altında platformdan bağımsız bir arayüzle yazılır; oyun motoru Android'i ya da iOS'u bilmez.

**İlk hafta kurulum listesi:**

- [ ] Flutter SDK ve Android Studio (Windows), Xcode 26 (Mac); iki makinede `flutter doctor` ile doğrula
- [ ] GitHub deposu (kod iki bilgisayar arasında buradan taşınır)
- [ ] Paket kimliği seçimi (örnek: `com.<senin-adın>.biromur`); sonradan değiştirilemez
- [ ] Google Play kapalı testi için şimdiden 15–20 test adayı topla (hesapta 12 kişi / 14 gün şartı var)
- [ ] App Store Connect ve Play Console'da "Bir Ömür" uygulama kaydını oluştur (ismi ayırtır)

## Örnek olay kartları

**Aşağıdaki 10 kart, oyunun sesini tanımlayan referans kartlardır; yeni kartlar bu tona göre yazılır.** Etkiler: S = Sağlık, M = Mutluluk, B = Bilgi, İ = İtibar, A = Aile Bağı.

| Yaş | Kart | Sol seçenek → etki | Sağ seçenek → etki |
| --- | --- | --- | --- |
| 0 | Ailen isim koyamıyor. Deden kendi babasının adını, annen dizideki karakterin adını istiyor. | Dedenin dediği → A +10 | Annenin dediği → M +5, deden bir süre küs |
| 8 | Karnende üç "iyi" var. Baban: "Komşunun oğlu hepsinden pekiyi almış." | Ağla → M −5, A +5 | "Ama resimden pekiyi aldım" → M +5, İ −2 |
| 14 | LGS'ye 3 ay kaldı. Annen kurs kaydını çoktan yaptırmış. | Gitmem → M +5, B −5 | Hafta sonu dahil giderim → B +10, M −10 |
| 18 | Tercih zamanı. Baban "Mühendislik" diyor, sen "Grafik tasarım". | Babayı dinle → A +10, M −5 | Kendi yolun → M +10, A −5 |
| 21 | Askerlik zamanı geldi. | Bedelli → Para −− | Yaparım → S +5, M −5, bayrak: asker_anilari |
| 24 | Ev sahibi kirayı iki katına çıkarmak istiyor. Gerekçesi: "Piyasa böyle." | Taşınırım → Para −, M −5 | Pazarlık ederim → şans zarı |
| 27 | Kız isteme günü. Kahvene tuz konmuş. | Yüzünü bozmadan iç → İ +10 | "Bunda tuz var galiba" → M +5, İ −5, yengeler gülüyor |
| 29 | Düğünde 14 çeyrek ve 2 bilezik takıldı. Kayınpeder: "Altını bozdurmayın." | Kenara koy → varlık: altın | Araba peşinatı → varlık: araba, kayınpeder küs |
| 24 → 26 | (Zincir) Komşunun oğlu borç istedi. İki yıl sonra: "Borcu getirdi mi?" | Verme → İ −3 | Ver → iki yıl sonra şans zarı: para geri ya da komşuluk biter |
| 70 | Torunun telefonu uzatıyor: "Dede, bir story at." | Kahvehanede çay fotoğrafı → M +5, İ +3 | Tüm rehbere bayram mesajı → A +10, mahallede efsane olursun |

## MVP kapsamı ve yol haritası

**İlk oynanabilir sürüm (F0–F1) 5 haftada, mağaza yayını 10 haftada; bir faz kapısından geçmeden sonrakine başlanmaz.**

| Faz | Hafta | İçerik | Kapı (sonraki faza geçiş şartı) |
| --- | --- | --- | --- |
| F0 · Motor prototipi | 1.–2. | Durum, kart destesi, kaydırma, yıl döngüsü ve ölüm kontrolü; 40 kart, basit hayat özeti; Android telefonda ve iPhone'da ilk çalışan sürüm | Bir hayat baştan sona çökmeden oynanıyor |
| F1 · Dikey dilim | 3.–5. | 6 gösterge, 8 evre, 3 kariyer, ekonomi ve yerel kayıt; 150 kart ve card_lint kart denetleyicisi | 5 test oyuncusu üst üste 3 hayat oynuyor |
| F2 · Cila ve paylaşım | 6.–7. | Görsel stil, ses ve titreşim, hayat özeti kartı paylaşımı; başarımlar, Hayat Albümü ve Firebase analitik | Çökme yok, analitik olayları akıyor |
| F3 · Kapalı beta | 8.–9. | Google Play kapalı testi (en az 12 kişi, 14 gün) ve iOS'ta TestFlight; denge ayarı ve hassas kart taraması | Hedef: 1. gün dönüşü en az %35, ortalama hayat en az 12 dakika |
| F4 · Yayın | 10. | Mağaza sayfaları, reklam ve satın alma; ilk TikTok ve Instagram içerikleri | — |

Sonrası: her ay bir meslek paketi ve yeni kartlar. Kapılardaki dönüş ve süre hedefleri öneridir; beta verisine göre güncellenir.

**MVP'de olanlar:**

- Doğum ekranı: isim, cinsiyet, rastgele şehir ve aile.
- 8 evre, 150 kart, 3 kariyer (Memur, Esnaf, Plaza çalışanı).
- 6 gösterge; TL, altın ve ev ile basit ekonomi; zincir olaylar.
- Ölüm ve hayat özeti ekranı (paylaşım görseli F2'de).
- Yerel kayıt.

**MVP'de olmayanlar:** Reklam ve satın alma (F4), meslek paketleri, doğum seçimi, kozmetik, İngilizce, bulut kayıt ve çevrim içi özellikler.

## Riskler ve açık sorular

**En büyük risk teknik değil, içeriktir: oyunun kalitesi kart sayısına ve kartların komikliğine bağlı.**

| Risk | Etki | Önlem |
| --- | --- | --- |
| İçerik hacmi | Tek kişi 300+ iyi kart yazamazsa oyun tekrar eder | Yapay zekâyla taslak, elle düzenleme; kart öneri formu; `card_lint` ile hızlı kontrol |
| Tekrar hissi | 3. hayattan sonra oyuncu aynı kartları görür | Nadir ve efsane kartlar, zincirler, rastgele doğum ve mizaç |
| Mizahın çizgiyi aşması | Mağaza şikayeti, sosyal medya tepkisi | Ton rehberi, kapalı betada hassas kart taraması |
| Düşük reklam geliri | Türkiye'de oyuncu başı gelir düşük kalabilir | Meslek paketleri, Avrupa'daki Türk oyuncular, ileride İngilizce sürüm |
| Kopyalanma | Başarılı olursa benzerleri çıkar | Aylık içerik ritmi, topluluk ve tanınan marka |
| Mağaza yaş derecesi | Kumar ya da alkol içeriği derecesini yükseltir | Kumar simülasyonu yok, alkol ima düzeyinde |
| Google Play kapalı test şartı | 12 test kullanıcısı 14 gün kesintisiz kalmazsa Android yayını gecikir | F3'te planlı; 15–20 aday önceden toplanır ki birkaçı bırakırsa süre başa dönmesin |

**Verilen kararlar (14 Ekim 2026):**

- **Karakter görselleri:** Parçalı çizim portre. Yüz, saç, yaş ve aksesuar katmanlarından birleşen düz vektör çizimler.
- **Oyunun adı:** Bir Ömür. Mağaza başlığı "Bir Ömür: Türk Hayat Simülasyonu". İlk aramada aynı adlı uygulama görülmedi, aynı adlı filmler var; yayından önce iki mağazada son kontrol yapılır.
- **İngilizce sürüm:** Oyun Türkiye'de tutunca. Kod baştan çeviriye hazır yazılır (ARB).
- **Kart yazımı:** Şimdilik geliştirici ve yapay zekâ taslakları; mizah kapalı betada test edilir.
- **Aksiyon sistemi:** Hayat evresine göre 2–4 hak, bazı aksiyonlarda para maliyeti.
- **Geliştirme ortamı:** Windows ve Mac, iPhone ile test; iki mağaza hesabı hazır ve daha önce yayın yapılmış.

## Kaynaklar

- [App Store Türkiye oyun listeleri – Appfigures](https://app.appfigures.com/top-apps/ios-app-store/turkey/iphone/games)
- [Google Play Türkiye ücretsiz oyunlar – AppBrain](https://www.appbrain.com/stats/google-play-rankings/top_free/game/tr)
- [Duty Court tahmini indirme – AppGoblin](https://appgoblin.info/apps/6760950124)
- [Bir TC Simülasyonu – App Store](https://apps.apple.com/us/app/-/id1670750852)
- [BitLife'ın yükselişi – The Highlander](https://thehighlandernews.com/16032/arts-ent/the-rise-of-bitlife/)
- [Google Play hedef API şartı – Android Developers](https://developer.android.com/google/play/requirements/target-sdk)
- [App Store SDK şartları – Apple Developer](https://www.developer.apple.com/news/upcoming-requirements/)
- [Yeni kişisel hesaplarda test şartı – Play Console Yardım](https://support.google.com/googleplay/android-developer/answer/14151465?hl=en-GB)
- [Mağaza hesap ücretleri – Choicely](https://www.choicely.com/tutorials/how-much-does-it-cost-to-publish-an-app)
