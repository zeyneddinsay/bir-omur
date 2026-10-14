import '../engine/achievements.dart';
import '../engine/life_record.dart';

/// Yerel kayıt. Motor bunu bilmez; arayüz katmanı her karardan sonra
/// hayatın tam durumunu buraya yazar.
abstract interface class SaveStore {
  /// Yarım kalan hayatın kaydı (`LifeEngine.toSnapshot`); yoksa null.
  Future<Map<String, dynamic>?> loadCurrentLife();

  Future<void> saveCurrentLife(Map<String, Object?> snapshot);

  Future<void> clearCurrentLife();

  /// Biten hayatlar, en yenisi sonda.
  Future<List<LifeRecord>> loadAlbum();

  Future<void> addToAlbum(LifeRecord record);

  /// Kazanılmış rozetler: kimlik → ilerleme.
  Future<Map<String, AchievementProgress>> loadAchievements();

  Future<void> saveAchievements(Map<String, AchievementProgress> progress);
}

/// Bellekte duran kayıt; testler ve kaydın açılamadığı durumlar için.
class MemorySaveStore implements SaveStore {
  Map<String, Object?>? _current;
  final List<LifeRecord> _album = [];
  Map<String, AchievementProgress> _achievements = const {};

  @override
  Future<Map<String, dynamic>?> loadCurrentLife() async =>
      _current == null ? null : Map<String, dynamic>.of(_current!);

  @override
  Future<void> saveCurrentLife(Map<String, Object?> snapshot) async =>
      _current = snapshot;

  @override
  Future<void> clearCurrentLife() async => _current = null;

  @override
  Future<List<LifeRecord>> loadAlbum() async => List.unmodifiable(_album);

  @override
  Future<void> addToAlbum(LifeRecord record) async => _album.add(record);

  @override
  Future<Map<String, AchievementProgress>> loadAchievements() async =>
      Map.of(_achievements);

  @override
  Future<void> saveAchievements(
    Map<String, AchievementProgress> progress,
  ) async => _achievements = Map.unmodifiable(progress);
}
