import '../models/cinema_theater.dart';
import '../models/geo_coordinates.dart';

abstract interface class CinemaRepository {
  Future<List<CinemaTheater>> findNearby({
    required GeoCoordinates center,
    required double radiusMeters,
  });
}
