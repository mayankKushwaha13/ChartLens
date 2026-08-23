import 'dart:convert';

import 'package:csv/csv.dart' as csv_package;
import 'package:flutter/services.dart';
import 'package:sqflite/sqflite.dart';

import 'artist_parser.dart';
import 'database_helper.dart';

class DatabaseImporter {
  static Future<void> importAll() async {
    final db = await DatabaseHelper.instance.database;

    await db.transaction((txn) async {
      await _importHot100(txn);
      await _importBillboard200(txn);
    });
  }

  // HOT 100

  static Future<void> _importHot100(Transaction txn) async {
    final jsonString = await rootBundle.loadString(
      'assets/data/hot100_2022_2025.json',
    );

    final List<dynamic> charts = jsonDecode(jsonString);

    final chartId = await _getOrCreateChart(
      txn,
      'Billboard Hot 100',
    );

    final artistCache = <String, int>{};
    final songCache = <String, int>{};

    for (final chart in charts) {
      final chartDate = chart['date'].toString();

      final List<dynamic> entries = chart['data'];

      for (final entry in entries) {
        final title = entry['song'].toString().trim();
        final artistCredit = entry['artist'].toString().trim();

        if (title.isEmpty || artistCredit.isEmpty) {
          continue;
        }

        final songId = await _getOrCreateSong(
          txn,
          title,
          artistCredit,
          artistCache,
          songCache,
        );

        await txn.insert(
          'chart_entry',
          {
            'song_id': songId,
            'chart_id': chartId,
            'chart_date': chartDate,
            'rank': _toInt(entry['this_week']),
            'last_week_rank': _toNullableInt(entry['last_week']),
            'peak_rank': _toInt(entry['peak_position']),
            'weeks_on_chart': _toInt(entry['weeks_on_chart']),
          },
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
      }
    }
  }

  // BILLBOARD 200

  static Future<void> _importBillboard200(Transaction txn) async {
    final csvString = await rootBundle.loadString(
      'assets/data/billboard200_2022_2025.csv',
    );

    final List<List<dynamic>> rows =
        csv_package.csv.decode(csvString);

    if (rows.isEmpty) {
      return;
    }

    final header = rows.first
        .map((value) => value.toString().trim())
        .toList();

    final dateIndex = header.indexOf('Date');
    final titleIndex = header.indexOf('Song');
    final artistIndex = header.indexOf('Artist');
    final rankIndex = header.indexOf('Rank');
    final lastWeekIndex = header.indexOf('Last Week');
    final peakIndex = header.indexOf('Peak Position');
    final weeksIndex = header.indexOf('Weeks in Charts');
    final imageIndex = header.indexOf('Image URL');

    final indexes = [
      dateIndex,
      titleIndex,
      artistIndex,
      rankIndex,
      lastWeekIndex,
      peakIndex,
      weeksIndex,
      imageIndex,
    ];

    if (indexes.contains(-1)) {
      throw Exception(
        'Billboard 200 CSV has unexpected or missing columns.',
      );
    }

    final chartId = await _getOrCreateChart(
      txn,
      'Billboard 200',
    );

    final artistCache = <String, int>{};
    final albumCache = <String, int>{};

    for (final row in rows.skip(1)) {
      final chartDate = row[dateIndex].toString().trim();
      final title = row[titleIndex].toString().trim();
      final artistCredit = row[artistIndex].toString().trim();

      if (title.isEmpty || artistCredit.isEmpty) {
        continue;
      }

      final imageUrl = row[imageIndex].toString().trim();

      final albumId = await _getOrCreateAlbum(
        txn,
        title,
        artistCredit,
        imageUrl,
        artistCache,
        albumCache,
      );

      await txn.insert(
        'album_chart_entry',
        {
          'album_id': albumId,
          'chart_id': chartId,
          'chart_date': chartDate,
          'rank': _toInt(row[rankIndex]),
          'last_week_rank': _toNullableInt(row[lastWeekIndex]),
          'peak_rank': _toInt(row[peakIndex]),
          'weeks_on_chart': _toInt(row[weeksIndex]),
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
  }

  // SONG

  static Future<int> _getOrCreateSong(
    Transaction txn,
    String title,
    String artistCredit,
    Map<String, int> artistCache,
    Map<String, int> songCache,
  ) async {
    final songKey = '$title|||$artistCredit';

    if (songCache.containsKey(songKey)) {
      return songCache[songKey]!;
    }

    final existingSong = await txn.query(
      'song',
      columns: ['song_id'],
      where: 'title = ? AND artist_credit = ?',
      whereArgs: [title, artistCredit],
      limit: 1,
    );

    late int songId;

    if (existingSong.isNotEmpty) {
      songId = existingSong.first['song_id'] as int;
    } else {
      songId = await txn.insert(
        'song',
        {
          'title': title,
          'artist_credit': artistCredit,
        },
      );
    }

    final artists = ArtistParser.parse(artistCredit);

    for (final artistName in artists) {
      final artistId = await _getOrCreateArtist(
        txn,
        artistName,
        artistCache,
      );

      await txn.insert(
        'song_artist',
        {
          'song_id': songId,
          'artist_id': artistId,
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }

    songCache[songKey] = songId;

    return songId;
  }

  // ALBUM

  static Future<int> _getOrCreateAlbum(
    Transaction txn,
    String title,
    String artistCredit,
    String imageUrl,
    Map<String, int> artistCache,
    Map<String, int> albumCache,
  ) async {
    final albumKey = '$title|||$artistCredit';

    if (albumCache.containsKey(albumKey)) {
      return albumCache[albumKey]!;
    }

    final existingAlbum = await txn.query(
      'album',
      columns: ['album_id'],
      where: 'title = ? AND artist_credit = ?',
      whereArgs: [title, artistCredit],
      limit: 1,
    );

    late int albumId;

    if (existingAlbum.isNotEmpty) {
      albumId = existingAlbum.first['album_id'] as int;
    } else {
      albumId = await txn.insert(
        'album',
        {
          'title': title,
          'artist_credit': artistCredit,
          'image_url': imageUrl.isEmpty ? null : imageUrl,
        },
      );
    }

    final artists = ArtistParser.parse(artistCredit);

    for (final artistName in artists) {
      final artistId = await _getOrCreateArtist(
        txn,
        artistName,
        artistCache,
      );

      await txn.insert(
        'album_artist',
        {
          'album_id': albumId,
          'artist_id': artistId,
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }

    albumCache[albumKey] = albumId;

    return albumId;
  }

  // ARTIST

  static Future<int> _getOrCreateArtist(
    Transaction txn,
    String name,
    Map<String, int> cache,
  ) async {
    if (cache.containsKey(name)) {
      return cache[name]!;
    }

    final existingArtist = await txn.query(
      'artist',
      columns: ['artist_id'],
      where: 'name = ?',
      whereArgs: [name],
      limit: 1,
    );

    late int artistId;

    if (existingArtist.isNotEmpty) {
      artistId = existingArtist.first['artist_id'] as int;
    } else {
      artistId = await txn.insert(
        'artist',
        {
          'name': name,
        },
      );
    }

    cache[name] = artistId;

    return artistId;
  }

  // CHART

  static Future<int> _getOrCreateChart(
    Transaction txn,
    String name,
  ) async {
    final existingChart = await txn.query(
      'chart',
      columns: ['chart_id'],
      where: 'name = ?',
      whereArgs: [name],
      limit: 1,
    );

    if (existingChart.isNotEmpty) {
      return existingChart.first['chart_id'] as int;
    }

    return txn.insert(
      'chart',
      {
        'name': name,
      },
    );
  }

  // INTEGER HELPERS

  static int _toInt(dynamic value) {
    if (value == null) {
      throw FormatException('Expected an integer but received null.');
    }

    if (value is int) {
      return value;
    }

    final parsed = int.tryParse(
      value.toString().trim(),
    );

    if (parsed == null) {
      throw FormatException(
        'Expected an integer but received "$value".',
      );
    }

    return parsed;
  }

  static int? _toNullableInt(dynamic value) {
    if (value == null) {
      return null;
    }

    final text = value.toString().trim();

    if (text.isEmpty || text == '-') {
      return null;
    }

    return int.tryParse(text);
  }
}