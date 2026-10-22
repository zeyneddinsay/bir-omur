import 'dart:convert';

import 'package:bir_omur/engine/relationships.dart';
import 'package:bir_omur/models/models.dart';
import 'package:flutter_test/flutter_test.dart';

Person person({
  int base = 0,
  Set<Trait> traits = const {},
  List<Memory> memories = const [],
  Impression impression = Impression.none,
  int metAt = 0,
  int? lastContactAt,
}) => Person(
  id: 'p1',
  name: 'Kerem',
  surname: 'Yılmaz',
  gender: Gender.erkek,
  bornAt: 0,
  city: 'Samsun',
  origin: Origin.okul,
  metAt: metAt,
  base: base,
  portraitSeed: 7,
  traits: traits,
  memories: memories,
  impression: impression,
  lastContactAt: lastContactAt,
);

Memory memory({
  MemoryTone tone = MemoryTone.olumlu,
  int severity = 2,
  int age = 0,
  MemoryOwner owner = MemoryOwner.ikisi,
  String kind = 'test',
  double bonus = 1.0,
  bool healed = false,
}) => Memory(
  kind: kind,
  label: 'Bir anı',
  age: age,
  tone: tone,
  severity: severity,
  owner: owner,
  bonus: bonus,
  healed: healed,
);

const _neg = MemoryTone.olumsuz;

