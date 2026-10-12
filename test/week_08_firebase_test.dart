import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movie_watchlist/app/firebase_configuration.dart';
import 'package:movie_watchlist/app/firebase_providers.dart';
import 'package:movie_watchlist/app/router.dart';
import 'package:movie_watchlist/presentation/screens/auth_screen.dart';
import 'package:movie_watchlist/presentation/screens/cloud_account_screen.dart';

void main() {
  test('Firebase configuration maps public identifiers by platform', () {
    final configuration = FirebaseLocalConfiguration.fromJson({
      'platforms': {
        'web': {
          'apiKey': 'public-web-key',
          'appId': 'web-app-id',
          'messagingSenderId': 'sender-id',
          'projectId': 'movie-watchlist-test',
          'authDomain': 'movie-watchlist-test.firebaseapp.com',
        },
      },
      'googleWebClientId': 'web-client.apps.googleusercontent.com',
      'vapidKey': 'public-vapid-key',
    });

    expect(configuration.platforms['web']?['appId'], 'web-app-id');
    expect(
      configuration.googleWebClientId,
      'web-client.apps.googleusercontent.com',
    );
    expect(configuration.vapidKey, 'public-vapid-key');
  });

  testWidgets('Protected cloud account redirects to sign-in with return path', (
    tester,
  ) async {
    final router = buildAppRouter(initialLocation: '/account');
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [firebaseEnabledProvider.overrideWithValue(false)],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(SignInScreen), findsOneWidget);
    expect(router.routeInformationProvider.value.uri.path, '/sign-in');
    expect(
      router.routeInformationProvider.value.uri.queryParameters['from'],
      '/account',
    );
    expect(
      find.text('Firebase пока не настроен для этого устройства.'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'A newly authenticated session is redirected to its destination',
    (tester) async {
      var signedIn = false;
      final refresh = ValueNotifier<int>(0);
      addTearDown(refresh.dispose);
      final router = buildAppRouter(
        initialLocation: '/account',
        isAuthenticated: () => signedIn,
        refreshListenable: refresh,
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [firebaseEnabledProvider.overrideWithValue(false)],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(SignInScreen), findsOneWidget);

      signedIn = true;
      refresh.value++;
      await tester.pumpAndSettle();

      expect(find.byType(CloudAccountScreen), findsOneWidget);
      expect(router.routeInformationProvider.value.uri.path, '/account');
      expect(find.byTooltip('На главную'), findsOneWidget);

      await tester.tap(find.byTooltip('На главную'));
      await tester.pumpAndSettle();

      expect(router.routeInformationProvider.value.uri.path, '/home');
      expect(tester.takeException(), isNull);
    },
  );
}
