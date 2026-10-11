import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/models/app_settings.dart';

class SettingsStore {
  SettingsStore(this.preferences);
  final SharedPreferencesAsync preferences;
  Future<AppSettings> read() async {
    final saved = await preferences.getString('movie_watchlist.settings_v1');
    Map<String, dynamic>? decoded;
    if (saved != null) {
      try {
        final value = jsonDecode(saved);
        if (value is Map<String, dynamic>) decoded = value;
      } on FormatException {
        /* Invalid settings fall back to defaults. */
      }
    }
    final theme =
        decoded?['theme'] ??
        await preferences.getString('movie_watchlist.theme');
    final language =
        decoded?['language'] ??
        await preferences.getString('movie_watchlist.language');
    return AppSettings(
      theme: ['dark', 'light', 'system'].contains(theme)
          ? theme as String
          : 'dark',
      language: language == 'en' ? 'en' : 'ru',
    );
  }

  Future<void> write(AppSettings value) async {
    await preferences.setString(
      'movie_watchlist.settings_v1',
      jsonEncode({'theme': value.theme, 'language': value.language}),
    );
  }
}
