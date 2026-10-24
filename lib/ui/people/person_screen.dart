import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../content/person_text.dart';
import '../../engine/engine.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../models/models.dart';
import '../l10n_names.dart';
import '../portrait/portrait.dart';
import '../portrait/portrait_spec.dart';
import '../providers.dart';
import 'people_tab.dart';
import 'people_text.dart';

/// Bir kişinin sayfası: kim olduğu, seninle bağı, hatırladıkları ve
/// yapabileceğin etkileşimler.
class PersonScreen extends ConsumerWidget {
  const PersonScreen({super.key, required this.personId});

  final String personId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final state = ref.watch(lifeProvider);
    final content = ref.watch(contentProvider).value;
    final p = state?.character.people[personId];
    if (state == null || content == null || p == null) {
      return const Scaffold(body: SizedBox.shrink());
    }
    final c = state.character;
    final now = c.age;
    final controller = ref.read(lifeProvider.notifier);
    // Yaşına uymayan seçenekler hiç görünmez: altı satır "çok küçüksün"
    // çocuğa uygun olanı ("Elini öp") aşağıya iter.
    final options = state.phase == YearPhase.actions
        ? [
            for (final o in controller.engine.interactionsWith(p.id))
              if (o.blocked != Blocked.yas) o,
          ]
        : const <InteractionOption>[];
    final result = state.lastInteraction;
    final resultText = result != null && result.personId == p.id
        ? _resultText(content.interactions, result, p, c)
        : null;
    final occupation = content.families.occupations[p.occupation];
    final yearsApart = now - p.lastContactAt;

    return Scaffold(
      appBar: AppBar(title: Text('${p.name} ${p.surname}'.trim())),
      body: SafeArea(
        child: ListView(
          key: const Key('person_screen'),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            Row(
              children: [
                Portrait(
                  spec: PortraitDesigner.ofPerson(
                    p,
                    playerAge: p.isAlive ? now : p.diedAt!,
                    family: c,
                  ),
                  size: 80,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.relationOf(p),
                        key: const Key('person_relation'),
                        style: theme.textTheme.titleMedium,
                      ),
                      Text(
                        [
                          if (p.isAlive)
                            l10n.personAge(p.ageAt(now))
                          else
                            l10n.personDiedAt(p.ageAt(p.diedAt!)),
                          ?occupation,
                          p.city,
                        ].join(' · '),
                      ),
                      if (p.metAt > 0) Text(l10n.personMet(p.metAt)),
                      if (p.isAlive)
                        Text(
                          l10n.personLastContact(yearsApart),
                          style: theme.textTheme.bodySmall,
                        ),
                    ],
                  ),
                ),
              ],
            ),
            if (p.isAlive) ...[
              const SizedBox(height: 16),
              RelationBars(person: p, now: now),
              const SizedBox(height: 8),
              Text(
                l10n.colorName(
                  Relationships.colorOf(p, now),
                  kin: p.kin != null,
                ),
                key: const Key('person_color'),
                style: theme.textTheme.labelLarge,
              ),
            ],
            if (p.archived && p.isAlive)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  l10n.personArchived,
                  style: theme.textTheme.bodySmall,
                ),
              ),
            if (resultText != null) ...[
              const SizedBox(height: 16),
              Container(
                key: const Key('interaction_result'),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.cardTheme.color,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.12),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.lastInteractionTitle,
                      style: theme.textTheme.labelMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(resultText),
                  ],
                ),
              ),
            ],
            if (p.traits.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(l10n.traitsTitle, style: theme.textTheme.titleSmall),
              const SizedBox(height: 4),
              Wrap(
                spacing: 8,
                children: [
                  for (final t in p.traits)
                    Chip(label: Text(l10n.traitName(t))),
                ],
              ),
            ],
            if (p.isAlive) ...[
              const SizedBox(height: 16),
              Text(l10n.interactionsTitle, style: theme.textTheme.titleSmall),
              if (state.phase != YearPhase.actions)
                Text(l10n.interactionsAfterCards)
              else
                for (final option in options)
                  _InteractionTile(
                    closeness: Relationships.closeness(p, now),
                    option: option,
                    divorce:
                        option.kind == InteractionKind.ayril &&
                        p.kin == Kinship.es,
                    onTap: () => switch (option.kind) {
                      InteractionKind.ara => _openCall(context, p.id),
                      InteractionKind.ayril => _confirmBreakUp(
                        context,
                        p,
                        c,
                        () => controller.interact(
                          InteractionRequest(option.kind, p.id),
                        ),
                      ),
                      _ => controller.interact(
                        InteractionRequest(option.kind, p.id),
                      ),
                    },
                  ),
            ],
            const SizedBox(height: 16),
            Text(l10n.memoriesTitle, style: theme.textTheme.titleSmall),
            if (p.memories.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(l10n.memoriesEmpty),
              )
            else
              for (final m in p.memories.reversed) _MemoryTile(memory: m),
          ],
        ),
      ),
    );
  }

  static String? _resultText(
    InteractionBook book,
    InteractionResult result,
    Person p,
    Character c,
  ) {
    final text = book.textFor(
      result.outcome,
      result.variant,
      traits: [for (final t in p.traits) t.name],
      child: c.age < Interactions.childTextMaxAge,
    );
    return text == null ? null : PersonText.render(text, p, c);
  }

  /// Ayrılık ve boşanma geri alınamaz: önce sorulur; boşanmada bölünecek
  /// birikim gösterilir.
  static Future<void> _confirmBreakUp(
    BuildContext context,
    Person p,
    Character c,
    VoidCallback action,
  ) async {
    final l10n = AppLocalizations.of(context);
    final divorce = p.kin == Kinship.es;
    final half = c.stats.money > 0 ? c.stats.money ~/ 2 : 0;
    final yes = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        content: Text(
          divorce
              ? l10n.divorceConfirm(l10n.tl(half))
              : l10n.breakUpConfirm(p.name),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialog).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            key: const Key('break_up_yes'),
            onPressed: () => Navigator.of(dialog).pop(true),
            child: Text(l10n.breakUpYes),
          ),
        ],
      ),
    );
    if (yes ?? false) action();
  }

  static void _openCall(BuildContext context, String personId) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => CallSheet(personId: personId),
    );
  }
}

