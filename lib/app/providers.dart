import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repositories/in_memory_watchlist_repository.dart';
import '../data/repositories/static_catalog_repository.dart';
import '../domain/models/movie.dart';
import '../domain/repositories/catalog_repository.dart';
import '../domain/repositories/watchlist_repository.dart';

// Composition root: только здесь выбираются конкретные источники данных.
final watchlistRepositoryProvider = Provider<WatchlistRepository>(
  (ref) => InMemoryWatchlistRepository(),
);
final catalogRepositoryProvider = Provider<CatalogRepository>(
  (ref) => StaticCatalogRepository(),
);
final catalogProvider = Provider<List<Movie>>(
  (ref) => ref.watch(catalogRepositoryProvider).movies,
);
