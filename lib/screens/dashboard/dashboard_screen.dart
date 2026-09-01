import 'package:flutter/material.dart';

import '../../database/database_helper.dart';
import '../../repositories/album_repository.dart';
import '../../repositories/artist_repository.dart';
import '../../repositories/song_repository.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late Future<_DashboardData> _dashboardData;

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

    final topSongs = await songRepository.getTopSongs(limit: 5);
    final topArtists = await artistRepository.getTopArtists(limit: 5);
    final topAlbums = await albumRepository.getTopAlbums(limit: 5);

    return _DashboardData(
      songCount: (songCountResult.first['count'] as int?) ?? 0,
      artistCount: (artistCountResult.first['count'] as int?) ?? 0,
      albumCount: (albumCountResult.first['count'] as int?) ?? 0,
      chartEntryCount: (chartEntryResult.first['count'] as int?) ?? 0,
      topSongs: topSongs,
      topArtists: topArtists,
      topAlbums: topAlbums,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_DashboardData>(
      future: _dashboardData,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Failed to load dashboard.\n\n${snapshot.error}',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        final data = snapshot.data!;

        return RefreshIndicator(
          onRefresh: () async {
            setState(() {
              _dashboardData = _loadDashboardData();
            });

            await _dashboardData;
          },
          child: ListView(
            padding: const EdgeInsets.all(20),
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
                'Explore Billboard chart data from 2024–2025.',
                style: Theme.of(context).textTheme.bodyLarge,
              ),

              const SizedBox(height: 24),

              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.15,
                children: [
                  _StatCard(
                    icon: Icons.music_note,
                    value: data.songCount,
                    label: 'Songs',
                  ),
                  _StatCard(
                    icon: Icons.person,
                    value: data.artistCount,
                    label: 'Artists',
                  ),
                  _StatCard(
                    icon: Icons.album,
                    value: data.albumCount,
                    label: 'Albums',
                  ),
                  _StatCard(
                    icon: Icons.bar_chart,
                    value: data.chartEntryCount,
                    label: 'Chart Entries',
                  ),
                ],
              ),

              const SizedBox(height: 32),

              _SectionHeader(
                title: 'Top Songs',
                subtitle: 'Based on ChartLens score',
              ),

              const SizedBox(height: 12),

              ...data.topSongs.asMap().entries.map(
                (entry) {
                  final index = entry.key;
                  final song = entry.value;

                  return _RankingCard(
                    rank: index + 1,
                    title: song['title']?.toString() ?? 'Unknown Song',
                    subtitle:
                        song['artist_credit']?.toString() ?? 'Unknown Artist',
                    score: song['chart_score']?.toString() ?? '0',
                  );
                },
              ),

              const SizedBox(height: 32),

              _SectionHeader(
                title: 'Top Artists',
                subtitle: 'Based on chart performance',
              ),

              const SizedBox(height: 12),

              ...data.topArtists.asMap().entries.map(
                (entry) {
                  final index = entry.key;
                  final artist = entry.value;

                  return _RankingCard(
                    rank: index + 1,
                    title: artist['name']?.toString() ?? 'Unknown Artist',
                    subtitle:
                        '${artist['song_count'] ?? 0} songs • '
                        '${artist['chart_appearances'] ?? 0} appearances',
                    score: artist['chart_score']?.toString() ?? '0',
                  );
                },
              ),

              const SizedBox(height: 32),

              _SectionHeader(
                title: 'Top Albums',
                subtitle: 'Based on Billboard 200 performance',
              ),

              const SizedBox(height: 12),

              ...data.topAlbums.asMap().entries.map(
                (entry) {
                  final index = entry.key;
                  final album = entry.value;

                  return _RankingCard(
                    rank: index + 1,
                    title: album['title']?.toString() ?? 'Unknown Album',
                    subtitle:
                        album['artist_credit']?.toString() ?? 'Unknown Artist',
                    score: album['chart_score']?.toString() ?? '0',
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

  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 28,
              color: Theme.of(context).colorScheme.primary,
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
      crossAxisAlignment: CrossAxisAlignment.start,
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
          style: Theme.of(context).textTheme.bodyMedium,
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

  const _RankingCard({
    required this.rank,
    required this.title,
    required this.subtitle,
    required this.score,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          child: Text('$rank'),
        ),
        title: Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          subtitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              score,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            const Text(
              'score',
              style: TextStyle(fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}