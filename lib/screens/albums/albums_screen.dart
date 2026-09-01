import 'package:flutter/material.dart';

import '../../database/database_helper.dart';
import '../../repositories/album_repository.dart';
import 'album_detail_screen.dart';

class AlbumsScreen extends StatefulWidget {
  const AlbumsScreen({super.key});

  @override
  State<AlbumsScreen> createState() => _AlbumsScreenState();
}

class _AlbumsScreenState extends State<AlbumsScreen> {
  final TextEditingController _searchController = TextEditingController();

  late AlbumRepository _albumRepository;

  List<Map<String, dynamic>> _albums = [];

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

      _albumRepository = AlbumRepository(db);

      await _loadAlbums();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _loadAlbums({String query = ''}) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final albums = await _albumRepository.searchAlbums(query);

      if (!mounted) return;

      setState(() {
        _albums = albums;
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
    _loadAlbums(query: value);
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
        // ============================================================
        // SEARCH
        // ============================================================

        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
          child: TextField(
            controller: _searchController,
            onChanged: _onSearchChanged,
            decoration: InputDecoration(
              hintText: 'Search albums...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();

                        _loadAlbums();

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

        // ============================================================
        // CONTENT
        // ============================================================
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
            'Failed to load albums.\n\n$_error',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    if (_albums.isEmpty) {
      return const Center(
        child: Text('No albums found.', style: TextStyle(fontSize: 16)),
      );
    }

    return RefreshIndicator(
      onRefresh: () {
        return _loadAlbums(query: _searchController.text);
      },
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        itemCount: _albums.length,
        itemBuilder: (context, index) {
          final album = _albums[index];

          return _AlbumCard(
            album: album,
            rank: index + 1,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AlbumDetailScreen(
                    albumId: (album['album_id'] as num).toInt(),
                    title: album['title']?.toString() ?? 'Unknown Album',
                    artist:
                        album['artist_credit']?.toString() ?? 'Unknown Artist',
                    peakRank: (album['peak_rank'] as num?)?.toInt() ?? 0,
                    weeksOnChart:
                        (album['weeks_on_chart'] as num?)?.toInt() ?? 0,
                    chartScore: (album['chart_score'] as num?)?.toInt() ?? 0,
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

// ==========================================================================
// ALBUM CARD
// ==========================================================================

class _AlbumCard extends StatelessWidget {
  final Map<String, dynamic> album;
  final int rank;
  final VoidCallback onTap;

  const _AlbumCard({
    required this.album,
    required this.rank,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final title = album['title']?.toString() ?? 'Unknown Album';

    final artist = album['artist_credit']?.toString() ?? 'Unknown Artist';

    final weeks = album['weeks_on_chart'] ?? 0;

    final peak = album['peak_rank'] ?? '-';

    final score = album['chart_score'] ?? 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              // ========================================================
              // RANK
              // ========================================================

              CircleAvatar(radius: 20, child: Text('$rank')),

              const SizedBox(width: 14),

              // ========================================================
              // ALBUM INFO
              // ========================================================
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

                    const SizedBox(height: 4),

                    Text(
                      artist,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),

                    const SizedBox(height: 6),

                    Text(
                      'Peak: #$peak  •  '
                      'Weeks: $weeks',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // ========================================================
              // SCORE
              // ========================================================
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
