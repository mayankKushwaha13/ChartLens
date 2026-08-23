import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import 'database_schema.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._internal();

  static Database? _database;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }

    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final databasePath = await getDatabasesPath();
    final path = join(databasePath, 'chartlens.db');

    return await openDatabase(
      path,
      version: 2,
      onCreate: (db, version) async {
        await db.execute(DatabaseSchema.createArtistTable);
        await db.execute(DatabaseSchema.createSongTable);
        await db.execute(DatabaseSchema.createSongArtistTable);
        await db.execute(DatabaseSchema.createAlbumTable);
        await db.execute(DatabaseSchema.createAlbumArtistTable);
        await db.execute(DatabaseSchema.createChartTable);
        await db.execute(DatabaseSchema.createChartEntryTable);
        await db.execute(DatabaseSchema.createAlbumChartEntryTable);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('ALTER TABLE artist ADD COLUMN musicbrainz_id TEXT');

          await db.execute(
            'ALTER TABLE song ADD COLUMN musicbrainz_recording_id TEXT',
          );

          await db.execute(
            'ALTER TABLE album ADD COLUMN musicbrainz_release_group_id TEXT',
          );
        }
      },
    );
  }
}
