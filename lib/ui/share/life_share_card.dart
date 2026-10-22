import 'package:flutter/material.dart';

import '../../content/event_text.dart';
import '../../content/content_loader.dart';
import '../../engine/engine.dart';
import '../../l10n/generated/app_localizations.dart';
import '../l10n_names.dart';
import '../theme.dart';
import '../widgets/life_status.dart';

/// Büyük tutarları okunur yazar: "2,8 milyon TL", "640 bin TL".
String compactMoney(AppLocalizations l10n, int amount) {
  final abs = amount.abs();
  final sign = amount < 0 ? '−' : '';
  if (abs >= 1000000) {
    final value = (abs / 1000000).toStringAsFixed(1).replaceAll('.', ',');
    return sign + l10n.amountMillion(value.replaceAll(',0', ''));
  }
  if (abs >= 1000) return sign + l10n.amountThousand('${(abs / 1000).round()}');
  return sign + l10n.money(abs);
}

/// Kartta gösterilecek sayılar: sıfır olmayanlardan en fazla üçü ve en
/// sonda geride bırakılan servet. Borç dönemi gösterilmez; para sıfır
/// çevresinde dolaşınca yanıltıcı büyür.
List<String> shareNumbers(AppLocalizations l10n, LifeSummary summary) {
  final k = summary.character.counters;
  final candidates = [
    if (k.moves > 0) l10n.numMoves(k.moves),
    if (k.rentPaid > 0) l10n.numRent(compactMoney(l10n, k.rentPaid)),
    if (k.goldReceived > 0) l10n.numGold(k.goldReceived),
    if (k.promotions > 0) l10n.numPromotions(k.promotions),
    if (k.yearsWorked > 0) l10n.numYearsWorked(k.yearsWorked),
  ];
  return [
    ...candidates.take(3),
    l10n.numNetWorth(compactMoney(l10n, summary.netWorth)),
  ];
}

/// 9:16 hayat özeti kartı. Her zaman [size] boyutunda çizilir; görsel
/// [pixelRatio] ile büyütülerek 1080×1920 PNG olur. Tema yerine kendi
/// renklerini kullanır ki karanlık modda da aynı görünsün.
class LifeShareCard extends StatelessWidget {
  const LifeShareCard({
    super.key,
    required this.summary,
    required this.content,
  });

  final LifeSummary summary;
  final GameContent content;

  static const Size size = Size(360, 640);
  static const double pixelRatio = 3;

  static const Color _paper = AppColors.paper;
  static const Color _ink = AppColors.ink;
  static const Color _accent = AppColors.accent;
  static const Color _muted = AppColors.muted;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = summary.character;
    final job = lastJobLabel(l10n, c, content.careers);
    final moment = summary.biggestMoment;
    final momentCard = moment == null ? null : content.deck.byId(moment.cardId);
    const base = TextStyle(color: _ink, fontFamily: appFontFamily);

    return SizedBox.fromSize(
      size: size,
      child: DecoratedBox(
        decoration: const BoxDecoration(color: _paper),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 36, 28, 24),
          child: DefaultTextStyle(
            style: base.copyWith(fontSize: 14),
            textAlign: TextAlign.center,
            child: Column(
              children: [
                Text(
                  l10n.appTitle.toUpperTr(),
                  style: base.copyWith(
                    fontSize: 12,
                    letterSpacing: 4,
                    color: _accent,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  c.name,
                  style: base.copyWith(
                    fontSize: 34,
                    fontWeight: FontWeight.w800,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.deathLifespan(summary.deathAge),
                  style: base.copyWith(fontSize: 16, color: _muted),
                ),
                Text(
                  [c.hometown, ?job].join(' · '),
                  style: base.copyWith(fontSize: 13, color: _muted),
                  maxLines: 2,
                ),
                const SizedBox(height: 28),
                Text(
                  l10n.nicknameTitle,
                  style: base.copyWith(fontSize: 12, color: _muted),
                ),
                const SizedBox(height: 6),
                Text(
                  l10n.nicknameName(summary.nickname),
                  key: const Key('share_nickname'),
                  style: base.copyWith(
                    fontSize: 28,
                    height: 1.15,
                    color: _accent,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 28),
                Text(
                  l10n.shareNumbersTitle.toUpperTr(),
                  style: base.copyWith(
                    fontSize: 11,
                    letterSpacing: 2,
                    color: _muted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                for (final line in shareNumbers(l10n, summary))
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Text(
                      line,
                      style: base.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                const Spacer(),
                if (moment != null && momentCard != null) ...[
                  Text(
                    l10n.biggestMomentTitle.toUpperTr(),
                    style: base.copyWith(
                      fontSize: 11,
                      letterSpacing: 2,
                      color: _muted,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${l10n.biggestMomentAge(moment.age)}: '
                    '${EventText.render(momentCard.text, moment.people, summary.character)}',
                    style: base.copyWith(
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                    ),
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 16),
                ],
                Container(height: 1, color: _muted.withValues(alpha: 0.3)),
                const SizedBox(height: 10),
                Text(
                  l10n.shareFooter,
                  style: base.copyWith(fontSize: 11, color: _muted),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
