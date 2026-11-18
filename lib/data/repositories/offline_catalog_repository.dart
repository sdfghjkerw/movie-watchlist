import '../../domain/models/movie.dart';
import '../../domain/repositories/catalog_repository.dart';
import '../local/catalog_cache.dart';

class OfflineCatalogRepository
    implements CachedCatalogRepository, PaginatedCatalogRepository {
  OfflineCatalogRepository({
    required this.remote,
    required this.cache,
    required this.language,
  });
  final CatalogRepository remote;
  final CatalogCache cache;
  final String language;
  String get catalogKey => 'catalog:$language';
  @override
  List<Movie>? get cachedMovies => cache.readList(catalogKey);
  bool usedCache = false;
  bool updating = false;
  String? warning;
  final cachedSearches = <String>{};
  final cachedDetails = <int>{};
  String _normalized(String query) => query.trim().toLowerCase();
  @override
  bool searchUsesCache(String query) =>
      cachedSearches.contains(_normalized(query));
  @override
  bool detailsUseCache(int id) => cachedDetails.contains(id);
  @override
  String? get cacheNotice => cachedMovies == null || (!usedCache && !updating)
      ? null
      : warning ?? 'Сохранённый каталог · обновляем из сети';
  @override
  void beginRefresh() {
    usedCache = true;
    updating = true;
    warning = null;
  }

  @override
  Future<List<Movie>> fetchMovies() async {
    return (await fetchMoviesPage(1)).results;
  }

  @override
  Future<MoviePage> fetchMoviesPage(int page) async {
    final cacheKey = page == 1 ? catalogKey : '$catalogKey:page:$page';
    if (page == 1) updating = true;
    try {
      final result = remote is PaginatedCatalogRepository
          ? await (remote as PaginatedCatalogRepository).fetchMoviesPage(page)
          : MoviePage(
              page: 1,
              totalPages: 1,
              results: await remote.fetchMovies(),
            );
      await cache.writeList(cacheKey, result.results, language);
      if (page == 1) {
        usedCache = false;
        warning = null;
      }
      return result;
    } catch (_) {
      final cached =
          cache.readList(cacheKey) ?? (page == 1 ? cachedMovies : null);
      if (cached == null) rethrow;
      usedCache = true;
      warning = 'Нет обновления из сети. Показан сохранённый каталог.';
      return MoviePage(page: page, totalPages: page, results: cached);
    } finally {
      if (page == 1) updating = false;
    }
  }

  @override
  Future<List<Movie>> searchMovies(String query) async {
    return (await searchMoviesPage(query, 1)).results;
  }

  @override
  Future<MoviePage> searchMoviesPage(String query, int page) async {
    if (query.trim().isEmpty) {
      return MoviePage(page: 1, totalPages: 1, results: const []);
    }
    final baseKey = 'search:$language:${query.trim().toLowerCase()}';
    final key = page == 1 ? baseKey : '$baseKey:page:$page';
    try {
      final result = remote is PaginatedCatalogRepository
          ? await (remote as PaginatedCatalogRepository).searchMoviesPage(
              query,
              page,
            )
          : MoviePage(
              page: 1,
              totalPages: 1,
              results: await remote.searchMovies(query),
            );
      await cache.writeList(key, result.results, language);
      if (page == 1) cachedSearches.remove(_normalized(query));
      return result;
    } catch (_) {
      final cached =
          cache.readList(key) ?? (page == 1 ? cache.readList(baseKey) : null);
      if (cached == null) rethrow;
      cachedSearches.add(_normalized(query));
      return MoviePage(page: page, totalPages: page, results: cached);
    }
  }

  @override
  Future<Movie> fetchMovie(int id) async {
    try {
      final movie = await remote.fetchMovie(id);
      await cache.writeMovie(movie, language);
      cachedDetails.remove(id);
      return movie;
    } catch (_) {
      final cached = cache.readMovie(id, language);
      if (cached == null) rethrow;
      cachedDetails.add(id);
      return cached;
    }
  }
}
