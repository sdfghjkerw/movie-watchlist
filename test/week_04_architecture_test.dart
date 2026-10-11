import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movie_watchlist/app/providers.dart';
import 'package:movie_watchlist/data/repositories/in_memory_watchlist_repository.dart';
import 'package:movie_watchlist/domain/models/movie.dart';
import 'package:movie_watchlist/domain/repositories/catalog_repository.dart';
import 'package:movie_watchlist/domain/repositories/watchlist_repository.dart';
import 'package:movie_watchlist/presentation/state/watchlist_controller.dart';
import 'package:movie_watchlist/sample_data/movies.dart';
import 'package:movie_watchlist/presentation/screens/main_screen.dart';

class RecordingRepository implements WatchlistRepository {
  RecordingRepository(this.movie);
  final Movie movie;
  bool saved = true;
  int adds = 0;
  int removes = 0;
  @override
  List<Movie> get movies => saved ? List.unmodifiable([movie]) : const [];
  @override
  void add(Movie movie) {
    adds++;
    saved = true;
  }

  @override
  void remove(int id) {
    removes++;
    saved = false;
  }
}

class EmptyCatalog implements CatalogRepository {
  @override
  List<Movie> get movies => const [];
}

void main() {
  test('Repository uses unique IDs and exposes immutable snapshots', () {
    final repository = InMemoryWatchlistRepository();
    repository.add(sampleMovies.first);
    final snapshot = repository.movies;
    repository.add(sampleMovies.first);
    expect(repository.movies, hasLength(1));
    expect(() => snapshot.clear(), throwsUnsupportedError);
    repository.remove(sampleMovies.first.id);
    expect(repository.movies, isEmpty);
    expect(snapshot, hasLength(1));
  });

  test('DI supplies a different repository; controller delegates changes', () {
    final repository = RecordingRepository(sampleMovies.first);
    final container = ProviderContainer(
      overrides: [watchlistRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
    expect(container.read(watchlistProvider), hasLength(1));
    final controller = container.read(watchlistProvider.notifier);
    controller.toggle(sampleMovies.first);
    expect(repository.removes, 1);
    expect(container.read(watchlistProvider), isEmpty);
    controller.toggle(sampleMovies.first);
    expect(repository.adds, 1);
    expect(container.read(watchlistProvider), hasLength(1));
    controller.remove(sampleMovies.first.id);
    expect(container.read(watchlistProvider), isEmpty);
  });

  test('Independent scopes do not share mutable repositories', () {
    final first = ProviderContainer();
    final second = ProviderContainer();
    addTearDown(first.dispose);
    addTearDown(second.dispose);
    first.read(watchlistProvider.notifier).toggle(sampleMovies.first);
    expect(first.read(watchlistProvider), hasLength(1));
    expect(second.read(watchlistProvider), isEmpty);
    first.invalidate(watchlistProvider);
    expect(first.read(watchlistProvider), hasLength(1));
  });

  test('Catalog is injected independently of sample data', () {
    final container = ProviderContainer(
      overrides: [catalogRepositoryProvider.overrideWithValue(EmptyCatalog())],
    );
    addTearDown(container.dispose);
    expect(container.read(catalogProvider), isEmpty);
  });

  testWidgets('Screens accept an empty injected catalog without index errors', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          catalogRepositoryProvider.overrideWithValue(EmptyCatalog()),
        ],
        child: const MaterialApp(home: MainScreen()),
      ),
    );
    await tester.tap(find.text('Коллекция'));
    await tester.pumpAndSettle();
    expect(
      find.text('Пока нет фильмов. Добавь фильм на его странице.'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
