import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../domain/models/movie.dart';

final watchlistProvider = NotifierProvider<WatchlistController, List<Movie>>(
  WatchlistController.new,
);

class WatchlistController extends Notifier<List<Movie>> {
  @override
  List<Movie> build() => ref.watch(watchlistRepositoryProvider).movies;

  void toggle(Movie movie) {
    final repository = ref.read(watchlistRepositoryProvider);
    if (state.any((item) => item.id == movie.id)) {
      repository.remove(movie.id);
    } else {
      repository.add(movie);
    }
    state = repository.movies;
  }

  void remove(int id) {
    final repository = ref.read(watchlistRepositoryProvider);
    repository.remove(id);
    state = repository.movies;
  }
}
