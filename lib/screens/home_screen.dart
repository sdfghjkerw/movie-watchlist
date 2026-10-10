import 'package:flutter/material.dart';

import '../models/movie.dart';
import '../widgets/movie_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const movies = [
    Movie(
      id: 1,
      title: 'Interstellar',
      year: 2014,
      genre: 'Sci-Fi · Drama',
      rating: 8.7,
      emoji: '🚀',
      description:
          'Команда исследователей отправляется за пределы Солнечной системы '
          'в поисках нового дома для человечества.',
    ),
    Movie(
      id: 2,
      title: 'The Grand Budapest Hotel',
      year: 2014,
      genre: 'Comedy · Adventure',
      rating: 8.1,
      emoji: '🏨',
      description:
          'История консьержа знаменитого отеля и его молодого помощника '
          'на фоне необыкновенных событий в Европе.',
    ),
    Movie(
      id: 3,
      title: 'Perfect Days',
      year: 2023,
      genre: 'Drama',
      rating: 7.9,
      emoji: '🌿',
      description:
          'Тихая история о повседневной жизни, привычках и красоте '
          'маленьких моментов.',
    ),
    Movie(
      id: 4,
      title: 'La La Land',
      year: 2016,
      genre: 'Musical · Romance',
      rating: 8.0,
      emoji: '🎹',
      description:
          'Музыкант и начинающая актриса пытаются найти баланс '
          'между любовью и своими мечтами.',
    ),
  ];

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
              Text(
                'Выбрали для тебя',
                style: Theme.of(context).textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const Spacer(),
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
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Выбран фильм: ${movie.title}')),
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
            onPressed: () {},
            icon: const Icon(Icons.bookmark_add_outlined),
            label: const Text('Мой список просмотра'),
          ),
        ],
      ),
    );
  }
}
