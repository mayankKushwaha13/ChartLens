import 'package:flutter/material.dart';

import '../../database/database_helper.dart';
import '../../repositories/song_repository.dart';
import 'song_detail_screen.dart';

class SongsScreen extends StatefulWidget {
  const SongsScreen({super.key});

  @override
  State<SongsScreen> createState() => _SongsScreenState();
}

class _SongsScreenState extends State<SongsScreen> {
  final TextEditingController _searchController = TextEditingController();

  late SongRepository _songRepository;

  List<Map<String, dynamic>> _songs = [];

  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      final db = await DatabaseHelper.instance.database;

      _songRepository = SongRepository(db);

      await _loadSongs();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _loadSongs({String query = ''}) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final songs = await _songRepository.searchSongs(query);

      if (!mounted) return;

      setState(() {
        _songs = songs;
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

  void _onSearchChanged(String value) {
    _loadSongs(query: value);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
          child: TextField(
            controller: _searchController,
            onChanged: _onSearchChanged,
            decoration: InputDecoration(
              hintText: 'Search songs or artists...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        _loadSongs();
                        setState(() {});
                      },
                    )
                  : null,
              filled: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),

        Expanded(child: _buildContent()),
      ],
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Failed to load songs.\n\n$_error',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    if (_songs.isEmpty) {
      return const Center(
        child: Text('No songs found.', style: TextStyle(fontSize: 16)),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _loadSongs(query: _searchController.text),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        itemCount: _songs.length,
        itemBuilder: (context, index) {
          final song = _songs[index];

          return _SongCard(
            song: song,
            rank: index + 1,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SongDetailScreen(
                    songId: song['song_id'] as int,
                    title: song['title']?.toString() ?? 'Unknown Song',
                    artist:
                        song['artist_credit']?.toString() ?? 'Unknown Artist',
                    peakRank: (song['peak_rank'] as num?)?.toInt() ?? 0,
                    weeksOnChart:
                        (song['weeks_on_chart'] as num?)?.toInt() ?? 0,
                    chartScore: (song['chart_score'] as num?)?.toInt() ?? 0,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _SongCard extends StatelessWidget {
  final Map<String, dynamic> song;
  final int rank;
  final VoidCallback onTap;

  const _SongCard({
    required this.song,
    required this.rank,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final title = song['title']?.toString() ?? 'Unknown Song';
    final artist = song['artist_credit']?.toString() ?? 'Unknown Artist';
    final peakRank = song['peak_rank'] ?? '-';
    final weeks = song['weeks_on_chart'] ?? 0;
    final score = song['chart_score'] ?? 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              CircleAvatar(radius: 20, child: Text('$rank')),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 3),

                    Text(
                      artist,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),

                    const SizedBox(height: 8),

                    Row(
                      children: [
                        _MiniStat(label: 'Peak', value: '#$peakRank'),
                        const SizedBox(width: 14),
                        _MiniStat(label: 'Weeks', value: '$weeks'),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '$score',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const Text('score', style: TextStyle(fontSize: 10)),
                ],
              ),

              const SizedBox(width: 4),

              const Icon(Icons.chevron_right, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;

  const _MiniStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text('$label: ', style: Theme.of(context).textTheme.bodySmall),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
        ),
      ],
    );
  }
}
