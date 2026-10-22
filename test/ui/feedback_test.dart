import 'dart:io';
import 'dart:typed_data';

import 'package:bir_omur/main.dart';
import 'package:bir_omur/services/feedback_service.dart';
import 'package:bir_omur/services/save_store.dart';
import 'package:bir_omur/ui/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/content.dart';
import '../helpers/stores.dart';

class _Recorder implements FeedbackService {
  final sounds = <GameSound>[];
  final haptics = <HapticStrength>[];

  @override
  Future<void> play(GameSound sound) async => sounds.add(sound);

  @override
  Future<void> haptic(HapticStrength strength) async => haptics.add(strength);
}

void main() {
  final content = uiTestContent();

  testWidgets('bir hayat boyunca sesler ve titreşim olaylara göre çalar', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 3;
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    addTearDown(tester.view.reset);
    final recorder = _Recorder();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          contentProvider.overrideWith((ref) async => content),
          seedGeneratorProvider.overrideWithValue(() => 7),
          saveStoreProvider.overrideWithValue(answeredStore()),
          feedbackServiceProvider.overrideWithValue(recorder),
        ],
        child: const BirOmurApp(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('birth_button')));
    await tester.pumpAndSettle();
    expect(recorder.sounds, isEmpty, reason: 'doğumda ses yok');

    var cards = 0;
    while (find.byKey(const Key('rebirth')).evaluate().isEmpty) {
      if (find.byKey(const Key('choose_left')).evaluate().isNotEmpty) {
        cards++;
        await tester.tap(find.byKey(const Key('choose_left')));
      } else {
        await tester.tap(find.byKey(const Key('age_up')));
      }
      await tester.pumpAndSettle();
    }

    final cardSounds = recorder.sounds.where(
      (s) => const {
        GameSound.swipe,
        GameSound.rollSuccess,
        GameSound.rollFail,
      }.contains(s),
    );
    expect(cardSounds.length, cards, reason: 'her kart bir ses');
    expect(recorder.sounds.where((s) => s == GameSound.death), hasLength(1));
    expect(
      recorder.haptics.where((h) => h == HapticStrength.heavy),
      hasLength(1),
    );
  });

  testWidgets('ayarlar kaydedilir ve açılışta okunur', (tester) async {
    final store = MemorySaveStore();
    Widget app() => ProviderScope(
      key: UniqueKey(),
      overrides: [
        contentProvider.overrideWith((ref) async => content),
        saveStoreProvider.overrideWithValue(store),
        feedbackServiceProvider.overrideWithValue(_Recorder()),
      ],
      child: const BirOmurApp(),
    );
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('settings_button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('setting_sound')));
    await tester.pumpAndSettle();
    expect((await store.loadSettings()).sound, isFalse);
    expect((await store.loadSettings()).haptics, isTrue);

    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('settings_button')));
    await tester.pumpAndSettle();
    final sound = tester.widget<SwitchListTile>(
      find.byKey(const Key('setting_sound')),
    );
    expect(sound.value, isFalse);
  });

  testWidgets('titreşim kapalıyken titreşim isteği gönderilmez', (
    tester,
  ) async {
    final calls = <String>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        calls.add(call.method);
        return null;
      },
    );
    var settings = const GameSettings(sound: false);
    final service = DeviceFeedbackService(() => settings);
    await service.haptic(HapticStrength.medium);
    expect(calls, contains('HapticFeedback.vibrate'));

    calls.clear();
    settings = const GameSettings(sound: false, haptics: false);
    await service.haptic(HapticStrength.medium);
    expect(calls, isEmpty);
  });

  test('ses dosyaları geçerli WAV ve kısa', () {
    for (final sound in GameSound.values) {
      final file = File('assets/sounds/${sound.file}');
      expect(file.existsSync(), isTrue, reason: sound.file);
      final bytes = file.readAsBytesSync();
      expect(
        String.fromCharCodes(bytes.sublist(0, 4)),
        'RIFF',
        reason: sound.file,
      );
      expect(
        String.fromCharCodes(bytes.sublist(8, 12)),
        'WAVE',
        reason: sound.file,
      );
      final header = ByteData.sublistView(bytes);
      final byteRate = header.getUint32(28, Endian.little);
      final seconds = (bytes.length - 44) / byteRate;
      expect(
        seconds,
        lessThan(sound == GameSound.death ? 2 : 0.6),
        reason: sound.file,
      );
    }
    expect(
      (File('assets/sounds/swipe.wav').lengthSync() - 44) / (22050 * 2),
      lessThanOrEqualTo(0.2),
    );
  });
}
