import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../content/content_loader.dart';
import '../../engine/life_engine.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../models/models.dart';
import '../../services/analytics_service.dart';
import '../l10n_names.dart';
import '../portrait/portrait.dart';
import '../portrait/portrait_spec.dart';
import '../providers.dart';
import 'album_screen.dart';
import 'settings_screen.dart';

/// Doğum ekranı: isim ve cinsiyet. İsim boş bırakılırsa aile seçer;
/// cinsiyet seçilmeden doğulmaz.
class BirthScreen extends ConsumerStatefulWidget {
  const BirthScreen({super.key, required this.content});

  final GameContent content;

  @override
  ConsumerState<BirthScreen> createState() => _BirthScreenState();
}

class _BirthScreenState extends ConsumerState<BirthScreen> {
  final _name = TextEditingController();
  // Cinsiyet seçilmeden doğum düğmesi açılmaz.
  Gender? _gender;

  @override
  void initState() {
    super.initState();
    // Yazılan isim üstteki portreleri canlı değiştirir.
    _name.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _born() {
    ref
        .read(lifeProvider.notifier)
        .startLife(widget.content, name: _name.text, gender: _gender);
  }

  void _resume(Map<String, dynamic> snapshot) {
    final ok = ref.read(lifeProvider.notifier).resume(widget.content, snapshot);
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).resumeFailed)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    // İkisi de koşulsuz izlenir; ayarlar ancak izlenince yüklenir.
    final settings = ref.watch(settingsProvider);
    final settingsLoaded = ref.watch(settingsLoadedProvider);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        actions: [SettingsScreen.button(context)],
      ),
      body: DecoratedBox(
        // Üstten sıcak bir ışık: kâğıt rengine doğru solan vurgu.
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(0, -1.1),
            radius: 1.2,
            colors: [
              scheme.primary.withValues(alpha: 0.14),
              scheme.surface.withValues(alpha: 0),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _LifeArc(
                      name: _name.text.trim(),
                      gender: _gender ?? Gender.kadin,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      l10n.appTitle,
                      style: theme.textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.birthTagline.toUpperTr(),
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: scheme.primary,
                        letterSpacing: 1.6,
                        fontWeight: FontWeight.w800,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (settingsLoaded && settings.analyticsConsent == null)
                      const _ConsentCard(),
                    if (ref.watch(savedLifeProvider).value case final saved?)
                      LifeEngine.canRestore(saved)
                          ? _ResumeCard(
                              snapshot: saved,
                              onResume: () => _resume(saved),
                            )
                          : _OutdatedSaveCard(
                              onDismiss: () => ref
                                  .read(lifeProvider.notifier)
                                  .discardSavedLife(),
                            ),
                    const SizedBox(height: 20),
                    _Panel(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            l10n.birthTitle,
                            style: theme.textTheme.titleLarge,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            l10n.birthSubtitle,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: scheme.onSurface.withValues(alpha: 0.65),
                            ),
                          ),
                          const SizedBox(height: 20),
                          TextField(
                            key: const Key('birth_name'),
                            controller: _name,
                            textCapitalization: TextCapitalization.words,
                            maxLength: 20,
                            decoration: InputDecoration(
                              labelText: l10n.birthNameLabel,
                              hintText: l10n.birthNameHint,
                              counterText: '',
                              filled: true,
                              fillColor: scheme.onSurface.withValues(
                                alpha: 0.05,
                              ),
                              prefixIcon: const Icon(Icons.badge_outlined),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(
                                  color: scheme.primary,
                                  width: 2,
                                ),
                              ),
                            ),
                            onSubmitted: (_) {
                              if (_gender != null) _born();
                            },
                          ),
                          const SizedBox(height: 20),
                          Text(
                            l10n.birthGenderLabel,
                            style: theme.textTheme.labelLarge,
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              for (final (i, (value, label)) in [
                                (Gender.kadin, l10n.genderFemale),
                                (Gender.erkek, l10n.genderMale),
                              ].indexed) ...[
                                if (i > 0) const SizedBox(width: 12),
                                Expanded(
                                  child: _GenderTile(
                                    gender: value,
                                    label: label,
                                    selected: _gender == value,
                                    onTap: () =>
                                        setState(() => _gender = value),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            height: 56,
                            child: FilledButton.icon(
                              key: const Key('birth_button'),
                              onPressed: _gender == null ? null : _born,
                              style: FilledButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                textStyle: theme.textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w900),
                              ),
                              icon: const Icon(Icons.child_care),
                              label: Text(l10n.birthButton),
                            ),
                          ),
                          AnimatedSize(
                            duration: const Duration(milliseconds: 200),
                            child: _gender == null
                                ? Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Text(
                                      l10n.birthPickGender,
                                      textAlign: TextAlign.center,
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            color: scheme.onSurface.withValues(
                                              alpha: 0.6,
                                            ),
                                          ),
                                    ),
                                  )
                                : const SizedBox(width: double.infinity),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    _AlbumRow(
                      onTap: () {
                        ref
                            .read(analyticsServiceProvider)
                            .logEvent(AnalyticsEvents.albumOpen);
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) =>
                                AlbumScreen(content: widget.content),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Beyaz, gölgeli, yuvarlak köşeli bölüm.
class _Panel extends StatelessWidget {
  const _Panel({super.key, required this.child, this.padding});

  final Widget child;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    return Container(
      padding: padding ?? const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.08),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: dark ? 0.3 : 0.06),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }
}

