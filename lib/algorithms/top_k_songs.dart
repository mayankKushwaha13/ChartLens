import '../repositories/song_repository.dart';
import 'min_heap.dart';

class TopKSongs {
  static List<Map<String, dynamic>> getTopSongs(
    List<Map<String, dynamic>> songs, {
    int k = 10,
  }) {
    if (k <= 0 || songs.isEmpty) {
      return [];
    }

    final heap = MinHeap<Map<String, dynamic>>(
      compare: (a, b) {
        final scoreA =
            (a['chart_score'] as num?)?.toInt() ?? 0;

        final scoreB =
            (b['chart_score'] as num?)?.toInt() ?? 0;

        return scoreA.compareTo(scoreB);
      },
    );

    for (final song in songs) {
      if (heap.length < k) {
        heap.add(song);
        continue;
      }

      final currentMinimum = heap.minimum;

      final currentMinimumScore =
          (currentMinimum['chart_score'] as num?)?.toInt() ?? 0;

      final songScore =
          (song['chart_score'] as num?)?.toInt() ?? 0;

      if (songScore > currentMinimumScore) {
        heap.removeMin();
        heap.add(song);
      }
    }

    final result = heap.toSortedList();

    return result.reversed.toList();
  }

  static Future<List<Map<String, dynamic>>> getTopSongsFromRepository(
    SongRepository repository, {
    int k = 10,
  }) async {
    final songs = await repository.getAllSongsForRanking();

    return getTopSongs(
      songs,
      k: k,
    );
  }
}