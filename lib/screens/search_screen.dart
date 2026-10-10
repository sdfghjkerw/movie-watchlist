import 'package:flutter/material.dart';

import '../sample_data/movies.dart';
import '../widgets/movie_list_tile.dart';

class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Поиск фильмов')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const TextField(
            readOnly: true,
            decoration: InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'Название фильма',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          const Text('Статический макет: поиск пока не подключён.'),
          const SizedBox(height: 24),
          Text(
            'Открой для себя',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          for (final movie in sampleMovies) MovieListTile(movie: movie),
        ],
      ),
    );
  }
}
