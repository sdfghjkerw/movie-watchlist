import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../domain/models/movie.dart';
import 'settings_controller.dart';

final searchProvider =
    NotifierProvider<MovieSearchController, AsyncValue<List<Movie>>>(
      MovieSearchController.new,
    );

class MovieSearchController extends Notifier<AsyncValue<List<Movie>>> {
  Timer? _timer;
  int _generation = 0;
  String _query = '';

  @override
  AsyncValue<List<Movie>> build() {
    ref.listen(settingsProvider, (previous, next) {
      if (previous?.language != next.language) setQuery(_query);
    });
    ref.onDispose(() {
      _timer?.cancel();
      _generation++;
    });
    return const AsyncData([]);
  }

  void setQuery(String value) {
    _query = value.trim();
    final generation = ++_generation;
    _timer?.cancel();
    if (_query.isEmpty) {
      state = const AsyncData([]);
      return;
    }
    state = const AsyncLoading();
    _timer = Timer(
      const Duration(milliseconds: 400),
      () => _load(_query, generation),
    );
  }

  Future<void> refresh() async {
    _timer?.cancel();
    final generation = ++_generation;
    if (_query.isEmpty) {
      state = const AsyncData([]);
      return;
    }
    state = const AsyncLoading();
    await _load(_query, generation);
  }

  Future<void> _load(String query, int generation) async {
    final repository = ref.read(catalogRepositoryProvider);
    try {
      final movies = await repository.searchMovies(query);
      if (ref.mounted && generation == _generation) {
        state = AsyncData(movies);
      }
    } catch (error, stack) {
      if (ref.mounted && generation == _generation) {
        state = AsyncError(error, stack);
      }
    }
  }
}
