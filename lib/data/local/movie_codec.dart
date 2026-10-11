import '../../domain/models/movie.dart';

Map<String, dynamic> encodeMovie(Movie movie) => {
  'id': movie.id,
  'title': movie.title,
  'year': movie.year,
  'genre': movie.genre,
  'rating': movie.rating,
  'description': movie.description,
  'emoji': movie.emoji,
  'posterUrl': movie.posterUrl,
  'originalTitle': movie.originalTitle,
  'runtimeMinutes': movie.runtimeMinutes,
};

Movie decodeMovie(Map<dynamic, dynamic> json) => Movie(
  id: json['id'] as int,
  title: json['title'] as String,
  year: json['year'] as int?,
  genre: json['genre'] as String,
  rating: (json['rating'] as num?)?.toDouble(),
  description: json['description'] as String,
  emoji: json['emoji'] as String,
  posterUrl: json['posterUrl'] as String?,
  originalTitle: json['originalTitle'] as String?,
  runtimeMinutes: json['runtimeMinutes'] as int?,
);
