import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../engine/engine.dart';
import '../services/analytics_service.dart';
import 'providers.dart';

/// Hayatın sonunu ve yeni rozetleri analitiğe yazar. Karakter adı
/// gönderilmez; yalnızca oyunu dengelemek için gereken sayılar.
class AnalyticsListener extends ConsumerWidget {
  const AnalyticsListener({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<LifeState?>(lifeProvider, (previous, next) {
      if (next == null || !next.isOver || (previous?.isOver ?? true)) return;
      final controller = ref.read(lifeProvider.notifier);
      final startedAt = controller.lifeStartedAt;
      final minutes = startedAt == null
          ? 0
          : ref.read(clockProvider)().difference(startedAt).inMinutes;
      ref
          .read(analyticsServiceProvider)
          .logEvent(
            AnalyticsEvents.lifeEnd,
            lifeEndParameters(next.summary!, minutes),
          );
    });
    ref.listen<Set<String>>(newBadgesProvider, (previous, next) {
      final analytics = ref.read(analyticsServiceProvider);
      for (final id in next) {
        analytics.logEvent(AnalyticsEvents.badgeEarned, {'badge': id});
      }
    });
    return child;
  }

  /// `life_end` olayının parametreleri. Süre bu oturumdakidir; yarıda
  /// bırakılıp sürdürülen hayatta yalnızca son oturum sayılır.
  static Map<String, Object> lifeEndParameters(
    LifeSummary summary,
    int sessionMinutes,
  ) {
    final c = summary.character;
    final job = c.careerJob;
    return {
      'age': summary.deathAge,
      'cause': summary.cause.name,
      'nickname': summary.nickname.name,
      'career': job?.careerId ?? 'none',
      'tier': job?.tier ?? 0,
      'background': c.background.id,
      'cards': summary.cardsSeen,
      'net_worth_m': (summary.netWorth / 1000000).round(),
      'session_minutes': sessionMinutes,
    };
  }
}
