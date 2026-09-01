import 'package:flutter/material.dart';

import '../../algorithms/top_k_songs.dart';
import '../../database/database_helper.dart';
import '../../repositories/album_repository.dart';
import '../../repositories/artist_repository.dart';
import '../../repositories/song_repository.dart';

import '../albums/album_detail_screen.dart';
import '../artists/artist_detail_screen.dart';
import '../songs/song_detail_screen.dart';

class DashboardScreen extends StatefulWidget {
  final ValueChanged<int>? onNavigate;

  const DashboardScreen({
    super.key,
    this.onNavigate,
  });

  @override
  State<DashboardScreen> createState() =>
      _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late Future<_DashboardData> _dashboardData;

  int _topK = 5;

  @override
  void initState() {
    super.initState();

    _dashboardData = _loadDashboardData();
  }

  Future<_DashboardData> _loadDashboardData() async {
    final db = await DatabaseHelper.instance.database;

    final songRepository = SongRepository(db);
    final artistRepository = ArtistRepository(db);
    final albumRepository = AlbumRepository(db);

    final songCountResult = await db.rawQuery(
      'SELECT COUNT(*) AS count FROM song',
    );

    final artistCountResult = await db.rawQuery(
      'SELECT COUNT(*) AS count FROM artist',
    );

    final albumCountResult = await db.rawQuery(
      'SELECT COUNT(*) AS count FROM album',
    );

    final chartEntryResult = await db.rawQuery(
      'SELECT COUNT(*) AS count FROM chart_entry',
    );

    final topSongs =
        await TopKSongs.getTopSongsFromRepository(
      songRepository,
      k: _topK,
    );

    final topArtists =
        await artistRepository.getTopArtists(
      limit: 5,
    );

    final topAlbums =
        await albumRepository.getTopAlbums(
      limit: 5,
    );

    return _DashboardData(
      songCount:
          (songCountResult.first['count'] as int?) ?? 0,
      artistCount:
          (artistCountResult.first['count'] as int?) ?? 0,
      albumCount:
          (albumCountResult.first['count'] as int?) ?? 0,
      chartEntryCount:
          (chartEntryResult.first['count'] as int?) ?? 0,
      topSongs: topSongs,
      topArtists: topArtists,
      topAlbums: topAlbums,
    );
  }

  void _openSongs() {
    widget.onNavigate?.call(1);
  }

  void _openArtists() {
    widget.onNavigate?.call(2);
  }

  void _openAlbums() {
    widget.onNavigate?.call(3);
  }

