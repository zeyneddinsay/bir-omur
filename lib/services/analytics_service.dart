import 'package:firebase_analytics/firebase_analytics.dart';

/// Oyun içi kullanım verisi. Oyuncu onay vermedikçe kapalıdır (KVKK);
/// karakter adı gibi oyuncunun yazdığı hiçbir şey gönderilmez.
abstract interface class AnalyticsService {
  Future<void> setCollectionEnabled(bool enabled);

  Future<void> logEvent(String name, [Map<String, Object> parameters]);
}

/// Hiçbir şey göndermeyen uygulama; testlerde ve Firebase açılamazsa.
class NoopAnalytics implements AnalyticsService {
  const NoopAnalytics();

  @override
  Future<void> setCollectionEnabled(bool enabled) async {}

  @override
  Future<void> logEvent(String name, [Map<String, Object>? parameters]) async {}
}

class FirebaseAnalyticsService implements AnalyticsService {
  FirebaseAnalyticsService(this._analytics);

  final FirebaseAnalytics _analytics;

  @override
  Future<void> setCollectionEnabled(bool enabled) =>
      _analytics.setAnalyticsCollectionEnabled(enabled);

  @override
  Future<void> logEvent(String name, [Map<String, Object>? parameters]) async {
    try {
      await _analytics.logEvent(name: name, parameters: parameters);
    } on Object {
      // Analitik oyunu durdurmamalı.
    }
  }
}

/// Olay adları; Firebase'de 40 karakteri geçmemeli.
abstract final class AnalyticsEvents {
  static const String lifeStart = 'life_start';
  static const String lifeResume = 'life_resume';
  static const String lifeEnd = 'life_end';
  static const String badgeEarned = 'badge_earned';
  static const String shareCard = 'share_card';
  static const String albumOpen = 'album_open';
}
