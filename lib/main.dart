import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';

import 'app/providers.dart';
import 'app/router.dart';
import 'app/tmdb_configuration.dart';
import 'app/local_storage.dart';
import 'app/firebase_configuration.dart';
import 'app/firebase_providers.dart';
import 'presentation/state/settings_controller.dart';
import 'presentation/state/cloud_sync_controller.dart';
import 'presentation/localization/app_strings.dart';

import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final apiKey = await loadTmdbApiKey();
  final firebaseConfiguration = await loadFirebaseConfiguration();
  var firebaseEnabled = false;
  String? firebaseSetupMessage;
  if (firebaseConfiguration?.isCurrentPlatformConfigured == true) {
    try {
      await Firebase.initializeApp(
        options: firebaseConfiguration!.currentPlatformOptions,
      );
      firebaseEnabled = true;
    } catch (error) {
      firebaseSetupMessage =
          'Firebase не запустился: $error. Локальный режим приложения доступен.';
    }
  } else {
    firebaseSetupMessage =
        'Заполни Firebase-конфигурацию для ${firebaseConfiguration?.platformName ?? 'этой платформы'} в .vscode/firebase.local.json.';
  }
  try {
    final overrides = await openLocalStorage();
    runApp(
      MovieWatchlistApp(
        apiKey: apiKey,
        storageOverrides: overrides,
        firebaseConfiguration: firebaseConfiguration,
        firebaseEnabled: firebaseEnabled,
        firebaseSetupMessage: firebaseSetupMessage,
      ),
    );
  } catch (_) {
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Не удалось открыть локальное хранилище. Данные не удалены.',
                ),
                FilledButton(onPressed: main, child: const Text('Повторить')),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class MovieWatchlistApp extends StatelessWidget {
  const MovieWatchlistApp({
    super.key,
    this.apiKey = '',
    this.storageOverrides = const [],
    this.firebaseConfiguration,
    this.firebaseEnabled = false,
    this.firebaseSetupMessage,
  });
  final String apiKey;
  final List<Override> storageOverrides;
  final FirebaseLocalConfiguration? firebaseConfiguration;
  final bool firebaseEnabled;
  final String? firebaseSetupMessage;

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      overrides: [
        tmdbApiKeyProvider.overrideWithValue(apiKey),
        firebaseEnabledProvider.overrideWithValue(firebaseEnabled),
        firebaseLocalConfigurationProvider.overrideWithValue(
          firebaseConfiguration,
        ),
        firebaseSetupMessageProvider.overrideWithValue(firebaseSetupMessage),
        ...storageOverrides,
      ],
      child: Consumer(
        builder: (context, ref, _) {
          final settings = ref.watch(settingsProvider);
          if (ref.watch(firebaseEnabledProvider)) {
            ref.watch(cloudSyncProvider);
            ref.watch(cloudSyncAuthBootstrapProvider);
          }
          final router = ref.watch(appRouterProvider);
          return AppLanguage(
            language: settings.language,
            child: MaterialApp.router(
              title: 'Movie Watchlist',
              debugShowCheckedModeBanner: false,
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              themeMode: switch (settings.theme) {
                'light' => ThemeMode.light,
                'system' => ThemeMode.system,
                _ => ThemeMode.dark,
              },
              locale: Locale(settings.language),
              supportedLocales: const [Locale('ru'), Locale('en')],
              localizationsDelegates: GlobalMaterialLocalizations.delegates,
              routerConfig: router,
            ),
          );
        },
      ),
    );
  }
}
