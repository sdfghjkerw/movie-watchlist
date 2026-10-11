import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../domain/repositories/catalog_repository.dart';
import '../../domain/models/movie.dart';

class CatalogController extends AsyncNotifier<List<Movie>> {
  int _generation = 0;
  @override
  FutureOr<List<Movie>> build() {
    _generation++;
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
    return repository.fetchMovies();
  }

  Future<void> refresh() async {
    final generation = _generation;
    final repository = ref.read(catalogRepositoryProvider);
    try {
      final movies = await repository.fetchMovies();
      if (ref.mounted && generation == _generation) {
        state = AsyncData(movies);
      }
    } catch (error, stack) {
      if (ref.mounted && generation == _generation) {
        state = AsyncError(error, stack);
      }
    }
  }
}
