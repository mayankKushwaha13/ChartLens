import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';

import 'database/database_helper.dart';
import 'database/database_importer.dart';
import 'database/database_validator.dart';
import 'services/musicbrainz_enricher.dart';
import 'services/musicbrainz_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await DatabaseHelper.instance.database;

  runApp(const ChartLensApp());
}

class ChartLensApp extends StatelessWidget {
  const ChartLensApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ChartLens',
      home: const DatabaseTestScreen(),
    );
  }
}

class DatabaseTestScreen extends StatefulWidget {
  const DatabaseTestScreen({super.key});

  @override
  State<DatabaseTestScreen> createState() => _DatabaseTestScreenState();
}

class _DatabaseTestScreenState extends State<DatabaseTestScreen> {
  String status = 'Checking database...';

  bool busy = false;

  double progress = 0.0;

  Map<String, int> counts = {};

  @override
  void initState() {
    super.initState();

    _loadExistingDatabase();
  }

  // ============================================================
  // DATABASE
  // ============================================================

  Future<void> _loadExistingDatabase() async {
    try {
      await loadCounts();

      if (!mounted) return;

      setState(() {
        status = 'Database loaded.';
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        status = 'Database check failed:\n$e';
      });
    }
  }

  Future<void> loadCounts() async {
    final db = await DatabaseHelper.instance.database;

    final artistCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM artist'),
    )!;

    final songCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM song'),
    )!;

    final albumCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM album'),
    )!;

    final hot100Count = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM chart_entry'),
    )!;

    final billboard200Count = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM album_chart_entry'),
    )!;

    if (!mounted) return;

    setState(() {
      counts = {
        'Artists': artistCount,
        'Songs': songCount,
        'Albums': albumCount,
        'Hot 100 entries': hot100Count,
        'Billboard 200 entries': billboard200Count,
      };
    });
  }

  // ============================================================
  // IMPORT
  // ============================================================

  Future<void> importDatabase() async {
    setState(() {
      busy = true;
      status = 'Importing data...';
    });

    try {
      await DatabaseImporter.importAll();

      await loadCounts();

      if (!mounted) return;

      setState(() {
        status = 'Import completed successfully!';
        busy = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        status = 'Import failed:\n$e';
        busy = false;
      });
    }
  }

  // ============================================================
  // DATABASE VALIDATION
  // ============================================================

  Future<void> validateDatabase() async {
    setState(() {
      busy = true;
      status = 'Validating database...';
    });

    try {
      final result = await DatabaseValidator.validate();

      final coopedUpArtists = (result['coopedUpArtists'] as List).join(', ');

      final coopedUpHistory = (result['coopedUpHistory'] as List)
          .map((row) {
            final map = Map<String, dynamic>.from(row);

            return '${map['chart_date']}  '
                '#${map['rank']}  '
                '(peak #${map['peak_rank']}, '
                '${map['weeks_on_chart']} weeks)';
          })
          .join('\n');

      if (!mounted) return;

      setState(() {
        busy = false;

        status =
            '''
Validation complete.

Hot 100:
${result['hot100FirstDate']} → ${result['hot100LastDate']}
Entries: ${result['hot100Entries']}

Billboard 200:
${result['billboard200FirstDate']} → ${result['billboard200LastDate']}
Entries: ${result['billboard200Entries']}

Cooped Up artists:
$coopedUpArtists

Cooped Up history:
$coopedUpHistory
''';
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        busy = false;
        status = 'Validation failed:\n$e';
      });
    }
  }

  // ============================================================
  // MUSICBRAINZ TEST
  // ============================================================

  Future<void> testMusicBrainz() async {
    setState(() {
      busy = true;
      status = 'Testing MusicBrainz matching...';
    });

    try {
      final testArtists = ['Jackson 5'];

      final results = <String>[];

      for (final artistName in testArtists) {
        final match = await MusicBrainzService.findBestArtistMatch(artistName);

        if (match == null) {
          results.add(
            '$artistName\n'
            'NO AUTOMATIC MATCH',
          );
        } else {
          results.add(
            '$artistName\n'
            '→ ${match.artist.name}\n'
            '→ ${match.artist.id}\n'
            '→ Score: ${match.artist.score}\n'
            '→ Confidence: ${match.confidence}',
          );
        }
      }

      if (!mounted) return;

      setState(() {
        busy = false;

        status = results.join('\n\n--------------------\n\n');
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        busy = false;
        status = 'MusicBrainz test failed:\n$e';
      });
    }
  }

  // ============================================================
  // ENRICH FIRST 10 ARTISTS
  // ============================================================

  Future<void> enrichFirst10Artists() async {
    setState(() {
      busy = true;
      progress = 0.0;
      status = 'Enriching first 10 artists...';
    });

    try {
      final result = await MusicBrainzEnricher.enrichArtists(
        limit: 20,
        onProgress: (completed, total) {
          if (!mounted) return;

          setState(() {
            progress = total == 0 ? 0 : completed / total;

            status =
                'Enriching artists...\n'
                '$completed / $total';
          });
        },
      );

      await loadCounts();

      if (!mounted) return;

      setState(() {
        busy = false;
        progress = 1.0;

        status =
            '''
Artist enrichment test complete.

Total: ${result.total}
Matched: ${result.matched}
Skipped: ${result.skipped}
Failed: ${result.failed}
''';
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        busy = false;
        status = 'Artist enrichment failed:\n$e';
      });
    }
  }

  // ============================================================
  // UI
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ChartLens Database Test')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                status,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),

              const SizedBox(height: 20),

              if (busy)
                Column(
                  children: [
                    LinearProgressIndicator(
                      value: progress == 0 ? null : progress,
                    ),

                    const SizedBox(height: 8),
                  ],
                ),

              const SizedBox(height: 8),

              // ------------------------------------------------
              // IMPORT
              // ------------------------------------------------
              ElevatedButton(
                onPressed: busy ? null : importDatabase,
                child: Text(busy ? 'Working...' : 'Import Database'),
              ),

              const SizedBox(height: 10),

              // ------------------------------------------------
              // VALIDATE
              // ------------------------------------------------
              ElevatedButton(
                onPressed: busy ? null : validateDatabase,
                child: const Text('Validate Database'),
              ),

              const SizedBox(height: 10),

              // ------------------------------------------------
              // MUSICBRAINZ TEST
              // ------------------------------------------------
              ElevatedButton(
                onPressed: busy ? null : testMusicBrainz,
                child: const Text('Test MusicBrainz'),
              ),

              const SizedBox(height: 10),

              // ------------------------------------------------
              // ENRICH 10
              // ------------------------------------------------
              ElevatedButton(
                onPressed: busy ? null : enrichFirst10Artists,
                child: const Text('Enrich First 10 Artists'),
              ),

              const SizedBox(height: 30),

              // ------------------------------------------------
              // DATABASE COUNTS
              // ------------------------------------------------
              if (counts.isNotEmpty)
                Column(
                  children: counts.entries.map((entry) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text(
                        '${entry.key}: ${entry.value}',
                        style: const TextStyle(fontSize: 18),
                      ),
                    );
                  }).toList(),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
