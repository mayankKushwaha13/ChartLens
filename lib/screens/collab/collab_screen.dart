import 'package:flutter/material.dart';

import '../../database/database_helper.dart';
import '../../repositories/artist_repository.dart';
import '../../repositories/collaboration_repository.dart';
import '../../services/collaboration_graph_service.dart';
import 'collaboration_detail_screen.dart';

class CollabScreen extends StatefulWidget {
  const CollabScreen({super.key});

  @override
  State<CollabScreen> createState() => _CollabScreenState();
}

class _CollabScreenState extends State<CollabScreen> {
  int _selectedYear = 2025;

  late CollaborationRepository _repository;
  late ArtistRepository _artistRepository;
  late CollaborationGraphService _graphService;

  bool _isLoading = true;
  String? _error;

  List<Map<String, dynamic>> _collaborations = [];
  List<Map<String, dynamic>> _artists = [];

  int? _selectedArtist1;
  int? _selectedArtist2;

  bool _isFindingConnection = false;
  List<int> _connectionPath = [];
  String? _connectionError;

  int? _networkArtist;
  bool _isExploringNetwork = false;
  List<int> _networkArtists = [];
  String? _networkError;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      final db = await DatabaseHelper.instance.database;

      _repository = CollaborationRepository(db);
      _artistRepository = ArtistRepository(db);
      _graphService =
          CollaborationGraphService(_artistRepository);

      final artists =
          await _artistRepository.getAllArtists();

      await _loadCollaborations();

      if (!mounted) return;

