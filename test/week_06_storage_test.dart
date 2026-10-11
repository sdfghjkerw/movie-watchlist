import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:movie_watchlist/app/providers.dart';
import 'package:movie_watchlist/data/local/catalog_cache.dart';
import 'package:movie_watchlist/data/local/poster_cache.dart';
import 'package:movie_watchlist/data/local/settings_store.dart';
import 'package:movie_watchlist/data/repositories/diary_repositories.dart';
import 'package:movie_watchlist/data/repositories/hive_watchlist_repository.dart';
import 'package:movie_watchlist/data/repositories/offline_catalog_repository.dart';
import 'package:movie_watchlist/data/repositories/tmdb_catalog_repository.dart';
import 'package:movie_watchlist/domain/models/app_settings.dart';
import 'package:movie_watchlist/domain/models/diary_entry.dart';
import 'package:movie_watchlist/domain/models/movie.dart';
import 'package:movie_watchlist/domain/repositories/catalog_repository.dart';
import 'package:movie_watchlist/presentation/state/settings_controller.dart';
import 'package:movie_watchlist/sample_data/movies.dart';

class SwitchableCatalog implements CatalogRepository {
  bool offline = false;
  Completer<List<Movie>>? pending;
  List<Movie> movies = [sampleMovies.first];
  @override
  Future<List<Movie>> fetchMovies() async {
    if (offline) throw const SocketException('Offline');
    return pending == null ? movies : pending!.future;
  }

  @override
  Future<List<Movie>> searchMovies(String query) => fetchMovies();
  @override
  Future<Movie> fetchMovie(int id) async => (await fetchMovies()).first;
}

class TestPreferences extends Fake implements SharedPreferencesAsync {
  final values = <String, String>{};
  final _failure = [false];
  bool get fail => _failure[0];
  set fail(bool value) => _failure[0] = value;
  @override
  Future<String?> getString(String key) async => values[key];
  @override
  Future<void> setString(String key, String value) async {
    if (fail) throw StateError('Disk full');
    values[key] = value;
  }
}

