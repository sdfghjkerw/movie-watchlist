import 'package:flutter/material.dart';

import '../../domain/models/movie.dart';
import 'movie_poster.dart';
import '../localization/app_strings.dart';

class MovieCard extends StatelessWidget {
  const MovieCard({super.key, required this.movie, required this.onTap});

  final Movie movie;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return SizedBox(
      width: 145,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: MoviePoster(url: movie.posterUrl),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              movie.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 3),
            Text(
              '${movie.year ?? 'Год неизвестен'.tr(context)} · ${movie.genre.tr(context)}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                color: colors.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 5),
            Row(
              children: [
                Icon(Icons.star_rounded, size: 15, color: colors.secondary),
                const SizedBox(width: 4),
                Text(
                  movie.rating?.toStringAsFixed(1) ?? '—',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
