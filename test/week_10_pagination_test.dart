import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:movie_watchlist/app/providers.dart';
import 'package:movie_watchlist/data/repositories/tmdb_catalog_repository.dart';
import 'package:movie_watchlist/domain/models/movie.dart';
import 'package:movie_watchlist/domain/repositories/catalog_repository.dart';
import 'package:movie_watchlist/presentation/state/search_controller.dart';

const _first = Movie(
  id: 1,
  title: 'First',
  year: 2020,
  genre: 'Drama',
  rating: 8,
  description: '',
  emoji: '',
);

const _second = Movie(
  id: 2,
  title: 'Second',
  year: 2021,
  genre: 'Drama',
  rating: 7,
  description: '',
  emoji: '',
);

class _PagedCatalog implements CatalogRepository, PaginatedCatalogRepository {
  final requestedPopularPages = <int>[];
  final requestedSearchPages = <int>[];
  bool failSecondPage = false;

  @override
  Future<List<Movie>> fetchMovies() async => [_first];

  @override
  Future<MoviePage> fetchMoviesPage(int page) async {
    requestedPopularPages.add(page);
    if (page == 2 && failSecondPage) throw StateError('offline');
    return MoviePage(
      page: page,
      totalPages: 2,
      results: page == 1 ? [_first] : [_first, _second],
    );
  }

  @override
  Future<List<Movie>> searchMovies(String query) async => [_first];

  @override
  Future<MoviePage> searchMoviesPage(String query, int page) async {
    requestedSearchPages.add(page);
    return MoviePage(
      page: page,
      totalPages: 2,
      results: page == 1 ? [_first] : [_second],
    );
  }

  @override
  Future<Movie> fetchMovie(int id) async => _first;
}

void main() {
  test('TMDB requests the selected page and reports available pages', () async {
    final requests = <Uri>[];
    final client = MockClient((request) async {
      requests.add(request.url);
      return http.Response(
        jsonEncode({
          'page': 2,
          'total_pages': 4,
          'results': [
            {'id': 2, 'title': 'Second'},
          ],
        }),
        200,
      );
    });
    addTearDown(client.close);

    final result = await TmdbCatalogRepository(
      client: client,
      apiKey: 'test-only',
    ).fetchMoviesPage(2);

    expect(requests.single.queryParameters['page'], '2');
    expect(result.page, 2);
    expect(result.totalPages, 4);
    expect(result.hasMore, isTrue);
    expect(result.results.single.id, 2);
  });

  test(
    'Catalog loads more lazily, deduplicates pages and can retry an error',
    () async {
      final repository = _PagedCatalog()..failSecondPage = true;
      final container = ProviderContainer(
        overrides: [catalogRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);
      final subscription = container.listen(catalogProvider, (_, _) {});
      addTearDown(subscription.close);

      await container.read(catalogProvider.future);
      final controller = container.read(catalogProvider.notifier);
      await controller.loadMore();
      expect(container.read(catalogProvider).asData!.value, [_first]);
      expect(controller.loadMoreError, isNotNull);

      repository.failSecondPage = false;
      await controller.loadMore();
      expect(container.read(catalogProvider).asData!.value, [_first, _second]);
      expect(controller.hasMore, isFalse);
      expect(repository.requestedPopularPages, [1, 2, 2]);
    },
  );

  test('Search debounces page one and appends the next page', () async {
    final repository = _PagedCatalog();
    final container = ProviderContainer(
      overrides: [catalogRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
    final search = container.read(searchProvider.notifier);

    search.setQuery('film');
    await Future<void>.delayed(const Duration(milliseconds: 450));
    expect(container.read(searchProvider).asData!.value, [_first]);
    await search.loadMore();

    expect(container.read(searchProvider).asData!.value, [_first, _second]);
    expect(repository.requestedSearchPages, [1, 2]);
  });
}
