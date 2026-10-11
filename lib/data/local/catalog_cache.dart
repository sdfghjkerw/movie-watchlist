import 'package:hive/hive.dart';

import '../../domain/models/movie.dart';
import 'movie_codec.dart';

class CatalogCache {
  CatalogCache(this.box);
  final Box<dynamic> box;
  List<Movie>? readList(String key) {
    final value = box.get(key);
    if (value == null) return null;
    return List.unmodifiable(
      (value as List).map((item) => decodeMovie(item as Map)),
    );
  }

  Future<void> writeList(
    String key,
    List<Movie> movies, [
    String language = 'ru',
  ]) async {
    await box.put(key, movies.map(encodeMovie).toList());
    for (final movie in movies) {
      if (readMovie(movie.id, language) == null) {
        await writeMovie(movie, language);
      }
    }
  }

  Movie? readMovie(int id, String language) {
    final value = box.get('movie:$language:$id');
    return value == null ? null : decodeMovie(value as Map);
  }

  Future<void> writeMovie(Movie movie, [String language = 'ru']) =>
      box.put('movie:$language:${movie.id}', encodeMovie(movie));
}
