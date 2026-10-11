import 'package:flutter/foundation.dart';

import '../models/movie.dart';

class WatchlistModel extends ChangeNotifier {
  // Единственный источник личного списка; поля Movie не изменяются.
  final Map<int, Movie> _movies = {};
  List<Movie> get movies => List.unmodifiable(_movies.values);
  bool contains(int id) => _movies.containsKey(id);

  void toggle(Movie movie) {
    if (contains(movie.id)) {
      _movies.remove(movie.id);
    } else {
      _movies[movie.id] = movie;
    }
    notifyListeners();
  }

  void remove(int id) {
    if (_movies.remove(id) != null) notifyListeners();
  }
}
