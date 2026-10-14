import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../engine/engine.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../models/models.dart';
import '../providers.dart';

/// Doğum ekranı: isim ve cinsiyet; boş bırakılanlar rastgele seçilir.
class BirthScreen extends ConsumerStatefulWidget {
  const BirthScreen({super.key, required this.deck});

  final EventDeck deck;

  @override
  ConsumerState<BirthScreen> createState() => _BirthScreenState();
}

class _BirthScreenState extends ConsumerState<BirthScreen> {
  final _name = TextEditingController();
  Gender? _gender;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _born() {
    ref
        .read(lifeProvider.notifier)
        .startLife(widget.deck, name: _name.text, gender: _gender);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.appTitle,
                    style: theme.textTheme.displaySmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.birthTitle,
                    style: theme.textTheme.titleLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(l10n.birthSubtitle, textAlign: TextAlign.center),
                  const SizedBox(height: 32),
                  TextField(
                    key: const Key('birth_name'),
                    controller: _name,
                    textCapitalization: TextCapitalization.words,
                    maxLength: 20,
                    decoration: InputDecoration(
                      labelText: l10n.birthNameLabel,
                      hintText: l10n.birthNameHint,
                      border: const OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _born(),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.birthGenderLabel,
                    style: theme.textTheme.labelLarge,
                  ),
                  const SizedBox(height: 8),
                  SegmentedButton<Gender?>(
                    // Seçili segment renginden belli olur; tik işareti dar
                    // ekranda "Rastgele" etiketini iki satıra bölüyordu.
                    showSelectedIcon: false,
                    segments: [
                      for (final (value, label) in [
                        (Gender.kadin, l10n.genderFemale),
                        (Gender.erkek, l10n.genderMale),
                        (null, l10n.genderRandom),
                      ])
                        ButtonSegment(
                          value: value,
                          label: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(label, maxLines: 1),
                          ),
                        ),
                    ],
                    selected: {_gender},
                    onSelectionChanged: (s) =>
                        setState(() => _gender = s.single),
                  ),
                  const SizedBox(height: 32),
                  FilledButton.icon(
                    key: const Key('birth_button'),
                    onPressed: _born,
                    icon: const Icon(Icons.child_care),
                    label: Text(l10n.birthButton),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
