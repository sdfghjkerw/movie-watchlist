import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movie_watchlist/app/providers.dart';
import 'package:movie_watchlist/domain/models/movie.dart';
import 'package:movie_watchlist/domain/models/catalog_exception.dart';
import 'package:movie_watchlist/domain/repositories/catalog_repository.dart';
import 'package:movie_watchlist/presentation/screens/home_screen.dart';
import 'package:movie_watchlist/presentation/screens/search_screen.dart';
import 'package:movie_watchlist/widgets/movie_card.dart';
import 'package:movie_watchlist/sample_data/movies.dart';

class ControlledCatalog implements CatalogRepository {
  final loads = <Completer<List<Movie>>>[];
  final searches = <String, Completer<List<Movie>>>{};
  @override
  Future<List<Movie>> fetchMovies() {
    final pending = Completer<List<Movie>>();
    loads.add(pending);
    return pending.future;
  }

  @override
  Future<List<Movie>> searchMovies(String query) {
    final pending = Completer<List<Movie>>();
    searches[query] = pending;
    return pending.future;
  }

  @override
  Future<Movie> fetchMovie(int id) async => sampleMovies.first;
}

void main() {
  testWidgets('Debounce sends only final input and ignores stale responses', (
    tester,
  ) async {
    final repository = ControlledCatalog();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [catalogRepositoryProvider.overrideWithValue(repository)],
        child: const MaterialApp(home: SearchScreen()),
      ),
    );
    await tester.enterText(find.byType(TextField), 'old');
    await tester.pump(const Duration(milliseconds: 399));
    expect(repository.searches, isEmpty);
    await tester.pump(const Duration(milliseconds: 1));
    expect(repository.searches.keys, ['old']);
    await tester.enterText(find.byType(TextField), 'ne');
    await tester.pump(const Duration(milliseconds: 200));
    await tester.enterText(find.byType(TextField), 'new');
    await tester.pump(const Duration(milliseconds: 400));
    expect(repository.searches.keys, ['old', 'new']);
    repository.searches['new']!.complete([sampleMovies[2]]);
    await tester.pumpAndSettle();
    expect(find.text('Perfect Days'), findsOneWidget);
    repository.searches['old']!.complete([sampleMovies.first]);
    await tester.pumpAndSettle();
    expect(find.text('Perfect Days'), findsOneWidget);
    expect(find.text('Interstellar'), findsNothing);
    await tester.tap(find.byTooltip('Очистить'));
    await tester.pumpAndSettle();
    expect(find.text('Perfect Days'), findsNothing);
  });

  testWidgets('Home displays loading, success, empty, error and refreshes', (
    tester,
  ) async {
    final repository = ControlledCatalog();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [catalogRepositoryProvider.overrideWithValue(repository)],
        child: const MaterialApp(home: HomeScreen()),
      ),
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    repository.loads.first.complete([sampleMovies.first]);
    await tester.pumpAndSettle();
    expect(find.byType(MovieCard), findsOneWidget);
    var refresh = tester
        .state<RefreshIndicatorState>(find.byType(RefreshIndicator))
        .show();
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    expect(repository.loads, hasLength(2));
    repository.loads.last.complete([]);
    await tester.pumpAndSettle();
    await refresh;
    expect(find.text('Каталог пока пуст.'), findsOneWidget);
    refresh = tester
        .state<RefreshIndicatorState>(find.byType(RefreshIndicator))
        .show();
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    repository.loads.last.completeError(const CatalogException('Нет сети'));
    await tester.pumpAndSettle();
    await refresh;
    expect(find.text('Нет сети'), findsOneWidget);
    expect(find.text('Повторить'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
