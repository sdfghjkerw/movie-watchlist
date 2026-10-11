import '../models/movie.dart';

abstract interface class CatalogRepository {
  Future<List<Movie>> fetchMovies();
  Future<List<Movie>> searchMovies(String query);
  Future<Movie> fetchMovie(int id);
}

/// Cache capabilities exposed to presentation without a dependency on Hive.
abstract interface class CachedCatalogRepository implements CatalogRepository {
  List<Movie>? get cachedMovies;
  String? get cacheNotice;
  void beginRefresh();
  bool searchUsesCache(String query);
  bool detailsUseCache(int id);
}
