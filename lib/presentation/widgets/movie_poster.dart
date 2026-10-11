import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';

class MoviePoster extends ConsumerWidget {
  const MoviePoster({super.key, this.url});
  final String? url;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final placeholder = ColoredBox(
      color: colors.surfaceContainerHighest,
      child: Center(
        child: Icon(
          Icons.local_movies_outlined,
          color: colors.primary,
          size: 48,
        ),
      ),
    );
    if (url == null) return placeholder;
    final cache = ref.watch(posterCacheProvider);
    if (cache != null) {
      return FutureBuilder(
        future: cache.load(url!),
        builder: (context, snapshot) => snapshot.data == null
            ? placeholder
            : Image.memory(
                snapshot.data!,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => placeholder,
              ),
      );
    }
    return Image.network(
      url!,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => placeholder,
      loadingBuilder: (_, child, progress) =>
          progress == null ? child : placeholder,
    );
  }
}
