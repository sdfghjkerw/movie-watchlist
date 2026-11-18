import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../domain/models/movie.dart';
import '../widgets/movie_card.dart';
import '../widgets/catalog_status.dart';
import '../localization/app_strings.dart';
import '../../domain/repositories/catalog_repository.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    final catalog = ref.watch(catalogProvider);
    final repository = ref.watch(catalogRepositoryProvider);
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'movie watchlist',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            onPressed: () => context.push('/profile/settings'),
            icon: const Icon(Icons.tune_rounded),
            tooltip: 'Настройки'.tr(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          try {
            await ref.read(catalogProvider.notifier).refresh();
          } catch (_) {
            /* Ошибка отображается через catalog.when. */
          }
        },
        child: LayoutBuilder(
          builder: (context, constraints) => ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(
              constraints.maxWidth > 1240
                  ? (constraints.maxWidth - 1120) / 2
                  : 20,
              8,
              constraints.maxWidth > 1240
                  ? (constraints.maxWidth - 1120) / 2
                  : 20,
              28,
            ),
            children: [
              if (repository is CachedCatalogRepository &&
                  repository.cacheNotice != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(repository.cacheNotice!.tr(context)),
                ),
              Text(
                'Твоё следующее\nкиновпечатление.'.tr(context),
                style: Theme.of(context).textTheme.headlineMedium
                    ?.copyWith(fontWeight: FontWeight.bold, height: 1.15),
              ),
              const SizedBox(height: 12),
              Text(
                'Находи фильмы. Сохраняй моменты.'.tr(context),
                style: TextStyle(
                  color: colors.onSurface.withValues(alpha: 0.65),
                ),
              ),
              const SizedBox(height: 28),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Выбрали для тебя'.tr(context),
                      style: Theme.of(context).textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'ПОДБОРКА'.tr(context),
                    style: TextStyle(
                      color: colors.secondary,
                      fontSize: 10,
                      letterSpacing: 1.4,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 260,
                child: catalog.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, _) => CatalogStatus(
                    message: error.toString(),
                    onRetry: () => ref.invalidate(catalogProvider),
                  ),
                  data: (movies) => movies.isEmpty
                      ? CatalogStatus(message: 'Каталог пока пуст.'.tr(context))
                      : _featuredMovies(movies),
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'Твоя киноистория начинается здесь'.tr(context),
                style: Theme.of(context).textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Добавляй фильмы в список просмотра, ставь оценки и сохраняй свои впечатления.'
                    .tr(context),
                style: TextStyle(
                  height: 1.5,
                  color: colors.onSurface.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 18),
              OutlinedButton.icon(
                onPressed: () => context.go('/collection'),
                icon: const Icon(Icons.bookmark_add_outlined),
                label: Text('Мой список просмотра'.tr(context)),
              ),
              const SizedBox(height: 16),
              Text(
                'Данные: TMDB. Приложение использует TMDB API и не одобрено или сертифицировано TMDB.'
                    .tr(context),
                style: TextStyle(fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _featuredMovies(List<Movie> movies) {
    final controller = ref.read(catalogProvider.notifier);
    final showFooter =
        controller.hasMore ||
        controller.isLoadingMore ||
        controller.loadMoreError != null;
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification.metrics.axis == Axis.horizontal &&
            notification.metrics.extentAfter < 420 &&
            controller.hasMore &&
            !controller.isLoadingMore &&
            controller.loadMoreError == null) {
          unawaited(controller.loadMore());
        }
        return false;
      },
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: movies.length + (showFooter ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == movies.length) {
            if (controller.loadMoreError != null) {
              return SizedBox(
                width: 170,
                child: Center(
                  child: TextButton.icon(
                    onPressed: () => unawaited(controller.loadMore()),
                    icon: const Icon(Icons.refresh),
                    label: Text('Повторить загрузку'.tr(context)),
                  ),
                ),
              );
            }
            return const SizedBox(
              width: 56,
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            );
          }
          final movie = movies[index];
          return Padding(
            padding: const EdgeInsets.only(right: 14),
            child: MovieCard(
              movie: movie,
              onTap: () => context.push('/movie/${movie.id}', extra: movie),
            ),
          );
        },
      ),
    );
  }
}
