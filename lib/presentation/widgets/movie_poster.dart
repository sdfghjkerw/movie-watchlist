import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';

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
    return LayoutBuilder(
      builder: (context, constraints) {
        final scale = MediaQuery.devicePixelRatioOf(context);
        final width = constraints.maxWidth.isFinite
            ? (constraints.maxWidth * scale).round().clamp(1, 1200)
            : 500;
        final height = constraints.maxHeight.isFinite
            ? (constraints.maxHeight * scale).round().clamp(1, 1800)
            : 750;
        final networkImage = CachedNetworkImage(
          imageUrl: url!,
          fit: BoxFit.cover,
          memCacheWidth: width,
          memCacheHeight: height,
          maxWidthDiskCache: 700,
          maxHeightDiskCache: 1050,
          placeholder: (_, _) => placeholder,
          errorWidget: (_, _, _) => placeholder,
          fadeInDuration: const Duration(milliseconds: 160),
          fadeOutDuration: const Duration(milliseconds: 80),
        );
        if (cache == null) return networkImage;
        return FutureBuilder(
          future: cache.load(url!),
          builder: (context, snapshot) {
            final bytes = snapshot.data;
            if (bytes != null) {
              return Image.memory(
                bytes,
                fit: BoxFit.cover,
                cacheWidth: width,
                cacheHeight: height,
                errorBuilder: (_, _, _) => placeholder,
              );
            }
            return snapshot.connectionState == ConnectionState.done
                ? networkImage
                : placeholder;
          },
        );
      },
    );
  }
}
