import 'dart:io';

class Movie {
  final String title;
  final int? releaseYear;
  final double rating;
  final bool isWatched;

  const Movie({
    required this.title,
    this.releaseYear,
    required this.rating,
    this.isWatched = false,
  });

  void printInfo() {
    final year = releaseYear?.toString() ?? 'Год неизвестен';
    stdout.writeln('$title ($year) — рейтинг $rating');
  }
}

// Учебная имитация асинхронной загрузки, без API и доступа к сети.
Future<List<Movie>> loadMovies() async {
  await Future<void>.delayed(const Duration(milliseconds: 10));
  return <Movie>[
    const Movie(
      title: 'Interstellar',
      releaseYear: 2014,
      rating: 8.7,
      isWatched: true,
    ),
    const Movie(title: 'Inception', releaseYear: 2010, rating: 8.8),
    const Movie(title: 'New Movie', rating: 7.5),
  ];
}

List<Movie> selectWatchlist(List<Movie> movies) {
  return movies.where((movie) => !movie.isWatched).toList();
}

Future<void> main() async {
  final movies = await loadMovies();

  final watchlist = selectWatchlist(movies);

  stdout.writeln('Фильмов в списке: ${watchlist.length}');

  for (final movie in watchlist) {
    movie.printInfo();
  }
}
