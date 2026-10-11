import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';

import '../../app/providers.dart';
import 'movie_details_screen.dart';
import 'watchlist_screen.dart';
import '../widgets/movie_card.dart';
import '../widgets/catalog_status.dart';
import 'profile_screen.dart';
import '../localization/app_strings.dart';
import '../../domain/repositories/catalog_repository.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const ProfileScreen()),
            ),
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
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
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
              style: TextStyle(color: colors.onSurface.withValues(alpha: 0.65)),
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
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => CatalogStatus(
                  message: error.toString(),
                  onRetry: () => ref.invalidate(catalogProvider),
                ),
                data: (movies) => movies.isEmpty
                    ? CatalogStatus(message: 'Каталог пока пуст.'.tr(context))
                    : ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: movies.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 14),
                        itemBuilder: (context, index) {
                          final movie = movies[index];

                          return MovieCard(
                            movie: movie,
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) =>
                                      MovieDetailsScreen(movie: movie),
                                ),
                              );
                            },
                          );
                        },
                      ),
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
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const WatchlistScreen(),
                ),
              ),
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
    );
  }
}
