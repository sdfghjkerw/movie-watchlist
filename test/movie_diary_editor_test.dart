import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movie_watchlist/app/providers.dart';
import 'package:movie_watchlist/data/repositories/diary_repositories.dart';
import 'package:movie_watchlist/domain/models/diary_entry.dart';
import 'package:movie_watchlist/presentation/screens/movie_details_screen.dart';
import 'package:movie_watchlist/presentation/state/diary_controller.dart';
import 'package:movie_watchlist/sample_data/movies.dart';
import 'package:movie_watchlist/theme/app_theme.dart';

import 'catalog_fixture.dart';

class ControlledDiary extends InMemoryDiaryRepository {
  bool fail = false;
  Completer<void>? gate;
  @override
  Future<void> save(DiaryEntry entry) async {
    if (gate != null) await gate!.future;
    if (fail) throw StateError('Disk full');
    await super.save(entry);
  }
}

void main() {
  test('Queued field updates preserve all independent fields and recover after failure', () async {
    final repository = ControlledDiary();
    final movie = sampleMovies.first;
    final date = DateTime(2026, 10, 11);
    await repository.save(
      DiaryEntry(movie: movie, score: 8, review: 'Existing', watchedAt: date),
    );
    final container = ProviderContainer(
      overrides: [diaryRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
    final controller = container.read(diaryProvider.notifier);
    repository.gate = Completer<void>();
    final first = controller.update(movie, review: 'Edited');
    final second = controller.update(movie, favorite: true);
    repository.gate!.complete();
    await Future.wait([first, second]);
    var entry = container.read(diaryProvider).single;
    expect(entry.review, 'Edited');
    expect(entry.score, 8);
    expect(entry.favorite, isTrue);
    expect(entry.watchedAt, date);
    repository.fail = true;
    await expectLater(
      controller.update(movie, review: 'Lost'),
      throwsStateError,
    );
    repository.fail = false;
    await controller.update(movie, updateScore: true, score: null);
    entry = container.read(diaryProvider).single;
    expect(entry.score, isNull);
    expect(entry.review, 'Edited');
    expect(entry.favorite, isTrue);
    expect(entry.watchedAt, date);
  });

  Future<void> tap(WidgetTester tester, String key) async {
    await tester.pumpAndSettle();
    final finder = find.byKey(ValueKey(key));
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  for (final dark in [true, false]) {
    testWidgets(
      'Inline editor hydrates, preserves drafts on failure and retries (${dark ? 'dark' : 'light'})',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final repository = ControlledDiary();
        await repository.save(
          DiaryEntry(
            movie: sampleMovies.first,
            score: 7,
            review: 'Saved review',
            favorite: true,
          ),
        );
        final container = ProviderContainer(
          overrides: [
            ...staticCatalogOverrides,
            diaryRepositoryProvider.overrideWithValue(repository),
          ],
        );
        addTearDown(container.dispose);
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              theme: dark ? AppTheme.darkTheme : AppTheme.lightTheme,
              home: MovieDetailsScreen(movie: sampleMovies.first),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('7/10'), findsOneWidget);
        expect(
          tester
              .widget<TextField>(find.byKey(const ValueKey('review-text')))
              .controller!
              .text,
          'Saved review',
        );
        await tester.ensureVisible(find.byKey(const ValueKey('review-text')));
        await tester.enterText(
          find.byKey(const ValueKey('review-text')),
          'New review',
        );
        repository.fail = true;
        await tap(tester, 'save-diary');
        expect(
          find.text('Не удалось сохранить. Попробуй ещё раз.'),
          findsOneWidget,
        );
        expect(
          tester
              .widget<TextField>(find.byKey(const ValueKey('review-text')))
              .controller!
              .text,
          'New review',
        );
        expect(container.read(diaryProvider).single.review, 'Saved review');
        repository.fail = false;
        repository.gate = Completer<void>();
        final saving = find.byKey(const ValueKey('save-diary'));
        await tester.tap(saving);
        await tester.pump();
        expect(find.text('Сохраняем…'), findsOneWidget);
        expect(
          tester
              .widget<TextField>(find.byKey(const ValueKey('review-text')))
              .readOnly,
          isTrue,
        );
        expect(tester.widget<FilledButton>(saving).onPressed, isNull);
        repository.gate!.complete();
        await tester.pumpAndSettle();
        repository.gate = null;
        expect(container.read(diaryProvider).single.score, 7);
        expect(container.read(diaryProvider).single.review, 'New review');
        final textController = tester
            .widget<TextField>(find.byKey(const ValueKey('review-text')))
            .controller!;
        textController.selection = const TextSelection.collapsed(offset: 0);
        await tester.pumpAndSettle();
        expect(find.text('Сохранено'), findsOneWidget);
        await tap(tester, 'clear-score');
        await tap(tester, 'save-diary');
        expect(container.read(diaryProvider).single.score, isNull);
        expect(container.read(diaryProvider).single.review, 'New review');
        expect(container.read(diaryProvider).single.favorite, isTrue);
        await tap(tester, 'rating-star-10');
        await tap(tester, 'save-diary');
        expect(container.read(diaryProvider).single.score, 10);
        expect(container.read(diaryProvider).single.review, 'New review');
        expect(find.byType(AlertDialog), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('Leaving with a draft requires an explicit inline decision', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: staticCatalogOverrides,
        child: MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) =>
                        MovieDetailsScreen(movie: sampleMovies.first),
                  ),
                ),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tap(tester, 'rating-star-8');
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.text('Сохранить изменения перед выходом?'), findsOneWidget);
    expect(find.byType(AlertDialog), findsNothing);
    await tap(tester, 'stay-diary');
    expect(find.text('8/10'), findsOneWidget);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    await tap(tester, 'save-and-exit');
    expect(find.text('Open'), findsOneWidget);
  });
}
