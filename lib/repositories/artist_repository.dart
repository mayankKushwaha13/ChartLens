import 'package:sqflite/sqflite.dart';

class ArtistRepository {
  final Database db;

  ArtistRepository(this.db);

  // ============================================================
  // TOP ARTISTS
  // ============================================================

  Future<List<Map<String, dynamic>>> getTopArtists({
    int limit = 10,
  }) async {
    return await db.rawQuery(
      '''
      SELECT
        a.artist_id,
        a.name,
        COUNT(DISTINCT sa.song_id) AS song_count,
        SUM(101 - ce.rank) AS chart_score,
        COUNT(*) AS chart_appearances,
        MIN(ce.rank) AS best_peak
      FROM artist a
      JOIN song_artist sa
        ON a.artist_id = sa.artist_id
      JOIN song s
        ON sa.song_id = s.song_id
      JOIN chart_entry ce
        ON s.song_id = ce.song_id
      JOIN chart c
        ON ce.chart_id = c.chart_id
      WHERE c.name = 'Billboard Hot 100'
      GROUP BY
        a.artist_id,
        a.name
      ORDER BY chart_score DESC
      LIMIT ?
      ''',
      [limit],
    );
  }

  // ============================================================
  // SEARCH ARTISTS
  // ============================================================

  Future<List<Map<String, dynamic>>> searchArtists(
    String query,
  ) async {
    final trimmedQuery = query.trim();

    if (trimmedQuery.isEmpty) {
      return getTopArtists(limit: 50);
    }

    return await db.rawQuery(
      '''
      SELECT
        a.artist_id,
        a.name,
        COUNT(DISTINCT sa.song_id) AS song_count,
        SUM(101 - ce.rank) AS chart_score,
        COUNT(*) AS chart_appearances,
        MIN(ce.rank) AS best_peak
      FROM artist a
      JOIN song_artist sa
        ON a.artist_id = sa.artist_id
      JOIN song s
        ON sa.song_id = s.song_id
      JOIN chart_entry ce
        ON s.song_id = ce.song_id
      JOIN chart c
        ON ce.chart_id = c.chart_id
      WHERE c.name = 'Billboard Hot 100'
        AND a.name LIKE ?
      GROUP BY
        a.artist_id,
        a.name
      ORDER BY chart_score DESC
      LIMIT 50
      ''',
      [
        '%$trimmedQuery%',
      ],
    );
  }

  // ============================================================
  // ARTIST SONGS
  // ============================================================

  Future<List<Map<String, dynamic>>> getArtistSongs(
    int artistId,
  ) async {
    return await db.rawQuery(
      '''
      SELECT
        s.song_id,
        s.title,
        s.artist_credit,
        SUM(101 - ce.rank) AS chart_score,
        COUNT(*) AS weeks_on_chart,
        MIN(ce.rank) AS peak_rank
      FROM song s
      JOIN song_artist sa
        ON s.song_id = sa.song_id
      JOIN chart_entry ce
        ON s.song_id = ce.song_id
      JOIN chart c
        ON ce.chart_id = c.chart_id
      WHERE sa.artist_id = ?
        AND c.name = 'Billboard Hot 100'
      GROUP BY
        s.song_id,
        s.title,
        s.artist_credit
      ORDER BY chart_score DESC
      ''',
      [artistId],
    );
  }

  // ============================================================
  // ARTIST SCORE
  // ============================================================

  Future<int> getArtistScore(int artistId) async {
    final result = await db.rawQuery(
      '''
      SELECT
        COALESCE(SUM(101 - ce.rank), 0) AS chart_score
      FROM artist a
      JOIN song_artist sa
        ON a.artist_id = sa.artist_id
      JOIN chart_entry ce
        ON sa.song_id = ce.song_id
      JOIN chart c
        ON ce.chart_id = c.chart_id
      WHERE a.artist_id = ?
        AND c.name = 'Billboard Hot 100'
      ''',
      [artistId],
    );

    return (result.first['chart_score'] as int?) ?? 0;
  }
}