import 'dart:math';

import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../models/models.dart';
import '../l10n_names.dart';
import '../portrait/portrait.dart';
import '../portrait/portrait_spec.dart';
import '../theme.dart';
import 'choice_preview.dart';

/// Sola, sağa ya da (varsa) yukarı kaydırılan olay kartı. Altında her
/// seçenek bir satırdır: etiketi, zarı ve neye dokunacağı görünür;
/// kaydırmak istemeyen satıra dokunur.
class SwipeCard extends StatefulWidget {
  const SwipeCard({
    super.key,
    required this.card,
    required this.text,
    required this.onChoose,
    this.onLean,
    this.speakerName,
    this.portrait,
    this.character,
    this.people = const {},
    this.remaining = 0,
    this.render = _plain,
  });

  final EventCard card;

  /// Kişilerle kurulmuş olay metni.
  final String text;
  final String? speakerName;

  /// Kartın üstündeki portre.
  final PortraitSpec? portrait;
  final ValueChanged<ChoiceSide> onChoose;

  /// Kart bir seçeneğe doğru eğildiğinde (ya da geri döndüğünde null).
  final ValueChanged<ChoiceSide?>? onLean;

  /// Zar ihtimali ve kişi adları için; yoksa yalnızca etiketler görünür.
  final Character? character;

  /// Olayın rol yuvalarına bağlanan kişiler.
  final Map<String, String> people;

  /// Bu yıl bu karttan sonra gelecek kart sayısı (arkada deste görünür).
  final int remaining;

  /// Seçenek etiketlerindeki yer tutucuları (`{a.ad}`) kişilerle kurar.
  /// Ekranda hiçbir zaman ham şablon görünmez.
  final String Function(String template) render;

  static String _plain(String text) => text;

  @override
  State<SwipeCard> createState() => _SwipeCardState();
}

