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

## iOS: Crashlytics dSYM yükleme

Release derlemesinde Dart kodu sembolsüz derlenir. Crashlytics'in çökme kayıtlarını okunur gösterebilmesi için her derlemede dSYM dosyalarını Firebase'e yüklemesi gerekir. Bunu Xcode'daki bir derleme betiği yapar. Bir kez eklenir; `project.pbxproj` değişir ve depoya girer.

Projede hazır olanlar (değiştirme):
- Release ve Profile'da `Debug Information Format = DWARF with dSYM File`.
- `User Script Sandboxing = No`.

### Bir kez: betiği ekle (Mac, Xcode)

1. `ios/Runner.xcworkspace` dosyasını Xcode'da aç. Workspace yoksa `ios/Runner.xcodeproj` dosyasını aç.
2. Bir kez derle (⌘B). Firebase paketi indirilir; betiğin çağıracağı dosya böylece oluşur.
3. Sol tarafta **Runner** projesine, sonra **TARGETS → Runner** hedefine, sonra **Build Phases** sekmesine git.
4. **+ → New Run Script Phase** ile yeni bir betik ekle ve adını `Crashlytics dSYM yükle` yap.
5. Betiği **en sona** sürükle. Flutter'ın "Thin Binary" adımından sonra gelmeli.
6. Shell alanı `/bin/sh` kalsın. Betik:

   ```
   "${BUILD_DIR%/Build/*}/SourcePackages/checkouts/firebase-ios-sdk/Crashlytics/run"
   ```

7. **Input Files** bölümüne şu beş satırı ekle:

   ```
   ${DWARF_DSYM_FOLDER_PATH}/${DWARF_DSYM_FILE_NAME}
   ${DWARF_DSYM_FOLDER_PATH}/${DWARF_DSYM_FILE_NAME}/Contents/Resources/DWARF/${PRODUCT_NAME}
   ${DWARF_DSYM_FOLDER_PATH}/${DWARF_DSYM_FILE_NAME}/Contents/Info.plist
   $(TARGET_BUILD_DIR)/$(UNLOCALIZED_RESOURCES_FOLDER_PATH)/GoogleService-Info.plist
   $(TARGET_BUILD_DIR)/$(EXECUTABLE_PATH)
   ```

8. **Based on dependency analysis** işaretini kaldır. Böylece betik her derlemede çalışır.
9. Değişikliği commit edip gönder. Değişen tek dosya `ios/Runner.xcodeproj/project.pbxproj` olmalı.

Betik, debug derlemelerinde de çalışır ama sorun çıkarmaz.

#### "No such file or directory" hatası alırsan

Firebase paketi başka bir klasöre inmiş demektir. Yerini bul:

```
find ~/Library/Developer/Xcode/DerivedData -path "*firebase-ios-sdk/Crashlytics/run" 2>/dev/null | head -1
```

- Bulunan yol `.../SourcePackages/checkouts/...` biçimindeyse betik doğru klasörü arıyordur. Önce **Product → Clean Build Folder** yapıp yeniden dene.
- Hiçbir şey bulunmazsa paketler henüz inmemiştir. **File → Packages → Resolve Package Versions** ile indir.

### Derleme ve doğrulama

```
flutter build ipa
```

1. Derleme günlüğünde (Xcode **Report navigator**) "Crashlytics dSYM yükle" adımı hatasız geçmeli. `flutter build ipa` için ayrıntılı çıktı: `flutter build ipa -v`.
2. Firebase konsolunda **Crashlytics → (iOS uygulaması) → dSYMs** sekmesinde yeni sürümün UUID'leri "Uploaded" görünmeli.
3. İsteğe bağlı gerçek deneme: TestFlight sürümünde bir çökme oluşturup konsolda yığın izinin dosya ve satır adlarıyla geldiğini gör. Bunu F3b'de birlikte yaparız.

Elle yükleme (betik bir derlemede çalışmadıysa):

```
"<firebase-ios-sdk yolu>/Crashlytics/upload-symbols" -gsp ios/Runner/GoogleService-Info.plist -p ios build/ios/archive/Runner.xcarchive/dSYMs
```

`<firebase-ios-sdk yolu>`, yukarıdaki `find` komutunun bulduğu yolun `/Crashlytics/run` kısmından önceki bölümüdür.

## iOS: sürüm ve TestFlight

- Sürüm numarası Android'deki gibi `pubspec.yaml` içindeki `version` satırından gelir.
- `flutter build ipa` arşivi `build/ios/archive/` altına, yüklenecek dosyayı `build/ios/ipa/` altına yazar.
- Yükleme: Xcode **Organizer → Distribute App → App Store Connect** ya da Apple'ın **Transporter** uygulaması.
- İmza: Xcode'da **Runner → Signing & Capabilities → Automatically manage signing**, Team olarak Apple Developer hesabın. Bu ayar `project.pbxproj` dosyasına `DEVELOPMENT_TEAM` olarak yazılır ve depoya girmesinde sakınca yoktur.
