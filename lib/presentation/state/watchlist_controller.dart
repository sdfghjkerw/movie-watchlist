import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../domain/models/movie.dart';

final watchlistProvider = NotifierProvider<WatchlistController, List<Movie>>(
  WatchlistController.new,
);

class WatchlistController extends Notifier<List<Movie>> {
  @override
  List<Movie> build() => ref.watch(watchlistRepositoryProvider).movies;

  Future<void> toggle(Movie movie) async {
    final repository = ref.read(watchlistRepositoryProvider);
    try {
      final result = state.any((item) => item.id == movie.id)
          ? repository.remove(movie.id)
          : repository.add(movie);
      state = repository.movies;
      await result;
    } finally {
      if (ref.mounted) state = repository.movies;
    }
  }

  Future<void> remove(int id) async {
    final repository = ref.read(watchlistRepositoryProvider);
    try {
      final result = repository.remove(id);
      state = repository.movies;
      await result;
    } finally {
      if (ref.mounted) state = repository.movies;
    }
  }
}
