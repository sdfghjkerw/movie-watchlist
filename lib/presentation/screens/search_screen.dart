import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../domain/models/movie.dart';
import '../../domain/repositories/catalog_repository.dart';
import '../localization/app_strings.dart';
import '../state/search_controller.dart';
import '../widgets/catalog_status.dart';
import '../widgets/movie_list_tile.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _text = TextEditingController();

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final results = ref.watch(searchProvider);
    final repository = ref.watch(catalogRepositoryProvider);
    final controller = ref.read(searchProvider.notifier);
    final query = _text.text.trim();
    final movies = results.asData?.value ?? const <Movie>[];
    final hasCacheNotice =
        repository is CachedCatalogRepository &&
        repository.searchUsesCache(query);
    final Widget? status = query.isEmpty
        ? CatalogStatus(
            message: 'Введи название фильма для поиска в TMDB.'.tr(context),
          )
        : results.isLoading
        ? const Center(child: CircularProgressIndicator())
        : results.hasError
        ? CatalogStatus(
            message: results.error.toString(),
            onRetry: () => unawaited(controller.refresh()),
          )
        : movies.isEmpty
        ? CatalogStatus(
            message: 'Ничего не найдено. Попробуй другое название.'.tr(context),
          )
        : null;
    final hasFooter =
        status == null &&
        (controller.hasMore ||
            controller.isLoadingMore ||
            controller.loadMoreError != null);
    final int itemCount =
        1 +
        (hasCacheNotice ? 1 : 0) +
        (status == null ? movies.length : 1) +
        (hasFooter ? 1 : 0);

    return Scaffold(
      appBar: AppBar(title: Text('Поиск фильмов'.tr(context))),
      body: LayoutBuilder(
        builder: (context, constraints) => RefreshIndicator(
          onRefresh: controller.refresh,
          child: NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              if (notification.metrics.axis == Axis.vertical &&
                  notification.metrics.extentAfter < 480 &&
                  controller.hasMore &&
                  !controller.isLoadingMore &&
                  controller.loadMoreError == null &&
                  query.isNotEmpty) {
                unawaited(controller.loadMore());
              }
              return false;
            },
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.symmetric(
                horizontal: constraints.maxWidth > 880
                    ? (constraints.maxWidth - 760) / 2
                    : 20,
                vertical: 20,
              ),
              itemCount: itemCount,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: TextField(
                      controller: _text,
                      onChanged: (value) {
                        ref.read(searchProvider.notifier).setQuery(value);
                        setState(() {});
                      },
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.search),
                        hintText: 'Название фильма'.tr(context),
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          tooltip: 'Очистить'.tr(context),
                          icon: const Icon(Icons.close),
                          onPressed: () {
                            _text.clear();
                            ref.read(searchProvider.notifier).setQuery('');
                            setState(() {});
                          },
                        ),
                      ),
                    ),
                  );
                }

                var contentIndex = index - 1;
                if (hasCacheNotice) {
                  if (contentIndex == 0) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: Text('Сохранённые результаты поиска.'.tr(context)),
                    );
                  }
                  contentIndex--;
                }
                if (status != null) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: status,
                  );
                }
                if (contentIndex < movies.length) {
                  return MovieListTile(movie: movies[contentIndex]);
                }
                if (controller.loadMoreError != null) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: TextButton.icon(
                        onPressed: () => unawaited(controller.loadMore()),
                        icon: const Icon(Icons.refresh),
                        label: Text('Повторить загрузку'.tr(context)),
                      ),
                    ),
                  );
                }
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 18),
                  child: Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
