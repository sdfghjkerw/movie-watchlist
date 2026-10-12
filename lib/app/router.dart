import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../domain/models/movie.dart';
import '../presentation/localization/app_strings.dart';
import '../presentation/screens/home_screen.dart';
import '../presentation/screens/auth_screen.dart';
import '../presentation/screens/cloud_account_screen.dart';
import '../presentation/screens/main_screen.dart';
import '../presentation/screens/movie_details_screen.dart';
import '../presentation/screens/profile_screen.dart';
import '../presentation/screens/reviews_screen.dart';
import '../presentation/screens/search_screen.dart';
import '../presentation/screens/settings_screen.dart';
import '../presentation/screens/watchlist_screen.dart';
import '../presentation/state/diary_controller.dart';
import '../presentation/state/watchlist_controller.dart';
import 'firebase_providers.dart';
import 'providers.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final refreshListenable = ValueNotifier<int>(0);
  final authSubscription = ref.listen(authStateProvider, (_, _) {
    refreshListenable.value++;
  });
  final router = buildAppRouter(
    refreshListenable: refreshListenable,
    isAuthenticated: () =>
        ref.read(authStateProvider).whenOrNull(data: (user) => user != null) ??
        false,
  );
  ref.onDispose(() {
    authSubscription.close();
    router.dispose();
    refreshListenable.dispose();
  });
  return router;
});

GoRouter buildAppRouter({
  String initialLocation = '/home',
  bool Function()? isAuthenticated,
  Listenable? refreshListenable,
}) {
  final signedIn = isAuthenticated ?? () => false;
  return GoRouter(
    initialLocation: initialLocation,
    refreshListenable: refreshListenable,
    routes: [
      GoRoute(path: '/', redirect: (_, _) => '/home'),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            MainScreen(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/home', builder: (_, _) => const HomeScreen()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/search', builder: (_, _) => const SearchScreen()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/collection',
                builder: (_, _) => const WatchlistScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/reviews',
                builder: (_, _) => const ReviewsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (_, _) => const ProfileScreen(),
                routes: [
                  GoRoute(
                    path: 'settings',
                    builder: (_, _) => const SettingsScreen(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/sign-in',
        redirect: (_, state) {
          if (!signedIn()) return null;
          return _safeRedirect(state.uri.queryParameters['from']) ?? '/account';
        },
        builder: (_, state) => SignInScreen(
          redirectPath: _safeRedirect(state.uri.queryParameters['from']),
        ),
      ),
      GoRoute(
        path: '/account',
        redirect: (_, state) {
          if (signedIn()) return null;
          return Uri(
            path: '/sign-in',
            queryParameters: {'from': state.uri.toString()},
          ).toString();
        },
        builder: (_, _) => const CloudAccountScreen(),
      ),
      GoRoute(
        path: '/movie/:id',
        // Details are addressable by ID (also on web); malformed IDs cannot
        // enter a page whose data provider requires a positive TMDB identifier.
        redirect: (_, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '');
          return id == null || id <= 0 ? '/home' : null;
        },
        builder: (context, state) => MovieRouteScreen(
          movieId: int.parse(state.pathParameters['id']!),
          movie: state.extra is Movie ? state.extra! as Movie : null,
          focusDiary: state.uri.queryParameters['focusDiary'] == 'true',
        ),
      ),
    ],
    errorBuilder: (context, state) =>
        _UnknownRouteScreen(message: state.error?.toString()),
  );
}

String? _safeRedirect(String? path) =>
    path != null && path.startsWith('/') && !path.startsWith('//')
    ? path
    : null;

class MovieRouteScreen extends ConsumerWidget {
  const MovieRouteScreen({
    super.key,
    required this.movieId,
    this.movie,
    this.focusDiary = false,
  });

  final int movieId;
  final Movie? movie;
  final bool focusDiary;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final routeMovie = movie ?? _findKnownMovie(ref, movieId);
    if (routeMovie != null) {
      return MovieDetailsScreen(movie: routeMovie, focusDiary: focusDiary);
    }

    final details = ref.watch(movieDetailsProvider(movieId));
    return details.when(
      data: (resolvedMovie) =>
          MovieDetailsScreen(movie: resolvedMovie, focusDiary: focusDiary),
      loading: () => Scaffold(
        appBar: AppBar(leading: const BackButton()),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(
        appBar: AppBar(leading: const BackButton()),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(error.toString(), textAlign: TextAlign.center),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () =>
                      ref.invalidate(movieDetailsProvider(movieId)),
                  child: Text('Повторить'.tr(context)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Movie? _findKnownMovie(WidgetRef ref, int id) {
    for (final movie in ref.read(watchlistProvider)) {
      if (movie.id == id) return movie;
    }
    for (final entry in ref.read(diaryProvider)) {
      if (entry.movie.id == id) return entry.movie;
    }
    return ref
        .read(catalogProvider)
        .whenOrNull(
          data: (movies) {
            for (final movie in movies) {
              if (movie.id == id) return movie;
            }
            return null;
          },
        );
  }
}

class _UnknownRouteScreen extends StatelessWidget {
  const _UnknownRouteScreen({this.message});
  final String? message;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text('Страница не найдена'.tr(context))),
    body: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message ?? 'Неизвестный маршрут'.tr(context)),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: () => context.go('/home'),
            child: Text('На главную'.tr(context)),
          ),
        ],
      ),
    ),
  );
}
