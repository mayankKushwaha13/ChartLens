import 'package:sqflite/sqflite.dart';

import 'database_helper.dart';

class DatabaseValidator {
  static Future<Map<String, dynamic>> validate() async {
    final db = await DatabaseHelper.instance.database;

    // Basic row counts.
    final artists = await _count(db, 'artist');
    final songs = await _count(db, 'song');
    final albums = await _count(db, 'album');
    final hot100Entries = await _count(db, 'chart_entry');
    final billboard200Entries = await _count(
      db,
      'album_chart_entry',
    );

    // Check that the Hot 100 covers the expected date range.
    final hot100Dates = await db.rawQuery('''
      SELECT MIN(chart_date) AS first_date,
             MAX(chart_date) AS last_date
      FROM chart_entry
    ''');

    // Check that Billboard 200 covers the expected date range.
    final billboard200Dates = await db.rawQuery('''
      SELECT MIN(chart_date) AS first_date,
             MAX(chart_date) AS last_date
      FROM album_chart_entry
    ''');

    // Check a known collaboration.
    final coopedUp = await db.rawQuery('''
      SELECT
        song.title,
        artist.name
      FROM song
      JOIN song_artist
        ON song.song_id = song_artist.song_id
      JOIN artist
        ON artist.artist_id = song_artist.artist_id
      WHERE song.title = ?
    ''', ['Cooped Up']);

    // Check the chart history of that song.
    final coopedUpHistory = await db.rawQuery('''
      SELECT
        chart_date,
        rank,
        peak_rank,
        weeks_on_chart
      FROM chart_entry
      JOIN song
        ON song.song_id = chart_entry.song_id
      WHERE song.title = ?
      ORDER BY chart_date
    ''', ['Cooped Up']);

    return {
      'artists': artists,
      'songs': songs,
      'albums': albums,
      'hot100Entries': hot100Entries,
      'billboard200Entries': billboard200Entries,
      'hot100FirstDate': hot100Dates.first['first_date'],
      'hot100LastDate': hot100Dates.first['last_date'],
      'billboard200FirstDate':
          billboard200Dates.first['first_date'],
      'billboard200LastDate':
          billboard200Dates.first['last_date'],
      'coopedUpArtists': coopedUp
          .map((row) => row['name'])
          .toList(),
      'coopedUpHistory': coopedUpHistory,
    };
  }

  static Future<int> _count(
    Database db,
    String table,
  ) async {
    final result = await db.rawQuery(
      'SELECT COUNT(*) AS count FROM $table',
    );

    return Sqflite.firstIntValue(result)!;
  }
}