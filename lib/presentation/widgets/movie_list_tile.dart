import 'package:flutter/material.dart';

import '../../domain/models/movie.dart';
import '../screens/movie_details_screen.dart';

class MovieListTile extends StatelessWidget {
  const MovieListTile({super.key, required this.movie});

  final Movie movie;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: Container(
          width: 48,
          height: 64,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.local_movies_outlined),
        ),
        title: Text(movie.title),
        subtitle: Text('${movie.year} · ${movie.genre}'),
        trailing: Text('★ ${movie.rating.toStringAsFixed(1)}'),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => MovieDetailsScreen(movie: movie),
          ),
        ),
      ),
    );
  }
}
