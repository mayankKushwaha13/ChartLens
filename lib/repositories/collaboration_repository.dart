import 'package:sqflite/sqflite.dart';

class CollaborationRepository {
  final Database db;

  CollaborationRepository(this.db);

  // ============================================================
  // TOP COLLABORATIONS
  // ============================================================

  Future<List<Map<String, dynamic>>> getTopCollaborations({
    int limit = 20,
  }) async {
    return await db.rawQuery(
      '''
      SELECT
        a1.artist_id AS artist1_id,
        a1.name AS artist1_name,

        a2.artist_id AS artist2_id,
        a2.name AS artist2_name,

        COUNT(DISTINCT s.song_id) AS song_count,

        SUM(101 - ce.rank) AS chart_score,

        COUNT(*) AS chart_appearances,

        MIN(ce.rank) AS best_peak

      FROM song_artist sa1

      JOIN song_artist sa2
        ON sa1.song_id = sa2.song_id
        AND sa1.artist_id < sa2.artist_id

      JOIN artist a1
        ON sa1.artist_id = a1.artist_id

      JOIN artist a2
        ON sa2.artist_id = a2.artist_id

      JOIN song s
        ON sa1.song_id = s.song_id

      JOIN chart_entry ce
        ON s.song_id = ce.song_id

      JOIN chart c
        ON ce.chart_id = c.chart_id

      WHERE c.name = 'Billboard Hot 100'

      GROUP BY
        a1.artist_id,
        a1.name,
        a2.artist_id,
        a2.name

      ORDER BY chart_score DESC

      LIMIT ?
      ''',
      [limit],
    );
  }

  // ============================================================
  // COLLABORATIONS FOR A YEAR
  // ============================================================

  Future<List<Map<String, dynamic>>>
      getTopCollaborationsForYear({
    required int year,
    int limit = 20,
  }) async {
    return await db.rawQuery(
      '''
      SELECT
        a1.artist_id AS artist1_id,
        a1.name AS artist1_name,

        a2.artist_id AS artist2_id,
        a2.name AS artist2_name,

        COUNT(DISTINCT s.song_id) AS song_count,

        SUM(101 - ce.rank) AS chart_score,

        COUNT(*) AS chart_appearances,

        MIN(ce.rank) AS best_peak

      FROM song_artist sa1

      JOIN song_artist sa2
        ON sa1.song_id = sa2.song_id
        AND sa1.artist_id < sa2.artist_id

      JOIN artist a1
        ON sa1.artist_id = a1.artist_id

      JOIN artist a2
        ON sa2.artist_id = a2.artist_id

      JOIN song s
        ON sa1.song_id = s.song_id

      JOIN chart_entry ce
        ON s.song_id = ce.song_id

      JOIN chart c
        ON ce.chart_id = c.chart_id

      WHERE c.name = 'Billboard Hot 100'
        AND ce.chart_date BETWEEN ? AND ?

      GROUP BY
        a1.artist_id,
        a1.name,
        a2.artist_id,
        a2.name

      ORDER BY chart_score DESC

      LIMIT ?
      ''',
      [
        '$year-01-01',
        '$year-12-31',
        limit,
      ],
    );
  }

  // ============================================================
  // SONGS BETWEEN TWO ARTISTS
  // ============================================================

  Future<List<Map<String, dynamic>>>
      getCollaborationSongs({
    required int artist1Id,
    required int artist2Id,
  }) async {
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

      JOIN song_artist sa1
        ON s.song_id = sa1.song_id

      JOIN song_artist sa2
        ON s.song_id = sa2.song_id

      JOIN chart_entry ce
        ON s.song_id = ce.song_id

      JOIN chart c
        ON ce.chart_id = c.chart_id

      WHERE sa1.artist_id = ?
        AND sa2.artist_id = ?
        AND c.name = 'Billboard Hot 100'

      GROUP BY
        s.song_id,
        s.title,
        s.artist_credit

      ORDER BY chart_score DESC
      ''',
      [
        artist1Id,
        artist2Id,
      ],
    );
  }
}