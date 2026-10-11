class Movie {
  final int id;
  final String title;
  final int? year;
  final String genre;
  final double? rating;
  final String? posterUrl;
  final String? originalTitle;
  final int? runtimeMinutes;
  final String description;
  final String emoji;
  final bool isInWatchlist;
  final bool isWatched;

  const Movie({
    required this.id,
    required this.title,
    required this.year,
    required this.genre,
    required this.rating,
    required this.description,
    required this.emoji,
    this.isInWatchlist = false,
    this.isWatched = false,
    this.posterUrl,
    this.originalTitle,
    this.runtimeMinutes,
  });
}
