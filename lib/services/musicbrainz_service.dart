import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:diacritic/diacritic.dart';
import 'package:http/http.dart' as http;

class MusicBrainzService {
  static const String _baseUrl =
      'https://musicbrainz.org/ws/2';

  static const String _userAgent =
      'ChartLens/0.1.0';

  static DateTime? _lastRequestTime;

  static const int _maxRetries = 3;

  // ============================================================
  // SEARCH ARTIST BY CANONICAL NAME
  // ============================================================

  static Future<List<MusicBrainzArtist>> searchArtist(
    String artistName,
  ) async {
    return _searchArtistWithQuery(
      'artist:"$artistName"',
    );
  }

  // ============================================================
  // SEARCH ARTIST BY ALIAS
  // ============================================================

  static Future<List<MusicBrainzArtist>> searchArtistAlias(
    String artistName,
  ) async {
    return _searchArtistWithQuery(
      'alias:"$artistName"',
    );
  }

  // ============================================================
  // GENERIC MUSICBRAINZ SEARCH
  // ============================================================

  static Future<List<MusicBrainzArtist>> _searchArtistWithQuery(
    String query,
  ) async {
    int attempt = 0;

    while (true) {
      await _respectRateLimit();

      try {
        final uri = Uri.parse(
          '$_baseUrl/artist',
        ).replace(
          queryParameters: {
            'query': query,
            'fmt': 'json',
            'limit': '10',
          },
        );

        final response = await http
            .get(
              uri,
              headers: {
                'User-Agent': _userAgent,
                'Accept': 'application/json',
              },
            )
            .timeout(
              const Duration(seconds: 15),
            );

        // ------------------------------------------------------
        // SUCCESS
        // ------------------------------------------------------

        if (response.statusCode == 200) {
          final Map<String, dynamic> data =
              jsonDecode(response.body);

          final List<dynamic> artists =
              data['artists'] ?? [];

          return artists
              .map(
                (artist) =>
                    MusicBrainzArtist.fromJson(
                  artist as Map<String, dynamic>,
                ),
              )
              .toList();
        }

        // ------------------------------------------------------
        // RETRYABLE HTTP ERRORS
        // ------------------------------------------------------

        if (_isRetryableStatus(response.statusCode)) {
          if (attempt >= _maxRetries) {
            throw Exception(
              'MusicBrainz request failed after '
              '${_maxRetries + 1} attempts: '
              '${response.statusCode} '
              '${response.reasonPhrase}',
            );
          }

          attempt++;

          final retryDelay = Duration(
            seconds: 2 * attempt,
          );

          print(
            'MusicBrainz ${response.statusCode} '
            'for query "$query". '
            'Retrying in '
            '${retryDelay.inSeconds}s '
            '(attempt $attempt/$_maxRetries)...',
          );

          await Future.delayed(retryDelay);

          continue;
        }

        // ------------------------------------------------------
        // NON-RETRYABLE HTTP ERROR
        // ------------------------------------------------------

        throw Exception(
          'MusicBrainz request failed: '
          '${response.statusCode} '
          '${response.reasonPhrase}',
        );
      }

      // --------------------------------------------------------
      // TIMEOUT
      // --------------------------------------------------------

      on TimeoutException catch (e) {
        if (attempt >= _maxRetries) {
          throw Exception(
            'MusicBrainz request timed out after '
            '${_maxRetries + 1} attempts: $e',
          );
        }

        attempt++;

        final retryDelay = Duration(
          seconds: 2 * attempt,
        );

        print(
          'MusicBrainz timeout for query "$query". '
          'Retrying in ${retryDelay.inSeconds}s '
          '(attempt $attempt/$_maxRetries)...',
        );

        await Future.delayed(retryDelay);
      }

      // --------------------------------------------------------
      // SOCKET / CONNECTION ERROR
      // --------------------------------------------------------

      on SocketException catch (e) {
        if (attempt >= _maxRetries) {
          throw Exception(
            'MusicBrainz connection failed after '
            '${_maxRetries + 1} attempts: $e',
          );
        }

        attempt++;

        final retryDelay = Duration(
          seconds: 2 * attempt,
        );

        print(
          'MusicBrainz connection error for '
          'query "$query". '
          'Retrying in ${retryDelay.inSeconds}s '
          '(attempt $attempt/$_maxRetries)...',
        );

        await Future.delayed(retryDelay);
      }

      // --------------------------------------------------------
      // HTTP CLIENT ERROR
      // --------------------------------------------------------

      on http.ClientException catch (e) {
        if (attempt >= _maxRetries) {
          throw Exception(
            'MusicBrainz client error after '
            '${_maxRetries + 1} attempts: $e',
          );
        }

        attempt++;

        final retryDelay = Duration(
          seconds: 2 * attempt,
        );

        print(
          'MusicBrainz client error for '
          'query "$query". '
          'Retrying in ${retryDelay.inSeconds}s '
          '(attempt $attempt/$_maxRetries)...',
        );

        await Future.delayed(retryDelay);
      }
    }
  }

  // ============================================================
  // FIND BEST ARTIST MATCH
  // ============================================================

