import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import '../../domain/models/geo_coordinates.dart';

enum LocationProblem {
  servicesDisabled,
  permissionDenied,
  permissionDeniedForever,
  positionTimeout,
}

class LocationAccessException implements Exception {
  const LocationAccessException(this.problem);
  final LocationProblem problem;
}

abstract interface class DeviceLocationService {
  Future<GeoCoordinates> currentPosition();
}

class GeolocatorDeviceLocationService implements DeviceLocationService {
  @override
  Future<GeoCoordinates> currentPosition() async {
    if (!kIsWeb && !await Geolocator.isLocationServiceEnabled()) {
      throw const LocationAccessException(LocationProblem.servicesDisabled);
    }

    if (!kIsWeb) {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied) {
        throw const LocationAccessException(LocationProblem.permissionDenied);
      }
      if (permission == LocationPermission.deniedForever) {
        throw const LocationAccessException(
          LocationProblem.permissionDeniedForever,
        );
      }
    }

    late final Position position;
    try {
      position = await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(
          // On Web, the browser prompts inside getCurrentPosition itself.
          // Pre-checking/requesting can make the browser wait for two fixes.
          accuracy: kIsWeb ? LocationAccuracy.medium : LocationAccuracy.high,
          timeLimit: const Duration(seconds: 12),
        ),
      );
    } on PermissionDeniedException {
      throw const LocationAccessException(LocationProblem.permissionDenied);
    } on TimeoutException {
      throw const LocationAccessException(LocationProblem.positionTimeout);
    }
    return GeoCoordinates(
      latitude: position.latitude,
      longitude: position.longitude,
    );
  }
}
