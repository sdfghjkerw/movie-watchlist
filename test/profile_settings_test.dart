import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:movie_watchlist/app/providers.dart';
import 'package:movie_watchlist/data/local/avatar_picker.dart';
import 'package:movie_watchlist/data/local/settings_store.dart';
import 'package:movie_watchlist/data/repositories/profile_repositories.dart';
import 'package:movie_watchlist/domain/models/local_profile.dart';
import 'package:movie_watchlist/domain/models/diary_entry.dart';
import 'package:movie_watchlist/presentation/screens/profile_screen.dart';
import 'package:movie_watchlist/presentation/screens/settings_screen.dart';
import 'package:movie_watchlist/presentation/state/diary_controller.dart';
import 'package:movie_watchlist/presentation/state/watchlist_controller.dart';
import 'package:movie_watchlist/presentation/state/profile_controller.dart';
import 'package:movie_watchlist/presentation/state/settings_controller.dart';
import 'package:movie_watchlist/main.dart';
import 'package:movie_watchlist/sample_data/movies.dart';
import 'package:movie_watchlist/theme/app_theme.dart';

import 'catalog_fixture.dart';

class SwitchableProfile extends InMemoryProfileRepository {
  bool fail = false;
  Completer<void>? pending;
  @override
  Future<void> save(LocalProfile value) async {
    if (pending != null) await pending!.future;
    if (fail) throw StateError('Write failed');
    await super.save(value);
  }
}

class Preferences extends Fake implements SharedPreferencesAsync {
  final values = <String, String>{};
  final _failure = [false];
  bool get fail => _failure[0];
  set fail(bool value) => _failure[0] = value;
  @override
  Future<String?> getString(String key) async => values[key];
  @override
  Future<void> setString(String key, String value) async {
    if (fail) throw StateError('Write failed');
    values[key] = value;
  }
}

Future<void> tap(WidgetTester tester, String key) async {
  await tester.pumpAndSettle();
  if (find.byKey(ValueKey(key)).evaluate().isEmpty) {
    await tester.scrollUntilVisible(
      find.byKey(ValueKey(key)),
      180,
      scrollable: find.byType(Scrollable).first,
    );
  }
  await tester.ensureVisible(find.byKey(ValueKey(key)));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(ValueKey(key)));
  await tester.pumpAndSettle();
}

