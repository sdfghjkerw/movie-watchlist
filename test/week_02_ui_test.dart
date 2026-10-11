import 'package:flutter/material.dart';

import 'catalog_fixture.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:movie_watchlist/screens/main_screen.dart';
import 'package:movie_watchlist/screens/movie_details_screen.dart';
import 'package:movie_watchlist/theme/app_theme.dart';
import 'package:movie_watchlist/widgets/movie_card.dart';

void main() {
  for (final brightness in Brightness.values) {
    testWidgets('Static screens and details work in ${brightness.name} theme', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        ProviderScope(
          overrides: staticCatalogOverrides,
          child: MaterialApp(
            theme: brightness == Brightness.dark
                ? AppTheme.darkTheme
                : AppTheme.lightTheme,
            home: const MainScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();
      await tester.tap(find.byType(MovieCard).first);
      await tester.pumpAndSettle();
      expect(find.byType(MovieDetailsScreen), findsOneWidget);
      expect(find.text('Interstellar'), findsOneWidget);
      expect(find.text('Постер пока недоступен'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Поиск'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Perfect Days');
      await tester.pump(const Duration(milliseconds: 450));
      await tester.pumpAndSettle();
      expect(
        tester.widget<TextField>(find.byType(TextField)).readOnly,
        isFalse,
      );
      await tester.tap(find.text('Perfect Days').last);
      await tester.pumpAndSettle();
      expect(find.text('Perfect Days'), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();

      await tester.tap(find.text('Коллекция'));
      await tester.pumpAndSettle();
      expect(find.text('Хочу посмотреть'), findsOneWidget);
      expect(find.text('Просмотрено'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
