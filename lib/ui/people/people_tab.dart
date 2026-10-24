import 'package:flutter/material.dart';

import '../../engine/engine.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../models/models.dart';
import '../portrait/portrait.dart';
import '../portrait/portrait_spec.dart';
import 'people_text.dart';
import 'people_view.dart';
import 'person_screen.dart';

/// İnsanlar sekmesi: aile, okul, arkadaşlar, mahalle, eski tanıdıklar ve
/// kaybedilenler. Birine dokununca kişi ekranı açılır.
class PeopleTab extends StatelessWidget {
  const PeopleTab({super.key, required this.character});

  final Character character;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final groups = PeopleView.grouped(character);
    if (groups.isEmpty) {
      return Center(child: Text(l10n.peopleEmpty));
    }
    return ListView(
      key: const Key('people_list'),
      padding: const EdgeInsets.only(bottom: 16),
      children: [
        for (final MapEntry(key: group, value: people) in groups.entries) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Text(
              l10n.groupName(group),
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
          ),
          for (final p in people) PersonTile(person: p, character: character),
        ],
      ],
    );
  }
}

/// Listede bir kişi: portre, ad, bağ ve iki küçük çubuk.
class PersonTile extends StatelessWidget {
  const PersonTile({super.key, required this.person, required this.character});

  final Person person;
  final Character character;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final p = person;
    final now = character.age;
    final alive = p.isAlive;
    final ageText = alive
        ? l10n.personAge(p.ageAt(now))
        : l10n.personDiedAt(p.ageAt(p.diedAt!));
    return ListTile(
      key: Key('person_${p.id}'),
      leading: Opacity(
        opacity: alive ? 1 : 0.5,
        child: Portrait(
          spec: PortraitDesigner.ofPerson(
            p,
            playerAge: alive ? now : p.diedAt!,
            family: character,
          ),
          size: 44,
        ),
      ),
      title: Text('${p.name} ${p.surname}'.trim()),
      subtitle: Text(
        '${l10n.relationOf(p)} · $ageText',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: alive
          ? SizedBox(
              width: 56,
              child: RelationBars(person: p, now: now, compact: true),
            )
          : null,
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => PersonScreen(personId: p.id)),
      ),
    );
  }
}

/// Yakınlık (yeşil) ve husumet (kırmızı) çubukları.
class RelationBars extends StatelessWidget {
  const RelationBars({
    super.key,
    required this.person,
    required this.now,
    this.compact = false,
  });

  final Person person;
  final int now;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final closeness = Relationships.closeness(person, now);
    final hostility = Relationships.hostility(person, now);
    Widget bar(String label, int value, Color color, Key key) {
      final indicator = ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: LinearProgressIndicator(
          key: key,
          value: value / 100,
          minHeight: compact ? 5 : 8,
          color: color,
          backgroundColor: scheme.surfaceContainerHighest,
          semanticsLabel: label,
          semanticsValue: '$value',
        ),
      );
      if (compact) return indicator;
      return Row(
        children: [
          SizedBox(width: 84, child: Text(label)),
          Expanded(child: indicator),
          SizedBox(width: 36, child: Text('$value', textAlign: TextAlign.end)),
        ],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        bar(
          l10n.closenessLabel,
          closeness,
          Colors.green.shade600,
          const Key('closeness_bar'),
        ),
        SizedBox(height: compact ? 4 : 8),
        bar(
          l10n.hostilityLabel,
          hostility,
          scheme.error,
          const Key('hostility_bar'),
        ),
      ],
    );
  }
}
