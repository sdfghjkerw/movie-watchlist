import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movie_watchlist/main.dart';
import 'package:movie_watchlist/app/providers.dart';
import 'package:movie_watchlist/data/repositories/diary_repositories.dart';
import 'package:movie_watchlist/domain/models/app_settings.dart';
import 'package:movie_watchlist/presentation/screens/movie_details_screen.dart';
import 'package:movie_watchlist/presentation/screens/reviews_screen.dart';
import 'package:movie_watchlist/presentation/state/diary_controller.dart';
import 'package:movie_watchlist/presentation/state/settings_controller.dart';
import 'package:movie_watchlist/sample_data/movies.dart';

import 'catalog_fixture.dart';

void main() {
  testWidgets(
    'Personal actions and review editor update diary and reviews screen',
    (tester) async {
      final container = ProviderContainer(overrides: staticCatalogOverrides);
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: MovieDetailsScreen(movie: sampleMovies.first),
          ),
        ),
      );
      await tester.pumpAndSettle();
      Future<void> tapAction(String key) async {
        final finder = find.byKey(ValueKey(key));
        await tester.scrollUntilVisible(
          finder,
          250,
          scrollable: find.byType(Scrollable).last,
        );
        await tester.tap(finder);
        await tester.pumpAndSettle();
      }

      await tapAction('toggle-favorite');
      await tapAction('toggle-watched');
      expect(container.read(diaryProvider).single.favorite, isTrue);
      expect(container.read(diaryProvider).single.watchedAt, isNotNull);
      await tapAction('rating-star-8');
      await tester.ensureVisible(find.byKey(const ValueKey('review-text')));
      await tester.enterText(
        find.byKey(const ValueKey('review-text')),
        'A personal impression',
      );
      await tapAction('save-diary');
      expect(container.read(diaryProvider).single.score, 8);
      expect(
        container.read(diaryProvider).single.review,
        'A personal impression',
      );
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: ReviewsScreen()),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('A personal impression'), findsOneWidget);
      expect(find.text('8/10'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Theme and language update app and all five navigation labels', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: staticCatalogOverrides,
        child: const MovieWatchlistApp(),
      ),
    );
    await tester.pumpAndSettle();
    final context = tester.element(find.byType(NavigationBar));
    final container = ProviderScope.containerOf(context);
    await container
        .read(settingsProvider.notifier)
        .update(theme: 'light', language: 'en');
    await tester.pumpAndSettle();
    for (final label in [
      'Home',
      'Search',
      'My collection',
      'Reviews',
      'Profile',
    ]) {
      expect(find.text(label), findsOneWidget);
    }
    expect(
      Theme.of(tester.element(find.byType(NavigationBar))).brightness,
      Brightness.light,
    );
    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('open-settings')));
    await tester.pumpAndSettle();
    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Language'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Failed diary write is visible and does not claim success', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...staticCatalogOverrides,
          diaryRepositoryProvider.overrideWithValue(FailingDiary()),
          initialSettingsProvider.overrideWithValue(const AppSettings()),
        ],
        child: MaterialApp(home: MovieDetailsScreen(movie: sampleMovies.first)),
      ),
    );
    await tester.pumpAndSettle();
    final favorite = find.byKey(const ValueKey('toggle-favorite'));
    await tester.scrollUntilVisible(
      favorite,
      250,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(favorite);
    await tester.pump();
    expect(
      find.text('Не удалось сохранить. Попробуй ещё раз.'),
      findsOneWidget,
    );
    expect(find.text('Добавить в избранное'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

class FailingDiary extends InMemoryDiaryRepository {
  @override
  Future<void> save(entry) async => throw StateError('Write failed');
}
