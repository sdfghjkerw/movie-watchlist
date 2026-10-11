import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../domain/models/diary_entry.dart';
import '../../domain/models/movie.dart';

final diaryProvider = NotifierProvider<DiaryController, List<DiaryEntry>>(
  DiaryController.new,
);

class DiaryController extends Notifier<List<DiaryEntry>> {
  Future<void> _pending = Future.value();

  Future<void> _enqueue(Future<void> Function() operation) {
    final result = _pending.then((_) => operation());
    _pending = result.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return result;
  }

  @override
  List<DiaryEntry> build() => ref.watch(diaryRepositoryProvider).entries;
  Future<void> save(DiaryEntry entry) => _enqueue(() => _save(entry));

  // Read inside the queue so independent edits cannot overwrite newer fields.
  // updateScore distinguishes clearing a score from leaving it untouched.
  Future<void> update(
    Movie movie, {
    bool? favorite,
    bool? watched,
    bool updateScore = false,
    int? score,
    String? review,
  }) => _enqueue(() async {
    final current =
        ref
            .read(diaryRepositoryProvider)
            .entries
            .where((entry) => entry.movie.id == movie.id)
            .firstOrNull ??
        DiaryEntry(movie: movie);
    await _save(
      DiaryEntry(
        movie: movie,
        favorite: favorite ?? current.favorite,
        watchedAt: watched == null
            ? current.watchedAt
            : watched
            ? current.watchedAt ?? DateTime.now()
            : null,
        score: updateScore ? score : current.score,
        review: review ?? current.review,
      ),
    );
  });

  Future<void> _save(DiaryEntry entry) async {
    if (entry.score != null && (entry.score! < 1 || entry.score! > 10)) {
      throw ArgumentError('Score must be between 1 and 10');
    }
    await ref.read(diaryRepositoryProvider).save(entry);
    state = ref.read(diaryRepositoryProvider).entries;
  }
}
