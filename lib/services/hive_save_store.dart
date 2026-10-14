import 'dart:convert';

import 'package:hive_ce/hive_ce.dart';

import '../engine/life_record.dart';
import 'save_store.dart';

/// Hive üzerinde kayıt. Değerler JSON metni olarak tutulur; böylece tip
/// adaptörü gerekmez ve kayıt biçimi motorun `toSnapshot`'ıyla aynı kalır.
///
/// `Hive.init` (ya da Flutter'da `Hive.initFlutter`) [open]'dan önce
/// çağrılmış olmalı.
class HiveSaveStore implements SaveStore {
  HiveSaveStore._(this._life, this._album);

  static const String lifeBoxName = 'hayat';
  static const String albumBoxName = 'album';
  static const String _currentKey = 'current';

  final Box<String> _life;
  final Box<String> _album;

  static Future<HiveSaveStore> open() async => HiveSaveStore._(
    await Hive.openBox<String>(lifeBoxName),
    await Hive.openBox<String>(albumBoxName),
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
  }
}
