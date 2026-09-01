import 'package:flutter/material.dart';

import '../../database/database_helper.dart';
import '../../repositories/collaboration_repository.dart';
import 'collaboration_detail_screen.dart';

class CollabScreen extends StatefulWidget {
  const CollabScreen({super.key});

  @override
  State<CollabScreen> createState() => _CollabScreenState();
}

class _CollabScreenState extends State<CollabScreen> {
  int _selectedYear = 2025;

  late CollaborationRepository _repository;

  bool _isLoading = true;
  String? _error;

  List<Map<String, dynamic>> _collaborations = [];

  @override
  void initState() {
    super.initState();

    _initialize();
  }

  Future<void> _initialize() async {
    try {
      final db = await DatabaseHelper.instance.database;

      _repository = CollaborationRepository(db);

      await _loadCollaborations();
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
                'Collab',
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
            'Failed to load collaborations.\n\n$_error',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    if (_collaborations.isEmpty) {
      return const Center(
        child: Text(
          'No collaborations found.',
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
      ],
    );
  }
}

// ==========================================================================
// COLLABORATION CARD
// ==========================================================================

class _CollaborationCard extends StatelessWidget {
  final int rank;
  final Map<String, dynamic> collaboration;

  const _CollaborationCard({
    required this.rank,
    required this.collaboration,
  });

  @override
  Widget build(BuildContext context) {
    final artist1 =
        collaboration['artist1_name']?.toString() ??
            'Unknown Artist';

    final artist2 =
        collaboration['artist2_name']?.toString() ??
            'Unknown Artist';

    final songCount =
        (collaboration['song_count'] as num?)?.toInt() ??
            0;

    final appearances =
        (collaboration['chart_appearances'] as num?)
                ?.toInt() ??
            0;

    final bestPeak =
        (collaboration['best_peak'] as num?)?.toInt() ??
            0;

    final score =
        (collaboration['chart_score'] as num?)?.toInt() ??
            0;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  CollaborationDetailScreen(
                artist1Id:
                    (collaboration['artist1_id'] as num)
                        .toInt(),
                artist2Id:
                    (collaboration['artist2_id'] as num)
                        .toInt(),
                artist1Name:
                    artist1,
                artist2Name:
                    artist2,
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
            vertical: 14,
          ),
          child: Row(
            children: [
              // ========================================================
              // RANK
              // ========================================================

              CircleAvatar(
                radius: 20,
                child: Text('$rank'),
              ),

              const SizedBox(width: 14),

              // ========================================================
              // ARTISTS
              // ========================================================

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
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
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

              // ========================================================
              // SCORE
              // ========================================================

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