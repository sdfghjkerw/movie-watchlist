import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Firebase identifiers and the public Web Push key from a local, untracked
/// launch configuration. Admin/service-account keys must never go here.
class FirebaseLocalConfiguration {
  const FirebaseLocalConfiguration({
    required this.platforms,
    this.googleWebClientId,
    this.googleIosClientId,
    this.vapidKey,
  });

  final Map<String, Map<String, dynamic>> platforms;
  final String? googleWebClientId;
  final String? googleIosClientId;
  final String? vapidKey;

  factory FirebaseLocalConfiguration.fromJson(Map<String, dynamic> json) {
    final rawPlatforms = json['platforms'];
    final platforms = <String, Map<String, dynamic>>{};
    if (rawPlatforms is Map) {
      for (final entry in rawPlatforms.entries) {
        if (entry.key is String && entry.value is Map) {
          platforms[entry.key as String] = Map<String, dynamic>.from(
            entry.value as Map,
          );
        }
      }
    }
    return FirebaseLocalConfiguration(
      platforms: platforms,
      googleWebClientId: _string(json['googleWebClientId']),
      googleIosClientId: _string(json['googleIosClientId']),
      vapidKey: _string(json['vapidKey']),
    );
  }

  String get platformName => kIsWeb
      ? 'web'
      : switch (defaultTargetPlatform) {
          TargetPlatform.android => 'android',
          TargetPlatform.iOS => 'ios',
          TargetPlatform.macOS => 'macos',
          TargetPlatform.windows => 'windows',
          TargetPlatform.linux => 'linux',
          TargetPlatform.fuchsia => 'fuchsia',
        };

  Map<String, dynamic>? get currentPlatformValues => platforms[platformName];

  bool get isCurrentPlatformConfigured {
    final values = currentPlatformValues;
    return values != null &&
        [
          'apiKey',
          'appId',
          'messagingSenderId',
          'projectId',
        ].every((key) => _string(values[key])?.isNotEmpty == true);
  }

  FirebaseOptions get currentPlatformOptions {
    final values = currentPlatformValues;
    if (values == null) {
      throw StateError('Firebase is not configured for $platformName.');
    }
    return FirebaseOptions(
      apiKey: _required(values, 'apiKey'),
      appId: _required(values, 'appId'),
      messagingSenderId: _required(values, 'messagingSenderId'),
      projectId: _required(values, 'projectId'),
      authDomain: _string(values['authDomain']),
      databaseURL: _string(values['databaseURL']),
      storageBucket: _string(values['storageBucket']),
      measurementId: _string(values['measurementId']),
      trackingId: _string(values['trackingId']),
      deepLinkURLScheme: _string(values['deepLinkURLScheme']),
      androidClientId: _string(values['androidClientId']),
      iosClientId: _string(values['iosClientId']) ?? googleIosClientId,
      iosBundleId: _string(values['iosBundleId']),
      appGroupId: _string(values['appGroupId']),
    );
  }

  static String _required(Map<String, dynamic> values, String key) {
    final value = _string(values[key]);
    if (value == null || value.isEmpty) {
      throw StateError('Firebase config is missing "$key".');
    }
    return value;
  }

  static String? _string(Object? value) =>
      value is String ? value.trim() : null;
}

Future<FirebaseLocalConfiguration?> loadFirebaseConfiguration({
  AssetBundle? bundle,
}) async {
  try {
    final text = await (bundle ?? rootBundle).loadString(
      '.vscode/firebase.local.json',
    );
    final decoded = jsonDecode(text);
    if (decoded is! Map<String, dynamic>) return null;
    return FirebaseLocalConfiguration.fromJson(decoded);
  } on FlutterError {
    return null;
  } on FormatException {
    return null;
  }
}
