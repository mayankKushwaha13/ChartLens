import '../repositories/song_repository.dart';

class AnalyticsService {
  // ============================================================
  // CHART SCORE
  // ============================================================

  static int hot100Points(int rank) {
    return 101 - rank;
  }

  static int billboard200Points(int rank) {
    return 201 - rank;
  }

  // ============================================================
  // RANK MOVEMENT
  // ============================================================

  static int calculateRankChange(
    int previousRank,
    int currentRank,
  ) {
    return previousRank - currentRank;
  }

  static int calculateBiggestClimb(
    List<Map<String, dynamic>> history,
  ) {
    int biggestClimb = 0;

    for (final entry in history) {
      final currentRank = entry['rank'] as int?;
      final previousRank =
          entry['last_week_rank'] as int?;

      if (currentRank == null ||
          previousRank == null) {
        continue;
      }

      final improvement = calculateRankChange(
        previousRank,
        currentRank,
      );

      if (improvement > biggestClimb) {
        biggestClimb = improvement;
      }
    }

    return biggestClimb;
  }

  static int calculateBiggestDrop(
    List<Map<String, dynamic>> history,
  ) {
    int biggestDrop = 0;

    for (final entry in history) {
      final currentRank = entry['rank'] as int?;
      final previousRank =
          entry['last_week_rank'] as int?;

      if (currentRank == null ||
          previousRank == null) {
        continue;
      }

      final change = calculateRankChange(
        previousRank,
        currentRank,
      );

      if (change < biggestDrop) {
        biggestDrop = change;
      }
    }

    return biggestDrop;
  }

  // ============================================================
  // AVERAGE RANK
  // ============================================================

  static double calculateAverageRank(
    List<int> ranks,
  ) {
    if (ranks.isEmpty) return 0;

    final total = ranks.reduce(
      (value, element) => value + element,
    );

    return total / ranks.length;
  }

  // ============================================================
  // SONG ANALYTICS
  // ============================================================

  static Future<Map<String, dynamic>> getSongAnalytics({
    required SongRepository repository,
    required int songId,
  }) async {
    final history =
        await repository.getSongChartHistory(songId);

    if (history.isEmpty) {
      return {
        'weeks_on_chart': 0,
        'peak_rank': null,
        'average_rank': 0.0,
        'biggest_climb': 0,
        'biggest_drop': 0,
        'history': <Map<String, dynamic>>[],
      };
    }

    final ranks = history
        .map((entry) => entry['rank'] as int)
        .toList();

    final peakRank = ranks.reduce(
      (current, value) =>
          value < current ? value : current,
    );

    return {
      'weeks_on_chart': history.length,
      'peak_rank': peakRank,
      'average_rank': calculateAverageRank(ranks),
      'biggest_climb': calculateBiggestClimb(history),
      'biggest_drop': calculateBiggestDrop(history),
      'history': history,
    };
  }

  // ============================================================
  // YEAR UTILITIES
  // ============================================================

  static String startOfYear(int year) {
    return '$year-01-01';
  }

  static String endOfYear(int year) {
    return '$year-12-31';
  }

  // ============================================================
  // TOP SONGS FOR A YEAR
  // ============================================================

  static Future<List<Map<String, dynamic>>>
      getTopSongsForYear({
    required SongRepository repository,
    required int year,
    int limit = 10,
  }) async {
    final db = repository.db;

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
        AND ce.chart_date BETWEEN ? AND ?
      GROUP BY
        s.song_id,
        s.title,
        s.artist_credit
      ORDER BY chart_score DESC
      LIMIT ?
      ''',
      [
        startOfYear(year),
        endOfYear(year),
        limit,
      ],
    );
  }

  // ============================================================
  // TOP ARTISTS FOR A YEAR
  // ============================================================

  static Future<List<Map<String, dynamic>>>
      getTopArtistsForYear({
    required SongRepository repository,
    required int year,
    int limit = 10,
  }) async {
    final db = repository.db;

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
      JOIN chart_entry ce
        ON sa.song_id = ce.song_id
      JOIN chart c
        ON ce.chart_id = c.chart_id
      WHERE c.name = 'Billboard Hot 100'
        AND ce.chart_date BETWEEN ? AND ?
      GROUP BY
        a.artist_id,
        a.name
      ORDER BY chart_score DESC
      LIMIT ?
      ''',
      [
        startOfYear(year),
        endOfYear(year),
        limit,
      ],
    );
  }
}