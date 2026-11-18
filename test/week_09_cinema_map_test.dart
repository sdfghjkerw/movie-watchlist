import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movie_watchlist/app/providers.dart';
import 'package:movie_watchlist/data/services/device_location_service.dart';
import 'package:movie_watchlist/domain/models/cinema_theater.dart';
import 'package:movie_watchlist/domain/models/geo_coordinates.dart';
import 'package:movie_watchlist/domain/models/movie.dart';
import 'package:movie_watchlist/domain/repositories/cinema_repository.dart';
import 'package:movie_watchlist/presentation/screens/cinema_map_screen.dart';

class _DeniedLocationService implements DeviceLocationService {
  @override
  Future<GeoCoordinates> currentPosition() async {
    throw const LocationAccessException(LocationProblem.permissionDenied);
  }
}

class _UnusedCinemaRepository implements CinemaRepository {
  @override
  Future<List<CinemaTheater>> findNearby({
    required GeoCoordinates center,
    required double radiusMeters,
  }) async => const [];
}

const _movie = Movie(
  id: 42,
  title: 'Perfect Days',
  year: 2023,
  genre: 'Drama',
  rating: 7.8,
  description: 'A film description.',
  emoji: '🎬',
);

void main() {
  test('Cinema model parses an OSM way center without inventing data', () {
    final cinema = CinemaTheater.fromOverpassJson({
      'type': 'way',
      'id': 123,
      'center': {'lat': 43.2, 'lon': 76.9},
      'tags': {'amenity': 'cinema', 'name': 'Cinema One'},
    });

    expect(cinema.name, 'Cinema One');
    expect(cinema.location.latitude, 43.2);
    expect(cinema.address, isNull);
    expect(cinema.rating, isNull);
  });

  testWidgets('Location refusal is explained and does not create a map', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          deviceLocationServiceProvider.overrideWithValue(
            _DeniedLocationService(),
          ),
          cinemaRepositoryProvider.overrideWithValue(_UnusedCinemaRepository()),
        ],
        child: const MaterialApp(home: CinemaMapScreen(movie: _movie)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Кинотеатры рядом'), findsOneWidget);
    await tester.tap(find.text('Найти кинотеатры рядом'));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Доступ к местоположению запрещён. Разреши его для этого сайта и повтори попытку.',
      ),
      findsOneWidget,
    );
    expect(find.text('Повторить поиск'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
