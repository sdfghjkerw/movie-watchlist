import 'package:flutter/foundation.dart' show FlutterError;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movie_watchlist/app/tmdb_configuration.dart';

class ConfigurationBundle extends CachingAssetBundle {
  ConfigurationBundle(this.content);
  final String? content;

  @override
  Future<ByteData> load(String key) async => throw UnimplementedError();

  @override
  Future<String> loadString(String key, {bool cache = true}) async {
    expect(key, '.vscode/tmdb.local.json');
    if (content == null) throw FlutterError('Missing local configuration');
    return content!;
  }
}

void main() {
  test('loads and trims the key from local configuration', () async {
    expect(
      await loadTmdbApiKey(
        bundle: ConfigurationBundle('{"TMDB_API_KEY":" example "}'),
        definedKey: '',
      ),
      'example',
    );
  });
  test('explicit build configuration takes precedence', () async {
    expect(
      await loadTmdbApiKey(
        bundle: ConfigurationBundle(null),
        definedKey: ' supplied ',
      ),
      'supplied',
    );
  });
  test(
    'missing, invalid and wrong-type configuration return an empty key',
    () async {
      for (final content in [null, 'invalid', '{"TMDB_API_KEY":42}']) {
        expect(
          await loadTmdbApiKey(
            bundle: ConfigurationBundle(content),
            definedKey: '',
          ),
          '',
        );
      }
    },
  );
}
