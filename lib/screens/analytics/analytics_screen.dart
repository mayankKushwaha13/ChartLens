import 'package:flutter/material.dart';

import '../../database/database_helper.dart';
import '../../repositories/song_repository.dart';
import '../../services/analytics_service.dart';
import '../songs/song_detail_screen.dart';
import '../artists/artist_detail_screen.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  int _selectedYear = 2025;

  late SongRepository _songRepository;

  bool _isLoading = true;
  String? _error;

  List<Map<String, dynamic>> _topSongs = [];
  List<Map<String, dynamic>> _topArtists = [];

  @override
  void initState() {
    super.initState();

    _initialize();
  }

  Future<void> _initialize() async {
    try {
      final db = await DatabaseHelper.instance.database;

      _songRepository = SongRepository(db);

      await _loadAnalytics();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _loadAnalytics() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final songs =
          await AnalyticsService.getTopSongsForYear(
        repository: _songRepository,
        year: _selectedYear,
        limit: 10,
      );

      final artists =
          await AnalyticsService.getTopArtistsForYear(
        repository: _songRepository,
        year: _selectedYear,
        limit: 10,
      );

      if (!mounted) return;

      setState(() {
        _topSongs = songs;
        _topArtists = artists;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _changeYear(int year) async {
    setState(() {
      _selectedYear = year;
    });

    await _loadAnalytics();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ============================================================
        // HEADER
        // ============================================================

        Padding(
          padding: const EdgeInsets.fromLTRB(
            20,
            20,
            20,
            8,
          ),
          child: Row(
            mainAxisAlignment:
                MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Analytics',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),

              DropdownButton<int>(
                value: _selectedYear,
                items: const [
                  DropdownMenuItem(
                    value: 2022,
                    child: Text('2022'),
                  ),
                  DropdownMenuItem(
                    value: 2023,
                    child: Text('2023'),
                  ),
                  DropdownMenuItem(
                    value: 2024,
                    child: Text('2024'),
                  ),
                  DropdownMenuItem(
                    value: 2025,
                    child: Text('2025'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    _changeYear(value);
                  }
                },
              ),
            ],
          ),
        ),

        // ============================================================
        // CONTENT
        // ============================================================

        Expanded(
          child: _buildContent(),
        ),
      ],
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Failed to load analytics.\n\n$_error',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        20,
        8,
        20,
        20,
      ),
      children: [
        // ============================================================
        // YEAR DESCRIPTION
        // ============================================================

        Text(
          'Billboard performance in $_selectedYear',
          style: Theme.of(context)
              .textTheme
              .bodyMedium,
        ),

        const SizedBox(height: 24),

        // ============================================================
        // TOP SONGS
        // ============================================================

        const Text(
          'Top Songs',
          style: TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 6),

        const Text(
          'Ranked by ChartLens score.',
        ),

        const SizedBox(height: 12),

        ..._topSongs.asMap().entries.map(
          (entry) {
            return _SongAnalyticsCard(
              rank: entry.key + 1,
              song: entry.value,
            );
          },
        ),

        const SizedBox(height: 28),

        // ============================================================
        // TOP ARTISTS
        // ============================================================

        const Text(
          'Top Artists',
          style: TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 6),

        const Text(
          'Ranked by total Billboard impact.',
        ),

        const SizedBox(height: 12),

        ..._topArtists.asMap().entries.map(
          (entry) {
            return _ArtistAnalyticsCard(
              rank: entry.key + 1,
              artist: entry.value,
            );
          },
        ),
      ],
    );
  }
}

// ==========================================================================
// SONG ANALYTICS CARD
// ==========================================================================

class _SongAnalyticsCard extends StatelessWidget {
  final int rank;
  final Map<String, dynamic> song;

  const _SongAnalyticsCard({
    required this.rank,
    required this.song,
  });

  @override
  Widget build(BuildContext context) {
    final title =
        song['title']?.toString() ??
        'Unknown Song';

    final artist =
        song['artist_credit']?.toString() ??
        'Unknown Artist';

    final score =
        (song['chart_score'] as num?)?.toInt() ?? 0;

    final peak =
        (song['peak_rank'] as num?)?.toInt() ?? 0;

    final weeks =
        (song['weeks_on_chart'] as num?)?.toInt() ?? 0;

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
                artist: artist,
                peakRank: peak,
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
                      artist,
                      maxLines: 1,
                      overflow:
                          TextOverflow.ellipsis,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall,
                    ),

                    const SizedBox(height: 6),

                    Text(
                      'Peak: #$peak • Weeks: $weeks',
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

// ==========================================================================
// ARTIST ANALYTICS CARD
// ==========================================================================

class _ArtistAnalyticsCard extends StatelessWidget {
  final int rank;
  final Map<String, dynamic> artist;

  const _ArtistAnalyticsCard({
    required this.rank,
    required this.artist,
  });

  @override
  Widget build(BuildContext context) {
    final name =
        artist['name']?.toString() ??
        'Unknown Artist';

    final score =
        (artist['chart_score'] as num?)?.toInt() ?? 0;

    final songCount =
        (artist['song_count'] as num?)?.toInt() ?? 0;

    final appearances =
        (artist['chart_appearances'] as num?)?.toInt() ??
            0;

    final bestPeak =
        (artist['best_peak'] as num?)?.toInt() ?? 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ArtistDetailScreen(
                artistId:
                    (artist['artist_id'] as num).toInt(),
                artistName:
                    name,
                chartScore:
                    score,
                songCount:
                    songCount,
                chartAppearances:
                    appearances,
                bestPeak:
                    bestPeak,
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

              // ARTIST INFORMATION
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
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
                      '$songCount songs • '
                      '$appearances appearances',
                      maxLines: 1,
                      overflow:
                          TextOverflow.ellipsis,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall,
                    ),

                    const SizedBox(height: 6),

                    Text(
                      'Best peak: #$bestPeak',
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