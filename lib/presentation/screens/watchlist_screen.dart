import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/watchlist_controller.dart';

import '../../app/providers.dart';
import '../widgets/movie_list_tile.dart';

class WatchlistScreen extends ConsumerWidget {
  const WatchlistScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final movies = ref.watch(watchlistProvider);
    final catalog = ref.watch(catalogProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Моя коллекция')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Твой личный кинодневник',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 12),
          const Text(
            'Список просмотра хранится в памяти до перезапуска. Остальные разделы — демонстрационные.',
          ),
          const SizedBox(height: 24),
          Text(
            'Хочу посмотреть',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          if (movies.isEmpty)
            const Text('Пока нет фильмов. Добавь фильм на его странице.'),
          for (final movie in movies)
            Column(
              children: [
                MovieListTile(movie: movie),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    key: ValueKey('remove-${movie.id}'),
                    onPressed: () =>
                        ref.read(watchlistProvider.notifier).remove(movie.id),
                    icon: const Icon(Icons.bookmark_remove_outlined),
                    label: const Text('Удалить из списка'),
                  ),
                ),
              ],
            ),
          const SizedBox(height: 24),
          Text('Просмотрено', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          if (catalog.isNotEmpty) MovieListTile(movie: catalog.first),
          const SizedBox(height: 24),
          Text('Избранное', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          if (catalog.length > 3) MovieListTile(movie: catalog[3]),
        ],
      ),
    );
  }
}
