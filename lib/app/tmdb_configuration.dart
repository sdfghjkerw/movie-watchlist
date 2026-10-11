import 'dart:convert';

import 'package:flutter/foundation.dart' show FlutterError;

import 'package:flutter/services.dart';

/// Локальная конфигурация включается в assets, но исключена из Git.
Future<String> loadTmdbApiKey({AssetBundle? bundle, String? definedKey}) async {
  final supplied = definedKey ?? const String.fromEnvironment('TMDB_API_KEY');
  if (supplied.trim().isNotEmpty) return supplied.trim();
  try {
    final text = await (bundle ?? rootBundle).loadString(
      '.vscode/tmdb.local.json',
    );
    final json = jsonDecode(text);
    if (json is Map<String, dynamic> && json['TMDB_API_KEY'] is String) {
      return (json['TMDB_API_KEY'] as String).trim();
    }
  } on FormatException {
    return '';
  } on FlutterError {
    return '';
  }
  return '';
}
