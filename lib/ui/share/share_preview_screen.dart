import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../content/content_loader.dart';
import '../../engine/engine.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../services/analytics_service.dart';
import '../providers.dart';
import 'life_share_card.dart';

/// Kartı önizler; "Paylaş" ile PNG'ye çevirip telefonun paylaşım menüsünü
/// açar.
class SharePreviewScreen extends ConsumerStatefulWidget {
  const SharePreviewScreen({
    super.key,
    required this.summary,
    required this.content,
  });

  final LifeSummary summary;
  final GameContent content;

  @override
  ConsumerState<SharePreviewScreen> createState() => _SharePreviewScreenState();
}

class _SharePreviewScreenState extends ConsumerState<SharePreviewScreen> {
  final _cardKey = GlobalKey();
  bool _busy = false;

  Future<void> _share() async {
    if (_busy) return;
    setState(() => _busy = true);
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final box = context.findRenderObject() as RenderBox?;
    try {
      final boundary =
          _cardKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await boundary.toImage(
        pixelRatio: LifeShareCard.pixelRatio,
      );
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      await ref
          .read(shareServiceProvider)
          .shareImage(
            bytes!.buffer.asUint8List(),
            fileName: 'bir-omur.png',
            text: l10n.shareText(widget.summary.deathAge),
            origin: box == null
                ? null
                : box.localToGlobal(Offset.zero) & box.size,
          );
      ref.read(analyticsServiceProvider).logEvent(AnalyticsEvents.shareCard, {
        'age': widget.summary.deathAge,
        'nickname': widget.summary.nickname.name,
      });
    } on Object catch (error, stack) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stack,
          library: 'paylaşım',
        ),
      );
      messenger.showSnackBar(SnackBar(content: Text(l10n.shareFailed)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.sharePreviewTitle)),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: FittedBox(
                  child: Material(
                    elevation: 6,
                    child: RepaintBoundary(
                      key: _cardKey,
                      child: LifeShareCard(
                        summary: widget.summary,
                        content: widget.content,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  key: const Key('share_action'),
                  onPressed: _busy ? null : _share,
                  icon: _busy
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.ios_share),
                  label: Text(l10n.shareAction),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
