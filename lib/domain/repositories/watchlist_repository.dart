import '../models/movie.dart';

abstract interface class WatchlistRepository {
  List<Movie> get movies;
  void add(Movie movie);
  void remove(int id);
}
