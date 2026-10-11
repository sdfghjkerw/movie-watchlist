import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../domain/models/catalog_exception.dart';
import '../../domain/models/movie.dart';
import '../../domain/repositories/catalog_repository.dart';
import '../remote/movie_dto.dart';

class TmdbCatalogRepository implements CatalogRepository {
  TmdbCatalogRepository({
    required this.client,
    required this.apiKey,
    this.timeout = const Duration(seconds: 12),
    this.language = 'ru-RU',
  });
  final http.Client client;
  final String apiKey;
  final Duration timeout;
  final String language;

  Future<Map<String, dynamic>> _get(
    String path, [
    Map<String, String> parameters = const {},
  ]) async {
    if (apiKey.trim().isEmpty) {
      throw const CatalogException(
        'Не настроен доступ TMDB. Проверьте локальный файл .vscode/tmdb.local.json.',
      );
    }
    try {
      final response = await client
          .get(
            Uri.https('api.themoviedb.org', '/3/$path', {
              'api_key': apiKey,
              'language': language,
              ...parameters,
            }),
          )
          .timeout(timeout);
      if (response.statusCode == 401 || response.statusCode == 403) {
        throw const CatalogException(
          'TMDB отклонил доступ. Проверьте API-ключ.',
        );
      }
      if (response.statusCode == 429) {
        throw const CatalogException(
          'Слишком много запросов. Попробуйте позже.',
        );
      }
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw CatalogException(
          'Сервис недоступен (HTTP ${response.statusCode}). Попробуйте ещё раз.',
        );
      }
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is! Map<String, dynamic>) throw const FormatException();
      return decoded;
    } on TimeoutException {
      throw const CatalogException(
        'Сервис не ответил вовремя. Попробуйте ещё раз.',
      );
    } on http.ClientException {
      throw const CatalogException(
        'Не удалось подключиться. Проверьте интернет и доступность сервиса.',
      );
    } on FormatException {
      throw const CatalogException('Сервис вернул некорректные данные.');
    }
  }

  Future<List<Movie>> _list(
    String path, [
    Map<String, String> parameters = const {},
  ]) async {
    final json = await _get(path, parameters);
    try {
      final results = json['results'];
      if (results is! List) throw const FormatException();
      return List.unmodifiable(
        results.map(
          (item) => MovieDto.fromJson(item as Map<String, dynamic>).toMovie(),
        ),
      );
    } catch (_) {
      throw const CatalogException(
        'Сервис вернул некорректные сведения о фильмах.',
      );
    }
  }

  @override
  Future<List<Movie>> fetchMovies() => _list('movie/popular');
  @override
  Future<List<Movie>> searchMovies(String query) => query.trim().isEmpty
      ? Future.value(const [])
      : _list('search/movie', {
          'query': query.trim(),
          'include_adult': 'false',
        });
  @override
  Future<Movie> fetchMovie(int id) async {
    final json = await _get('movie/$id');
    try {
      return MovieDto.fromJson(json).toMovie();
    } catch (_) {
      throw const CatalogException(
        'Сервис вернул некорректные сведения о фильме.',
      );
    }
  }
}
