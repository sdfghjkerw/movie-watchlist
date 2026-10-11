import '../localization/app_strings.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/search_controller.dart';
import '../widgets/catalog_status.dart';
import '../widgets/movie_list_tile.dart';
import '../../app/providers.dart';
import '../../domain/repositories/catalog_repository.dart';

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
    return Scaffold(
      appBar: AppBar(title: Text('Поиск фильмов'.tr(context))),
      body: RefreshIndicator(
        onRefresh: () => ref.read(searchProvider.notifier).refresh(),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          children: [
            TextField(
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
            const SizedBox(height: 24),
            if (repository is CachedCatalogRepository &&
                repository.searchUsesCache(_text.text))
              Text('Сохранённые результаты поиска.'.tr(context)),
            if (_text.text.trim().isEmpty)
              CatalogStatus(
                message: 'Введи название фильма для поиска в TMDB.'.tr(context),
              )
            else
              results.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => CatalogStatus(
                  message: error.toString(),
                  onRetry: () => ref.read(searchProvider.notifier).refresh(),
                ),
                data: (movies) => movies.isEmpty
                    ? CatalogStatus(
                        message: 'Ничего не найдено. Попробуй другое название.'
                            .tr(context),
                      )
                    : Column(
                        children: [
                          for (final movie in movies)
                            MovieListTile(movie: movie),
                        ],
                      ),
              ),
          ],
        ),
      ),
    );
  }
}
