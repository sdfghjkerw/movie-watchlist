import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:movie_watchlist/app/providers.dart';
import 'package:movie_watchlist/data/repositories/static_catalog_repository.dart';

List<Override> get staticCatalogOverrides => [
  catalogRepositoryProvider.overrideWithValue(StaticCatalogRepository()),
];
