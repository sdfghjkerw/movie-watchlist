import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/firebase_providers.dart';
import '../../app/providers.dart';
import '../../domain/models/diary_entry.dart';
import '../../domain/models/local_profile.dart';
import '../../domain/models/movie.dart';
import 'diary_controller.dart';
import 'profile_controller.dart';
import 'watchlist_controller.dart';

class CloudSyncStatus {
  const CloudSyncStatus({
    this.isSyncing = false,
    this.error,
    this.lastSyncedAt,
    this.fcmTokenPreview,
    this.lastNotification,
  });

  final bool isSyncing;
  final String? error;
  final DateTime? lastSyncedAt;
  final String? fcmTokenPreview;
  final String? lastNotification;

  CloudSyncStatus copyWith({
    bool? isSyncing,
    Object? error = _unchanged,
    Object? lastSyncedAt = _unchanged,
    Object? fcmTokenPreview = _unchanged,
    Object? lastNotification = _unchanged,
  }) => CloudSyncStatus(
    isSyncing: isSyncing ?? this.isSyncing,
    error: identical(error, _unchanged) ? this.error : error as String?,
    lastSyncedAt: identical(lastSyncedAt, _unchanged)
        ? this.lastSyncedAt
        : lastSyncedAt as DateTime?,
    fcmTokenPreview: identical(fcmTokenPreview, _unchanged)
        ? this.fcmTokenPreview
        : fcmTokenPreview as String?,
    lastNotification: identical(lastNotification, _unchanged)
        ? this.lastNotification
        : lastNotification as String?,
  );
}

const _unchanged = Object();

final cloudSyncProvider =
    NotifierProvider<CloudSyncController, CloudSyncStatus>(
      CloudSyncController.new,
    );

final cloudSyncAuthBootstrapProvider = Provider<void>((ref) {
  ref.listen(authStateProvider, (previous, next) {
    final user = next.whenOrNull(data: (value) => value);
    final previousUid = previous?.whenOrNull(data: (value) => value?.uid);
    if (user != null && user.uid != previousUid) {
      unawaited(
        ref.read(cloudSyncProvider.notifier).syncNow().catchError((_) {}),
      );
    }
  });
});

class CloudSyncController extends Notifier<CloudSyncStatus> {
  StreamSubscription<RemoteMessage>? _messageSubscription;
  StreamSubscription<String>? _tokenSubscription;

  @override
  CloudSyncStatus build() {
    if (ref.watch(firebaseEnabledProvider)) {
      _messageSubscription = FirebaseMessaging.onMessage.listen((message) {
        if (!ref.mounted) return;
        final title = message.notification?.title ?? message.data['title'];
        state = state.copyWith(
          lastNotification: title is String ? title : null,
        );
      });
      _tokenSubscription = FirebaseMessaging.instance.onTokenRefresh.listen((
        token,
      ) async {
        final user = ref
            .read(authStateProvider)
            .whenOrNull(data: (value) => value);
        final repository = ref.read(firestoreUserDataRepositoryProvider);
        if (user == null || repository == null) return;
        await repository.saveFcmToken(
          user.uid,
          token,
          kIsWeb ? 'web' : defaultTargetPlatform.name,
        );
        if (ref.mounted) {
          state = state.copyWith(
            fcmTokenPreview:
                '${token.substring(0, 8)}…${token.substring(token.length - 6)}',
          );
        }
      }, onError: (Object _) {});
    }
    ref.onDispose(() {
      _messageSubscription?.cancel();
      _tokenSubscription?.cancel();
    });
    return const CloudSyncStatus();
  }

  Future<void> syncNow() async {
    final user = ref.read(authStateProvider).whenOrNull(data: (value) => value);
    if (user == null) throw StateError('Сначала войди в аккаунт.');
    final repository = ref.read(firestoreUserDataRepositoryProvider);
    if (repository == null) throw StateError('Firebase ещё не настроен.');

    state = state.copyWith(isSyncing: true, error: null);
    try {
      await repository.syncLocalData(
        uid: user.uid,
        watchlist: ref.read(watchlistRepositoryProvider),
        diary: ref.read(diaryRepositoryProvider),
        profile: ref.read(profileRepositoryProvider),
      );
      if (!ref.mounted) return;
      ref.invalidate(watchlistProvider);
      ref.invalidate(diaryProvider);
      ref.invalidate(profileProvider);
      state = state.copyWith(isSyncing: false, lastSyncedAt: DateTime.now());
    } catch (error) {
      if (!ref.mounted) return;
      state = state.copyWith(isSyncing: false, error: _friendlyError(error));
      rethrow;
    }
  }

