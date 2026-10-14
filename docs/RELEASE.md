# Yayın notları

## Android imzası

Google Play App Signing kullanılır:
- Uygulamayı Google'ın sakladığı **uygulama imzalama anahtarı** imzalar.
- Bizdeki anahtar yalnızca **yükleme anahtarıdır** (upload key).
- Yükleme anahtarı kaybolursa Play Console'dan sıfırlatılabilir. Yine de kaybetmemek en iyisi.

### Bir kez: yükleme anahtarını oluştur (Windows)

Anahtar depo klasörünün **dışında** durur. Örnek konum `C:\development\zeysoft\biromur-keys\`.

```
mkdir C:\development\zeysoft\biromur-keys
"C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe" -genkeypair -v -keystore C:\development\zeysoft\biromur-keys\upload-keystore.jks -storetype PKCS12 -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

- `keytool` bir şifre ve ad/kurum bilgisi sorar.
- PKCS12 dosyasında anahtar şifresi depo şifresiyle aynıdır.

Ardından `android/key.properties.example` dosyasını `android/key.properties` olarak kopyala ve şifreyi doldur. `storeFile`, `android/` klasörüne göre yazılır.

Bu iki dosya depoya **girmez**. Bunu `android/.gitignore` sağlar.

Yedekle:
- `upload-keystore.jks` dosyasını ve şifreyi parola yöneticisine ya da şifreli bir yedeğe koy.
- Mac'te Android derlemesi yapılacaksa iki dosyayı oraya elle taşı. GitHub üzerinden **taşıma**.

### Derleme

```
flutter build appbundle
```

Çıktı: `build/app/outputs/bundle/release/app-release.aab`.

`key.properties` yoksa release sürümü debug anahtarıyla imzalanır. Bu derleme çalışır ama Play Console onu kabul etmez.

Kontrol:

```
"C:\Program Files\Android\Android Studio\jbr\bin\jarsigner.exe" -verify -verbose -certs build\app\outputs\bundle\release\app-release.aab
```

Çıktıdaki sertifika kendi `CN=` değerin olmalı, `CN=Android Debug` olmamalı.

### Sürüm numarası

`pubspec.yaml` içindeki `version: 1.0.0+1` satırı:
- `+` öncesi kullanıcının gördüğü sürümdür.
- `+` sonrası `versionCode`'dur.
- Play her yüklemede daha büyük bir `versionCode` ister.