void main() {
  test(
    'Profile survives Hive reopen independently of existing diary data',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'movie-profile-test-',
      );
      Hive.init(directory.path);
      addTearDown(() async {
        await Hive.close();
        await directory.delete(recursive: true);
      });
      final diary = await Hive.openBox<dynamic>('diary_v1');
      await diary.put(12, {'score': 8, 'review': 'Keep me'});
      var box = await Hive.openBox<dynamic>('profile_v1');
      var repository = HiveProfileRepository(box);
      expect(repository.profile.name, isEmpty);
      final avatar = Uint8List.fromList([1, 2, 3]);
      await repository.save(
        LocalProfile(
          name: 'User supplied',
          email: 'reader@example.org',
          avatar: avatar,
        ),
      );
      await box.close();
      box = await Hive.openBox<dynamic>('profile_v1');
      repository = HiveProfileRepository(box);
      expect(repository.profile.name, 'User supplied');
      expect(repository.profile.email, 'reader@example.org');
      expect(repository.profile.avatar, orderedEquals(avatar));
      await repository.save(
        LocalProfile(name: 'Changed', avatar: repository.profile.avatar),
      );
      await box.close();
      box = await Hive.openBox<dynamic>('profile_v1');
      expect(HiveProfileRepository(box).profile.email, isEmpty);
      expect(HiveProfileRepository(box).profile.avatar, orderedEquals(avatar));
      expect(diary.get(12), {'score': 8, 'review': 'Keep me'});
    },
  );

  for (final dark in [true, false]) {
    testWidgets(
      'Profile starts empty, validates optional email and preserves failed draft (${dark ? 'dark' : 'light'})',
      (tester) async {
        tester.view.physicalSize = const Size(320, 820);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final repository = SwitchableProfile();
        final container = ProviderContainer(
          overrides: [
            ...staticCatalogOverrides,
            profileRepositoryProvider.overrideWithValue(repository),
            avatarPickerProvider.overrideWithValue(() async => null),
          ],
        );
        addTearDown(container.dispose);
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              theme: dark ? AppTheme.darkTheme : AppTheme.lightTheme,
              home: const ProfileScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Email не указан'), findsOneWidget);
        expect(find.byType(DropdownButtonFormField<String>), findsNothing);
        await tap(tester, 'edit-profile');
        await tester.enterText(
          find.byKey(const ValueKey('profile-name')),
          'My name',
        );
        await tester.enterText(
          find.byKey(const ValueKey('profile-email')),
          'invalid',
        );
        await tap(tester, 'save-profile');
        expect(find.text('Проверь формат email'), findsOneWidget);
        expect(container.read(profileProvider).name, isEmpty);
        await tester.enterText(find.byKey(const ValueKey('profile-email')), '');
        repository.fail = true;
        await tap(tester, 'save-profile');
        expect(
          find.text('Не удалось сохранить. Попробуй ещё раз.'),
          findsOneWidget,
        );
        expect(
          tester
              .widget<TextFormField>(find.byKey(const ValueKey('profile-name')))
              .controller!
              .text,
          'My name',
        );
        repository.fail = false;
        repository.pending = Completer<void>();
        await tester.tap(find.byKey(const ValueKey('save-profile')));
        await tester.pump();
        expect(
          tester
              .widget<TextField>(
                find.descendant(
                  of: find.byKey(const ValueKey('profile-name')),
                  matching: find.byType(TextField),
                ),
              )
              .readOnly,
          isTrue,
        );
        repository.pending!.complete();
        await tester.pumpAndSettle();
        expect(container.read(profileProvider).name, 'My name');
        expect(container.read(profileProvider).email, isEmpty);
        expect(find.text('Email не указан'), findsOneWidget);
        await tap(tester, 'edit-profile');
        await tap(tester, 'choose-avatar');
        expect(container.read(profileProvider).avatar, isNull);
        await tap(tester, 'cancel-profile');
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'Profile statistics use diary and watchlist; highlighted film opens correct details',
    (tester) async {
      final container = ProviderContainer(overrides: staticCatalogOverrides);
      addTearDown(container.dispose);
      await container
          .read(diaryProvider.notifier)
          .save(
            DiaryEntry(
              movie: sampleMovies.last,
              favorite: true,
              watchedAt: DateTime(2026),
              score: 9,
              review: 'My impression',
            ),
          );
      await container
          .read(watchlistProvider.notifier)
          .toggle(sampleMovies.first);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: ProfileScreen()),
        ),
      );
      await tester.pumpAndSettle();
      for (final label in ['Просмотрено', 'Хочу посмотреть', 'Избранное']) {
        expect(
          tester.widget<Text>(find.byKey(ValueKey('profile-stat-$label'))).data,
          '1',
        );
      }
      await tap(tester, 'profile-film-${sampleMovies.last.id}');
      expect(find.text(sampleMovies.last.title), findsOneWidget);
      expect(find.text('9/10'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Settings change actual app theme, language, system mode and persist independently',
    (tester) async {
      final preferences = Preferences();
      await tester.pumpWidget(
        MovieWatchlistApp(
          storageOverrides: [
            ...staticCatalogOverrides,
            settingsStoreProvider.overrideWithValue(SettingsStore(preferences)),
          ],
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Профиль'));
      await tester.pumpAndSettle();
      await tap(tester, 'open-settings');
      expect(find.byType(SettingsScreen), findsOneWidget);
      await tap(tester, 'settings-theme-light');
      expect(
        Theme.of(tester.element(find.byType(SettingsScreen))).brightness,
        Brightness.light,
      );
      await tap(tester, 'settings-language-en');
      expect(find.text('Language'), findsOneWidget);
      await tap(tester, 'settings-theme-system');
      final context = tester.element(find.byType(SettingsScreen));
      final container = ProviderScope.containerOf(context);
      expect(container.read(settingsProvider).theme, 'system');
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
      await tester.pumpAndSettle();
      expect(Theme.of(context).brightness, Brightness.dark);
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
      await tester.pumpAndSettle();
      expect(Theme.of(context).brightness, Brightness.light);
      tester.platformDispatcher.clearPlatformBrightnessTestValue();
      final restored = await SettingsStore(preferences).read();
      expect(restored.theme, 'system');
      expect(restored.language, 'en');
      expect(jsonDecode(preferences.values['movie_watchlist.settings_v1']!), {
        'theme': 'system',
        'language': 'en',
      });
      preferences.fail = true;
      await tap(tester, 'settings-theme-dark');
      expect(container.read(settingsProvider).theme, 'system');
      expect(find.text('Could not save. Please try again.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Photo selection, retry, cancellation and removal preserve personal fields',
    (tester) async {
      final bytes = (await tester.runAsync(() async {
        final recorder = ui.PictureRecorder();
        Canvas(recorder).drawRect(
          const Rect.fromLTWH(0, 0, 2, 2),
          Paint()..color = Colors.green,
        );
        final picture = recorder.endRecording();
        final image = await picture.toImage(2, 2);
        final data = await image.toByteData(format: ui.ImageByteFormat.png);
        image.dispose();
        picture.dispose();
        return data!.buffer.asUint8List();
      }))!;
      final repository = SwitchableProfile();
      await repository.save(
        const LocalProfile(name: 'Reader', email: 'reader@example.org'),
      );
      var badFile = false;
      final container = ProviderContainer(
        overrides: [
          ...staticCatalogOverrides,
          profileRepositoryProvider.overrideWithValue(repository),
          avatarPickerProvider.overrideWithValue(() async {
            if (badFile) {
              throw const FormatException('Не удалось прочитать фото.');
            }
            return bytes;
          }),
        ],
      );
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: ProfileScreen()),
        ),
      );
      await tester.pumpAndSettle();
      await tap(tester, 'edit-profile');
      await tap(tester, 'choose-avatar');
      repository.fail = true;
      await tap(tester, 'save-profile');
      expect(container.read(profileProvider).avatar, isNull);
      expect(find.byKey(const ValueKey('remove-avatar')), findsOneWidget);
      repository.fail = false;
      await tap(tester, 'save-profile');
      expect(container.read(profileProvider).avatar, orderedEquals(bytes));
      await tap(tester, 'edit-profile');
      badFile = true;
      await tap(tester, 'choose-avatar');
      expect(find.text('Не удалось прочитать фото.'), findsOneWidget);
      await tap(tester, 'remove-avatar');
      await tap(tester, 'cancel-profile');
      expect(container.read(profileProvider).avatar, orderedEquals(bytes));
      await tap(tester, 'edit-profile');
      await tap(tester, 'remove-avatar');
      await tap(tester, 'save-profile');
      expect(container.read(profileProvider).avatar, isNull);
      expect(container.read(profileProvider).name, 'Reader');
      expect(container.read(profileProvider).email, 'reader@example.org');
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Avatar decoding resizes large images and rejects invalid files',
    (tester) async {
      await tester.runAsync(() async {
        final recorder = ui.PictureRecorder();
        Canvas(recorder).drawRect(
          const Rect.fromLTWH(0, 0, 1000, 800),
          Paint()..color = Colors.purple,
        );
        final picture = recorder.endRecording();
        final image = await picture.toImage(1000, 800);
        final data = await image.toByteData(format: ui.ImageByteFormat.png);
        image.dispose();
        picture.dispose();
        final resized = await prepareAvatar(data!.buffer.asUint8List());
        final codec = await ui.instantiateImageCodec(resized);
        final frame = await codec.getNextFrame();
        expect(frame.image.width, 512);
        expect(frame.image.height, 410);
        frame.image.dispose();
        codec.dispose();
        await expectLater(
          prepareAvatar(Uint8List.fromList([1, 2, 3])),
          throwsA(anything),
        );
        await expectLater(
          prepareAvatar(Uint8List(5 * 1024 * 1024 + 1)),
          throwsFormatException,
        );
      });
    },
  );
}
