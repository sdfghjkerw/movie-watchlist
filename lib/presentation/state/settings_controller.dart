import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../domain/models/app_settings.dart';

final settingsProvider = NotifierProvider<SettingsController, AppSettings>(
  SettingsController.new,
);

class SettingsController extends Notifier<AppSettings> {
  Future<void> _pending = Future.value();
  @override
  AppSettings build() => ref.watch(initialSettingsProvider);
  Future<void> update({String? theme, String? language}) {
    final result = _pending.then((_) async {
      final next = AppSettings(
        theme: theme ?? state.theme,
        language: language ?? state.language,
      );
      await ref.read(settingsStoreProvider)?.write(next);
      if (ref.mounted) state = next;
    });
    _pending = result.catchError((Object _) {});
    return result;
  }
}
