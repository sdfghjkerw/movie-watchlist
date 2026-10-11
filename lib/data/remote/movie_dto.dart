import 'package:json_annotation/json_annotation.dart';

import '../../domain/models/movie.dart';

part 'movie_dto.g.dart';

@JsonSerializable()
class GenreDto {
  const GenreDto({required this.name});
  final String name;
  factory GenreDto.fromJson(Map<String, dynamic> json) =>
      _$GenreDtoFromJson(json);
  Map<String, dynamic> toJson() => _$GenreDtoToJson(this);
}

@JsonSerializable(explicitToJson: true)
class MovieDto {
  const MovieDto({
    required this.id,
    required this.title,
    this.overview,
    this.releaseDate,
    this.voteAverage,
    this.voteCount,
    this.posterPath,
    this.originalTitle,
    this.runtime,
    this.genres = const [],
  });
  final int id;
  final String title;
  final String? overview;
  @JsonKey(name: 'release_date')
  final String? releaseDate;
  @JsonKey(name: 'vote_average')
  final double? voteAverage;
  @JsonKey(name: 'vote_count')
  final int? voteCount;
  @JsonKey(name: 'poster_path')
  final String? posterPath;
  @JsonKey(name: 'original_title')
  final String? originalTitle;
  final int? runtime;
  final List<GenreDto> genres;
  factory MovieDto.fromJson(Map<String, dynamic> json) =>
      _$MovieDtoFromJson(json);
  Map<String, dynamic> toJson() => _$MovieDtoToJson(this);

  Movie toMovie() => Movie(
    id: id,
    title: title,
    year: DateTime.tryParse(releaseDate ?? '')?.year,
    genre: genres.isEmpty
        ? 'Жанры не указаны'
        : genres.map((genre) => genre.name).join(' · '),
    rating: (voteCount ?? 0) > 0 ? voteAverage : null,
    description: overview == null || overview!.trim().isEmpty
        ? 'Описание отсутствует.'
        : overview!,
    emoji: '',
    posterUrl: posterPath == null || posterPath!.isEmpty
        ? null
        : 'https://image.tmdb.org/t/p/w500$posterPath',
    originalTitle: originalTitle,
    runtimeMinutes: runtime != null && runtime! > 0 ? runtime : null,
  );
}
