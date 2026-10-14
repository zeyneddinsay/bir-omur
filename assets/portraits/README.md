# Portre parçaları

Her dosya 200×200 `viewBox` içinde tek bir katmandır. Portre, bu katmanların
üst üste çizilmesiyle oluşur. Bir illüstratör aynı dosya adlarıyla yeni
çizimler koyarsa kod değişmez.

## Yer tutucu renkler

Çizim sırasında aşağıdaki renkler kişiye özgü renklerle değiştirilir. Yeni
çizimlerde bu renkler tam olarak (büyük harf, `#RRGGBB`) kullanılmalıdır.

| Renk | Anlamı |
| --- | --- |
| `#E8B98F` | Ten |
| `#CC9A72` | Ten gölgesi (burun, boyun, kırışıklık) |
| `#3B2A20` | Saç, kaş, bıyık, sakal |
| `#4A6FA5` | Gömlek |
| `#EFE6DA` | Arka plan |
| `#9C4A5A` | Aksesuar (başörtüsü) |

Diğer renkler (göz bebeği, dudak, gözlük çerçevesi, kasket) sabittir.

## Katman sırası

1. `bg`
2. `hair_*_back` (uzun saçın arka kısmı; varsa)
3. `body`
4. `ears`
5. `face_*`
6. `cheeks`, `wrinkles` (varsa)
7. `eyes_*`, `brows_*`, `nose_*`, `mouth_*`
8. `beard` ya da `mustache` (varsa)
9. ön saç (`hair_*`)
10. `glasses_*` (varsa)
11. `headscarf` ya da `cap_flat` (varsa)

Hangi karaktere hangi parçaların seçileceği
`lib/ui/portrait/portrait_spec.dart` dosyasındadır.
