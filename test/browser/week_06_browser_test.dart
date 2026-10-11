@TestOn('browser')
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_web/shared_preferences_web.dart';
import 'package:movie_watchlist/data/local/settings_store.dart';
import 'package:movie_watchlist/data/repositories/hive_watchlist_repository.dart';
import 'package:movie_watchlist/data/repositories/diary_repositories.dart';
import 'package:movie_watchlist/domain/models/app_settings.dart';
import 'package:movie_watchlist/domain/models/diary_entry.dart';
import 'package:movie_watchlist/sample_data/movies.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'Real IndexedDB restores personal data after closing and reopening Hive',
    () async {
      await Hive.initFlutter();
      final name = 'week06_browser_${DateTime.now().microsecondsSinceEpoch}';
      var box = await Hive.openBox<dynamic>(name);
      await HiveWatchlistRepository(box).add(sampleMovies.first);
      await box.close();
      box = await Hive.openBox<dynamic>(name);
      expect(HiveWatchlistRepository(box).movies.single.title, 'Interstellar');
      await HiveWatchlistRepository(box).remove(sampleMovies.first.id);
      await box.close();
      box = await Hive.openBox<dynamic>(name);
      expect(HiveWatchlistRepository(box).movies, isEmpty);
      await HiveDiaryRepository(box).save(
        DiaryEntry(
          movie: sampleMovies.first,
          favorite: true,
          watchedAt: DateTime(2026, 10, 11),
          score: 8,
          review: 'Browser test',
        ),
      );
      await box.close();
      box = await Hive.openBox<dynamic>(name);
      final restored = HiveDiaryRepository(box).entries.single;
      expect(restored.favorite, isTrue);
      expect(restored.score, 8);
      expect(restored.review, 'Browser test');
      expect(restored.watchedAt, DateTime(2026, 10, 11));
      // This is an isolated test database created above, never the application's boxes.
      await box.deleteFromDisk();
    },
  );
  test('Real browser SharedPreferences restores theme and language', () async {
    SharedPreferencesPlugin.registerWith(null);
    final preferences = SharedPreferencesAsync();
    final store = SettingsStore(preferences);
    final previous = await store.read();
    try {
      await store.write(const AppSettings(theme: 'light', language: 'en'));
      final restored = await SettingsStore(SharedPreferencesAsync()).read();
      expect(restored.theme, 'light');
      expect(restored.language, 'en');
    } finally {
      await store.write(previous);
    }
  });
}
