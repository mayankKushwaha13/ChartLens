import 'package:sqflite/sqflite.dart';

class ChartRepository {
  final Database db;

  ChartRepository(this.db);

  Future<List<String>> getHot100Dates() async {
    final result = await db.rawQuery(
      '''
      SELECT DISTINCT ce.chart_date
      FROM chart_entry ce
      JOIN chart c
        ON ce.chart_id = c.chart_id
      WHERE c.name = 'Billboard Hot 100'
      ORDER BY ce.chart_date ASC
      ''',
    );

    return result
        .map((row) => row['chart_date'] as String)
        .toList();
  }

  Future<List<Map<String, dynamic>>> getHot100ForDate(
    String date,
  ) async {
    return await db.rawQuery(
      '''
      SELECT
        s.song_id,
        s.title,
        s.artist_credit,
        ce.rank,
        ce.last_week_rank,
        ce.peak_rank,
        ce.weeks_on_chart
      FROM chart_entry ce
      JOIN song s
        ON ce.song_id = s.song_id
      JOIN chart c
        ON ce.chart_id = c.chart_id
      WHERE c.name = 'Billboard Hot 100'
        AND ce.chart_date = ?
      ORDER BY ce.rank ASC
      ''',
      [date],
    );
  }

  Future<List<Map<String, dynamic>>> getBillboard200ForDate(
    String date,
  ) async {
    return await db.rawQuery(
      '''
      SELECT
        a.album_id,
        a.title,
        a.artist_credit,
        ace.rank,
        ace.last_week_rank,
        ace.peak_rank,
        ace.weeks_on_chart
      FROM album_chart_entry ace
      JOIN album a
        ON ace.album_id = a.album_id
      JOIN chart c
        ON ace.chart_id = c.chart_id
      WHERE c.name = 'Billboard 200'
        AND ace.chart_date = ?
      ORDER BY ace.rank ASC
      ''',
      [date],
    );
  }

  Future<List<Map<String, dynamic>>> getHot100BetweenDates(
    String startDate,
    String endDate,
  ) async {
    return await db.rawQuery(
      '''
      SELECT
        s.song_id,
        s.title,
        s.artist_credit,
        ce.chart_date,
        ce.rank,
        ce.last_week_rank,
        ce.peak_rank,
        ce.weeks_on_chart
      FROM chart_entry ce
      JOIN song s
        ON ce.song_id = s.song_id
      JOIN chart c
        ON ce.chart_id = c.chart_id
      WHERE c.name = 'Billboard Hot 100'
        AND ce.chart_date BETWEEN ? AND ?
      ORDER BY ce.chart_date ASC, ce.rank ASC
      ''',
      [startDate, endDate],
    );
  }
}