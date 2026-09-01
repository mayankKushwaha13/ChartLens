import 'package:sqflite/sqflite.dart';

class SongRepository {
  final Database db;

  SongRepository(this.db);

  Future<List<Map<String, dynamic>>> getTopSongs({int limit = 10}) async {
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
      JOIN chart_entry ce
        ON s.song_id = ce.song_id
      JOIN chart c
        ON ce.chart_id = c.chart_id
      WHERE c.name = 'Billboard Hot 100'
      GROUP BY
        s.song_id,
        s.title,
        s.artist_credit
      ORDER BY chart_score DESC
      LIMIT ?
      ''',
      [limit],
    );
  }

  Future<List<Map<String, dynamic>>> searchSongs(String query) async {
    final trimmedQuery = query.trim();

    if (trimmedQuery.isEmpty) {
      return getTopSongs(limit: 50);
    }

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
      JOIN chart_entry ce
        ON s.song_id = ce.song_id
      JOIN chart c
        ON ce.chart_id = c.chart_id
      WHERE c.name = 'Billboard Hot 100'
        AND (
          s.title LIKE ?
          OR s.artist_credit LIKE ?
        )
      GROUP BY
        s.song_id,
        s.title,
        s.artist_credit
      ORDER BY chart_score DESC
      LIMIT 50
      ''',
      ['%$trimmedQuery%', '%$trimmedQuery%'],
    );
  }

  Future<List<Map<String, dynamic>>> getSongChartHistory(int songId) async {
    return await db.rawQuery(
      '''
      SELECT
        ce.chart_date,
        ce.rank,
        ce.last_week_rank,
        ce.peak_rank,
        ce.weeks_on_chart
      FROM chart_entry ce
      JOIN chart c
        ON ce.chart_id = c.chart_id
      WHERE ce.song_id = ?
        AND c.name = 'Billboard Hot 100'
      ORDER BY ce.chart_date ASC
      ''',
      [songId],
    );
  }

  Future<int> getWeeksOnChart(int songId) async {
    final result = await db.rawQuery(
      '''
      SELECT COUNT(*) AS weeks
      FROM chart_entry ce
      JOIN chart c
        ON ce.chart_id = c.chart_id
      WHERE ce.song_id = ?
        AND c.name = 'Billboard Hot 100'
      ''',
      [songId],
    );

    return Sqflite.firstIntValue(result) ?? 0;
  }
}
