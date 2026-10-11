import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movie_watchlist/app/router.dart';
import 'package:movie_watchlist/main.dart';

import 'catalog_fixture.dart';

void main() {
  testWidgets('Phone navigation preserves each tab state', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: staticCatalogOverrides,
        child: const MovieWatchlistApp(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(NavigationBar), findsOneWidget);

    await tester.tap(find.text('Поиск'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'Perfect Days');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Профиль'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Поиск'));
    await tester.pumpAndSettle();

    expect(
      tester.widget<TextField>(find.byType(TextField).first).controller!.text,
      'Perfect Days',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Tablet layout uses the persistent navigation rail', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1024, 768);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: staticCatalogOverrides,
        child: const MovieWatchlistApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Portrait tablet keeps the adaptive shell within its viewport', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(768, 1024);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: staticCatalogOverrides,
        child: const MovieWatchlistApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(NavigationRail), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Malformed movie parameter redirects to home', (tester) async {
    final router = buildAppRouter(initialLocation: '/movie/not-an-id');
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: staticCatalogOverrides,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Твоё следующее\nкиновпечатление.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
