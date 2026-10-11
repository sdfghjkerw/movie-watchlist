import '../../domain/models/movie.dart';
import '../../domain/repositories/watchlist_repository.dart';

class InMemoryWatchlistRepository implements WatchlistRepository {
  final Map<int, Movie> _movies = {};

  @override
  List<Movie> get movies => List.unmodifiable(_movies.values);
  @override
  void add(Movie movie) => _movies[movie.id] = movie;
  @override
  void remove(int id) => _movies.remove(id);
}
