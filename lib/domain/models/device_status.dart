class DeviceStatus {
  const DeviceStatus({
    required this.deviceModel,
    required this.androidVersion,
    required this.batteryLevel,
    required this.isCharging,
  });

  final String deviceModel;
  final String androidVersion;
  final int? batteryLevel;
  final bool isCharging;

  factory DeviceStatus.fromMap(Map<Object?, Object?> value) {
    final rawLevel = value['batteryLevel'];
    return DeviceStatus(
      deviceModel: value['deviceModel'] as String? ?? 'Android',
      androidVersion: value['androidVersion'] as String? ?? '—',
      batteryLevel: rawLevel is int && rawLevel >= 0 && rawLevel <= 100
          ? rawLevel
          : null,
      isCharging: value['isCharging'] as bool? ?? false,
    );
  }
}