void main() {
  late Directory directory;
  setUp(() async {
    directory = await Directory.systemTemp.createTemp(
      'movie-watchlist-week06-',
    );
    Hive.init(directory.path);
  });
  tearDown(() async {
    await Hive.close();
    // Only this test's newly created temporary directory is removed.
    await directory.delete(recursive: true);
  });

  test(
    'Watchlist survives close/reopen, deduplicates and persists deletion',
    () async {
      var box = await Hive.openBox<dynamic>('watchlist');
      var repository = HiveWatchlistRepository(box);
      await repository.add(sampleMovies.first);
      await repository.add(sampleMovies.first);
      await box.close();
      box = await Hive.openBox<dynamic>('watchlist');
      repository = HiveWatchlistRepository(box);
      expect(repository.movies.single.title, 'Interstellar');
      expect(() => repository.movies.clear(), throwsUnsupportedError);
      await repository.remove(sampleMovies.first.id);
      await box.close();
      expect(
        HiveWatchlistRepository(await Hive.openBox<dynamic>('watchlist'))
            .movies,
        isEmpty,
      );
    },
  );

  test(
    'Diary restores favorites, watched date, personal score and edited review',
    () async {
      var box = await Hive.openBox<dynamic>('diary');
      final date = DateTime(2026, 10, 11);
      await HiveDiaryRepository(box).save(
        DiaryEntry(
          movie: sampleMovies.first,
          favorite: true,
          watchedAt: date,
          score: 9,
          review: 'Personal review',
        ),
      );
      await box.close();
      box = await Hive.openBox<dynamic>('diary');
      var entry = HiveDiaryRepository(box).entries.single;
      expect(entry.favorite, isTrue);
      expect(entry.watchedAt, date);
      expect(entry.score, 9);
      expect(entry.review, 'Personal review');
      await HiveDiaryRepository(box).save(DiaryEntry(movie: entry.movie));
      await box.close();
      entry = HiveDiaryRepository(await Hive.openBox<dynamic>('diary'))
          .entries
          .single;
      expect(entry.favorite, isFalse);
      expect(entry.watchedAt, isNull);
      expect(entry.score, isNull);
      expect(entry.review, isEmpty);
    },
  );

  test(
    'Network catalog, details and searches survive restart and offline errors',
    () async {
      var box = await Hive.openBox<dynamic>('catalog');
      final remote = SwitchableCatalog();
      var repository = OfflineCatalogRepository(
        remote: remote,
        cache: CatalogCache(box),
        language: 'en',
      );
      await repository.fetchMovies();
      await repository.fetchMovie(1);
      await repository.searchMovies('Interstellar');
      await box.close();
      box = await Hive.openBox<dynamic>('catalog');
      remote.offline = true;
      repository = OfflineCatalogRepository(
        remote: remote,
        cache: CatalogCache(box),
        language: 'en',
      );
      expect((await repository.fetchMovies()).single.title, 'Interstellar');
      expect(repository.usedCache, isTrue);
      expect(repository.warning, isNotNull);
      expect((await repository.fetchMovie(1)).id, 1);
      expect(await repository.searchMovies(' INTERSTELLAR '), hasLength(1));
      await expectLater(
        repository.searchMovies('uncached'),
        throwsA(isA<SocketException>()),
      );
      final otherLanguage = OfflineCatalogRepository(
        remote: remote,
        cache: CatalogCache(box),
        language: 'ru',
      );
      await expectLater(
        otherLanguage.fetchMovies(),
        throwsA(isA<SocketException>()),
      );
    },
  );

  test('Empty successful response replaces stale cache; errors without cache stay errors', () async {
    final remote = SwitchableCatalog();
    final repository = OfflineCatalogRepository(
      remote: remote,
      cache: CatalogCache(await Hive.openBox<dynamic>('catalog')),
      language: 'ru',
    );
    remote.offline = true;
    await expectLater(
      repository.fetchMovies(),
      throwsA(isA<SocketException>()),
    );
    remote.offline = false;
    await repository.fetchMovies();
    remote.movies = [];
    expect(await repository.fetchMovies(), isEmpty);
    remote.offline = true;
    expect(await repository.fetchMovies(), isEmpty);
  });

  test('Offline-first provider exposes cache before network finishes, then updates', () async {
    final cache = CatalogCache(await Hive.openBox<dynamic>('catalog'));
    await cache.writeList('catalog:ru', [sampleMovies.first]);
    final remote = SwitchableCatalog()..pending = Completer<List<Movie>>();
    final repository = OfflineCatalogRepository(
      remote: remote,
      cache: cache,
      language: 'ru',
    );
    final container = ProviderContainer(
      overrides: [catalogRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
    expect(
      (await container.read(catalogProvider.future)).single.id,
      sampleMovies.first.id,
    );
    await Future<void>.delayed(Duration.zero);
    final updated = Completer<void>();
    final subscription = container.listen(catalogProvider, (_, value) {
      if (value.value?.firstOrNull?.id == sampleMovies[1].id &&
          !updated.isCompleted) {
        updated.complete();
      }
    });
    addTearDown(subscription.close);
    remote.pending!.complete([sampleMovies[1]]);
    await updated.future.timeout(const Duration(seconds: 3));
    expect(
      container.read(catalogProvider).value!.single.id,
      sampleMovies[1].id,
    );
  });

  test(
    'Poster bytes survive reopen and are served without an HTTP request',
    () async {
      const url = 'https://image.tmdb.org/t/p/w500/example.jpg';
      var box = await Hive.openBox<dynamic>('posters');
      final bytes = Uint8List.fromList([1, 2, 3]);
      var requests = 0;
      final online = MockClient((_) async {
        requests++;
        return http.Response.bytes(
          bytes,
          200,
          headers: {'content-type': 'image/jpeg'},
        );
      });
      expect(await PosterCache(box, online).load(url), bytes);
      await box.close();
      box = await Hive.openBox<dynamic>('posters');
      final offline = MockClient((_) async {
        requests++;
        throw http.ClientException('Offline');
      });
      expect(await PosterCache(box, offline).load(url), bytes);
      expect(requests, 1);
      expect(await PosterCache(box, offline).load('$url-missing'), isNull);
      online.close();
      offline.close();
    },
  );

  test('Settings restore validated values and failed save does not update UI state', () async {
    final preferences = TestPreferences();
    final store = SettingsStore(preferences);
    expect((await store.read()).theme, 'dark');
    await store.write(const AppSettings(theme: 'light', language: 'en'));
    final restored = await SettingsStore(preferences).read();
    expect(restored.theme, 'light');
    expect(restored.language, 'en');
    final container = ProviderContainer(
      overrides: [
        settingsStoreProvider.overrideWithValue(store),
        initialSettingsProvider.overrideWithValue(restored),
      ],
    );
    addTearDown(container.dispose);
    preferences.fail = true;
    await expectLater(
      container.read(settingsProvider.notifier).update(theme: 'dark'),
      throwsStateError,
    );
    expect(container.read(settingsProvider).theme, 'light');
    preferences.values['movie_watchlist.settings_v1'] =
        '{"theme":"invalid","language":"en"}';
    expect((await store.read()).theme, 'dark');
  });
  test(
    'Concurrent theme and language changes preserve both preferences',
    () async {
      final store = SettingsStore(TestPreferences());
      final container = ProviderContainer(
        overrides: [settingsStoreProvider.overrideWithValue(store)],
      );
      addTearDown(container.dispose);
      final settings = container.read(settingsProvider.notifier);
      await Future.wait([
        settings.update(theme: 'light'),
        settings.update(language: 'en'),
      ]);
      final restored = await store.read();
      expect(restored.theme, 'light');
      expect(restored.language, 'en');
    },
  );

  test('Refreshing a catalog preserves richer cached movie details', () async {
    final cache = CatalogCache(await Hive.openBox<dynamic>('catalog'));
    final remote = SwitchableCatalog();
    final repository = OfflineCatalogRepository(
      remote: remote,
      cache: cache,
      language: 'ru',
    );
    const detailed = Movie(
      id: 1,
      title: 'Interstellar',
      year: 2014,
      genre: 'Drama',
      rating: 8.6,
      description: 'Full description',
      emoji: '',
      runtimeMinutes: 169,
    );
    remote.movies = [detailed];
    await repository.fetchMovie(1);
    remote.movies = [sampleMovies.first];
    await repository.fetchMovies();
    remote.offline = true;
    expect((await repository.fetchMovie(1)).runtimeMinutes, 169);
    expect(repository.cachedDetails, contains(1));
  });

  test('TMDB sends the selected language to the API', () async {
    final client = MockClient((request) async {
      expect(request.url.queryParameters['language'], 'en-US');
      return http.Response('{"results":[]}', 200);
    });
    addTearDown(client.close);
    await TmdbCatalogRepository(
      client: client,
      apiKey: 'test-only',
      language: 'en-US',
    ).fetchMovies();
  });
}
