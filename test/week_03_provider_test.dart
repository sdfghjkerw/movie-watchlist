import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:movie_watchlist/learning/week_03/provider_demo.dart';
import 'package:movie_watchlist/main.dart';
import 'package:movie_watchlist/sample_data/movies.dart';
import 'package:movie_watchlist/state/watchlist_model.dart';
import 'package:movie_watchlist/widgets/movie_card.dart';

void main() {
  test('Watchlist has unique IDs, immutable output and notifies changes', () {
    final model = WatchlistModel();
    addTearDown(model.dispose);
    var notifications = 0;
    model.addListener(() => notifications++);
    model.toggle(sampleMovies.first);
    expect(model.movies, hasLength(1));
    expect(() => model.movies.clear(), throwsUnsupportedError);
    model.remove(999);
    expect(notifications, 1);
    model.toggle(sampleMovies.first);
    expect(model.movies, isEmpty);
    expect(notifications, 2);
  });

  testWidgets('Provider demo adds and removes the same movie', (tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => WatchlistModel(),
        child: const MaterialApp(home: ProviderDemo()),
      ),
    );
    expect(find.text('В списке: 0'), findsOneWidget);
    await tester.tap(find.text('Добавить'));
    await tester.pump();
    expect(find.text('В списке: 1'), findsOneWidget);
    await tester.tap(find.text('Удалить'));
    await tester.pump();
    expect(find.text('В списке: 0'), findsOneWidget);
  });

  testWidgets('Details and collection share current app state across routes', (
    tester,
  ) async {
    await tester.pumpWidget(const MovieWatchlistApp());
    await tester.tap(find.byType(MovieCard).first);
    await tester.pumpAndSettle();
    final toggle = find.byKey(const ValueKey('toggle-watchlist'));
    await tester.scrollUntilVisible(
      toggle,
      200,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(toggle);
    await tester.pump();
    expect(find.text('Удалить из списка'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Коллекция'));
    await tester.pumpAndSettle();
    final remove = find.byKey(const ValueKey('remove-1'));
    await tester.scrollUntilVisible(
      remove,
      200,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(remove);
    await tester.pumpAndSettle();
    expect(
      find.text('Пока нет фильмов. Добавь фильм на его странице.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Главная'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(MovieCard).first);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      toggle,
      200,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('В список просмотра'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
