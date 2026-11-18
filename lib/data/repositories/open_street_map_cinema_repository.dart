import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../domain/models/cinema_theater.dart';
import '../../domain/models/geo_coordinates.dart';
import '../../domain/repositories/cinema_repository.dart';

class OpenStreetMapCinemaRepository implements CinemaRepository {
  OpenStreetMapCinemaRepository({required this.client});

  static final Uri _endpoint = Uri.parse(
    'https://overpass-api.de/api/interpreter',
  );
  final http.Client client;

  @override
  Future<List<CinemaTheater>> findNearby({
    required GeoCoordinates center,
    required double radiusMeters,
  }) async {
    final query =
        '''[out:json][timeout:15];
nwr["amenity"="cinema"](around:${radiusMeters.round()},${center.latitude},${center.longitude});
out center tags;''';
    final response = await client
        .post(
          _endpoint,
          headers: {
            'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8',
            if (!kIsWeb)
              'User-Agent': 'MovieWatchlist/1.0 (nearby cinema search)',
          },
          body: {'data': query},
        )
        .timeout(const Duration(seconds: 25));
    if (response.statusCode == 429 || response.statusCode == 504) {
      throw const CinemaSearchUnavailableException();
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw const CinemaSearchUnavailableException();
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic> || decoded['elements'] is! List) {
      throw const FormatException('Unexpected Overpass response.');
    }
    return (decoded['elements'] as List)
        .whereType<Map<String, dynamic>>()
        .map(CinemaTheater.fromOverpassJson)
        .toList(growable: false);
  }
}

class CinemaSearchUnavailableException implements Exception {
  const CinemaSearchUnavailableException();
}
