import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movie_watchlist/data/services/android_device_service.dart';
import 'package:movie_watchlist/domain/models/device_status.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('movie_watchlist/device');

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test(
    'Android device service reads battery and device data from Kotlin',
    () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            expect(call.method, 'getDeviceStatus');
            return {
              'deviceModel': 'Google Pixel 9',
              'androidVersion': '16',
              'batteryLevel': 83,
              'isCharging': true,
            };
          });

      const service = AndroidDeviceService();
      final status = await service.getStatus();

      expect(status.deviceModel, 'Google Pixel 9');
      expect(status.androidVersion, '16');
      expect(status.batteryLevel, 83);
      expect(status.isCharging, isTrue);
    },
  );

  test('device status tolerates unsupported battery readings', () {
    final status = DeviceStatus.fromMap({
      'deviceModel': 'Android device',
      'androidVersion': '—',
      'batteryLevel': -1,
      'isCharging': false,
    });

    expect(status.batteryLevel, isNull);
    expect(status.isCharging, isFalse);
  });
}
