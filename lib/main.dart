import 'package:flutter/material.dart';

import 'database/database_helper.dart';
import 'database/database_importer.dart';
import 'database/database_validator.dart';
import 'services/musicbrainz_enricher.dart';

void main() {
  runApp(const ChartLensApp());
}

class ChartLensApp extends StatelessWidget {
  const ChartLensApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ChartLens',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
        ),
        useMaterial3: true,
      ),
      home: const DatabaseScreen(),
    );
  }
}

class DatabaseScreen extends StatefulWidget {
  const DatabaseScreen({super.key});

  @override
  State<DatabaseScreen> createState() =>
      _DatabaseScreenState();
}

class _DatabaseScreenState
    extends State<DatabaseScreen> {
  bool _loading = true;
  bool _enriching = false;

  String _status = 'Loading database...';

  int _artists = 0;
  int _songs = 0;
  int _albums = 0;
  int _hot100Entries = 0;
  int _billboard200Entries = 0;

  int _completed = 0;
  int _total = 0;
  int _matched = 0;
  int _skipped = 0;
  int _failed = 0;

  String _currentArtist = '';

  @override
  void initState() {
    super.initState();
    _loadCounts();
  }

  // ============================================================
  // LOAD DATABASE COUNTS
  // ============================================================

  Future<void> _loadCounts() async {
    try {
      final db =
          await DatabaseHelper.instance.database;

      final artists =
          await db.rawQuery(
        'SELECT COUNT(*) AS count FROM artist',
      );

      final songs =
          await db.rawQuery(
        'SELECT COUNT(*) AS count FROM song',
      );

      final albums =
          await db.rawQuery(
        'SELECT COUNT(*) AS count FROM album',
      );

      final hot100 =
          await db.rawQuery(
        '''
        SELECT COUNT(*) AS count
        FROM chart_entry
        WHERE chart_id = (
          SELECT chart_id
          FROM chart
          WHERE name = 'Hot 100'
        )
        ''',
      );

      final billboard200 =
          await db.rawQuery(
        '''
        SELECT COUNT(*) AS count
        FROM chart_entry
        WHERE chart_id = (
          SELECT chart_id
          FROM chart
          WHERE name = 'Billboard 200'
        )
        ''',
      );

      if (!mounted) return;

      setState(() {
        _artists =
            artists.first['count'] as int? ?? 0;

        _songs =
            songs.first['count'] as int? ?? 0;

        _albums =
            albums.first['count'] as int? ?? 0;

        _hot100Entries =
            hot100.first['count'] as int? ?? 0;

        _billboard200Entries =
            billboard200.first['count'] as int? ?? 0;

        _loading = false;
        _status = 'Database loaded.';
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _status = 'Database error: $e';
      });
    }
  }

  // ============================================================
  // IMPORT DATABASE
  // ============================================================

  Future<void> _importDatabase() async {
    setState(() {
      _loading = true;
      _status = 'Importing database...';
    });

    try {
      await DatabaseImporter.importAll();

      await _loadCounts();

      if (!mounted) return;

      setState(() {
        _status = 'Import completed successfully.';
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _status = 'Import failed: $e';
      });
    }
  }

  // ============================================================
  // VALIDATE DATABASE
  // ============================================================

  Future<void> _validateDatabase() async {
    setState(() {
      _loading = true;
      _status = 'Validating database...';
    });

    try {
      final result =
          await DatabaseValidator.validate();

      if (!mounted) return;

      setState(() {
        _loading = false;
        _status = result.toString();
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _status = 'Validation failed: $e';
      });
    }
  }

  // ============================================================
  // ENRICH ARTISTS
  // ============================================================

  Future<void> _enrichArtists() async {
    if (_enriching) return;

    setState(() {
      _enriching = true;
      _status = 'Starting artist enrichment...';

      _completed = 0;
      _total = 0;
      _matched = 0;
      _skipped = 0;
      _failed = 0;
      _currentArtist = '';
    });

    try {
      final result =
          await MusicBrainzEnricher.enrichArtists(
        onProgress: (
          completed,
          total,
          currentArtist,
        ) {
          if (!mounted) return;

          setState(() {
            _completed = completed;
            _total = total;
            _currentArtist = currentArtist;
          });
        },
      );

      if (!mounted) return;

      setState(() {
        _enriching = false;

        _completed = result.total;
        _total = result.total;
        _matched = result.matched;
        _skipped = result.skipped;
        _failed = result.failed;

        _currentArtist = '';
        _status = 'Artist enrichment complete.';
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _enriching = false;
        _status = 'Enrichment failed: $e';
      });
    }

    await _loadCounts();
  }

  // ============================================================
  // UI
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final progress =
        _total == 0
            ? 0.0
            : _completed / _total;

    return Scaffold(
      appBar: AppBar(
        title: const Text('ChartLens'),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Text(
                    _status,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 18,
                    ),
                  ),

                  const SizedBox(height: 32),

                  // ------------------------------------------------
                  // DATABASE COUNTS
                  // ------------------------------------------------

                  _buildCount(
                    'Artists',
                    _artists,
                  ),

                  _buildCount(
                    'Songs',
                    _songs,
                  ),

                  _buildCount(
                    'Albums',
                    _albums,
                  ),

                  _buildCount(
                    'Hot 100 entries',
                    _hot100Entries,
                  ),

                  _buildCount(
                    'Billboard 200 entries',
                    _billboard200Entries,
                  ),

                  const SizedBox(height: 32),

                  // ------------------------------------------------
                  // IMPORT
                  // ------------------------------------------------

                  ElevatedButton(
                    onPressed: _enriching
                        ? null
                        : _importDatabase,
                    child: const Text(
                      'Import Database',
                    ),
                  ),

                  const SizedBox(height: 12),

                  // ------------------------------------------------
                  // VALIDATE
                  // ------------------------------------------------

                  ElevatedButton(
                    onPressed: _enriching
                        ? null
                        : _validateDatabase,
                    child: const Text(
                      'Validate Database',
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ------------------------------------------------
                  // ARTIST ENRICHMENT
                  // ------------------------------------------------

                  const Text(
                    'MusicBrainz Artist Enrichment',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 16),

                  ElevatedButton(
                    onPressed: _enriching
                        ? null
                        : _enrichArtists,
                    child: Text(
                      _enriching
                          ? 'Enriching...'
                          : 'Enrich All Artists',
                    ),
                  ),

                  const SizedBox(height: 24),

                  if (_enriching ||
                      _total > 0) ...[
                    LinearProgressIndicator(
                      value: progress,
                    ),

                    const SizedBox(height: 12),

                    Text(
                      '$_completed / $_total',
                    ),

                    const SizedBox(height: 16),

                    if (_currentArtist.isNotEmpty)
                      Text(
                        'Current artist:\n'
                        '$_currentArtist',
                        textAlign: TextAlign.center,
                      ),

                    const SizedBox(height: 20),

                    _buildCount(
                      'Matched',
                      _matched,
                    ),

                    _buildCount(
                      'Skipped',
                      _skipped,
                    ),

                    _buildCount(
                      'Failed',
                      _failed,
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  // ============================================================
  // COUNT WIDGET
  // ============================================================

  Widget _buildCount(
    String label,
    int value,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 4,
      ),
      child: Text(
        '$label: $value',
        style: const TextStyle(
          fontSize: 17,
        ),
      ),
    );
  }
}