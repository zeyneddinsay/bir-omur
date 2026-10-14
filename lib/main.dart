import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';

import 'l10n/generated/app_localizations.dart';
import 'services/hive_save_store.dart';
import 'services/save_store.dart';
import 'ui/feedback_listener.dart';
import 'ui/providers.dart';
import 'ui/screens/game_screen.dart';
import 'ui/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  _registerFontLicense();
  runApp(
    ProviderScope(
      overrides: [saveStoreProvider.overrideWithValue(await _openSaveStore())],
      child: const BirOmurApp(),
    ),
  );
}

/// Kayıt açılamazsa oyun yine açılır; hayat yalnızca bellekte tutulur.
Future<SaveStore> _openSaveStore() async {
  try {
    await Hive.initFlutter();
    return await HiveSaveStore.open();
  } on Object catch (error, stack) {
    FlutterError.reportError(
      FlutterErrorDetails(exception: error, stack: stack, library: 'kayıt'),
    );
    return MemorySaveStore();
  }
}

class BirOmurApp extends StatelessWidget {
  const BirOmurApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      debugShowCheckedModeBanner: false,
      locale: const Locale('tr'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: buildAppTheme(Brightness.light),
      darkTheme: buildAppTheme(Brightness.dark),
      home: const FeedbackListener(child: GameScreen()),
    );
  }
}

/// Nunito (OFL) lisansı, yazı tipiyle birlikte dağıtılmalı; Ayarlar →
/// Lisanslar sayfasında görünür.
void _registerFontLicense() {
  LicenseRegistry.addLicense(() async* {
    final text = await rootBundle.loadString('assets/fonts/OFL.txt');
    yield LicenseEntryWithLineBreaks(['Nunito'], text);
  });
}
