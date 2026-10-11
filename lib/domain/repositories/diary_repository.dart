import '../models/diary_entry.dart';

abstract interface class DiaryRepository {
  List<DiaryEntry> get entries;
  Future<void> save(DiaryEntry entry);
}
