import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'dart:typed_data';

import '../data/local/avatar_picker.dart';

import '../data/repositories/in_memory_watchlist_repository.dart';
import '../data/repositories/tmdb_catalog_repository.dart';
import '../data/repositories/diary_repositories.dart';
import '../data/repositories/profile_repositories.dart';
import '../domain/repositories/profile_repository.dart';
import '../data/repositories/offline_catalog_repository.dart';
import '../data/local/catalog_cache.dart';
import '../data/local/poster_cache.dart';
import '../data/local/settings_store.dart';
import '../domain/models/app_settings.dart';
import '../domain/repositories/diary_repository.dart';
import '../presentation/state/settings_controller.dart';
import '../presentation/state/catalog_controller.dart';

import 'package:http/http.dart' as http;

import '../domain/models/movie.dart';
import '../domain/repositories/catalog_repository.dart';
import '../domain/repositories/watchlist_repository.dart';

// Composition root: только здесь выбираются конкретные источники данных.
final tmdbApiKeyProvider = Provider<String>((ref) => '');
final initialSettingsProvider = Provider<AppSettings>(
  (ref) => const AppSettings(),
);
final settingsStoreProvider = Provider<SettingsStore?>((ref) => null);
final catalogCacheProvider = Provider<CatalogCache?>((ref) => null);
final posterCacheProvider = Provider<PosterCache?>((ref) => null);
final diaryRepositoryProvider = Provider<DiaryRepository>(
  (ref) => InMemoryDiaryRepository(),
);
final profileRepositoryProvider = Provider<ProfileRepository>(
  (ref) => InMemoryProfileRepository(),
);
final avatarPickerProvider = Provider<Future<Uint8List?> Function()>(
  (ref) => pickAvatar,
);
final watchlistRepositoryProvider = Provider<WatchlistRepository>(
  (ref) => InMemoryWatchlistRepository(),
);
final catalogRepositoryProvider = Provider<CatalogRepository>((ref) {
  final client = http.Client();
  ref.onDispose(client.close);
  final language = ref.watch(settingsProvider).language;
  final remote = TmdbCatalogRepository(
    client: client,
    apiKey: ref.watch(tmdbApiKeyProvider),
    language: language == 'en' ? 'en-US' : 'ru-RU',
  );
  final cache = ref.watch(catalogCacheProvider);
  return cache == null
      ? remote
      : OfflineCatalogRepository(
          remote: remote,
          cache: cache,
          language: language,
        );
});
final catalogProvider = AsyncNotifierProvider<CatalogController, List<Movie>>(
  CatalogController.new,
  retry: (_, _) => null,
);
final movieDetailsProvider = FutureProvider.autoDispose.family<Movie, int>(
  (ref, id) => ref.watch(catalogRepositoryProvider).fetchMovie(id),
  retry: (_, _) => null,
);
