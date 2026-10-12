import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/models/diary_entry.dart';
import '../../domain/models/local_profile.dart';
import '../../domain/models/movie.dart';
import '../../domain/repositories/diary_repository.dart';
import '../../domain/repositories/profile_repository.dart';
import '../../domain/repositories/watchlist_repository.dart';
import '../local/movie_codec.dart';

class FirestoreUserDataRepository {
  FirestoreUserDataRepository(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _collection(
    String uid,
    String name,
  ) => _firestore.collection('users').doc(uid).collection(name);

  Future<void> saveDiaryEntry(String uid, DiaryEntry entry) =>
      _collection(uid, 'diary').doc('${entry.movie.id}').set({
        ..._encodeDiary(entry),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

  Future<void> saveWatchlistMovie(String uid, Movie movie) =>
      _collection(uid, 'watchlist').doc('${movie.id}').set({
        'movie': encodeMovie(movie),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

  Future<void> removeWatchlistMovie(String uid, int movieId) =>
      _collection(uid, 'watchlist').doc('$movieId').delete();

  Future<void> saveProfile(String uid, LocalProfile profile) =>
      _collection(uid, 'profile').doc('identity').set({
        ..._encodeProfile(profile),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

  Future<void> saveFcmToken(String uid, String token, String platform) =>
      _collection(uid, 'devices').doc(token).set({
        'token': token,
        'platform': platform,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

  /// Combines the current device's Hive data with the account's cloud data.
  /// Unique entries from both sides are retained; on ID conflicts, the local
  /// copy wins. The merged values are written to both stores.
  Future<void> syncLocalData({
    required String uid,
    required WatchlistRepository watchlist,
    required DiaryRepository diary,
    required ProfileRepository profile,
  }) async {
    final watchlistSnapshot = await _collection(uid, 'watchlist').get();
    final diarySnapshot = await _collection(uid, 'diary').get();
    final profileSnapshot = await _collection(
      uid,
      'profile',
    ).doc('identity').get();
    final remoteWatchlist = {
      for (final doc in watchlistSnapshot.docs)
        doc.id: _decodeMovieDocument(doc.data()),
    };
    final remoteDiary = {
      for (final doc in diarySnapshot.docs) doc.id: _decodeDiary(doc.data()),
    };

    final localMovies = {
      for (final movie in watchlist.movies) '${movie.id}': movie,
    };
    final localDiary = {
      for (final entry in diary.entries) '${entry.movie.id}': entry,
    };
    final mergedMovies = {...remoteWatchlist, ...localMovies};
    final mergedDiary = {...remoteDiary, ...localDiary};

    final remoteProfileData = profileSnapshot.data();
    final localProfile = profile.profile;
    final remoteProfile = remoteProfileData == null
        ? const LocalProfile()
        : _decodeProfile(remoteProfileData);
    final mergedProfile = LocalProfile(
      name: localProfile.name.isNotEmpty
          ? localProfile.name
          : remoteProfile.name,
      email: localProfile.email.isNotEmpty
          ? localProfile.email
          : remoteProfile.email,
      avatar: localProfile.avatar ?? remoteProfile.avatar,
    );

    for (final movie in mergedMovies.values) {
      await watchlist.add(movie);
      await saveWatchlistMovie(uid, movie);
    }
    for (final entry in mergedDiary.values) {
      await diary.save(entry);
      await saveDiaryEntry(uid, entry);
    }
    await profile.save(mergedProfile);
    await saveProfile(uid, mergedProfile);
  }

  static Map<String, dynamic> _encodeDiary(DiaryEntry entry) => {
    'movie': encodeMovie(entry.movie),
    'favorite': entry.favorite,
    'watchedAt': entry.watchedAt == null
        ? null
        : Timestamp.fromDate(entry.watchedAt!),
    'score': entry.score,
    'review': entry.review,
  };

  static DiaryEntry _decodeDiary(Map<String, dynamic> data) {
    final watchedAt = data['watchedAt'];
    return DiaryEntry(
      movie: _decodeMovieDocument(data),
      favorite: data['favorite'] == true,
      watchedAt: watchedAt is Timestamp
          ? watchedAt.toDate()
          : watchedAt is DateTime
          ? watchedAt
          : watchedAt is String
          ? DateTime.tryParse(watchedAt)
          : null,
      score: data['score'] as int?,
      review: data['review'] as String? ?? '',
    );
  }

  static Map<String, dynamic> _encodeProfile(LocalProfile profile) {
    final avatar = profile.avatar;
    return {
      'name': profile.name,
      'email': profile.email,
      'avatar': avatar == null || avatar.isEmpty
          ? FieldValue.delete()
          : Blob(avatar),
    };
  }

  static LocalProfile _decodeProfile(Map<String, dynamic> data) {
    final avatarValue = data['avatar'];
    final avatar = avatarValue is Blob
        ? Uint8List.fromList(avatarValue.bytes)
        : null;
    return LocalProfile(
      name: data['name'] as String? ?? '',
      email: data['email'] as String? ?? '',
      avatar: avatar,
    );
  }

  static Movie _decodeMovieDocument(Map<String, dynamic> data) =>
      decodeMovie(Map<String, dynamic>.from(data['movie'] as Map));
}
