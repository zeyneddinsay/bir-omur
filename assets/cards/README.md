# Olay dosyaları

Bu klasördeki her `.json` dosyası bir olay dizisidir. Yeni olay eklemek kod
değişikliği istemez. Dosyalar yüklenirken ve `dart run tools/card_lint/bin/card_lint.dart`
ile denetlenir.

Tasarımın tamamı canlı tasarım dokümanının "Derin hayat" sekmesinde, "Hikâye
motoru" bölümündedir.

## Bir olay

```json
{
  "id": "teneffus_not",
  "type": "kisi",
  "theme": "okul",
  "minAge": 11,
  "maxAge": 14,
  "repeat": "once",
  "roles": {
    "kerem": { "roles": ["sinifArkadasi"], "minGap": -1, "maxGap": 1 }
  },
  "speaker": "kerem",
  "text": "Teneffüs. {kerem.ad}, sıra arkadaşına yazdığın notu buldu ve sınıfa okuyor.",
  "left": {
    "label": "Ver onu bana!",
    "effects": {
      "reputation": 3,
      "people": {
        "kerem": {
          "memory": {
            "kind": "rezil_etti",
            "label": "Sınıfın ortasında üstüme yürüdü",
            "tone": "olumsuz",
            "severity": 2
          }
        }
      }
    }
  },
  "right": { "label": "Gülüp geçerim", "effects": { "happiness": -2 } }
}
```

## Alanlar

| Alan | Zorunlu | Açıklama |
| --- | --- | --- |
| `id` | evet | Benzersiz kimlik |
| `type` | evet | `donemec` (şartı sağlanınca mutlaka gelir), `kisi`, `yer`, `tesaduf` (yılda en fazla 1), `genel`, `iplik` (yalnızca başka bir olayın `schedule` etkisiyle gelir) |
| `theme` | evet | `aile`, `okul`, `ask`, `is`, `para`, `mahalle`, `saglik`, `genel`; aynı yıl aynı temadan iki olay gelmez (dönemeçler hariç) |
| `minAge`, `maxAge` | evet | Oyuncunun yaşı, dahil |
| `repeat` | evet | `"once"` ya da `{"cooldown": 3}` |
| `rarity` | hayır | `siradan` (varsayılan), `nadir`, `efsane`; yukarı seçeneği (`up`) yalnızca nadir ve efsanede |
| `conditions` | hayır | Oyuncunun koşulları: `flags`, `notFlags`, `gender`, `temperament`, `background`, `familyProfile`, `career`, `minTier`, `min`, `max` |
| `roles` | hayır | Rol yuvaları (aşağıda); uygun kişi yoksa olay gelmez |
| `speaker` | hayır | Konuşan rol yuvası; kartta onun portresi görünür |
| `text` | evet | En fazla 140 karakter (en uzun adla) |
| `left`, `right`, `up` | sol ve sağ zorunlu | `label` (en fazla 24 karakter), `effects`, isteğe bağlı zar: `roll` + `success` + `fail` |

## Rol yuvası

`kin` (akrabalık listesi), `roles` (süren rol), `formerRoles` (bitmiş rol), `bond`, `gender`,
`side`, `minAge`/`maxAge` (kişinin yaşı), `minGap`/`maxGap` (oyuncudan yaş farkı),
`minCloseness`/`maxCloseness`, `minHostility`/`maxHostility`, `traits`, `notTraits`,
`memory`/`noMemory` (anı türü), `sameCity`, `offstage` (kişi sahnede değil, görüşme sayılmaz),
`deceased` (son bir yıl içinde vefat etmiş kişi; aşağıda).
Sınırlar dahildir.

Uygun kişi seçilirken yakınlığı ya da husumeti yüksek kişiler iki kat ağırlık alır. Olaya
çıkan kişi 2 yıl başka olaya çıkmaz; anne, baba, kardeş, eş ve çocuk hariç.

## Metin

- **Yer tutucular:** `{yuva.ad}`, `{yuva.soyad}`, `{yuva.akraba}` ("deden", "babaannen", "ablan",
  "dayın"), `{oyuncu.ad}`.
- **Hitaplar:** `{yuva.hitap.abi}` (abi/abla), `.evlat` (oğlum/kızım), `.amca` (amca/teyze), `.bey`
  (Bey/Hanım) kişinin cinsiyetine göre kurulur: oyuncu ona böyle seslenir. Kişi oyuncuya
  seslenirken `{oyuncu.hitap.evlat}` ("oğlum/kızım") ya da `{oyuncu.hitap.abi}` kullanılır; bunlar
  oyuncunun cinsiyetine göre kurulur.
- **Vefat yuvası:** `"deceased": true` olan yuva yalnızca son bir yıl içinde vefat etmiş kişiyle
  eşleşir (cenaze, taziye). Sahne dışıdır; ona kişi etkisi yazılmaz.
- **Ekler:** Ekler `{kerem.ad|e}` biçiminde yazılır: `e`, `i`, `in`, `de`, `den`, `le`. Elle yazılan
  ek (`{kerem.ad}'e`) hatadır.

## Etkiler

- **Göstergeler ve diğerleri:** Göstergeler (`health`, `happiness`, `knowledge`, `reputation`), `money`,
  varlıklar, `career`, `addFlags`, `removeFlags`.
- **Aile Bağı:** Değiştirilemez; ailenin yakınlığından hesaplanır.
- **Kişilere etki (`people`):** yuva adı → `memory` (`kind`, `label` kişinin gözünden, `tone`:
  `olumlu`/`olumsuz`, `severity` 1–3, isteğe bağlı `owner`: `kisi`/`oyuncu`/`ikisi`), `heal` (anı türü
  ya da `*`), `bond`, `archive`.
- **İplik (`schedule`):** `{"event": "id", "inYears": 2, "with": ["kerem"]}`. `with` listesindeki
  yuvalar devam olayına aynı kişiyle taşınır; iki olayda da tanımlı olmalı.

## Kurallar

- Romantik bağ (`flort`, `sevgili`, `nisanli`) içeren olay ve kişi en az 18 yaşında olmalı.
- Yılda en fazla 3 olay gelir, dönemeçler dahil.
