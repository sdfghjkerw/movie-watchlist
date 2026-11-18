import 'package:flutter/services.dart';

import '../../domain/models/device_status.dart';

class AndroidDeviceService {
  const AndroidDeviceService();

  static const MethodChannel _channel = MethodChannel('movie_watchlist/device');

  Future<DeviceStatus> getStatus() async {
    final result = await _channel.invokeMapMethod<Object?, Object?>(
      'getDeviceStatus',
    );
    if (result == null) {
      throw const FormatException('Device status was empty.');
    }
    return DeviceStatus.fromMap(result);
  }
}
