import 'package:flutter/material.dart';

import '../../database/database_helper.dart';
import '../../repositories/collaboration_repository.dart';
import '../songs/song_detail_screen.dart';

class CollaborationDetailScreen extends StatefulWidget {
  final int artist1Id;
  final int artist2Id;
  final String artist1Name;
  final String artist2Name;
  final int chartScore;
  final int songCount;
  final int chartAppearances;
  final int bestPeak;

  const CollaborationDetailScreen({
    super.key,
    required this.artist1Id,
    required this.artist2Id,
    required this.artist1Name,
    required this.artist2Name,
    required this.chartScore,
    required this.songCount,
    required this.chartAppearances,
    required this.bestPeak,
  });

  @override
  State<CollaborationDetailScreen> createState() =>
      _CollaborationDetailScreenState();
}

class _CollaborationDetailScreenState
    extends State<CollaborationDetailScreen> {
  late Future<List<Map<String, dynamic>>> _songs;

  @override
  void initState() {
    super.initState();

    _songs = _loadSongs();
  }

  Future<List<Map<String, dynamic>>> _loadSongs() async {
    final db = await DatabaseHelper.instance.database;
    final repository = CollaborationRepository(db);

    return repository.getCollaborationSongs(
      artist1Id: widget.artist1Id,
      artist2Id: widget.artist2Id,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Collaboration Details'),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _songs,
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
                  'Failed to load collaboration data.\n\n'
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
              // ============================================================
              // COLLABORATION HEADER
              // ============================================================

              Text(
                '${widget.artist1Name} × ${widget.artist2Name}',
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                'Billboard Hot 100',
                style: TextStyle(
                  fontSize: 16,
                ),
              ),

              const SizedBox(height: 24),

              // ============================================================
              // STATS
              // ============================================================

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
                      icon: Icons.emoji_events_outlined,
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

              // ============================================================
              // SONGS
              // ============================================================

              const Text(
                'Collaboration Songs',
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 6),

              const Text(
                'Songs featuring both artists.',
              ),

              const SizedBox(height: 16),

              if (songs.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Text(
                      'No collaboration songs found.',
                    ),
                  ),
                )
              else
                ...songs.asMap().entries.map(
                  (entry) {
                    return _CollaborationSongCard(
                      rank: entry.key + 1,
                      song: entry.value,
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
// COLLABORATION SONG CARD
// ==========================================================================

class _CollaborationSongCard extends StatelessWidget {
  final int rank;
  final Map<String, dynamic> song;

  const _CollaborationSongCard({
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
              CircleAvatar(
                radius: 20,
                child: Text('$rank'),
              ),

              const SizedBox(width: 14),

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
                      'Peak: #$peakRank • Weeks: $weeks',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall,
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              Column(
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