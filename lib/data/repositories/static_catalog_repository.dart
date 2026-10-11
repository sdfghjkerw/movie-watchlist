import '../../domain/models/movie.dart';
import '../../domain/repositories/catalog_repository.dart';
import '../sample_data/movies.dart';

class StaticCatalogRepository implements CatalogRepository {
  @override
  Future<List<Movie>> fetchMovies() async => sampleMovies;
  @override
  Future<List<Movie>> searchMovies(String query) async => sampleMovies
      .where((movie) => movie.title.toLowerCase().contains(query.toLowerCase()))
      .toList();
  @override
  Future<Movie> fetchMovie(int id) async =>
      sampleMovies.firstWhere((movie) => movie.id == id);
}