  static Future<MusicBrainzMatch?> findBestArtistMatch(
    String billboardArtist,
  ) async {
    final normalizedBillboardName =
        _normalizeName(billboardArtist);

    // ----------------------------------------------------------
    // STEP 1: Search canonical artist name
    // ----------------------------------------------------------

    final candidates = await searchArtist(
      billboardArtist,
    );

    if (candidates.isNotEmpty) {
      final exactMatches = candidates.where((candidate) {
        return _normalizeName(candidate.name) ==
            normalizedBillboardName;
      }).toList();

      if (exactMatches.isNotEmpty) {
        return _selectBestMatch(exactMatches);
      }
    }

    // ----------------------------------------------------------
    // STEP 2: Search MusicBrainz aliases
    // ----------------------------------------------------------

    print(
      'No canonical match for "$billboardArtist". '
      'Trying MusicBrainz aliases...',
    );

    final aliasCandidates = await searchArtistAlias(
      billboardArtist,
    );

    if (aliasCandidates.isEmpty) {
      return null;
    }

    // Alias search should return artists whose canonical
    // name may differ from the Billboard name.
    final aliasMatches = aliasCandidates.where((candidate) {
      return _normalizeName(candidate.name) !=
          normalizedBillboardName;
    }).toList();

    if (aliasMatches.isEmpty) {
      return null;
    }

    print(
      'ALIAS MATCH CANDIDATES for "$billboardArtist":',
    );

    for (final candidate in aliasMatches) {
      print(
        '  ${candidate.name} '
        '| score: ${candidate.score} '
        '| type: ${candidate.type} '
        '| id: ${candidate.id}',
      );
    }

    return _selectBestMatch(aliasMatches);
  }

  // ============================================================
  // SELECT BEST MATCH
  // ============================================================

  static MusicBrainzMatch _selectBestMatch(
    List<MusicBrainzArtist> matches,
  ) {
    matches.sort(
      (a, b) =>
          (b.score ?? 0).compareTo(a.score ?? 0),
    );

    final best = matches.first;

    // If two candidates have exactly the same score,
    // don't automatically choose one.
    if (matches.length > 1) {
      final secondBest = matches[1];

      if ((best.score ?? 0) ==
          (secondBest.score ?? 0)) {
        return MusicBrainzMatch(
          artist: best,
          confidence: MatchConfidence.ambiguous,
        );
      }
    }

    if ((best.score ?? 0) >= 90) {
      return MusicBrainzMatch(
        artist: best,
        confidence: MatchConfidence.high,
      );
    }

    return MusicBrainzMatch(
      artist: best,
      confidence: MatchConfidence.low,
    );
  }

  // ============================================================
  // NORMALIZE ARTIST NAME
  // ============================================================

  static String _normalizeName(String name) {
    return removeDiacritics(name)
        .toLowerCase()
        .replaceAll(
          RegExp(
            r'[^\p{L}\p{N}\s]',
            unicode: true,
          ),
          '',
        )
        .replaceAll(
          RegExp(r'\s+'),
          ' ',
        )
        .trim();
  }

  // ============================================================
  // RETRYABLE STATUS CHECK
  // ============================================================

  static bool _isRetryableStatus(int statusCode) {
    return statusCode == 429 ||
        statusCode == 500 ||
        statusCode == 502 ||
        statusCode == 503 ||
        statusCode == 504;
  }

  // ============================================================
  // RATE LIMIT
  // ============================================================

  static Future<void> _respectRateLimit() async {
    final now = DateTime.now();

    if (_lastRequestTime != null) {
      final elapsed =
          now.difference(_lastRequestTime!);

      const minimumDelay =
          Duration(milliseconds: 1100);

      if (elapsed < minimumDelay) {
        await Future.delayed(
          minimumDelay - elapsed,
        );
      }
    }

    _lastRequestTime = DateTime.now();
  }
}

// ============================================================
// MUSICBRAINZ ARTIST
// ============================================================

class MusicBrainzArtist {
  final String id;
  final String name;
  final String? sortName;
  final String? type;
  final String? country;
  final String? disambiguation;
  final int? score;

  MusicBrainzArtist({
    required this.id,
    required this.name,
    this.sortName,
    this.type,
    this.country,
    this.disambiguation,
    this.score,
  });

  factory MusicBrainzArtist.fromJson(
    Map<String, dynamic> json,
  ) {
    return MusicBrainzArtist(
      id: json['id'] as String,
      name: json['name'] as String,
      sortName: json['sort-name'] as String?,
      type: json['type'] as String?,
      country: json['country'] as String?,
      disambiguation:
          json['disambiguation'] as String?,
      score: json['score'] as int?,
    );
  }

  @override
  String toString() {
    return '''
Name: $name
MBID: $id
Score: $score
Type: $type
Country: $country
Disambiguation: $disambiguation
''';
  }
}

// ============================================================
// MATCH CONFIDENCE
// ============================================================

enum MatchConfidence {
  high,
  low,
  ambiguous,
}

// ============================================================
// MUSICBRAINZ MATCH
// ============================================================

class MusicBrainzMatch {
  final MusicBrainzArtist artist;
  final MatchConfidence confidence;

  MusicBrainzMatch({
    required this.artist,
    required this.confidence,
  });

  @override
  String toString() {
    return '''
Match confidence: $confidence

${artist.toString()}
''';
  }
}