/// Aynı kişinin bebeklikten yaşlılığa dört portresi, bir yayın üstünde.
/// İsim ve cinsiyet değiştikçe yüz de değişir.
class _LifeArc extends StatelessWidget {
  const _LifeArc({required this.name, required this.gender});

  final String name;
  final Gender gender;

  static const _ages = [1, 9, 32, 72];
  static const _sizes = [52.0, 62.0, 76.0, 62.0];

  /// Yayın tepesi ve derinliği (ölçek 1'de).
  static const double _top = 44;
  static const double _depth = 64;

  /// Yay üstünde [t] (0–1) noktasının yüksekliği: ortada tepe, uçlarda dip.
  static double _yAt(double t, double s) =>
      (_top + _depth * pow((t - 0.5) / 0.5, 2)) * s;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = min(constraints.maxWidth, 360.0);
        final left = (constraints.maxWidth - width) / 2;
        // Dar ekranda portreler küçülür, üst üste binmez.
        final s = (width / 360).clamp(0.7, 1.0);
        return SizedBox(
          height: (_top + _depth + 40) * s,
          child: Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _ArcPainter(
                    color: scheme.primary.withValues(alpha: 0.35),
                    left: left,
                    width: width,
                    yAt: (t) => _yAt(t, s),
                  ),
                ),
              ),
              for (var i = 0; i < _ages.length; i++)
                Builder(
                  builder: (context) {
                    final t = (i + 0.5) / _ages.length;
                    final size = _sizes[i] * s;
                    return Positioned(
                      left: left + width * t - size / 2 - 3,
                      top: _yAt(t, s) - size / 2 - 3,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        child: Container(
                          key: ValueKey('$name|${gender.id}|$i'),
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: theme.cardTheme.color,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.08),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Portrait(
                            spec: PortraitDesigner.forPerson(
                              name: name.isEmpty ? 'Bir Ömür' : name,
                              hometown: '',
                              gender: gender,
                              age: _ages[i],
                              mood: Mood.happy,
                            ),
                            size: size,
                          ),
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
  }
}

/// Portrelerin arkasındaki kesik çizgili yay.
class _ArcPainter extends CustomPainter {
  const _ArcPainter({
    required this.color,
    required this.left,
    required this.width,
    required this.yAt,
  });

  final Color color;
  final double left;
  final double width;
  final double Function(double t) yAt;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()..moveTo(left, yAt(0));
    for (var i = 1; i <= 40; i++) {
      final t = i / 40;
      path.lineTo(left + width * t, yAt(t));
    }
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    for (final metric in path.computeMetrics()) {
      for (var d = 0.0; d < metric.length; d += 10) {
        canvas.drawPath(metric.extractPath(d, d + 5), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_ArcPainter old) =>
      old.color != color || old.left != left || old.width != width;
}

/// Bebek portreli büyük cinsiyet kartı.
class _GenderTile extends StatelessWidget {
  const _GenderTile({
    required this.gender,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final Gender gender;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Material(
      color: selected
          ? scheme.primary.withValues(alpha: 0.08)
          : scheme.onSurface.withValues(alpha: 0.03),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: selected
              ? scheme.primary
              : scheme.onSurface.withValues(alpha: 0.12),
          width: selected ? 2 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          child: Column(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Portrait(
                    spec: PortraitDesigner.build(
                      seed: gender == Gender.kadin ? 7 : 11,
                      gender: gender,
                      age: AgeLook.bebek,
                    ),
                    size: 56,
                  ),
                  Positioned(
                    right: -4,
                    bottom: -2,
                    child: AnimatedScale(
                      scale: selected ? 1 : 0,
                      duration: const Duration(milliseconds: 150),
                      child: CircleAvatar(
                        radius: 11,
                        backgroundColor: scheme.primary,
                        child: Icon(
                          Icons.check,
                          size: 14,
                          color: scheme.onPrimary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  key: Key('gender_${gender.name}'),
                  maxLines: 1,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: selected ? scheme.primary : null,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Hayat Albümü'ne giden satır.
class _AlbumRow extends StatelessWidget {
  const _AlbumRow({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Material(
      color: theme.cardTheme.color,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: scheme.onSurface.withValues(alpha: 0.08)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: const Key('album_button'),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: scheme.primary.withValues(alpha: 0.1),
                child: Icon(
                  Icons.photo_album_outlined,
                  color: scheme.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.albumButton,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      l10n.albumSubtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: scheme.onSurface.withValues(alpha: 0.4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Oyunun eski bir sürümünden kalan, sürdürülemeyen yarım hayat.
class _OutdatedSaveCard extends StatelessWidget {
  const _OutdatedSaveCard({required this.onDismiss});

  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: _Panel(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  Icons.history_toggle_off,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.outdatedSaveTitle,
                    style: theme.textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(l10n.outdatedSaveBody),
            const SizedBox(height: 12),
            OutlinedButton(
              key: const Key('discard_old_save'),
              onPressed: onDismiss,
              child: Text(l10n.outdatedSaveDismiss),
            ),
          ],
        ),
      ),
    );
  }
}

/// Yarım kalan hayatı gösterir; isim ve yaş kaydın içinden okunur.
class _ResumeCard extends StatelessWidget {
  const _ResumeCard({required this.snapshot, required this.onResume});

  final Map<String, dynamic> snapshot;
  final VoidCallback onResume;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final character = snapshot['character'];
    final name = character is Map ? character['name'] : null;
    final age = character is Map ? character['age'] : null;
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: _Panel(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: scheme.primary.withValues(alpha: 0.12),
                  child: Icon(Icons.auto_stories, color: scheme.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.resumeTitle,
                        style: theme.textTheme.titleMedium,
                      ),
                      if (name is String && age is int)
                        Text(
                          l10n.resumeLine(name, age),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: scheme.onSurface.withValues(alpha: 0.7),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            FilledButton.icon(
              key: const Key('resume_button'),
              onPressed: onResume,
              icon: const Icon(Icons.play_arrow_rounded),
              label: Text(l10n.resumeButton),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.resumeOrNew,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Kullanım verisi onayı; yalnızca hiç sorulmamışsa bir kez görünür.
class _ConsentCard extends ConsumerWidget {
  const _ConsentCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final settings = ref.read(settingsProvider.notifier);
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: _Panel(
        key: const Key('consent_card'),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.insights_outlined, color: scheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.consentTitle,
                    style: theme.textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              l10n.consentBody,
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurface.withValues(alpha: 0.75),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    key: const Key('consent_decline'),
                    onPressed: () => settings.setAnalyticsConsent(false),
                    child: Text(l10n.consentDecline),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton(
                    key: const Key('consent_accept'),
                    onPressed: () => settings.setAnalyticsConsent(true),
                    child: Text(l10n.consentAccept),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
