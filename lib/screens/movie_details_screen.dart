import 'package:flutter/material.dart';

import '../models/movie.dart';

class MovieDetailsScreen extends StatelessWidget {
  const MovieDetailsScreen({super.key, required this.movie});

  final Movie movie;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('О фильме')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: SizedBox(
              width: 220,
              height: 300,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: colors.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      Icons.local_movies_outlined,
                      size: 72,
                      color: colors.primary,
                    ),
                  ),
                  Positioned(
                    right: 12,
                    top: 12,
                    child: Chip(
                      avatar: Icon(Icons.star_rounded, color: colors.secondary),
                      label: Text(movie.rating.toStringAsFixed(1)),
                    ),
                  ),
                  const Positioned(
                    bottom: 16,
                    left: 16,
                    right: 16,
                    child: Text(
                      'Постер пока недоступен',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(movie.title, style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          Row(
            children: [
              Text('${movie.year}'),
              const SizedBox(width: 12),
              Expanded(child: Text(movie.genre)),
            ],
          ),
          const SizedBox(height: 24),
          Text('О фильме', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(movie.description, style: const TextStyle(height: 1.5)),
          const SizedBox(height: 24),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FilledButton.icon(
                onPressed: null,
                icon: const Icon(Icons.bookmark_add_outlined),
                label: const Text('В список просмотра'),
              ),
              OutlinedButton.icon(
                onPressed: null,
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('Отметить просмотренным'),
              ),
              OutlinedButton.icon(
                onPressed: null,
                icon: const Icon(Icons.rate_review_outlined),
                label: const Text('Оценить и написать отзыв'),
              ),
              const SizedBox(height: 8),
              const Text('Статический макет. Личные действия пока недоступны.'),
            ],
          ),
        ],
      ),
    );
  }
}
