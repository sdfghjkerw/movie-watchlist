import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../domain/models/movie.dart';
import '../../domain/repositories/catalog_repository.dart';

class CatalogController extends AsyncNotifier<List<Movie>> {
  int _generation = 0;
  int _page = 0;
  bool _hasMore = false;
  bool _isLoadingMore = false;
  Object? _loadMoreError;

  bool get hasMore => _hasMore;
  bool get isLoadingMore => _isLoadingMore;
  Object? get loadMoreError => _loadMoreError;

  @override
  Future<List<Movie>> build() async {
    _page = 0;
    _hasMore = false;
    _isLoadingMore = false;
    _loadMoreError = null;
    final generation = ++_generation;
    ref.onDispose(() => _generation++);
    final repository = ref.watch(catalogRepositoryProvider);
    if (repository is CachedCatalogRepository) {
      final cached = repository.cachedMovies;
      if (cached != null) {
        repository.beginRefresh();
        final timer = Timer(Duration.zero, () => refresh());
        ref.onDispose(timer.cancel);
        return cached;
      }
    }
    final page = await _fetchPage(repository, 1);
    if (generation == _generation) {
      _page = page.page;
      _hasMore = page.hasMore;
    }
    return page.results;
  }

  Future<void> refresh() async {
    final generation = ++_generation;
    _page = 0;
    _hasMore = false;
    _isLoadingMore = false;
    _loadMoreError = null;
    final repository = ref.read(catalogRepositoryProvider);
    try {
      final page = await _fetchPage(repository, 1);
      if (!ref.mounted || generation != _generation) return;
      _page = page.page;
      _hasMore = page.hasMore;
      state = AsyncData(page.results);
    } catch (error, stack) {
      if (ref.mounted && generation == _generation) {
        state = AsyncError(error, stack);
      }
    }
  }

  Future<void> loadMore() async {
    final current = state.asData?.value;
    if (current == null || !_hasMore || _isLoadingMore) return;
    final repository = ref.read(catalogRepositoryProvider);
    if (repository is! PaginatedCatalogRepository) return;
    final generation = _generation;
    final nextPage = _page + 1;
    _isLoadingMore = true;
    _loadMoreError = null;
    state = AsyncData(List<Movie>.of(current));
    try {
      final page = await (repository as PaginatedCatalogRepository)
          .fetchMoviesPage(nextPage);
      if (!ref.mounted || generation != _generation) return;
      final ids = current.map((movie) => movie.id).toSet();
      final added = page.results.where((movie) => ids.add(movie.id));
      _page = page.page;
      _hasMore = page.hasMore;
      _isLoadingMore = false;
      state = AsyncData([...current, ...added]);
    } catch (error) {
      if (!ref.mounted || generation != _generation) return;
      _loadMoreError = error;
      _isLoadingMore = false;
      state = AsyncData(List<Movie>.of(current));
    } finally {
      if (ref.mounted && generation == _generation) _isLoadingMore = false;
    }
  }

  Future<MoviePage> _fetchPage(CatalogRepository repository, int page) async {
    if (repository is PaginatedCatalogRepository) {
      return (repository as PaginatedCatalogRepository).fetchMoviesPage(page);
    }
    return MoviePage(
      page: 1,
      totalPages: 1,
      results: await repository.fetchMovies(),
    );
  }
}
