import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:movie_watchlist/data/remote/movie_dto.dart';
import 'package:movie_watchlist/data/repositories/tmdb_catalog_repository.dart';
import 'package:movie_watchlist/domain/models/catalog_exception.dart';

const movieJson = {
  'id': 42,
  'title': 'Film',
  'release_date': '2020-01-01',
  'vote_average': 8.0,
  'vote_count': 20,
  'poster_path': '/poster.jpg',
  'genres': [
    {'name': 'Drama'},
  ],
  'runtime': 100,
};

void main() {
  test('Generated JSON round-trip and conversion preserve valid fields', () {
    final dto = MovieDto.fromJson(movieJson);
    expect(MovieDto.fromJson(dto.toJson()).toMovie().title, 'Film');
    final movie = dto.toMovie();
    expect(movie.year, 2020);
    expect(movie.rating, 8);
    expect(movie.runtimeMinutes, 100);
    expect(movie.genre, 'Drama');
    expect(movie.posterUrl, 'https://image.tmdb.org/t/p/w500/poster.jpg');
  });
  test('Absent metadata stays absent without invented values', () {
    final movie = MovieDto.fromJson({'id': 1, 'title': 'Minimal'}).toMovie();
    expect(movie.year, isNull);
    expect(movie.rating, isNull);
    expect(movie.posterUrl, isNull);
    expect(movie.runtimeMinutes, isNull);
  });
  test(
    'Popular, encoded search and detail use the correct endpoints',
    () async {
      final requests = <Uri>[];
      final client = MockClient((request) async {
        requests.add(request.url);
        return http.Response(
          jsonEncode(
            request.url.path == '/3/movie/42'
                ? movieJson
                : {
                    'results': [movieJson],
                  },
          ),
          200,
        );
      });
      addTearDown(client.close);
      final repo = TmdbCatalogRepository(client: client, apiKey: 'test-only');
      expect(await repo.fetchMovies(), hasLength(1));
      expect(await repo.searchMovies(' A & B '), hasLength(1));
      expect((await repo.fetchMovie(42)).id, 42);
      expect(requests[0].path, '/3/movie/popular');
      expect(requests[1].queryParameters['query'], 'A & B');
      expect(requests[2].path, '/3/movie/42');
    },
  );
  test(
    'Empty results are successful; blank search does not call HTTP',
    () async {
      var calls = 0;
      final client = MockClient((_) async {
        calls++;
        return http.Response('{"results":[]}', 200);
      });
      addTearDown(client.close);
      final repo = TmdbCatalogRepository(client: client, apiKey: 'test-only');
      expect(await repo.searchMovies('  '), isEmpty);
      expect(calls, 0);
      expect(await repo.fetchMovies(), isEmpty);
    },
  );
  for (final status in [401, 429, 500]) {
    test(
      'HTTP $status becomes a user-facing error without exposing credentials',
      () async {
        final client = MockClient(
          (_) async => http.Response('secret response', status),
        );
        addTearDown(client.close);
        final repo = TmdbCatalogRepository(client: client, apiKey: 'test-only');
        await expectLater(repo.fetchMovies(), throwsA(isA<CatalogException>()));
      },
    );
  }
  test('Malformed JSON and malformed records are handled', () async {
    for (final body in ['broken', '{"results":[{"id":"wrong"}]}']) {
      final client = MockClient((_) async => http.Response(body, 200));
      addTearDown(client.close);
      await expectLater(
        TmdbCatalogRepository(
          client: client,
          apiKey: 'test-only',
        ).fetchMovies(),
        throwsA(isA<CatalogException>()),
      );
    }
  });
  test('Timeout and client error are handled', () async {
    final clients = [
      MockClient((_) => Completer<http.Response>().future),
      MockClient((_) async => throw http.ClientException('offline')),
    ];
    for (final client in clients) {
      addTearDown(client.close);
      await expectLater(
        TmdbCatalogRepository(
          client: client,
          apiKey: 'test-only',
          timeout: const Duration(milliseconds: 10),
        ).fetchMovies(),
        throwsA(isA<CatalogException>()),
      );
    }
  });
  test(
    'Missing access fails explicitly instead of showing demo data',
    () async {
      final client = MockClient(
        (_) async => throw StateError('Must not send request'),
      );
      addTearDown(client.close);
      await expectLater(
        TmdbCatalogRepository(client: client, apiKey: '').fetchMovies(),
        throwsA(isA<CatalogException>()),
      );
    },
  );
}
