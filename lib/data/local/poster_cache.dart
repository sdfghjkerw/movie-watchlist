import 'dart:typed_data';

import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;

class PosterCache {
  PosterCache(this.box, this.client);
  final Box<dynamic> box;
  final http.Client client;
  final _pending = <String, Future<Uint8List?>>{};
  Future<Uint8List?> load(String url) {
    final cached = box.get(url);
    if (cached is Uint8List) return Future.value(cached);
    return _pending.putIfAbsent(url, () => _fetch(url));
  }

  Future<Uint8List?> _fetch(String url) async {
    try {
      final response = await client
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 12));
      if (response.statusCode != 200 ||
          !(response.headers['content-type'] ?? '').startsWith('image/')) {
        return null;
      }
      await box.put(url, response.bodyBytes);
      return response.bodyBytes;
    } catch (_) {
      return null;
    } finally {
      _pending.remove(url);
    }
  }
}
