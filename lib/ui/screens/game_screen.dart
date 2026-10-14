import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../engine/engine.dart';
import '../../l10n/generated/app_localizations.dart';
import '../providers.dart';
import 'birth_screen.dart';
import 'death_screen.dart';
import 'year_screen.dart';

/// Hayatın durumuna göre doğum, yıl ya da ölüm ekranını gösterir.
class GameScreen extends ConsumerWidget {
  const GameScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final content = ref.watch(contentProvider);
    final life = ref.watch(lifeProvider);
    // Ayarlar açılışta yüklensin; kayıttaki analitik onayı hemen uygulanır.
    ref.watch(settingsProvider);

    return switch (content) {
      AsyncData(:final value) => AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: switch (life) {
          null => BirthScreen(content: value),
          LifeState(phase: YearPhase.dead) => DeathScreen(
            state: life,
            content: value,
          ),
          _ => YearScreen(state: life, registry: value.registry),
        },
      ),
      AsyncError(:final error) => Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              l10n.contentError('$error'),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
      _ => Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(l10n.loadingCards),
            ],
          ),
        ),
      ),
    };
  }
}