class _InteractionTile extends StatelessWidget {
  const _InteractionTile({
    required this.option,
    required this.onTap,
    required this.closeness,
    this.divorce = false,
  });

  final InteractionOption option;
  final int closeness;
  final VoidCallback onTap;

  /// Eşte "Ayrıl" yerine "Boşan".
  final bool divorce;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cost = option.moneyCost > 0
        ? l10n.interactionCostMoney(option.timeCost, l10n.tl(option.moneyCost))
        : l10n.interactionCost(option.timeCost);
    return ListTile(
      key: Key('interaction_${option.kind.name}'),
      contentPadding: EdgeInsets.zero,
      enabled: option.enabled,
      leading: Icon(_icon(option.kind)),
      title: Text(
        divorce ? l10n.interaction_bosan : l10n.interactionName(option.kind),
      ),
      subtitle: Text(switch (option.blocked) {
        Blocked.yakinlikDusuk
            when Interactions.closenessNeeded(option.kind) != null =>
          l10n.blockedCloseness(
            Interactions.closenessNeeded(option.kind)!,
            closeness,
          ),
        final reason? => l10n.blockedReason(reason),
        null => cost,
      }),
      onTap: option.enabled ? onTap : null,
    );
  }

  static IconData _icon(InteractionKind kind) => switch (kind) {
    InteractionKind.bulus => Icons.local_cafe_outlined,
    InteractionKind.ara => Icons.call_outlined,
    InteractionKind.hediye => Icons.card_giftcard,
    InteractionKind.dertles => Icons.forum_outlined,
    InteractionKind.borcIste => Icons.request_quote_outlined,
    InteractionKind.borcOde => Icons.price_check,
    InteractionKind.lafSok => Icons.mood_bad_outlined,
    InteractionKind.uzaklas => Icons.do_not_disturb_on_outlined,
    InteractionKind.yemegiOv => Icons.restaurant,
    InteractionKind.macIzle => Icons.sports_soccer,
    InteractionKind.eliniOp => Icons.volunteer_activism_outlined,
    InteractionKind.kardesleOyna => Icons.toys_outlined,
    InteractionKind.cayaGit => Icons.emoji_food_beverage_outlined,
    InteractionKind.acil => Icons.favorite_border,
    InteractionKind.ciddi => Icons.favorite,
    InteractionKind.teklif => Icons.diamond_outlined,
    InteractionKind.ayril => Icons.heart_broken_outlined,
    InteractionKind.cocukIste => Icons.child_friendly_outlined,
  };
}

