import '../models/movie.dart';

abstract interface class CatalogRepository {
  List<Movie> get movies;
}
