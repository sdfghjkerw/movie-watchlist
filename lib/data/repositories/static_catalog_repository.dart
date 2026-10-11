import '../../domain/models/movie.dart';
import '../../domain/repositories/catalog_repository.dart';
import '../sample_data/movies.dart';

class StaticCatalogRepository implements CatalogRepository {
  @override
  List<Movie> get movies => sampleMovies;
}
