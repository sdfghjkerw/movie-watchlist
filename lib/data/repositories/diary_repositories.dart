import 'package:hive/hive.dart';

import '../../domain/models/diary_entry.dart';
import '../../domain/repositories/diary_repository.dart';
import '../local/movie_codec.dart';

class InMemoryDiaryRepository implements DiaryRepository {
  final _entries = <int, DiaryEntry>{};
  @override
  List<DiaryEntry> get entries => List.unmodifiable(_entries.values);
  @override
  Future<void> save(DiaryEntry entry) async {
    _entries[entry.movie.id] = entry;
  }
}

class HiveDiaryRepository implements DiaryRepository {
  HiveDiaryRepository(this.box);
  final Box<dynamic> box;
  @override
  List<DiaryEntry> get entries => List.unmodifiable(
    box.values.map((value) {
      final json = value as Map;
      return DiaryEntry(
        movie: decodeMovie(json['movie'] as Map),
        favorite: json['favorite'] == true,
        watchedAt: json['watchedAt'] == null
            ? null
            : DateTime.parse(json['watchedAt'] as String),
        score: json['score'] as int?,
        review: json['review'] as String? ?? '',
      );
    }),
  );
  @override
  Future<void> save(DiaryEntry entry) => box.put(entry.movie.id, {
    'movie': encodeMovie(entry.movie),
    'favorite': entry.favorite,
    'watchedAt': entry.watchedAt?.toIso8601String(),
    'score': entry.score,
    'review': entry.review,
  });
}
