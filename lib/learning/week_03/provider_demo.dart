import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../sample_data/movies.dart';
import '../../state/watchlist_model.dart';
import '../../theme/app_theme.dart';
import 'demo_view.dart';

void main() => runApp(
  ChangeNotifierProvider(
    create: (_) => WatchlistModel(),
    child: MaterialApp(theme: AppTheme.darkTheme, home: const ProviderDemo()),
  ),
);

class ProviderDemo extends StatelessWidget {
  const ProviderDemo({super.key});
  @override
  Widget build(BuildContext context) {
    final movie = sampleMovies.first;
    final model = context.watch<WatchlistModel>();
    return DemoView(
      selected: model.contains(movie.id),
      toggle: () => context.read<WatchlistModel>().toggle(movie),
    );
  }
}