  void _openSong(
    Map<String, dynamic> song,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SongDetailScreen(
          songId:
              (song['song_id'] as num).toInt(),
          title:
              song['title']?.toString() ??
                  'Unknown Song',
          artist:
              song['artist_credit']?.toString() ??
                  'Unknown Artist',
          peakRank:
              (song['peak_rank'] as num?)
                      ?.toInt() ??
                  0,
          weeksOnChart:
              (song['weeks_on_chart'] as num?)
                      ?.toInt() ??
                  0,
          chartScore:
              (song['chart_score'] as num?)
                      ?.toInt() ??
                  0,
        ),
      ),
    );
  }

  void _openArtist(
    Map<String, dynamic> artist,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ArtistDetailScreen(
          artistId:
              (artist['artist_id'] as num)
                  .toInt(),
          artistName:
              artist['name']?.toString() ??
                  'Unknown Artist',
          chartScore:
              (artist['chart_score'] as num?)
                      ?.toInt() ??
                  0,
          songCount:
              (artist['song_count'] as num?)
                      ?.toInt() ??
                  0,
          chartAppearances:
              (artist['chart_appearances'] as num?)
                      ?.toInt() ??
                  0,
          bestPeak:
              (artist['best_peak'] as num?)
                      ?.toInt() ??
                  0,
        ),
      ),
    );
  }

  void _openAlbum(
    Map<String, dynamic> album,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AlbumDetailScreen(
          albumId:
              (album['album_id'] as num)
                  .toInt(),
          title:
              album['title']?.toString() ??
                  'Unknown Album',
          artist:
              album['artist_credit']?.toString() ??
                  'Unknown Artist',
          peakRank:
              (album['peak_rank'] as num?)
                      ?.toInt() ??
                  0,
          weeksOnChart:
              (album['weeks_on_chart'] as num?)
                      ?.toInt() ??
                  0,
          chartScore:
              (album['chart_score'] as num?)
                      ?.toInt() ??
                  0,
        ),
      ),
    );
  }

  Future<void> _changeTopK(int value) async {
    setState(() {
      _topK = value;
      _dashboardData = _loadDashboardData();
    });

    await _dashboardData;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_DashboardData>(
      future: _dashboardData,
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
                'Failed to load dashboard.\n\n'
                '${snapshot.error}',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        final data = snapshot.data!;

        return RefreshIndicator(
          onRefresh: () async {
            setState(() {
              _dashboardData =
                  _loadDashboardData();
            });

            await _dashboardData;
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              20,
              20,
              20,
              24,
            ),
            children: [
              const Text(
                'Welcome to ChartLens',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 6),

              Text(
                'Explore Billboard chart data from 2022–2025.',
                style: Theme.of(context)
                    .textTheme
                    .bodyLarge,
              ),

              const SizedBox(height: 24),

              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics:
                    const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.15,
                children: [
                  _StatCard(
                    icon: Icons.music_note,
                    value: data.songCount,
                    label: 'Songs',
                    onTap: _openSongs,
                  ),
                  _StatCard(
                    icon: Icons.person,
                    value: data.artistCount,
                    label: 'Artists',
                    onTap: _openArtists,
                  ),
                  _StatCard(
                    icon: Icons.album,
                    value: data.albumCount,
                    label: 'Albums',
                    onTap: _openAlbums,
                  ),
                  _StatCard(
                    icon: Icons.bar_chart,
                    value: data.chartEntryCount,
                    label: 'Chart Entries',
                  ),
                ],
              ),

              const SizedBox(height: 32),

              Row(
                crossAxisAlignment:
                    CrossAxisAlignment.center,
                children: [
                  const Expanded(
                    child: _SectionHeader(
                      title: 'Top Songs',
                      subtitle:
                          'Based on ChartLens score',
                    ),
                  ),
                  DropdownButton<int>(
                    value: _topK,
                    underline: const SizedBox(),
                    items: const [
                      DropdownMenuItem(
                        value: 5,
                        child: Text('Top 5'),
                      ),
                      DropdownMenuItem(
                        value: 10,
                        child: Text('Top 10'),
                      ),
                      DropdownMenuItem(
                        value: 20,
                        child: Text('Top 20'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        _changeTopK(value);
                      }
                    },
                  ),
                ],
              ),

              const SizedBox(height: 12),

              ...data.topSongs.asMap().entries.map(
                (entry) {
                  final index = entry.key;
                  final song = entry.value;

                  return _RankingCard(
                    rank: index + 1,
                    title:
                        song['title']
                                ?.toString() ??
                            'Unknown Song',
                    subtitle:
                        song['artist_credit']
                                ?.toString() ??
                            'Unknown Artist',
                    score:
                        song['chart_score']
                                ?.toString() ??
                            '0',
                    onTap: () {
                      _openSong(song);
                    },
                  );
                },
              ),

              const SizedBox(height: 32),

              const _SectionHeader(
                title: 'Top Artists',
                subtitle:
                    'Based on chart performance',
              ),

              const SizedBox(height: 12),

              ...data.topArtists.asMap().entries.map(
                (entry) {
                  final index = entry.key;
                  final artist = entry.value;

                  final songCount =
                      (artist['song_count'] as num?)
                              ?.toInt() ??
                          0;

                  final appearances =
                      (artist['chart_appearances']
                                  as num?)
                              ?.toInt() ??
                          0;

                  return _RankingCard(
                    rank: index + 1,
                    title:
                        artist['name']
                                ?.toString() ??
                            'Unknown Artist',
                    subtitle:
                        '$songCount '
                        '${songCount == 1 ? 'song' : 'songs'} • '
                        '$appearances '
                        '${appearances == 1 ? 'appearance' : 'appearances'}',
                    score:
                        artist['chart_score']
                                ?.toString() ??
                            '0',
                    onTap: () {
                      _openArtist(artist);
                    },
                  );
                },
              ),

              const SizedBox(height: 32),

              const _SectionHeader(
                title: 'Top Albums',
                subtitle:
                    'Based on Billboard 200 performance',
              ),

              const SizedBox(height: 12),

              ...data.topAlbums.asMap().entries.map(
                (entry) {
                  final index = entry.key;
                  final album = entry.value;

                  return _RankingCard(
                    rank: index + 1,
                    title:
                        album['title']
                                ?.toString() ??
                            'Unknown Album',
                    subtitle:
                        album['artist_credit']
                                ?.toString() ??
                            'Unknown Artist',
                    score:
                        album['chart_score']
                                ?.toString() ??
                            '0',
                    onTap: () {
                      _openAlbum(album);
                    },
                  );
                },
              ),

              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }
}

class _DashboardData {
  final int songCount;
  final int artistCount;
  final int albumCount;
  final int chartEntryCount;

  final List<Map<String, dynamic>> topSongs;
  final List<Map<String, dynamic>> topArtists;
  final List<Map<String, dynamic>> topAlbums;

  const _DashboardData({
    required this.songCount,
    required this.artistCount,
    required this.albumCount,
    required this.chartEntryCount,
    required this.topSongs,
    required this.topArtists,
    required this.topAlbums,
  });
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final int value;
  final String label;
  final VoidCallback? onTap;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius:
            BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            mainAxisAlignment:
                MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 28,
                color: Theme.of(context)
                    .colorScheme
                    .primary,
              ),
              const SizedBox(height: 10),
              Text(
                value.toString(),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(label),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionHeader({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          subtitle,
          style: Theme.of(context)
              .textTheme
              .bodyMedium,
        ),
      ],
    );
  }
}

class _RankingCard extends StatelessWidget {
  final int rank;
  final String title;
  final String subtitle;
  final String score;
  final VoidCallback? onTap;

  const _RankingCard({
    required this.rank,
    required this.title,
    required this.subtitle,
    required this.score,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin:
          const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius:
            BorderRadius.circular(12),
        onTap: onTap,
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
                        fontWeight:
                            FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow:
                          TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              Column(
                mainAxisAlignment:
                    MainAxisAlignment.center,
                children: [
                  Text(
                    score,
                    style: const TextStyle(
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                  const Text(
                    'score',
                    style: TextStyle(
                      fontSize: 11,
                    ),
                  ),
                ],
              ),

              if (onTap != null) ...[
                const SizedBox(width: 4),
                const Icon(
                  Icons.chevron_right,
                  size: 20,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}