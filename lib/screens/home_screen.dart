import 'package:flutter/material.dart';

import '../sample_data/movies.dart';
import 'movie_details_screen.dart';
import 'watchlist_screen.dart';
import '../widgets/movie_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const movies = sampleMovies;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'movie watchlist',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.tune_rounded),
            tooltip: 'Настройки',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          Text(
            'Твоё следующее\nкиновпечатление.',
            style: Theme.of(context).textTheme.headlineMedium
                ?.copyWith(fontWeight: FontWeight.bold, height: 1.15),
          ),
          const SizedBox(height: 12),
          Text(
            'Находи фильмы. Сохраняй моменты.',
            style: TextStyle(color: colors.onSurface.withValues(alpha: 0.65)),
          ),
          const SizedBox(height: 28),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Выбрали для тебя',
                  style: Theme.of(context).textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'ПОДБОРКА',
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
            child: ListView.separated(
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
                        builder: (_) => MovieDetailsScreen(movie: movie),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'Твоя киноистория начинается здесь',
            style: Theme.of(context).textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Добавляй фильмы в список просмотра, '
            'ставь оценки и сохраняй свои впечатления.',
            style: TextStyle(
              height: 1.5,
              color: colors.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 18),
          OutlinedButton.icon(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const WatchlistScreen()),
            ),
            icon: const Icon(Icons.bookmark_add_outlined),
            label: const Text('Мой список просмотра'),
          ),
        ],
      ),
    );
  }
}
