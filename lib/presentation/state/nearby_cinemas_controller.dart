import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../domain/models/cinema_theater.dart';
import '../../domain/models/geo_coordinates.dart';

class NearbyCinemaSearch {
  const NearbyCinemaSearch({required this.center, required this.cinemas});

  final GeoCoordinates center;
  final List<CinemaTheater> cinemas;
}

final nearbyCinemasProvider =
    AsyncNotifierProvider<NearbyCinemasController, NearbyCinemaSearch?>(
      NearbyCinemasController.new,
    );

class NearbyCinemasController extends AsyncNotifier<NearbyCinemaSearch?> {
  @override
  FutureOr<NearbyCinemaSearch?> build() => null;

  Future<void> loadNearby() async {
    state = const AsyncLoading();
    try {
      final location = await ref
          .read(deviceLocationServiceProvider)
          .currentPosition();
      final cinemas = await ref
          .read(cinemaRepositoryProvider)
          .findNearby(center: location, radiusMeters: 12000);
      if (ref.mounted) {
        state = AsyncData(
          NearbyCinemaSearch(center: location, cinemas: cinemas),
        );
      }
    } catch (error, stackTrace) {
      if (ref.mounted) state = AsyncError(error, stackTrace);
    }
  }
}
