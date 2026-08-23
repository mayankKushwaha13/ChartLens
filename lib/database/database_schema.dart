class DatabaseSchema {
  static const String createArtistTable = '''
    CREATE TABLE IF NOT EXISTS artist (
      artist_id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL UNIQUE,
      musicbrainz_id TEXT
    )
  ''';

  static const String createSongTable = '''
    CREATE TABLE IF NOT EXISTS song (
      song_id INTEGER PRIMARY KEY AUTOINCREMENT,
      title TEXT NOT NULL,
      artist_credit TEXT NOT NULL,
      musicbrainz_recording_id TEXT,
      UNIQUE(title, artist_credit)
    )
  ''';

  static const String createSongArtistTable = '''
    CREATE TABLE IF NOT EXISTS song_artist (
      song_id INTEGER NOT NULL,
      artist_id INTEGER NOT NULL,
      PRIMARY KEY (song_id, artist_id),
      FOREIGN KEY (song_id) REFERENCES song(song_id),
      FOREIGN KEY (artist_id) REFERENCES artist(artist_id)
    )
  ''';

  static const String createAlbumTable = '''
    CREATE TABLE IF NOT EXISTS album (
      album_id INTEGER PRIMARY KEY AUTOINCREMENT,
      title TEXT NOT NULL,
      artist_credit TEXT NOT NULL,
      image_url TEXT,
      musicbrainz_release_group_id TEXT,
      UNIQUE(title, artist_credit)
    )
  ''';

  static const String createAlbumArtistTable = '''
    CREATE TABLE IF NOT EXISTS album_artist (
      album_id INTEGER NOT NULL,
      artist_id INTEGER NOT NULL,
      PRIMARY KEY (album_id, artist_id),
      FOREIGN KEY (album_id) REFERENCES album(album_id),
      FOREIGN KEY (artist_id) REFERENCES artist(artist_id)
    )
  ''';

  static const String createChartTable = '''
    CREATE TABLE IF NOT EXISTS chart (
      chart_id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL UNIQUE
    )
  ''';

  static const String createChartEntryTable = '''
    CREATE TABLE IF NOT EXISTS chart_entry (
      chart_entry_id INTEGER PRIMARY KEY AUTOINCREMENT,
      song_id INTEGER NOT NULL,
      chart_id INTEGER NOT NULL,
      chart_date TEXT NOT NULL,
      rank INTEGER NOT NULL,
      last_week_rank INTEGER,
      peak_rank INTEGER NOT NULL,
      weeks_on_chart INTEGER NOT NULL,
      FOREIGN KEY (song_id) REFERENCES song(song_id),
      FOREIGN KEY (chart_id) REFERENCES chart(chart_id),
      UNIQUE(song_id, chart_id, chart_date)
    )
  ''';

  static const String createAlbumChartEntryTable = '''
    CREATE TABLE IF NOT EXISTS album_chart_entry (
      album_chart_entry_id INTEGER PRIMARY KEY AUTOINCREMENT,
      album_id INTEGER NOT NULL,
      chart_id INTEGER NOT NULL,
      chart_date TEXT NOT NULL,
      rank INTEGER NOT NULL,
      last_week_rank INTEGER,
      peak_rank INTEGER NOT NULL,
      weeks_on_chart INTEGER NOT NULL,
      FOREIGN KEY (album_id) REFERENCES album(album_id),
      FOREIGN KEY (chart_id) REFERENCES chart(chart_id),
      UNIQUE(album_id, chart_id, chart_date)
    )
  ''';
}