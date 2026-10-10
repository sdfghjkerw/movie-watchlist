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
    print('$title ($year) — рейтинг $rating');
  }
}

void main() {
  final movies = <Movie>[
    const Movie(
      title: 'Interstellar',
      releaseYear: 2014,
      rating: 8.7,
      isWatched: true,
    ),
    const Movie(title: 'Inception', releaseYear: 2010, rating: 8.8),
    const Movie(title: 'New Movie', rating: 7.5),
  ];

  final watchlist = movies.where((movie) => !movie.isWatched).toList();

  print('Фильмов в списке: ${watchlist.length}');

  for (final movie in watchlist) {
    movie.printInfo();
  }
}
