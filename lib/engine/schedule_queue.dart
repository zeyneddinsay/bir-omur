/// Yıllar sonra gelecek zincir kartlarının sırası. Değişmezdir.
class ScheduleQueue {
  const ScheduleQueue([this.entries = const []]);

  final List<ScheduledCard> entries;

  bool get isEmpty => entries.isEmpty;

  ScheduleQueue add(String cardId, {required int atAge}) => ScheduleQueue(
    List.unmodifiable([...entries, ScheduledCard(cardId, atAge)]),
  );

  /// [age] yaşına kadar zamanı gelmiş kartları planlandıkları sırayla
  /// çıkarır. Kaçırılan yıllar da dahildir.
  (List<String> due, ScheduleQueue rest) takeDue(int age) {
    final due = <String>[];
    final rest = <ScheduledCard>[];
    for (final entry in entries) {
      if (entry.atAge <= age) {
        due.add(entry.cardId);
      } else {
        rest.add(entry);
      }
    }
    return (due, ScheduleQueue(List.unmodifiable(rest)));
  }
}

class ScheduledCard {
  const ScheduledCard(this.cardId, this.atAge);

  final String cardId;
  final int atAge;
}
