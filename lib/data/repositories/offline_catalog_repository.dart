import '../../domain/models/movie.dart';
import '../../domain/repositories/catalog_repository.dart';
import '../local/catalog_cache.dart';

class OfflineCatalogRepository implements CachedCatalogRepository {
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
    updating = true;
    try {
      final movies = await remote.fetchMovies();
      await cache.writeList(catalogKey, movies, language);
      usedCache = false;
      warning = null;
      return movies;
    } catch (_) {
      final cached = cachedMovies;
      if (cached == null) rethrow;
      usedCache = true;
      warning = 'Нет обновления из сети. Показан сохранённый каталог.';
      return cached;
    } finally {
      updating = false;
    }
  }

  @override
  Future<List<Movie>> searchMovies(String query) async {
    if (query.trim().isEmpty) return [];
    final key = 'search:$language:${query.trim().toLowerCase()}';
    try {
      final movies = await remote.searchMovies(query);
      await cache.writeList(key, movies, language);
      cachedSearches.remove(_normalized(query));
      return movies;
    } catch (_) {
      final cached = cache.readList(key);
      if (cached == null) rethrow;
      cachedSearches.add(_normalized(query));
      return cached;
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
