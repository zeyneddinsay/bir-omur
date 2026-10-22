import '../models/models.dart';
import 'cities.dart';
import 'person_factory.dart';

/// Askerlik (canlı doküman, "Eğitim yolu" → Askerlik). Celp kartında
/// "yaparak" seçen o yılı askerde geçirir: vakti olmaz. Yaşlanınca döner;
/// bölük arkadaşları kişi olarak hayatına girer ve ömür boyu "bizim bölükte"
/// diye anlatılır. Bedelli ödeyen bu yılı yaşamaz.
abstract final class Military {
  /// Kartın açtığı "askerde" bayrağı.
  static const String serviceFlag = 'askerde';
  static const String doneFlag = 'askerligini_yapti';
  static const String memoriesFlag = 'asker_anilari';

  /// Dönüşte hayata giren bölük arkadaşı sayısı.
  static const int comrades = 3;

  static bool inService(Character c) => c.hasFlag(serviceFlag);

  /// Yaşlanınca askerlik biter; bölük arkadaşları gelir.
  static Character returnHome(Character c, PersonFactory f) {
    if (!inService(c)) return c;
    var book = c.people;
    for (var i = 0; i < comrades; i++) {
      (book, _) = f.add(
        book,
        now: c.age,
        age: c.age + f.between(-2, 2),
        city: Cities.all[f.random.nextInt(Cities.all.length)],
        origin: Origin.askerlik,
        base: i == 0 ? 30 : 18,
        gender: Gender.erkek,
        roles: const [PersonRole(RoleKind.bolukArkadasi, active: false)],
        bond: i == 0 ? Bond.arkadas : Bond.tanidik,
        marital: MaritalStatus.bekar,
      );
    }
    final flags = {...c.flags}
      ..remove(serviceFlag)
      ..addAll(const {doneFlag, memoriesFlag});
    return c.copyWith(people: book, flags: flags);
  }
}
