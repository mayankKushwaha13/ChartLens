import 'package:flutter/material.dart';

import '../../database/database_helper.dart';
import '../../repositories/artist_repository.dart';
import 'artist_detail_screen.dart';

class ArtistsScreen extends StatefulWidget {
  const ArtistsScreen({super.key});

  @override
  State<ArtistsScreen> createState() => _ArtistsScreenState();
}

class _ArtistsScreenState extends State<ArtistsScreen> {
  final TextEditingController _searchController = TextEditingController();

  late ArtistRepository _artistRepository;

  List<Map<String, dynamic>> _artists = [];

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

      _artistRepository = ArtistRepository(db);

      await _loadArtists();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _loadArtists({String query = ''}) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final artists = await _artistRepository.searchArtists(query);

      if (!mounted) return;

      setState(() {
        _artists = artists;
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
    _loadArtists(query: value);
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
              hintText: 'Search artists...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();

                        _loadArtists();

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
            'Failed to load artists.\n\n$_error',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    if (_artists.isEmpty) {
      return const Center(
        child: Text('No artists found.', style: TextStyle(fontSize: 16)),
      );
    }

    return RefreshIndicator(
      onRefresh: () {
        return _loadArtists(query: _searchController.text);
      },
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        itemCount: _artists.length,
        itemBuilder: (context, index) {
          final artist = _artists[index];

          return _ArtistCard(
            artist: artist,
            rank: index + 1,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ArtistDetailScreen(
                    artistId: (artist['artist_id'] as num).toInt(),
                    artistName: artist['name']?.toString() ?? 'Unknown Artist',
                    chartScore: (artist['chart_score'] as num?)?.toInt() ?? 0,
                    songCount: (artist['song_count'] as num?)?.toInt() ?? 0,
                    chartAppearances:
                        (artist['chart_appearances'] as num?)?.toInt() ?? 0,
                    bestPeak: (artist['best_peak'] as num?)?.toInt() ?? 0,
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
// ARTIST CARD
// ==========================================================================

class _ArtistCard extends StatelessWidget {
  final Map<String, dynamic> artist;
  final int rank;
  final VoidCallback onTap;

  const _ArtistCard({
    required this.artist,
    required this.rank,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final name = artist['name']?.toString() ?? 'Unknown Artist';

    final songCount = artist['song_count'] ?? 0;

    final appearances = artist['chart_appearances'] ?? 0;

    final bestPeak = artist['best_peak'] ?? '-';

    final score = artist['chart_score'] ?? 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              // RANK
              CircleAvatar(radius: 20, child: Text('$rank')),

              const SizedBox(width: 14),

              // ARTIST INFO
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      '$songCount songs • '
                      '$appearances chart appearances',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),

                    const SizedBox(height: 6),

                    Text(
                      'Best peak: #$bestPeak',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // SCORE
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
