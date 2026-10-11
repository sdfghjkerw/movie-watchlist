import 'movie.dart';

class DiaryEntry {
  const DiaryEntry({
    required this.movie,
    this.favorite = false,
    this.watchedAt,
    this.score,
    this.review = '',
  });
  final Movie movie;
  final bool favorite;
  final DateTime? watchedAt;
  final int? score;
  final String review;
}
