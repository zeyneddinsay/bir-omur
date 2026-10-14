import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

/// Oyunun sesleri; dosyaları `assets/sounds/` altında.
enum GameSound {
  swipe('swipe.wav'),
  rollSuccess('roll_success.wav'),
  rollFail('roll_fail.wav'),
  promotion('promotion.wav'),
  badge('badge.wav'),
  death('death.wav');

  const GameSound(this.file);

  final String file;
}

enum HapticStrength { light, medium, heavy }

/// Kullanıcının ses ve titreşim tercihi.
class GameSettings {
  const GameSettings({this.sound = true, this.haptics = true});

  static const GameSettings defaults = GameSettings();

  final bool sound;
  final bool haptics;

  GameSettings copyWith({bool? sound, bool? haptics}) => GameSettings(
    sound: sound ?? this.sound,
    haptics: haptics ?? this.haptics,
  );

  Map<String, Object> toJson() => {'sound': sound, 'haptics': haptics};

  /// Eksik alan açık sayılır.
  factory GameSettings.fromJson(Map<String, dynamic> json) => GameSettings(
    sound: json['sound'] as bool? ?? true,
    haptics: json['haptics'] as bool? ?? true,
  );
}

/// Ses ve titreşim. Motor bunu bilmez; arayüz olaylara göre çağırır.
abstract interface class FeedbackService {
  Future<void> play(GameSound sound);

  Future<void> haptic(HapticStrength strength);
}

/// Sessiz uygulama; testlerde ve ayarlar kapalıyken.
class SilentFeedbackService implements FeedbackService {
  const SilentFeedbackService();

  @override
  Future<void> play(GameSound sound) async {}

  @override
  Future<void> haptic(HapticStrength strength) async {}
}

/// Telefonda çalan uygulama. Sesler çalan müziği kesmez (karışır) ve
/// iPhone'un sessiz anahtarına uyar. Ses çalınamazsa oyun etkilenmez.
class DeviceFeedbackService implements FeedbackService {
  DeviceFeedbackService(this._settings);

  /// Her çağrıda güncel tercihi verir.
  final GameSettings Function() _settings;

  final Map<GameSound, AudioPlayer> _players = {};

  static final AudioContext _context = AudioContextConfig(
    focus: AudioContextConfigFocus.mixWithOthers,
    respectSilence: true,
  ).build();

  Future<AudioPlayer> _player(GameSound sound) async {
    final existing = _players[sound];
    if (existing != null) return existing;
    final player = AudioPlayer();
    await player.setAudioContext(_context);
    await player.setPlayerMode(PlayerMode.lowLatency);
    await player.setReleaseMode(ReleaseMode.stop);
    return _players[sound] = player;
  }

  @override
  Future<void> play(GameSound sound) async {
    if (!_settings().sound) return;
    try {
      final player = await _player(sound);
      await player.stop();
      await player.play(AssetSource('sounds/${sound.file}'));
    } on Object {
      // Ses çalmamak oyunu durdurmamalı.
    }
  }

  @override
  Future<void> haptic(HapticStrength strength) async {
    if (!_settings().haptics) return;
    await switch (strength) {
      HapticStrength.light => HapticFeedback.selectionClick(),
      HapticStrength.medium => HapticFeedback.mediumImpact(),
      HapticStrength.heavy => HapticFeedback.heavyImpact(),
    };
  }
}