class _SwipeCardState extends State<SwipeCard>
    with SingleTickerProviderStateMixin {
  static const double _leanThreshold = 24;
  static const double _commitThreshold = 110;

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
  )..addListener(() => setState(() => _offset = _animation!.value));

  Animation<Offset>? _animation;
  Offset _offset = Offset.zero;
  ChoiceSide? _lean;
  bool _busy = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  ChoiceSide? _sideFor(Offset offset, double threshold) {
    if (widget.card.up != null &&
        offset.dy < -threshold &&
        offset.dy.abs() > offset.dx.abs()) {
      return ChoiceSide.up;
    }
    if (offset.dx > threshold) return ChoiceSide.right;
    if (offset.dx < -threshold) return ChoiceSide.left;
    return null;
  }

  void _setLean(ChoiceSide? side) {
    if (side == _lean) return;
    setState(() => _lean = side);
    widget.onLean?.call(side);
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_busy) return;
    setState(() => _offset += details.delta);
    _setLean(_sideFor(_offset, _leanThreshold));
  }

  void _onPanEnd(DragEndDetails details) {
    if (_busy) return;
    final side = _sideFor(_offset, _commitThreshold);
    if (side == null) {
      _animateTo(Offset.zero);
      _setLean(null);
    } else {
      _commit(side);
    }
  }

  Future<void> _animateTo(Offset target) {
    _animation = Tween(
      begin: _offset,
      end: target,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    return _controller.forward(from: 0);
  }

  Future<void> _commit(ChoiceSide side) async {
    if (_busy) return;
    _busy = true;
    _setLean(side);
    final width = MediaQuery.sizeOf(context).width;
    final target = switch (side) {
      ChoiceSide.left => Offset(-width * 1.5, _offset.dy),
      ChoiceSide.right => Offset(width * 1.5, _offset.dy),
      ChoiceSide.up => Offset(_offset.dx, -width * 2),
    };
    await _animateTo(target);
    if (!mounted) return;
    widget.onChoose(side);
  }

  @override
  Widget build(BuildContext context) {
    final card = widget.card;
    final angle = _offset.dx / 900 * pi / 4;
    final sides = [
      ChoiceSide.left,
      ChoiceSide.right,
      if (card.up != null) ChoiceSide.up,
    ];

    return LayoutBuilder(
      builder: (context, outer) {
        // Alçak ekranda seçenekler sıkışır, kart metne yer bırakır.
        final tight = outer.maxHeight < 440;
        return Column(
          children: [
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxHeight < 300;
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          // Bu yıl daha kart varsa arkada deste görünür.
                          if (widget.remaining > 0)
                            const Positioned(
                              left: 14,
                              right: 14,
                              top: 14,
                              bottom: -10,
                              child: _CardBack(),
                            ),
                          GestureDetector(
                            onPanUpdate: _onPanUpdate,
                            onPanEnd: _onPanEnd,
                            child: Transform.translate(
                              offset: _offset,
                              child: Transform.rotate(
                                angle: angle,
                                child: _CardFace(
                                  card: card,
                                  text: widget.text,
                                  speakerName: widget.speakerName,
                                  portrait: widget.portrait,
                                  lean: _lean,
                                  render: widget.render,
                                  compact: compact,
                                  maxHeight: min(
                                    constraints.maxHeight - 24,
                                    480,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            // Seçenekler ekranın en fazla yarısını alır; sığmazsa kayar ve kart
            // hep görünür kalır.
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: outer.maxHeight * (tight ? 0.42 : 0.55),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 480),
                    child: Column(
                      children: [
                        for (final side in sides)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: ChoiceTile(
                              key: Key('choose_${side.name}'),
                              side: side,
                              choice: card.choice(side),
                              label: widget.render(card.choice(side).label),
                              character: widget.character,
                              people: widget.people,
                              highlighted: _lean == side,
                              dense: tight,
                              onTap: () => _commit(side),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Destedeki sıradaki kartın arkası.
class _CardBack extends StatelessWidget {
  const _CardBack();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: scheme.onSurface.withValues(alpha: 0.08)),
      ),
    );
  }
}

class _CardFace extends StatelessWidget {
  const _CardFace({
    required this.card,
    required this.text,
    required this.lean,
    required this.render,
    required this.compact,
    required this.maxHeight,
    this.speakerName,
    this.portrait,
  });

  final EventCard card;
  final String text;
  final String? speakerName;
  final ChoiceSide? lean;
  final String Function(String template) render;

  /// Küçük ekranda portre gizlenir, yer metne kalır.
  final bool compact;

  /// Kartın en fazla boyu; kart bu boya kadar uzar.
  final double maxHeight;

  /// Konuşmacının (yoksa oyuncunun) portresi.
  final PortraitSpec? portrait;

  static const Map<EventTheme, IconData> themeIcons = {
    EventTheme.aile: Icons.family_restroom,
    EventTheme.okul: Icons.school_outlined,
    EventTheme.ask: Icons.favorite_border,
    EventTheme.isHayati: Icons.work_outline,
    EventTheme.para: Icons.payments_outlined,
    EventTheme.mahalle: Icons.holiday_village_outlined,
    EventTheme.saglik: Icons.local_hospital_outlined,
    EventTheme.genel: Icons.auto_stories_outlined,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final dark = theme.brightness == Brightness.dark;
    final rarityColor = switch (card.rarity) {
      Rarity.siradan => null,
      Rarity.nadir => scheme.tertiary,
      Rarity.efsane => AppColors.legendary,
    };
    final leanLabel = switch (lean) {
      final side? when side != ChoiceSide.up || card.up != null => render(
        card.choice(side).label,
      ),
      _ => null,
    };
    final muted = scheme.onSurface.withValues(alpha: 0.62);

    final header = Row(
      children: [
        _Pill(
          icon: themeIcons[card.theme]!,
          text: l10n.themeName(card.theme),
          color: muted,
        ),
        // Dar düzende konuşanın adı başlıkta durur; metne bir satır kalır.
        if (compact && speakerName != null)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                speakerName!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelLarge?.copyWith(color: muted),
              ),
            ),
          )
        else
          const Spacer(),
        if (l10n.rarityName(card.rarity) case final rarity?)
          _Pill(
            key: const Key('card_rarity'),
            icon: Icons.auto_awesome,
            text: rarity,
            color: rarityColor!,
            filled: true,
          ),
      ],
    );
    final speaker = speakerName == null
        ? null
        : Text(
            speakerName!,
            style: theme.textTheme.labelLarge?.copyWith(color: muted),
            textAlign: TextAlign.center,
          );
    final body = Text(
      text,
      key: const Key('card_text'),
      style: theme.textTheme.titleMedium?.copyWith(
        fontSize: compact ? 16 : 18,
        height: 1.45,
        fontWeight: FontWeight.w600,
      ),
      textAlign: TextAlign.center,
    );

    final face = ConstrainedBox(
      constraints: BoxConstraints(maxWidth: 360, maxHeight: maxHeight),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: theme.cardTheme.color,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: rarityColor ?? scheme.onSurface.withValues(alpha: 0.1),
            width: rarityColor == null ? 1 : 2.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: dark ? 0.35 : 0.08),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(18, compact ? 12 : 16, 18, 18),
          child: compact
              // Dar ekranda kartın tamamı kayar; hiçbir parça taşmaz.
              ? SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [header, const SizedBox(height: 8), body],
                  ),
                )
              // Kart oyun kartı boyunda durur; içerik ortada, sığmazsa kayar.
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    header,
                    Flexible(
                      child: Center(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (portrait case final spec?)
                                Container(
                                  padding: const EdgeInsets.all(3),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: (rarityColor ?? scheme.primary)
                                          .withValues(alpha: 0.35),
                                      width: 2,
                                    ),
                                  ),
                                  child: Portrait(spec: spec, size: 84),
                                ),
                              if (speaker != null) ...[
                                const SizedBox(height: 8),
                                speaker,
                              ],
                              const SizedBox(height: 16),
                              body,
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.topCenter,
      children: [
        face,
        // Eğilince seçilecek seçeneğin adı kartın üstünde belirir.
        Positioned(
          top: -14,
          child: IgnorePointer(
            child: AnimatedOpacity(
              opacity: leanLabel == null ? 0 : 1,
              duration: const Duration(milliseconds: 120),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 300),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: scheme.primary,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  leanLabel ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: scheme.onPrimary,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Kartın başlığındaki küçük etiket (tema, nadirlik).
class _Pill extends StatelessWidget {
  const _Pill({
    super.key,
    required this.icon,
    required this.text,
    required this.color,
    this.filled = false,
  });

  final IconData icon;
  final String text;
  final Color color;
  final bool filled;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: color.withValues(alpha: filled ? 0.16 : 0.08),
      borderRadius: BorderRadius.circular(999),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          text.toUpperTr(),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: color,
            letterSpacing: 0.8,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    ),
  );
}

/// Bir seçenek satırı: yön işareti, etiket, zar ve seçimin neye dokunacağı.
class ChoiceTile extends StatelessWidget {
  const ChoiceTile({
    super.key,
    required this.side,
    required this.choice,
    required this.label,
    required this.onTap,
    this.character,
    this.people = const {},
    this.highlighted = false,
    this.dense = false,
  });

  final ChoiceSide side;
  final Choice choice;

  /// Kişilerle kurulmuş etiket.
  final String label;
  final VoidCallback onTap;
  final Character? character;
  final Map<String, String> people;

  /// Kart bu seçeneğe doğru eğilmiş.
  final bool highlighted;

  /// Alçak ekranda: daha az boşluk, zar ve etkiler tek satırda.
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    List<PreviewItem> items(Effect e) =>
        previewItems(l10n, e, character: character, people: people);

    final base = items(choice.effects);
    final roll = choice.roll;
    final success = roll == null
        ? const <PreviewItem>[]
        : items(choice.success!);
    final fail = roll == null ? const <PreviewItem>[] : items(choice.fail!);
    final labelStyle = theme.textTheme.labelSmall?.copyWith(
      color: scheme.onSurface.withValues(alpha: 0.6),
      fontWeight: FontWeight.w700,
    );
    final effects = <Widget>[
      if (roll != null && dense) RollLine(roll: roll, character: character),
      for (final item in base) PreviewChip(item: item, dense: true),
      for (final (i, (branch, list)) in [
        (l10n.previewIfSuccess, success),
        (l10n.previewIfFail, fail),
      ].indexed)
        if (list.isNotEmpty) ...[
          Padding(
            padding: EdgeInsets.only(
              left: i == 0 && base.isEmpty && !dense ? 0 : 6,
            ),
            child: Text(branch, style: labelStyle),
          ),
          for (final item in list) PreviewChip(item: item, dense: true),
        ],
    ];

    return Material(
      color: highlighted
          ? scheme.primary.withValues(alpha: 0.08)
          : theme.cardTheme.color,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: highlighted
              ? scheme.primary
              : scheme.onSurface.withValues(alpha: 0.12),
          width: highlighted ? 2 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.fromLTRB(10, dense ? 7 : 10, 12, dense ? 7 : 10),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: highlighted
                      ? scheme.primary
                      : scheme.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  switch (side) {
                    ChoiceSide.left => Icons.arrow_back_rounded,
                    ChoiceSide.right => Icons.arrow_forward_rounded,
                    ChoiceSide.up => Icons.arrow_upward_rounded,
                  },
                  size: 18,
                  color: highlighted ? scheme.onPrimary : scheme.primary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (roll != null && !dense) ...[
                      const SizedBox(height: 3),
                      RollLine(roll: roll, character: character),
                    ],
                    // Etkiler tek akışta: önce kesin olanlar, sonra zarın
                    // iki dalı. Yoğun düzende zar da bu akışa girer.
                    if (effects.isNotEmpty) ...[
                      SizedBox(height: dense ? 3 : 5),
                      Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: effects,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
