// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'movie_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GenreDto _$GenreDtoFromJson(Map<String, dynamic> json) =>
    GenreDto(name: json['name'] as String);

Map<String, dynamic> _$GenreDtoToJson(GenreDto instance) => <String, dynamic>{
  'name': instance.name,
};

MovieDto _$MovieDtoFromJson(Map<String, dynamic> json) => MovieDto(
  id: (json['id'] as num).toInt(),
  title: json['title'] as String,
  overview: json['overview'] as String?,
  releaseDate: json['release_date'] as String?,
  voteAverage: (json['vote_average'] as num?)?.toDouble(),
  voteCount: (json['vote_count'] as num?)?.toInt(),
  posterPath: json['poster_path'] as String?,
  originalTitle: json['original_title'] as String?,
  runtime: (json['runtime'] as num?)?.toInt(),
  genres:
      (json['genres'] as List<dynamic>?)
          ?.map((e) => GenreDto.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
);

Map<String, dynamic> _$MovieDtoToJson(MovieDto instance) => <String, dynamic>{
  'id': instance.id,
  'title': instance.title,
  'overview': instance.overview,
  'release_date': instance.releaseDate,
  'vote_average': instance.voteAverage,
  'vote_count': instance.voteCount,
  'poster_path': instance.posterPath,
  'original_title': instance.originalTitle,
  'runtime': instance.runtime,
  'genres': instance.genres.map((e) => e.toJson()).toList(),
};
