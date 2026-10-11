import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movie_watchlist/app/providers.dart';
import 'package:movie_watchlist/app/router.dart';
import 'package:movie_watchlist/data/repositories/diary_repositories.dart';
import 'package:movie_watchlist/domain/models/diary_entry.dart';
import 'package:movie_watchlist/presentation/screens/movie_details_screen.dart';
import 'package:movie_watchlist/presentation/screens/reviews_screen.dart';
import 'package:movie_watchlist/sample_data/movies.dart';
import 'package:movie_watchlist/theme/app_theme.dart';

import 'catalog_fixture.dart';

Finder get reviewsListScrollable => find
    .descendant(
      of: find.byType(ListView).first,
      matching: find.byType(Scrollable),
    )
    .first;

Future<ProviderContainer> makeDiary() async {
  final repository = InMemoryDiaryRepository();
  await repository.save(
    DiaryEntry(
      movie: sampleMovies.first,
      score: 8,
      review: 'Beautiful cinematography and unforgettable ending.',
    ),
  );
  await repository.save(DiaryEntry(movie: sampleMovies[1], score: 6));
  await repository.save(
    DiaryEntry(
      movie: sampleMovies[2],
      review: 'A quiet, thoughtful afternoon.',
    ),
  );
  await repository.save(
    DiaryEntry(movie: sampleMovies[3], watchedAt: DateTime(2025)),
  );
  return ProviderContainer(
    overrides: [
      ...staticCatalogOverrides,
      diaryRepositoryProvider.overrideWithValue(repository),
    ],
  );
}

Future<void> tapKey(WidgetTester tester, String key) async {
  await tester.pumpAndSettle();
  final finder = find.byKey(ValueKey(key));
  if (finder.evaluate().isEmpty) {
    await tester.scrollUntilVisible(
      finder,
      180,
      scrollable: reviewsListScrollable,
    );
  }
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'Reviews group written reviews and rating-only entries without nested cards',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final container = await makeDiary();
      addTearDown(container.dispose);
      final router = buildAppRouter(initialLocation: '/reviews');
      addTearDown(router.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('review-entry-1')), findsOneWidget);
      expect(
        find.byKey(const ValueKey('review-entry-2')),
        findsOneWidget,
        reason:
            'search="${tester.widget<TextField>(find.byKey(const ValueKey('review-search'))).controller!.text}" text=${tester.widgetList<Text>(find.byType(Text)).map((item) => item.data).join(' | ')}',
      );
      expect(find.byKey(const ValueKey('review-entry-3')), findsOneWidget);
      expect(find.byKey(const ValueKey('review-entry-4')), findsNothing);
      expect(find.text('С отзывом'), findsOneWidget);
      expect(find.text('Только оценка'), findsOneWidget);
      expect(find.text('Оценка: 8/10'), findsNothing);
      expect(find.text('8/10'), findsOneWidget);
      expect(find.byType(Card), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Search matches film titles and review text; clear restores filtered entries',
    (tester) async {
      final container = await makeDiary();
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: ReviewsScreen()),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('review-search')),
        'CINEMATOGRAPHY',
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('review-entry-1')), findsOneWidget);
      expect(find.byKey(const ValueKey('review-entry-2')), findsNothing);
      expect(find.text('Только оценка · 0'), findsWidgets);
      await tester.tap(find.byKey(const ValueKey('clear-review-search')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('review-entry-1')), findsOneWidget);
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('review-entry-2')),
        160,
        scrollable: reviewsListScrollable,
      );
      expect(find.byKey(const ValueKey('review-entry-2')), findsOneWidget);
      await tester.enterText(
        find.byKey(const ValueKey('review-search')),
        'Perfect',
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('review-entry-3')), findsOneWidget);
      expect(find.byKey(const ValueKey('review-entry-1')), findsNothing);
    },
  );

  testWidgets(
    'Filters and empty states explain which personal entry is missing',
    (tester) async {
      final container = await makeDiary();
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: ReviewsScreen()),
        ),
      );
      await tester.pumpAndSettle();
      await tapKey(tester, 'review-filter-ratingOnly');
      expect(find.byKey(const ValueKey('review-entry-2')), findsOneWidget);
      expect(find.byKey(const ValueKey('review-entry-1')), findsNothing);
      await tapKey(tester, 'review-filter-withText');
      expect(find.byKey(const ValueKey('review-entry-1')), findsOneWidget);
      expect(find.byKey(const ValueKey('review-entry-2')), findsNothing);
      await tester.enterText(
        find.byKey(const ValueKey('review-search')),
        'this movie is missing',
      );
      await tester.pumpAndSettle();
      expect(find.text('Ничего не найдено'), findsOneWidget);
      expect(
        find.text('Попробуй изменить запрос или очистить поиск.'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('An empty diary has a tailored, useful personal-diary state', (
    tester,
  ) async {
    final container = ProviderContainer(overrides: staticCatalogOverrides);
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: ReviewsScreen()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Пока нет отзывов и оценок.'), findsOneWidget);
    expect(find.textContaining('Поставь оценку'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Choosing a review opens its movie and scrolls to the hydrated diary editor',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final container = await makeDiary();
      addTearDown(container.dispose);
      final router = buildAppRouter(initialLocation: '/reviews');
      addTearDown(router.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();
      await tapKey(tester, 'review-entry-2');
      expect(find.byType(MovieDetailsScreen), findsOneWidget);
      expect(
        tester
            .widget<MovieDetailsScreen>(find.byType(MovieDetailsScreen))
            .movie
            .id,
        sampleMovies[1].id,
      );
      expect(find.text('6/10'), findsOneWidget);
      final editorHeading = tester.getCenter(find.text('Моя оценка'));
      expect(
        editorHeading.dy,
        lessThan(tester.getSize(find.byType(Scaffold).last).height / 2),
      );
      expect(tester.takeException(), isNull);
    },
  );

  for (final size in [
    const Size(320, 820),
    const Size(430, 932),
    const Size(1024, 768),
  ]) {
    for (final brightness in Brightness.values) {
      testWidgets('Review list fits ${size.width} ${brightness.name} theme', (
        tester,
      ) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final container = await makeDiary();
        addTearDown(container.dispose);
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              theme: brightness == Brightness.dark
                  ? AppTheme.darkTheme
                  : AppTheme.lightTheme,
              home: const ReviewsScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final exception = tester.takeException();
        expect(exception, isNull);
        expect(find.byType(OverflowBar), findsNothing);
        expect(find.byKey(const ValueKey('review-search')), findsOneWidget);
      });
    }
  }
}
