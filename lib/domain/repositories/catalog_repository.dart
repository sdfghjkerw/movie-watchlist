import '../models/movie.dart';

abstract interface class CatalogRepository {
  Future<List<Movie>> fetchMovies();
  Future<List<Movie>> searchMovies(String query);
  Future<Movie> fetchMovie(int id);
}

class MoviePage {
  const MoviePage({
    required this.page,
    required this.totalPages,
    required this.results,
  });

  final int page;
  final int totalPages;
  final List<Movie> results;

  bool get hasMore => page < totalPages;
}

abstract interface class PaginatedCatalogRepository {
  Future<MoviePage> fetchMoviesPage(int page);
  Future<MoviePage> searchMoviesPage(String query, int page);
}

/// Cache capabilities exposed to presentation without a dependency on Hive.
abstract interface class CachedCatalogRepository implements CatalogRepository {
  List<Movie>? get cachedMovies;
  String? get cacheNotice;
  void beginRefresh();
  bool searchUsesCache(String query);
  bool detailsUseCache(int id);
}
