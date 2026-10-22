/// Yıllar sonra gelecek iplik olaylarının sırası. Değişmezdir.
class ScheduleQueue {
  const ScheduleQueue([this.entries = const []]);

  final List<ScheduledCard> entries;

  bool get isEmpty => entries.isEmpty;

  ScheduleQueue add(
    String cardId, {
    required int atAge,
    Map<String, String> people = const {},
  }) => ScheduleQueue(
    List.unmodifiable([
      ...entries,
      ScheduledCard(cardId, atAge, Map.unmodifiable(people)),
    ]),
  );

  /// [age] yaşına kadar zamanı gelmiş olayları planlandıkları sırayla
  /// çıkarır. Kaçırılan yıllar da dahildir.
  (List<ScheduledCard> due, ScheduleQueue rest) takeDue(int age) {
    final due = <ScheduledCard>[];
    final rest = <ScheduledCard>[];
    for (final entry in entries) {
      if (entry.atAge <= age) {
        due.add(entry);
      } else {
        rest.add(entry);
      }
    }
    return (due, ScheduleQueue(List.unmodifiable(rest)));
  }

  List<Map<String, Object>> toJson() => [
    for (final e in entries)
      {
        'card': e.cardId,
        'age': e.atAge,
        if (e.people.isNotEmpty) 'people': e.people,
      },
  ];

  factory ScheduleQueue.fromJson(List<dynamic> json) {
    var queue = const ScheduleQueue();
    for (final e in json) {
      final entry = e as Map<String, dynamic>;
      queue = queue.add(
        entry['card'] as String,
        atAge: entry['age'] as int,
        people: {
          ...?(entry['people'] as Map<String, dynamic>?)
              ?.cast<String, String>(),
        },
      );
    }
    return queue;
  }
}

class ScheduledCard {
  const ScheduledCard(this.cardId, this.atAge, [this.people = const {}]);

  final String cardId;
  final int atAge;

  /// Devam olayına aynı kişiyle taşınan yuvalar: yuva adı → kişi kimliği.
  final Map<String, String> people;
}
