import 'package:flutter/material.dart';

import '../../domain/models/movie.dart';
import 'movie_poster.dart';
import '../screens/movie_details_screen.dart';
import '../localization/app_strings.dart';

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
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: MoviePoster(url: movie.posterUrl),
          ),
        ),
        title: Text(movie.title),
        subtitle: Text(
          '${movie.year ?? 'Год неизвестен'.tr(context)} · ${movie.genre.tr(context)}',
        ),
        trailing: Text('★ ${movie.rating?.toStringAsFixed(1) ?? '—'}'),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => MovieDetailsScreen(movie: movie),
          ),
        ),
      ),
    );
  }
}
