import 'package:flutter_test/flutter_test.dart';
import 'package:movie_watchlist/dart_practice.dart' as practice;

void main() {
  test('Movie supports an unknown release year and default watched state', () {
    const movie = practice.Movie(title: 'Unknown', rating: 7.5);

    expect(movie.releaseYear, isNull);
    expect(movie.isWatched, isFalse);
  });

  test(
    'Async loading returns movies and filtering preserves the source',
    () async {
      final movies = await practice.loadMovies();
      final watchlist = practice.selectWatchlist(movies);

      expect(movies, hasLength(3));
      expect(watchlist.map((movie) => movie.title), ['Inception', 'New Movie']);
      expect(watchlist.every((movie) => !movie.isWatched), isTrue);
      expect(watchlist.last.releaseYear, isNull);
      expect(movies.first.isWatched, isTrue);
    },
  );
}