  Future<void> saveDiaryEntry(DiaryEntry entry) async {
    final user = ref.read(authStateProvider).whenOrNull(data: (value) => value);
    final repository = ref.read(firestoreUserDataRepositoryProvider);
    if (user == null || repository == null) return;
    try {
      await repository.saveDiaryEntry(user.uid, entry);
      if (ref.mounted) state = state.copyWith(error: null);
    } catch (error) {
      if (ref.mounted) state = state.copyWith(error: _friendlyError(error));
    }
  }

  Future<void> saveWatchlistMovie(Movie movie) async {
    final user = ref.read(authStateProvider).whenOrNull(data: (value) => value);
    final repository = ref.read(firestoreUserDataRepositoryProvider);
    if (user == null || repository == null) return;
    try {
      await repository.saveWatchlistMovie(user.uid, movie);
      if (ref.mounted) state = state.copyWith(error: null);
    } catch (error) {
      if (ref.mounted) state = state.copyWith(error: _friendlyError(error));
    }
  }

  Future<void> removeWatchlistMovie(int movieId) async {
    final user = ref.read(authStateProvider).whenOrNull(data: (value) => value);
    final repository = ref.read(firestoreUserDataRepositoryProvider);
    if (user == null || repository == null) return;
    try {
      await repository.removeWatchlistMovie(user.uid, movieId);
      if (ref.mounted) state = state.copyWith(error: null);
    } catch (error) {
      if (ref.mounted) state = state.copyWith(error: _friendlyError(error));
    }
  }

  Future<void> saveProfile(LocalProfile profile) async {
    final user = ref.read(authStateProvider).whenOrNull(data: (value) => value);
    final repository = ref.read(firestoreUserDataRepositoryProvider);
    if (user == null || repository == null) return;
    try {
      await repository.saveProfile(user.uid, profile);
      if (ref.mounted) state = state.copyWith(error: null);
    } catch (error) {
      if (ref.mounted) state = state.copyWith(error: _friendlyError(error));
    }
  }

  Future<void> registerForPush() async {
    final user = ref.read(authStateProvider).whenOrNull(data: (value) => value);
    final dataRepository = ref.read(firestoreUserDataRepositoryProvider);
    final configuration = ref.read(firebaseLocalConfigurationProvider);
    if (user == null || dataRepository == null) {
      throw StateError('Войди в аккаунт, чтобы включить уведомления.');
    }
    if (kIsWeb && (configuration?.vapidKey?.isNotEmpty != true)) {
      throw StateError('Добавь Web Push VAPID key в локальную конфигурацию.');
    }

    final messaging = FirebaseMessaging.instance;
    final permission = await messaging.requestPermission();
    if (permission.authorizationStatus == AuthorizationStatus.denied) {
      throw StateError('Разреши уведомления в настройках браузера.');
    }
    final token = await messaging.getToken(
      vapidKey: kIsWeb ? configuration!.vapidKey : null,
      serviceWorkerScriptPath: kIsWeb ? '/firebase-messaging-sw.js' : null,
    );
    if (token == null || token.isEmpty) {
      throw StateError('Firebase не выдал токен этого устройства.');
    }
    await dataRepository.saveFcmToken(
      user.uid,
      token,
      kIsWeb ? 'web' : defaultTargetPlatform.name,
    );
    if (ref.mounted) {
      state = state.copyWith(
        error: null,
        fcmTokenPreview:
            '${token.substring(0, 8)}…${token.substring(token.length - 6)}',
      );
    }
  }

  String _friendlyError(Object error) {
    if (error is FirebaseException && error.code == 'permission-denied') {
      return 'Firestore отклонил запись: проверь Security Rules.';
    }
    return 'Не удалось синхронизировать данные. Локальная копия сохранена.';
  }
}
