import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../data/local/catalog_cache.dart';
import '../data/local/poster_cache.dart';
import '../data/local/settings_store.dart';
import '../data/repositories/hive_watchlist_repository.dart';
import '../data/repositories/diary_repositories.dart';
import '../data/repositories/profile_repositories.dart';
import 'providers.dart';

Future<List<Override>> openLocalStorage() async {
  await Hive.initFlutter();
  final watchlist = await Hive.openBox<dynamic>('watchlist_v1');
  final diary = await Hive.openBox<dynamic>('diary_v1');
  final profile = await Hive.openBox<dynamic>('profile_v1');
  final catalog = await Hive.openBox<dynamic>('catalog_v1');
  final posters = await Hive.openBox<dynamic>('posters_v1');
  final settings = SettingsStore(SharedPreferencesAsync());
  final initial = await settings.read();
  return [
    watchlistRepositoryProvider.overrideWithValue(
      HiveWatchlistRepository(watchlist),
    ),
    diaryRepositoryProvider.overrideWithValue(HiveDiaryRepository(diary)),
    profileRepositoryProvider.overrideWithValue(HiveProfileRepository(profile)),
    catalogCacheProvider.overrideWithValue(CatalogCache(catalog)),
    posterCacheProvider.overrideWithValue(PosterCache(posters, http.Client())),
    settingsStoreProvider.overrideWithValue(settings),
    initialSettingsProvider.overrideWithValue(initial),
  ];
}
