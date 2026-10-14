import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/generated/app_localizations.dart';
import '../providers.dart';

/// Ses ve titreşim tercihleri, lisanslar.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  /// Üst çubuklarda kullanılan düğme.
  static Widget button(BuildContext context) => IconButton(
    key: const Key('settings_button'),
    tooltip: AppLocalizations.of(context).settingsTitle,
    icon: const Icon(Icons.settings_outlined),
    onPressed: () => Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => const SettingsScreen())),
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final settings = ref.watch(settingsProvider);
    final controller = ref.read(settingsProvider.notifier);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: ListView(
        children: [
          SwitchListTile(
            key: const Key('setting_sound'),
            title: Text(l10n.settingsSound),
            subtitle: Text(l10n.settingsSoundHint),
            value: settings.sound,
            onChanged: controller.setSound,
          ),
          SwitchListTile(
            key: const Key('setting_haptics'),
            title: Text(l10n.settingsHaptics),
            subtitle: Text(l10n.settingsHapticsHint),
            value: settings.haptics,
            onChanged: controller.setHaptics,
          ),
          SwitchListTile(
            key: const Key('setting_analytics'),
            title: Text(l10n.settingsAnalytics),
            subtitle: Text(l10n.settingsAnalyticsHint),
            value: settings.analyticsEnabled,
            onChanged: controller.setAnalyticsConsent,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Text(
              l10n.settingsCrashNote,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: Text(l10n.settingsLicenses),
            onTap: () => showLicensePage(
              context: context,
              applicationName: l10n.appTitle,
            ),
          ),
        ],
      ),
    );
  }
}
