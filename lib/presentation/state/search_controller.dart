import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../domain/models/movie.dart';
import '../../domain/repositories/catalog_repository.dart';
import 'settings_controller.dart';

final searchProvider =
    NotifierProvider<MovieSearchController, AsyncValue<List<Movie>>>(
      MovieSearchController.new,
    );

class MovieSearchController extends Notifier<AsyncValue<List<Movie>>> {
  Timer? _timer;
  int _generation = 0;
  int _page = 0;
  String _query = '';
  bool _hasMore = false;
  bool _isLoadingMore = false;
  Object? _loadMoreError;

  bool get hasMore => _hasMore;
  bool get isLoadingMore => _isLoadingMore;
  Object? get loadMoreError => _loadMoreError;

  @override
  AsyncValue<List<Movie>> build() {
    ref.listen(settingsProvider, (previous, next) {
      if (previous?.language != next.language) setQuery(_query);
    });
    ref.onDispose(() {
      _timer?.cancel();
      _generation++;
    });
    return const AsyncData([]);
  }

  void setQuery(String value) {
    _query = value.trim();
    final generation = ++_generation;
    _timer?.cancel();
    _page = 0;
    _hasMore = false;
    _isLoadingMore = false;
    _loadMoreError = null;
    if (_query.isEmpty) {
      state = const AsyncData([]);
      return;
    }
    state = const AsyncLoading();
    _timer = Timer(
      const Duration(milliseconds: 400),
      () => _load(_query, generation),
    );
  }

  Future<void> refresh() async {
    _timer?.cancel();
    final generation = ++_generation;
    _page = 0;
    _hasMore = false;
    _isLoadingMore = false;
    _loadMoreError = null;
    if (_query.isEmpty) {
      state = const AsyncData([]);
      return;
    }
    state = const AsyncLoading();
    await _load(_query, generation);
  }

  Future<void> loadMore() async {
    final current = state.asData?.value;
    if (current == null || _query.isEmpty || !_hasMore || _isLoadingMore) {
      return;
    }
    final repository = ref.read(catalogRepositoryProvider);
    if (repository is! PaginatedCatalogRepository) return;
    final generation = _generation;
    final query = _query;
    final nextPage = _page + 1;
    _isLoadingMore = true;
    _loadMoreError = null;
    state = AsyncData(List<Movie>.of(current));
    try {
      final page = await (repository as PaginatedCatalogRepository)
          .searchMoviesPage(query, nextPage);
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

  Future<void> _load(String query, int generation) async {
    final repository = ref.read(catalogRepositoryProvider);
    try {
      final page = repository is PaginatedCatalogRepository
          ? await (repository as PaginatedCatalogRepository).searchMoviesPage(
              query,
              1,
            )
          : MoviePage(
              page: 1,
              totalPages: 1,
              results: await repository.searchMovies(query),
            );
      if (ref.mounted && generation == _generation) {
        _page = page.page;
        _hasMore = page.hasMore;
        state = AsyncData(page.results);
      }
    } catch (error, stack) {
      if (ref.mounted && generation == _generation) {
        state = AsyncError(error, stack);
      }
    }
  }
}
