# Sesler

Buradaki sesler **yer tutucudur**: dosya indirilmeden, kodla sentezlenmiş
kısa tonlardır. Gerçek sesler bulunduğunda aynı dosya adlarıyla değiştirilir;
kod değişmez. Telifsiz seslerin lisansı kullanıcı tarafından kontrol edilir
(CLAUDE.md, F2 kararları) ve kaynağı bu dosyaya yazılır.

| Dosya | Ne zaman çalar |
| --- | --- |
| `swipe.wav` | Kart kaydırılınca |
| `roll_success.wav` | Zar tutunca |
| `roll_fail.wav` | Zar tutmayınca |
| `promotion.wav` | Terfi alınca |
| `badge.wav` | İlk kez bir rozet kazanılınca |
| `death.wav` | Hayat bitince |

Biçim: WAV (ya da MP3/OGG; uzantı değişirse `lib/services/feedback_service.dart`
içindeki dosya adları da güncellenir). Kısa tutulmalı; kart sesi 0,2 saniyeyi
geçmemeli.

## Kaynaklar

(Gerçek sesler eklendiğinde: dosya, kaynak, lisans.)