void main() {
  int close(Person p, int now) => Relationships.closeness(p, now);
  int hostile(Person p, int now) => Relationships.hostility(p, now);

  group('ağırlıklar', () {
    test('yalnızca taban', () {
      final p = person(base: 70);
      expect(close(p, 0), 70);
      expect(hostile(p, 0), 0);
    });

    test('şiddet puanları 10 / 30 / 50', () {
      for (final (s, points) in [(1, 10), (2, 30), (3, 50)]) {
        expect(close(person(memories: [memory(severity: s)]), 0), points);
        expect(
          hostile(
            person(
              memories: [memory(severity: s, tone: _neg)],
            ),
            0,
          ),
          points,
        );
      }
    });

    test('şiddet 1 beş yılda biter', () {
      final p = person(memories: [memory(severity: 1)]);
      expect(close(p, 2), 6);
      expect(close(p, 5), 0);
      expect(close(p, 9), 0);
    });

    test('şiddet 2 yüzde 20 tabanda kalır', () {
      final p = person(memories: [memory(severity: 2)], lastContactAt: 99);
      expect(close(p, 6), 18);
      expect(close(p, 12), 6);
      expect(close(p, 30), 6);
    });

    test('şiddet 3 yüzde 50 tabanda kalır', () {
      final p = person(memories: [memory(severity: 3)], lastContactAt: 99);
      expect(close(p, 4), 40);
      expect(close(p, 10), 25);
      expect(close(p, 40), 25);
    });

    test('Vefalı yavaş, Gamsız hızlı unutur', () {
      final m = [memory(severity: 2)];
      expect(
        close(
          person(traits: {Trait.vefali}, memories: m, lastContactAt: 99),
          6,
        ),
        24,
      );
      expect(
        close(
          person(traits: {Trait.gamsiz}, memories: m, lastContactAt: 99),
          6,
        ),
        6,
      );
    });

    test('Kıskanç kişide olumsuz anı 1,5 kat, olumlu anı aynı', () {
      final p = person(
        traits: {Trait.kiskanc},
        memories: [
          memory(tone: _neg),
          memory(),
        ],
      );
      expect(hostile(p, 0), 45);
      expect(close(p, 0), 30);
    });

    test('barışmayla yumuşamış olumsuz anı yarı ağırlıkta', () {
      expect(
        hostile(person(memories: [memory(tone: _neg, healed: true)]), 0),
        15,
      );
      expect(
        hostile(
          person(
            traits: {Trait.kiskanc},
            memories: [memory(tone: _neg, healed: true)],
          ),
          0,
        ),
        23,
      );
    });

    test('anının çarpanı (uzun aradan sonra arama)', () {
      expect(close(person(memories: [memory(bonus: 1.5)]), 0), 45);
    });

    test('oyuncunun anısı çubukları etkilemez', () {
      final p = person(
        memories: [
          memory(owner: MemoryOwner.oyuncu),
          memory(tone: _neg, owner: MemoryOwner.oyuncu),
        ],
      );
      expect(close(p, 0), 0);
      expect(hostile(p, 0), 0);
    });

    test('kişinin tek taraflı anısı çubukları etkiler', () {
      expect(close(person(memories: [memory(owner: MemoryOwner.kisi)]), 0), 30);
    });

    test('çubuklar 0–100 arasında kalır', () {
      final many = [
        for (var i = 0; i < 3; i++) memory(severity: 3, tone: _neg),
      ];
      expect(hostile(person(traits: {Trait.kiskanc}, memories: many), 0), 100);
      expect(close(person(base: 90, memories: [memory(severity: 3)]), 0), 100);
      expect(close(person(base: 5, lastContactAt: 0), 40), 0);
    });
  });

  group('soğuma', () {
    test('iki yıl hoşgörü, sonra yılda 2 puan, en fazla 30', () {
      final p = person(base: 60, lastContactAt: 10);
      expect(close(p, 12), 60);
      expect(close(p, 13), 58);
      expect(close(p, 20), 44);
      expect(close(p, 40), 30);
    });

    test('Vefalı yarı hızda soğur', () {
      final p = person(base: 60, traits: {Trait.vefali}, lastContactAt: 10);
      expect(close(p, 20), 52);
    });

    test('görüşme soğumayı sıfırlar', () {
      final p = Relationships.touch(person(base: 60, lastContactAt: 10), 20);
      expect(close(p, 20), 60);
    });

    test('soğuma husumeti etkilemez', () {
      final p = person(
        memories: [memory(severity: 3, tone: _neg)],
        lastContactAt: 0,
      );
      expect(hostile(p, 4), 40);
    });
  });

  group('genel izlenim', () {
    test('yılda yüzde 10 solar', () {
      final p = person(
        impression: const Impression(warmth: 20, grudge: 10, since: 0),
        lastContactAt: 2,
      );
      expect(close(p, 2), 16);
      expect(hostile(p, 2), 8);
    });

    test('dokuzuncu anıda en zayıfı izlenime katılır', () {
      var p = person(lastContactAt: 10);
      for (var i = 0; i < 8; i++) {
        p = Relationships.addMemory(p, memory(age: 10), now: 10);
      }
      p = Relationships.addMemory(
        p,
        memory(age: 10, severity: 1, tone: _neg),
        now: 10,
      );
      expect(p.memories, hasLength(Person.maxMemories));
      expect(p.memories.every((m) => m.tone == MemoryTone.olumlu), isTrue);
      expect(p.impression.grudge, 10);
      expect(hostile(p, 10), 10);
      expect(hostile(p, 11), 9);
    });

    test('oyuncunun anısı düşerse izlenime katılmaz', () {
      var p = person();
      for (var i = 0; i < 8; i++) {
        p = Relationships.addMemory(p, memory(), now: 0);
      }
      p = Relationships.addMemory(
        p,
        memory(severity: 1, owner: MemoryOwner.oyuncu),
        now: 0,
      );
      expect(p.memories, hasLength(Person.maxMemories));
      expect(p.impression.isEmpty, isTrue);
    });

    test('sekiz anıya kadar hiçbir şey birleşmez', () {
      var p = person();
      for (var i = 0; i < 8; i++) {
        p = Relationships.addMemory(p, memory(severity: 1), now: 0);
      }
      expect(p.memories, hasLength(8));
      expect(p.impression.isEmpty, isTrue);
    });
  });

  group('barışma', () {
    test('tür verilirse yalnızca o türdeki olumsuz anılar yumuşar', () {
      final p = person(
        memories: [
          memory(tone: _neg, kind: 'rezil_etti'),
          memory(tone: _neg, kind: 'borc_odemedi'),
        ],
      );
      final healed = Relationships.heal(p, kind: 'rezil_etti', now: 0);
      expect(healed.memories.map((m) => m.healed), [true, false]);
      expect(hostile(healed, 0), 45);
    });

    test('tür verilmezse en ağır olumsuz anı yumuşar', () {
      final p = person(
        memories: [
          memory(tone: _neg, severity: 1),
          memory(tone: _neg, severity: 3),
        ],
      );
      final healed = Relationships.heal(p, now: 0);
      expect(healed.memories.map((m) => m.healed), [false, true]);
    });

    test('oyuncunun anısı yumuşamaz', () {
      final p = person(
        memories: [memory(tone: _neg, owner: MemoryOwner.oyuncu)],
      );
      expect(Relationships.heal(p, now: 0).memories.single.healed, isFalse);
    });

    test('yumuşayacak anı yoksa kişi aynen döner', () {
      final p = person(memories: [memory()]);
      expect(identical(Relationships.heal(p, now: 0), p), isTrue);
    });
  });

  group('renk ve etiket', () {
    test('dört renk', () {
      expect(Relationships.colorOf(person(base: 60), 0), RelationColor.dost);
      expect(
        Relationships.colorOf(
          person(base: 60, memories: [memory(severity: 3, tone: _neg)]),
          0,
        ),
        RelationColor.kiskancYakin,
      );
      expect(Relationships.colorOf(person(base: 20), 0), RelationColor.tanidik);
      expect(
        Relationships.colorOf(
          person(base: 20, memories: [memory(severity: 3, tone: _neg)]),
          0,
        ),
        RelationColor.dusman,
      );
    });

    test('husumetli etiketi: husumet 60+, yakınlık 30 altı', () {
      final hateful = person(
        base: 10,
        traits: {Trait.kiskanc},
        memories: [memory(severity: 3, tone: _neg)],
      );
      expect(Relationships.isHostile(hateful, 0), isTrue);
      final rival = person(
        base: 40,
        traits: {Trait.kiskanc},
        memories: [memory(severity: 3, tone: _neg)],
      );
      expect(Relationships.isHostile(rival, 0), isFalse);
    });
  });

  group('kişilik', () {
    test('çelişen özellikler birlikte çıkmaz', () {
      expect(Trait.compatible(Trait.comert, Trait.cikarci), isFalse);
      expect(Trait.compatible(Trait.gamsiz, Trait.vefali), isFalse);
      expect(Trait.compatible(Trait.kiskanc, Trait.kiskanc), isFalse);
      expect(Trait.compatible(Trait.kiskanc, Trait.comert), isTrue);
    });
  });

  test('Kerem örneği (tasarım dokümanı)', () {
    // 12 yaşında sınıf arkadaşı; Kıskanç. 14 yaşında teneffüs olayı.
    var kerem = person(base: 10, traits: {Trait.kiskanc}, metAt: 12);
    kerem = Relationships.addMemory(
      Relationships.touch(kerem, 14),
      memory(tone: _neg, age: 14, kind: 'rezil_etti'),
      now: 14,
    );
    expect(hostile(kerem, 14), 45);
    expect(close(kerem, 14), 10);

    expect(hostile(kerem, 19), 30);
    expect(close(kerem, 19), 4);

    // 21: "Çocukluk işte, gel bir kahve içelim" (7 yıl sonra, 1,5 kat).
    expect(hostile(kerem, 21), 24);
    var calmed = Relationships.heal(kerem, kind: 'rezil_etti', now: 21);
    calmed = Relationships.addMemory(
      Relationships.touch(calmed, 21),
      memory(age: 21, bonus: 1.5, kind: 'kahve_ictik'),
      now: 21,
    );
    expect(hostile(calmed, 21), 12);
    expect(close(calmed, 21), 55);

    // 27: Kerem seni müdüre önerdi.
    calmed = Relationships.addMemory(
      Relationships.touch(calmed, 27),
      memory(age: 27, severity: 3, kind: 'ise_onerdi'),
      now: 27,
    );
    expect(hostile(calmed, 27), 5);
    // 70 üstü yarı hızla dolar (Relationships.softCap).
    expect(close(calmed, 27), 79);
    expect(Relationships.colorOf(calmed, 27), RelationColor.dost);

    // Öteki yol: 21'de iğnelemek.
    final stung = Relationships.addMemory(
      Relationships.touch(kerem, 21),
      memory(tone: _neg, severity: 3, age: 21, kind: 'igneledi'),
      now: 21,
    );
    expect(hostile(stung, 21), 99);
    expect(Relationships.isHostile(stung, 21), isTrue);
  });

  test('JSON gidip gelir', () {
    final p =
        person(
          base: 40,
          traits: {Trait.kiskanc, Trait.vefali},
          memories: [
            memory(tone: _neg, healed: true, kind: 'a'),
            memory(owner: MemoryOwner.oyuncu, bonus: 1.5, kind: 'b'),
          ],
          impression: const Impression(warmth: 3.5, since: 4),
          lastContactAt: 9,
        ).copyWith(
          roles: const [PersonRole(RoleKind.sinifArkadasi, active: false)],
          bond: Bond.arkadas,
          occupation: 'memur',
          diedAt: 60,
        );
    final round = Person.fromJson(
      jsonDecode(jsonEncode(p.toJson())) as Map<String, dynamic>,
    );
    expect(jsonEncode(round.toJson()), jsonEncode(p.toJson()));
    expect(round.isAlive, isFalse);
    expect(round.hasRole(RoleKind.sinifArkadasi), isFalse);
    expect(round.hasRole(RoleKind.sinifArkadasi, activeOnly: false), isTrue);
    expect(close(round, 9), close(p, 9));
    expect(hostile(round, 9), hostile(p, 9));
  });
}
