import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../engine/engine.dart';
import '../services/feedback_service.dart';
import 'providers.dart';

/// Oyundaki olayları sese ve titreşime çevirir: kart kaydırma, zar, terfi,
/// yeni rozet ve ölüm. Motora dokunmaz; yalnızca durum değişikliğini izler.
class FeedbackListener extends ConsumerWidget {
  const FeedbackListener({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<LifeState?>(lifeProvider, (previous, next) {
      if (previous == null || next == null) return;
      final feedback = ref.read(feedbackServiceProvider);
      final event = feedbackFor(previous, next, ref);
      if (event case (final sound, final haptic)) {
        feedback.play(sound);
        feedback.haptic(haptic);
      }
    });
    ref.listen<Set<String>>(newBadgesProvider, (previous, next) {
      if (next.isNotEmpty) {
        ref.read(feedbackServiceProvider).play(GameSound.badge);
      }
    });
    return child;
  }

  /// İki durum arasındaki olayın sesi ve titreşimi; olay yoksa null.
  static (GameSound, HapticStrength)? feedbackFor(
    LifeState previous,
    LifeState next,
    WidgetRef ref,
  ) {
    if (next.isOver && !previous.isOver) {
      return (GameSound.death, HapticStrength.heavy);
    }
    final aged = next.character.age > previous.character.age;
    if (aged) {
      final promoted =
          ref.read(lifeProvider.notifier).engine.lastCareer?.promoted ?? false;
      return promoted ? (GameSound.promotion, HapticStrength.medium) : null;
    }
    final outcome = next.lastOutcome;
    if (outcome != null && !identical(outcome, previous.lastOutcome)) {
      return switch (outcome.rollSucceeded) {
        true => (GameSound.rollSuccess, HapticStrength.medium),
        false => (GameSound.rollFail, HapticStrength.medium),
        null => (GameSound.swipe, HapticStrength.light),
      };
    }
    return null;
  }
}
