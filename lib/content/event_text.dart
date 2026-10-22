import '../models/models.dart';
import 'person_text.dart';
import 'turkish.dart';

/// Olay metinlerini rol yuvalarına bağlanan kişilerle kurar:
/// `{kerem.ad|e}` → "Kerem'e", `{anne.akraba}` → "annen",
/// `{oyuncu.ad}` → oyuncunun adı.
abstract final class EventText {
  /// [bindings]: yuva adı → kişi kimliği (bkz. `PendingEvent.people`).
  static String render(
    String template,
    Map<String, String> bindings,
    Character c,
  ) => PersonText.capitalizeFirst(
    renderTemplate(template, (path) => resolve(path, bindings, c)),
  );

  static TemplateValue? resolve(
    String path,
    Map<String, String> bindings,
    Character c,
  ) {
    final dot = path.indexOf('.');
    if (dot < 0) return null;
    final slot = path.substring(0, dot);
    final field = path.substring(dot + 1);
    if (slot == EventCard.playerSlot) {
      return field == 'ad'
          ? TemplateValue(c.name)
          : PersonText.addressOf(path, EventCard.playerSlot, c.gender);
    }
    final id = bindings[slot];
    final person = id == null ? null : c.people[id];
    if (person == null) return null;
    return PersonText.resolve('kisi.$field', person, c);
  }

  /// Kartın üstünde konuşanın adı: akrabaysa "Annen", değilse adı.
  static String? speakerName(
    EventCard card,
    Map<String, String> bindings,
    Character c,
  ) {
    final slot = card.speaker;
    if (slot == null) return null;
    final id = bindings[slot];
    final person = id == null ? null : c.people[id];
    if (person == null) return null;
    final kin = PersonText.kinWord(person);
    return kin == null ? person.name : PersonText.capitalizeFirst(kin);
  }
}
