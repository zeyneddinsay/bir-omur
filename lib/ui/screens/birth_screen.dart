import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../content/content_loader.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../models/models.dart';
import '../providers.dart';
import 'album_screen.dart';
import 'settings_screen.dart';

/// Doğum ekranı: isim ve cinsiyet; boş bırakılanlar rastgele seçilir.
class BirthScreen extends ConsumerStatefulWidget {
  const BirthScreen({super.key, required this.content});

  final GameContent content;

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
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        actions: [SettingsScreen.button(context)],
      ),
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
                  if (ref.watch(savedLifeProvider).value case final saved?)
                    _ResumeCard(
                      snapshot: saved,
                      onResume: () => _resume(saved),
                    ),
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
                  const SizedBox(height: 12),
                  TextButton.icon(
                    key: const Key('album_button'),
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => AlbumScreen(content: widget.content),
                      ),
                    ),
                    icon: const Icon(Icons.photo_album_outlined),
                    label: Text(l10n.albumButton),
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

/// Yarım kalan hayatı gösterir; isim ve yaş kaydın içinden okunur.
class _ResumeCard extends StatelessWidget {
  const _ResumeCard({required this.snapshot, required this.onResume});

  final Map<String, dynamic> snapshot;
  final VoidCallback onResume;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final character = snapshot['character'];
    final name = character is Map ? character['name'] : null;
    final age = character is Map ? character['age'] : null;
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Card(
        color: theme.colorScheme.primaryContainer,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l10n.resumeTitle, style: theme.textTheme.titleMedium),
              if (name is String && age is int)
                Text(l10n.resumeLine(name, age)),
              const SizedBox(height: 12),
              FilledButton.icon(
                key: const Key('resume_button'),
                onPressed: onResume,
                icon: const Icon(Icons.play_arrow),
                label: Text(l10n.resumeButton),
              ),
              const SizedBox(height: 8),
              Text(l10n.resumeOrNew, style: theme.textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}
