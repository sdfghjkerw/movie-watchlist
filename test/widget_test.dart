import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'catalog_fixture.dart';

import 'package:movie_watchlist/main.dart';

void main() {
  testWidgets('App displays the home screen', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: staticCatalogOverrides,
        child: const MovieWatchlistApp(),
      ),
    );

    expect(find.text('movie watchlist'), findsOneWidget);
    expect(find.text('Выбрали для тебя'), findsOneWidget);
  });
}
