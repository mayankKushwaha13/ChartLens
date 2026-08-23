import '../database/database_helper.dart';
import 'musicbrainz_service.dart';

class MusicBrainzEnricher {
  static const Set<String> _genericCredits = {
    'Various Artists',
  };

  static Future<EnrichmentResult> enrichArtists({
    int? limit,
    void Function(int completed, int total)? onProgress,
  }) async {
    final db = await DatabaseHelper.instance.database;

    final artists = await db.query(
      'artist',
      columns: [
        'artist_id',
        'name',
        'musicbrainz_id',
      ],
      where: 'musicbrainz_id IS NULL',
      orderBy: 'artist_id',
      limit: limit,
    );

    int matched = 0;
    int skipped = 0;
    int failed = 0;

    print(
      'Starting MusicBrainz enrichment '
      'for ${artists.length} artists...',
    );

    for (int i = 0; i < artists.length; i++) {
      final artist = artists[i];

      final artistId = artist['artist_id'] as int;
      final artistName = artist['name'] as String;

      onProgress?.call(i, artists.length);

      // --------------------------------------------------------
      // Skip generic artist credits
      // --------------------------------------------------------

      if (_genericCredits.contains(artistName)) {
        skipped++;

        print(
          'SKIPPED: "$artistName" → generic credit',
        );

        onProgress?.call(i + 1, artists.length);
        continue;
      }

      // --------------------------------------------------------
      // Search MusicBrainz
      // --------------------------------------------------------

      try {
        final match =
            await MusicBrainzService.findBestArtistMatch(
          artistName,
        );

        // ------------------------------------------------------
        // No suitable result
        // ------------------------------------------------------

        if (match == null) {
          skipped++;

          print(
            'SKIPPED: "$artistName" → no suitable match',
          );

          onProgress?.call(i + 1, artists.length);
          continue;
        }

        // ------------------------------------------------------
        // Only accept high-confidence matches
        // ------------------------------------------------------

        if (match.confidence != MatchConfidence.high) {
          skipped++;

          print(
            'SKIPPED: "$artistName" → '
            '${match.confidence}',
          );

          onProgress?.call(i + 1, artists.length);
          continue;
        }

        // ------------------------------------------------------
        // Save MusicBrainz ID
        // ------------------------------------------------------

        await db.update(
          'artist',
          {
            'musicbrainz_id': match.artist.id,
          },
          where: 'artist_id = ?',
          whereArgs: [artistId],
        );

        matched++;

        print(
          'MATCHED: "$artistName" → '
          '${match.artist.name} '
          '(${match.artist.id})',
        );
      } catch (e) {
        failed++;

        print(
          'FAILED: "$artistName" → $e',
        );
      }

      onProgress?.call(i + 1, artists.length);
    }

    print('''
MusicBrainz enrichment finished.

Total: ${artists.length}
Matched: $matched
Skipped: $skipped
Failed: $failed
''');

    return EnrichmentResult(
      total: artists.length,
      matched: matched,
      skipped: skipped,
      failed: failed,
    );
  }
}

// ============================================================
// ENRICHMENT RESULT
// ============================================================

class EnrichmentResult {
  final int total;
  final int matched;
  final int skipped;
  final int failed;

  EnrichmentResult({
    required this.total,
    required this.matched,
    required this.skipped,
    required this.failed,
  });

  @override
  String toString() {
    return '''
Artist enrichment complete.

Total: $total
Matched: $matched
Skipped: $skipped
Failed: $failed
''';
  }
}