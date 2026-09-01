import 'package:sqflite/sqflite.dart';

class AlbumRepository {
  final Database db;

  AlbumRepository(this.db);

  // ============================================================
  // TOP ALBUMS
  // ============================================================

  /// Returns the top albums according to ChartLens score.
  ///
  /// Billboard 200:
  /// #1   -> 200 points
  /// #2   -> 199 points
  /// ...
  /// #200 -> 1 point
  Future<List<Map<String, dynamic>>> getTopAlbums({
    int limit = 10,
  }) async {
    return await db.rawQuery(
      '''
      SELECT
        a.album_id,
        a.title,
        a.artist_credit,
        SUM(201 - ace.rank) AS chart_score,
        COUNT(*) AS weeks_on_chart,
        MIN(ace.rank) AS peak_rank
      FROM album a
      JOIN album_chart_entry ace
        ON a.album_id = ace.album_id
      JOIN chart c
        ON ace.chart_id = c.chart_id
      WHERE c.name = 'Billboard 200'
      GROUP BY
        a.album_id,
        a.title,
        a.artist_credit
      ORDER BY chart_score DESC
      LIMIT ?
      ''',
      [limit],
    );
  }

  // ============================================================
  // SEARCH ALBUMS
  // ============================================================

  Future<List<Map<String, dynamic>>> searchAlbums(
    String query,
  ) async {
    final trimmedQuery = query.trim();

    if (trimmedQuery.isEmpty) {
      return getTopAlbums(limit: 50);
    }

    return await db.rawQuery(
      '''
      SELECT
        a.album_id,
        a.title,
        a.artist_credit,
        SUM(201 - ace.rank) AS chart_score,
        COUNT(*) AS weeks_on_chart,
        MIN(ace.rank) AS peak_rank
      FROM album a
      JOIN album_chart_entry ace
        ON a.album_id = ace.album_id
      JOIN chart c
        ON ace.chart_id = c.chart_id
      WHERE c.name = 'Billboard 200'
        AND (
          a.title LIKE ?
          OR a.artist_credit LIKE ?
        )
      GROUP BY
        a.album_id,
        a.title,
        a.artist_credit
      ORDER BY chart_score DESC
      LIMIT 50
      ''',
      [
        '%$trimmedQuery%',
        '%$trimmedQuery%',
      ],
    );
  }

  // ============================================================
  // ALBUM CHART HISTORY
  // ============================================================

  /// Returns the complete Billboard 200 history of an album.
  Future<List<Map<String, dynamic>>> getAlbumChartHistory(
    int albumId,
  ) async {
    return await db.rawQuery(
      '''
      SELECT
        ace.chart_date,
        ace.rank,
        ace.last_week_rank,
        ace.peak_rank,
        ace.weeks_on_chart
      FROM album_chart_entry ace
      JOIN chart c
        ON ace.chart_id = c.chart_id
      WHERE ace.album_id = ?
        AND c.name = 'Billboard 200'
      ORDER BY ace.chart_date ASC
      ''',
      [albumId],
    );
  }

  // ============================================================
  // WEEKS ON CHART
  // ============================================================

  Future<int> getWeeksOnChart(int albumId) async {
    final result = await db.rawQuery(
      '''
      SELECT COUNT(*) AS weeks
      FROM album_chart_entry ace
      JOIN chart c
        ON ace.chart_id = c.chart_id
      WHERE ace.album_id = ?
        AND c.name = 'Billboard 200'
      ''',
      [albumId],
    );

    return Sqflite.firstIntValue(result) ?? 0;
  }
}