      setState(() {
        _artists = artists;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _loadCollaborations() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final collaborations =
          await _repository.getTopCollaborationsForYear(
        year: _selectedYear,
        limit: 20,
      );

      if (!mounted) return;

      setState(() {
        _collaborations = collaborations;
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

    await _loadCollaborations();
  }

  Future<void> _findConnection() async {
    if (_selectedArtist1 == null ||
        _selectedArtist2 == null) {
      setState(() {
        _connectionError =
            'Please select two artists.';
        _connectionPath = [];
      });
      return;
    }

    if (_selectedArtist1 == _selectedArtist2) {
      setState(() {
        _connectionError =
            'Please select two different artists.';
        _connectionPath = [];
      });
      return;
    }

    setState(() {
      _isFindingConnection = true;
      _connectionError = null;
      _connectionPath = [];
    });

    try {
      final path =
          await _graphService.getShortestPath(
        _selectedArtist1!,
        _selectedArtist2!,
      );

      if (!mounted) return;

      setState(() {
        _connectionPath = path;
        _isFindingConnection = false;

        if (path.isEmpty) {
          _connectionError =
              'No collaboration path found between these artists.';
        }
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isFindingConnection = false;
        _connectionError = e.toString();
        _connectionPath = [];
      });
    }
  }

  Future<void> _exploreNetwork() async {
    if (_networkArtist == null) {
      setState(() {
        _networkError =
            'Please select an artist.';
        _networkArtists = [];
      });
      return;
    }

    setState(() {
      _isExploringNetwork = true;
      _networkError = null;
      _networkArtists = [];
    });

    try {
      final artists =
          await _graphService.getDfsTraversal(
        _networkArtist!,
      );

      if (!mounted) return;

      setState(() {
        _networkArtists = artists;
        _isExploringNetwork = false;

        if (artists.isEmpty) {
          _networkError =
              'No collaboration network found.';
        }
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isExploringNetwork = false;
        _networkError = e.toString();
        _networkArtists = [];
      });
    }
  }

  String _artistName(int artistId) {
    for (final artist in _artists) {
      final id =
          (artist['artist_id'] as num?)?.toInt();

      if (id == artistId) {
        return artist['name']?.toString() ??
            'Unknown Artist';
      }
    }

    return 'Unknown Artist';
  }

  Future<int?> _selectArtist({
    required String title,
    int? excludedArtistId,
  }) async {
    return await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) {
        return _ArtistSearchSheet(
          title: title,
          artists: _artists,
          excludedArtistId: excludedArtistId,
        );
      },
    );
  }

  Future<void> _selectFirstArtist() async {
    final artistId = await _selectArtist(
      title: 'Select First Artist',
      excludedArtistId: _selectedArtist2,
    );

    if (!mounted || artistId == null) return;

    setState(() {
      _selectedArtist1 = artistId;
      _connectionPath = [];
      _connectionError = null;
    });
  }

  Future<void> _selectSecondArtist() async {
    final artistId = await _selectArtist(
      title: 'Select Second Artist',
      excludedArtistId: _selectedArtist1,
    );

    if (!mounted || artistId == null) return;

    setState(() {
      _selectedArtist2 = artistId;
      _connectionPath = [];
      _connectionError = null;
    });
  }

  Future<void> _selectNetworkArtist() async {
    final artistId = await _selectArtist(
      title: 'Select Artist',
    );

    if (!mounted || artistId == null) return;

    setState(() {
      _networkArtist = artistId;
      _networkArtists = [];
      _networkError = null;
    });
  }

  Widget _artistSelector({
    required String label,
    required int? selectedArtistId,
    required VoidCallback onTap,
  }) {
    final selectedName = selectedArtistId == null
        ? null
        : _artistName(selectedArtistId);

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          suffixIcon: const Icon(Icons.search),
        ),
        child: Text(
          selectedName ?? 'Search for an artist',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: selectedName == null
              ? Theme.of(context)
                  .textTheme
                  .bodyLarge
                  ?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurfaceVariant,
                  )
              : Theme.of(context)
                  .textTheme
                  .bodyLarge,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            20,
            12,
            20,
            8,
          ),
          child: Row(
            mainAxisAlignment:
                MainAxisAlignment.end,
            children: [
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
            'Failed to load collaborations.\n\n$_error',
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
        24,
      ),
      children: [
        Text(
          'Top collaborations in $_selectedYear',
          style: Theme.of(context)
              .textTheme
              .bodyMedium,
        ),
        const SizedBox(height: 24),
        const Text(
          'Top Collaborations',
          style: TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Ranked by combined Billboard Hot 100 impact.',
        ),
        const SizedBox(height: 14),
        ..._collaborations.asMap().entries.map(
          (entry) {
            return _CollaborationCard(
              rank: entry.key + 1,
              collaboration: entry.value,
            );
          },
        ),
        const SizedBox(height: 28),
        _buildConnectionSection(),
        const SizedBox(height: 20),
        _buildNetworkSection(),
      ],
    );
  }

  Widget _buildConnectionSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            const Text(
              'Find Artist Connection',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Find the shortest collaboration path between two artists.',
            ),
            const SizedBox(height: 18),
            _artistSelector(
              label: 'First Artist',
              selectedArtistId: _selectedArtist1,
              onTap: _selectFirstArtist,
            ),
            const SizedBox(height: 12),
            _artistSelector(
              label: 'Second Artist',
              selectedArtistId: _selectedArtist2,
              onTap: _selectSecondArtist,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _isFindingConnection
                    ? null
                    : _findConnection,
                icon: _isFindingConnection
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child:
                            CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.route),
                label: Text(
                  _isFindingConnection
                      ? 'Finding...'
                      : 'Find Connection',
                ),
              ),
            ),
            if (_connectionError != null) ...[
              const SizedBox(height: 16),
              Text(
                _connectionError!,
                style: TextStyle(
                  color: Theme.of(context)
                      .colorScheme
                      .error,
                ),
              ),
            ],
            if (_connectionPath.isNotEmpty) ...[
              const SizedBox(height: 20),
              const Text(
                'Collaboration Path',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              ..._connectionPath.asMap().entries.map(
                (entry) {
                  final index = entry.key;
                  final artistId = entry.value;

                  return Row(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Column(
                        children: [
                          CircleAvatar(
                            radius: 16,
                            child: Text(
                              '${index + 1}',
                              style:
                                  const TextStyle(
                                fontSize: 12,
                              ),
                            ),
                          ),
                          if (index <
                              _connectionPath.length - 1)
                            Container(
                              width: 2,
                              height: 28,
                              color: Theme.of(context)
                                  .colorScheme
                                  .outlineVariant,
                            ),
                        ],
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Padding(
                          padding:
                              const EdgeInsets.only(
                            top: 7,
                          ),
                          child: Text(
                            _artistName(artistId),
                            style:
                                const TextStyle(
                              fontWeight:
                                  FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 12),
              Text(
                '${_connectionPath.length - 1} collaboration '
                '${_connectionPath.length - 1 == 1 ? 'hop' : 'hops'}',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildNetworkSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            const Text(
              'Explore Collaboration Network',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Explore every artist reachable through collaborations.',
            ),
            const SizedBox(height: 18),
            _artistSelector(
              label: 'Artist',
              selectedArtistId: _networkArtist,
              onTap: _selectNetworkArtist,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _isExploringNetwork
                    ? null
                    : _exploreNetwork,
                icon: _isExploringNetwork
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child:
                            CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.hub),
                label: Text(
                  _isExploringNetwork
                      ? 'Exploring...'
                      : 'Explore Network',
                ),
              ),
            ),
            if (_networkError != null) ...[
              const SizedBox(height: 16),
              Text(
                _networkError!,
                style: TextStyle(
                  color: Theme.of(context)
                      .colorScheme
                      .error,
                ),
              ),
            ],
            if (_networkArtists.isNotEmpty) ...[
              const SizedBox(height: 20),
              Text(
                '${_networkArtists.length} artists in network',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              ..._networkArtists.take(20).map(
                (artistId) {
                  return ListTile(
                    dense: true,
                    leading: const Icon(
                      Icons.person_outline,
                    ),
                    title: Text(
                      _artistName(artistId),
                    ),
                  );
                },
              ),
              if (_networkArtists.length > 20)
                Padding(
                  padding:
                      const EdgeInsets.only(top: 8),
                  child: Text(
                    '+ ${_networkArtists.length - 20} more artists',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall,
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ArtistSearchSheet extends StatefulWidget {
  final String title;
  final List<Map<String, dynamic>> artists;
  final int? excludedArtistId;

  const _ArtistSearchSheet({
    required this.title,
    required this.artists,
    this.excludedArtistId,
  });

  @override
  State<_ArtistSearchSheet> createState() =>
      _ArtistSearchSheetState();
}

class _ArtistSearchSheetState
    extends State<_ArtistSearchSheet> {
  final TextEditingController _controller =
      TextEditingController();

  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _filteredArtists {
    final query =
        _query.trim().toLowerCase();

    return widget.artists.where((artist) {
      final id =
          (artist['artist_id'] as num?)?.toInt();

      if (id == widget.excludedArtistId) {
        return false;
      }

      final name =
          artist['name']?.toString() ?? '';

      if (query.isEmpty) {
        return true;
      }

      return name.toLowerCase().contains(query);
    }).take(100).toList();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height:
          MediaQuery.of(context).size.height * 0.85,
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom:
              MediaQuery.of(context)
                      .viewInsets
                      .bottom +
                  20,
        ),
        child: Column(
          children: [
            Text(
              widget.title,
              style: const TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'Search artists...',
                prefixIcon:
                    Icon(Icons.search),
                border:
                    OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  _query = value;
                });
              },
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _filteredArtists.isEmpty
                  ? const Center(
                      child: Text(
                        'No artists found.',
                      ),
                    )
                  : ListView.builder(
                      itemCount:
                          _filteredArtists.length,
                      itemBuilder:
                          (context, index) {
                        final artist =
                            _filteredArtists[index];

                        final id =
                            (artist['artist_id']
                                    as num)
                                .toInt();

                        final name =
                            artist['name']
                                    ?.toString() ??
                                'Unknown Artist';

                        return ListTile(
                          leading:
                              CircleAvatar(
                            child: Text(
                              name.isNotEmpty
                                  ? name[0]
                                      .toUpperCase()
                                  : '?',
                            ),
                          ),
                          title: Text(name),
                          onTap: () {
                            Navigator.pop(
                              context,
                              id,
                            );
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CollaborationCard
    extends StatelessWidget {
  final int rank;
  final Map<String, dynamic> collaboration;

  const _CollaborationCard({
    required this.rank,
    required this.collaboration,
  });

  @override
  Widget build(BuildContext context) {
    final artist1 =
        collaboration['artist1_name']
                ?.toString() ??
            'Unknown Artist';

    final artist2 =
        collaboration['artist2_name']
                ?.toString() ??
            'Unknown Artist';

    final songCount =
        (collaboration['song_count']
                    as num?)
                ?.toInt() ??
            0;

    final appearances =
        (collaboration['chart_appearances']
                    as num?)
                ?.toInt() ??
            0;

    final bestPeak =
        (collaboration['best_peak']
                    as num?)
                ?.toInt() ??
            0;

    final score =
        (collaboration['chart_score']
                    as num?)
                ?.toInt() ??
            0;

    return Card(
      margin:
          const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius:
            BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  CollaborationDetailScreen(
                artist1Id:
                    (collaboration[
                            'artist1_id']
                        as num)
                        .toInt(),
                artist2Id:
                    (collaboration[
                            'artist2_id']
                        as num)
                        .toInt(),
                artist1Name: artist1,
                artist2Name: artist2,
                chartScore: score,
                songCount: songCount,
                chartAppearances:
                    appearances,
                bestPeak: bestPeak,
              ),
            ),
          );
        },
        child: Padding(
          padding:
              const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 14,
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
                      '$artist1 × $artist2',
                      maxLines: 2,
                      overflow:
                          TextOverflow.ellipsis,
                      style:
                          const TextStyle(
                        fontSize: 16,
                        fontWeight:
                            FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '$songCount '
                      '${songCount == 1 ? 'song' : 'songs'} • '
                      '$appearances '
                      '${appearances == 1 ? 'appearance' : 'appearances'}',
                      maxLines: 1,
                      overflow:
                          TextOverflow.ellipsis,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall,
                    ),
                    const SizedBox(height: 5),
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
              Column(
                children: [
                  Text(
                    '$score',
                    style:
                        const TextStyle(
                      fontWeight:
                          FontWeight.bold,
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