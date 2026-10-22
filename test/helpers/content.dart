import 'package:bir_omur/content/content_loader.dart';
import 'package:bir_omur/engine/engine.dart';

import '../content/real_cards_test.dart' show loadRealContent;
import 'test_cards.dart';

/// Arayüz testleri için içerik: gerçek meslekler, aileler, rozetler ve
/// etkileşim metinleri; olaylar ise sentetik test destesi. Böylece arayüz
/// testleri olay içeriği değiştikçe kırılmaz.
///
/// Destede 0 yaşında mutlaka gelen bir olay vardır: "İlk olay".
GameContent uiTestContent() {
  final real = loadRealContent();
  return GameContent(
    deck: EventDeck([
      testCard(
        'ilk_olay',
        maxAge: 0,
        mandatory: true,
        once: true,
        theme: 'aile',
        text: 'İlk olay: evde herkes seni seviyor.',
      ),
      ...simulationDeck(),
    ]),
    careers: real.careers,
    achievements: real.achievements,
    families: real.families,
    interactions: real.interactions,
    registry: real.registry,
    warnings: const [],
  );
}

/// Test destesinin ilk olayının metni (doğumdan sonra ekranda).
const String firstEventText = 'İlk olay: evde herkes seni seviyor.';