class _MemoryTile extends StatelessWidget {
  const _MemoryTile({required this.memory});

  final Memory memory;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final positive = memory.tone == MemoryTone.olumlu;
    final notes = [
      l10n.memoryAge(memory.age),
      if (memory.owner == MemoryOwner.oyuncu) l10n.memoryMine,
      if (memory.healed) l10n.memoryHealed,
    ];
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        positive ? Icons.favorite_border : Icons.heart_broken_outlined,
        color: positive ? Colors.green.shade600 : scheme.error,
      ),
      title: Text('“${memory.label}”'),
      subtitle: Text(notes.join(' · ')),
    );
  }
}

/// Ara sohbeti: önce ton, nostalji ve iğnelemede sonra anı.
class CallSheet extends ConsumerStatefulWidget {
  const CallSheet({super.key, required this.personId});

  final String personId;

  @override
  ConsumerState<CallSheet> createState() => _CallSheetState();
}

class _CallSheetState extends ConsumerState<CallSheet> {
  CallTone? _tone;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final state = ref.watch(lifeProvider);
    final p = state?.character.people[widget.personId];
    if (state == null || p == null) return const SizedBox.shrink();
    final now = state.character.age;
    final tone = _tone;

    final children = tone == null
        ? [
            Text(l10n.callTitle, style: theme.textTheme.titleLarge),
            for (final t in CallTone.values)
              _toneTile(l10n, t, Interactions.toneBlocked(p, t, now)),
          ]
        : [
            Text(l10n.callPickMemory, style: theme.textTheme.titleLarge),
            for (final m in Interactions.callMemories(
              p,
              now,
              tone: tone == CallTone.igne ? MemoryTone.olumsuz : null,
            ))
              ListTile(
                key: Key('call_memory_${m.kind}'),
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  m.tone == MemoryTone.olumlu
                      ? Icons.favorite_border
                      : Icons.heart_broken_outlined,
                ),
                title: Text('“${m.label}”'),
                subtitle: Text(l10n.memoryAge(m.age)),
                onTap: () => _call(tone, memoryKind: m.kind),
              ),
          ];

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: children,
        ),
      ),
    );
  }

  Widget _toneTile(AppLocalizations l10n, CallTone tone, Blocked? blocked) =>
      ListTile(
        key: Key('call_tone_${tone.name}'),
        contentPadding: EdgeInsets.zero,
        enabled: blocked == null,
        title: Text(l10n.toneName(tone)),
        subtitle: Text(
          blocked == null ? l10n.toneHint(tone) : l10n.blockedReason(blocked),
        ),
        onTap: blocked != null
            ? null
            : () {
                if (tone == CallTone.nostalji || tone == CallTone.igne) {
                  setState(() => _tone = tone);
                } else {
                  _call(tone);
                }
              },
      );

  void _call(CallTone tone, {String? memoryKind}) {
    ref
        .read(lifeProvider.notifier)
        .interact(
          InteractionRequest(
            InteractionKind.ara,
            widget.personId,
            tone: tone,
            memoryKind: memoryKind,
          ),
        );
    Navigator.of(context).pop();
  }
}
