import 'dart:convert';

import 'package:hive_ce/hive_ce.dart';

import '../engine/achievements.dart';
import '../engine/life_record.dart';
import 'feedback_service.dart';
import 'save_store.dart';

/// Hive üzerinde kayıt. Değerler JSON metni olarak tutulur; böylece tip
/// adaptörü gerekmez ve kayıt biçimi motorun `toSnapshot`'ıyla aynı kalır.
///
/// `Hive.init` (ya da Flutter'da `Hive.initFlutter`) [open]'dan önce
/// çağrılmış olmalı.
class HiveSaveStore implements SaveStore {
  HiveSaveStore._(this._life, this._album, this._badges, this._settings);

  static const String lifeBoxName = 'hayat';
  static const String albumBoxName = 'album';
  static const String badgesBoxName = 'rozetler';
  static const String settingsBoxName = 'ayarlar';
  static const String _settingsKey = 'ayarlar';
  static const String _currentKey = 'current';

  final Box<String> _life;
  final Box<String> _album;

  /// Rozet kimliği → ilerleme (JSON).
  final Box<String> _badges;
  final Box<String> _settings;

  static Future<HiveSaveStore> open() async => HiveSaveStore._(
    await Hive.openBox<String>(lifeBoxName),
    await Hive.openBox<String>(albumBoxName),
    await Hive.openBox<String>(badgesBoxName),
    await Hive.openBox<String>(settingsBoxName),
  );

  @override
  Future<Map<String, dynamic>?> loadCurrentLife() async {
    final raw = _life.get(_currentKey);
    if (raw == null) return null;
    final json = jsonDecode(raw);
    return json is Map<String, dynamic> ? json : null;
  }

  @override
  Future<void> saveCurrentLife(Map<String, Object?> snapshot) =>
      _life.put(_currentKey, jsonEncode(snapshot));

  @override
  Future<void> clearCurrentLife() => _life.delete(_currentKey);

  /// Okunamayan albüm kayıtları atlanır; bir bozuk kayıt albümün tamamını
  /// götürmesin.
  @override
  Future<List<LifeRecord>> loadAlbum() async => [
    for (final raw in _album.values) ?_tryParse(raw),
  ];

  @override
  Future<void> addToAlbum(LifeRecord record) =>
      _album.add(jsonEncode(record.toJson()));

  /// Okunamayan rozet kaydı atlanır.
  @override
  Future<Map<String, AchievementProgress>> loadAchievements() async {
    final result = <String, AchievementProgress>{};
    for (final key in _badges.keys.cast<String>()) {
      try {
        result[key] = AchievementProgress.fromJson(
          jsonDecode(_badges.get(key)!) as Map<String, dynamic>,
        );
      } on Object {
        continue;
      }
    }
    return result;
  }

  @override
  Future<void> saveAchievements(Map<String, AchievementProgress> progress) =>
      _badges.putAll({
        for (final MapEntry(:key, :value) in progress.entries)
          key: jsonEncode(value.toJson()),
      });

  @override
  Future<GameSettings> loadSettings() async {
    final raw = _settings.get(_settingsKey);
    if (raw == null) return GameSettings.defaults;
    try {
      return GameSettings.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } on Object {
      return GameSettings.defaults;
    }
  }

  @override
  Future<void> saveSettings(GameSettings settings) =>
      _settings.put(_settingsKey, jsonEncode(settings.toJson()));

  static LifeRecord? _tryParse(String raw) {
    try {
      return LifeRecord.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } on Object {
      return null;
    }
  }

  Future<void> close() async {
    await _life.close();
    await _album.close();
    await _badges.close();
    await _settings.close();
  }
}
