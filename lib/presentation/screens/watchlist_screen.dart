import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/watchlist_controller.dart';
import '../state/diary_controller.dart';
import '../widgets/movie_list_tile.dart';
import '../widgets/save_action.dart';
import '../localization/app_strings.dart';

class WatchlistScreen extends ConsumerWidget {
  const WatchlistScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final movies = ref.watch(watchlistProvider);
    final diary = ref.watch(diaryProvider);
    final watched = diary.where((entry) => entry.watchedAt != null).toList()
      ..sort((a, b) => b.watchedAt!.compareTo(a.watchedAt!));
    final favorites = diary.where((entry) => entry.favorite);
    return Scaffold(
      appBar: AppBar(title: Text('Моя коллекция'.tr(context))),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Твой личный кинодневник'.tr(context),
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 12),
          Text('Данные сохраняются на этом устройстве.'.tr(context)),
          const SizedBox(height: 24),
          Text(
            'Хочу посмотреть'.tr(context),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          if (movies.isEmpty)
            Text('Пока нет фильмов. Добавь фильм на его странице.'.tr(context)),
          for (final movie in movies)
            Column(
              children: [
                MovieListTile(movie: movie),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    key: ValueKey('remove-${movie.id}'),
                    onPressed: () => saveAction(
                      context,
                      () =>
                          ref.read(watchlistProvider.notifier).remove(movie.id),
                    ),
                    icon: const Icon(Icons.bookmark_remove_outlined),
                    label: Text('Удалить из списка'.tr(context)),
                  ),
                ),
              ],
            ),
          const SizedBox(height: 24),
          Text(
            'Просмотрено'.tr(context),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          if (watched.isEmpty) Text('Нет просмотренных фильмов.'.tr(context)),
          for (final entry in watched)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MovieListTile(movie: entry.movie),
                Text(
                  MaterialLocalizations.of(context)
                      .formatMediumDate(entry.watchedAt!),
                ),
              ],
            ),
          const SizedBox(height: 24),
          Text(
            'Избранное'.tr(context),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          if (favorites.isEmpty) Text('Нет избранных фильмов.'.tr(context)),
          for (final entry in favorites) MovieListTile(movie: entry.movie),
        ],
      ),
    );
  }
}
