import 'package:flutter/material.dart';

import '../sample_data/movies.dart';
import '../widgets/movie_list_tile.dart';

class WatchlistScreen extends StatelessWidget {
  const WatchlistScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
            'Демонстрационные списки. Изменение коллекции появится позже.',
          ),
          const SizedBox(height: 24),
          Text(
            'Хочу посмотреть',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          MovieListTile(movie: sampleMovies[1]),
          MovieListTile(movie: sampleMovies[2]),
          const SizedBox(height: 24),
          Text('Просмотрено', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          MovieListTile(movie: sampleMovies[0]),
          const SizedBox(height: 24),
          Text('Избранное', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          MovieListTile(movie: sampleMovies[3]),
        ],
      ),
    );
  }
}
