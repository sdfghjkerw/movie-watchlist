import 'dart:async';

import '../models/movie.dart';

abstract interface class WatchlistRepository {
  List<Movie> get movies;
  FutureOr<void> add(Movie movie);
  FutureOr<void> remove(int id);
}
