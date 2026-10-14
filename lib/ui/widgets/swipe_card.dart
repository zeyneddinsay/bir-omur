import 'dart:math';

import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../models/models.dart';
import '../portrait/portrait.dart';
import '../portrait/portrait_spec.dart';

/// Sola, sağa ya da (varsa) yukarı kaydırılan olay kartı. Kaydırmak
/// istemeyenler için altında seçenek düğmeleri de vardır.
class SwipeCard extends StatefulWidget {
  const SwipeCard({
    super.key,
    required this.card,
    required this.onChoose,
    this.onLean,
    this.speakerName,
    this.portrait,
  });

  final EventCard card;
  final String? speakerName;

  /// Kartın üstündeki portre.
  final PortraitSpec? portrait;
  final ValueChanged<ChoiceSide> onChoose;

  /// Kart bir seçeneğe doğru eğildiğinde (ya da geri döndüğünde null).
  final ValueChanged<ChoiceSide?>? onLean;

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
    _lean = side;
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
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final angle = _offset.dx / 900 * pi / 4;

    return Column(
      children: [
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) => Center(
              child: GestureDetector(
                onPanUpdate: _onPanUpdate,
                onPanEnd: _onPanEnd,
                child: Transform.translate(
                  offset: _offset,
                  child: Transform.rotate(
                    angle: angle,
                    child: _CardFace(
                      card: card,
                      speakerName: widget.speakerName,
                      portrait: widget.portrait,
                      lean: _lean,
                      compact: constraints.maxHeight < 300,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        Text(
          card.up == null ? l10n.swipeHint : l10n.swipeUpHint(card.up!.label),
          style: theme.textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  key: const Key('choose_left'),
                  onPressed: () => _commit(ChoiceSide.left),
                  icon: const Icon(Icons.arrow_back),
                  label: Text(card.left.label, textAlign: TextAlign.center),
                ),
              ),
              if (card.up != null) ...[
                const SizedBox(width: 8),
                IconButton.outlined(
                  key: const Key('choose_up'),
                  tooltip: card.up!.label,
                  onPressed: () => _commit(ChoiceSide.up),
                  icon: const Icon(Icons.arrow_upward),
                ),
              ],
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  key: const Key('choose_right'),
                  onPressed: () => _commit(ChoiceSide.right),
                  icon: const Icon(Icons.arrow_forward),
                  iconAlignment: IconAlignment.end,
                  label: Text(card.right.label, textAlign: TextAlign.center),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _CardFace extends StatelessWidget {
  const _CardFace({
    required this.card,
    required this.lean,
    required this.compact,
    this.speakerName,
    this.portrait,
  });

  final EventCard card;
  final String? speakerName;
  final ChoiceSide? lean;

  /// Küçük ekranda portre gizlenir, yer metne kalır.
  final bool compact;

  /// Konuşmacının (yoksa oyuncunun) portresi.
  final PortraitSpec? portrait;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final rarityColor = switch (card.rarity) {
      Rarity.siradan => scheme.outlineVariant,
      Rarity.nadir => scheme.tertiary,
      Rarity.efsane => const Color(0xFFD4A017),
    };
    final leanLabel = switch (lean) {
      ChoiceSide.left => card.left.label,
      ChoiceSide.right => card.right.label,
      ChoiceSide.up => card.up?.label,
      null => null,
    };

    final leanText = AnimatedOpacity(
      opacity: leanLabel == null ? 0 : 1,
      duration: const Duration(milliseconds: 120),
      child: Text(
        leanLabel ?? '',
        style: theme.textTheme.titleMedium?.copyWith(
          color: scheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
    final speaker = speakerName == null
        ? null
        : Text(speakerName!, style: theme.textTheme.labelLarge);
    final text = Text(
      card.text,
      key: const Key('card_text'),
      style: theme.textTheme.titleMedium?.copyWith(height: 1.4),
      textAlign: TextAlign.center,
    );

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 340),
      child: Card(
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(
            color: rarityColor,
            width: card.rarity == Rarity.siradan ? 1 : 3,
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(compact ? 12 : 20),
          child: compact
              // Dar ekranda kartın tamamı kayar; hiçbir parça taşmaz.
              ? SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      leanText,
                      ?speaker,
                      const SizedBox(height: 8),
                      text,
                    ],
                  ),
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(height: 28, child: leanText),
                    const SizedBox(height: 8),
                    if (portrait case final spec?)
                      Portrait(spec: spec, size: 72),
                    if (speaker != null) ...[
                      const SizedBox(height: 8),
                      speaker,
                    ],
                    const SizedBox(height: 16),
                    // Metin sığmazsa kendi içinde kayar.
                    Flexible(child: SingleChildScrollView(child: text)),
                    const SizedBox(height: 12),
                  ],
                ),
        ),
      ),
    );
  }
}
