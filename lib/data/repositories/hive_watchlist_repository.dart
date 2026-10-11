import 'package:hive/hive.dart';

import '../../domain/models/movie.dart';
import '../../domain/repositories/watchlist_repository.dart';
import '../local/movie_codec.dart';

class HiveWatchlistRepository implements WatchlistRepository {
  HiveWatchlistRepository(this.box);
  final Box<dynamic> box;
  @override
  List<Movie> get movies =>
      List.unmodifiable(box.values.map((value) => decodeMovie(value as Map)));
  @override
  Future<void> add(Movie movie) => box.put(movie.id, encodeMovie(movie));
  @override
  Future<void> remove(int id) => box.delete(id);
}
