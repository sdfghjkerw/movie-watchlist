import 'geo_coordinates.dart';

class CinemaTheater {
  const CinemaTheater({
    required this.id,
    required this.name,
    required this.location,
    this.address,
    this.rating,
  });

  final String id;
  final String name;
  final GeoCoordinates location;
  final String? address;
  final double? rating;

  factory CinemaTheater.fromOverpassJson(Map<String, dynamic> json) {
    final tags = json['tags'];
    if (tags is! Map<String, dynamic>) {
      throw const FormatException('Cinema has no tags.');
    }
    final center = json['center'] is Map<String, dynamic>
        ? json['center'] as Map<String, dynamic>
        : json;
    final latitude = center['lat'];
    final longitude = center['lon'];
    final type = json['type'];
    final id = json['id'];
    if (latitude is! num ||
        longitude is! num ||
        type is! String ||
        id is! num) {
      throw const FormatException('Cinema data is incomplete.');
    }
    final name = [tags['name'], tags['name:ru'], tags['name:en']]
        .whereType<String>()
        .firstWhere(
          (value) => value.trim().isNotEmpty,
          orElse: () => 'Кинотеатр',
        );
    final address = tags['addr:full'] as String? ?? _addressFromTags(tags);
    return CinemaTheater(
      id: '$type/$id',
      name: name,
      location: GeoCoordinates(
        latitude: latitude.toDouble(),
        longitude: longitude.toDouble(),
      ),
      address: address,
    );
  }

  static String? _addressFromTags(Map<String, dynamic> tags) {
    final parts = <String>[
      if (tags['addr:street'] is String) tags['addr:street'] as String,
      if (tags['addr:housenumber'] is String)
        tags['addr:housenumber'] as String,
      if (tags['addr:city'] is String) tags['addr:city'] as String,
    ];
    return parts.isEmpty ? null : parts.join(', ');
  }
}
