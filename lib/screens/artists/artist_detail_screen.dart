import 'package:flutter/material.dart';

import '../../database/database_helper.dart';
import '../../repositories/artist_repository.dart';
import '../songs/song_detail_screen.dart';

class ArtistDetailScreen extends StatefulWidget {
  final int artistId;
  final String artistName;
  final int chartScore;
  final int songCount;
  final int chartAppearances;
  final int bestPeak;

  const ArtistDetailScreen({
    super.key,
    required this.artistId,
    required this.artistName,
    required this.chartScore,
    required this.songCount,
    required this.chartAppearances,
    required this.bestPeak,
  });

  @override
  State<ArtistDetailScreen> createState() =>
      _ArtistDetailScreenState();
}

class _ArtistDetailScreenState
    extends State<ArtistDetailScreen> {
  late Future<List<Map<String, dynamic>>> _artistSongs;

  @override
  void initState() {
    super.initState();

    _artistSongs = _loadArtistSongs();
  }

  Future<List<Map<String, dynamic>>> _loadArtistSongs() async {
    final db = await DatabaseHelper.instance.database;
    final repository = ArtistRepository(db);

    return repository.getArtistSongs(widget.artistId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Artist Details'),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _artistSongs,
        builder: (context, snapshot) {
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Failed to load artist data.\n\n'
                  '${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final songs = snapshot.data ?? [];

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // ==========================================================
              // ARTIST HEADER
              // ==========================================================

              Text(
                widget.artistName,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 6),

              const Text(
                'Billboard Hot 100',
                style: TextStyle(
                  fontSize: 16,
                ),
              ),

              const SizedBox(height: 24),

              // ==========================================================
              // ARTIST STATS
              // ==========================================================

              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      icon: Icons.music_note_outlined,
                      label: 'Songs',
                      value: '${widget.songCount}',
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: _StatCard(
                      icon: Icons.bar_chart_outlined,
                      label: 'Appearances',
                      value:
                          '${widget.chartAppearances}',
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      icon:
                          Icons.emoji_events_outlined,
                      label: 'Best Peak',
                      value: '#${widget.bestPeak}',
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: _StatCard(
                      icon: Icons.analytics_outlined,
                      label: 'ChartLens Score',
                      value: '${widget.chartScore}',
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // ==========================================================
              // SONGS SECTION
              // ==========================================================

              const Text(
                'Top Songs',
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 6),

              Text(
                'Songs ranked by Billboard performance.',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium,
              ),

              const SizedBox(height: 16),

              if (songs.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Text(
                      'No songs found for this artist.',
                    ),
                  ),
                )
              else
                ...songs.asMap().entries.map(
                  (entry) {
                    final index = entry.key;
                    final song = entry.value;

                    return _ArtistSongCard(
                      rank: index + 1,
                      song: song,
                    );
                  },
                ),

              const SizedBox(height: 24),
            ],
          );
        },
      ),
    );
  }
}

// ==========================================================================
// STAT CARD
// ==========================================================================

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              icon,
              color: Theme.of(context)
                  .colorScheme
                  .primary,
            ),

            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall,
                  ),

                  const SizedBox(height: 4),

                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================================================
// ARTIST SONG CARD
// ==========================================================================

class _ArtistSongCard extends StatelessWidget {
  final int rank;
  final Map<String, dynamic> song;

  const _ArtistSongCard({
    required this.rank,
    required this.song,
  });

  @override
  Widget build(BuildContext context) {
    final title =
        song['title']?.toString() ??
        'Unknown Song';

    final artistCredit =
        song['artist_credit']?.toString() ??
        'Unknown Artist';

    final peakRank =
        (song['peak_rank'] as num?)?.toInt() ?? 0;

    final weeks =
        (song['weeks_on_chart'] as num?)?.toInt() ?? 0;

    final score =
        (song['chart_score'] as num?)?.toInt() ?? 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => SongDetailScreen(
                songId:
                    (song['song_id'] as num).toInt(),
                title: title,
                artist: artistCredit,
                peakRank: peakRank,
                weeksOnChart: weeks,
                chartScore: score,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 12,
          ),
          child: Row(
            children: [
              // RANK
              CircleAvatar(
                radius: 20,
                child: Text('$rank'),
              ),

              const SizedBox(width: 14),

              // SONG INFORMATION
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow:
                          TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      artistCredit,
                      maxLines: 1,
                      overflow:
                          TextOverflow.ellipsis,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall,
                    ),

                    const SizedBox(height: 6),

                    Text(
                      'Peak: #$peakRank  •  '
                      'Weeks: $weeks',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall,
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // SCORE
              Column(
                mainAxisAlignment:
                    MainAxisAlignment.center,
                children: [
                  Text(
                    '$score',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const Text(
                    'score',
                    style: TextStyle(
                      fontSize: 10,
                    ),
                  ),
                ],
              ),

              const SizedBox(width: 4),

              const Icon(
                Icons.chevron_right,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}