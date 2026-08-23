import 'package:flutter_test/flutter_test.dart';
import 'package:chartlens/database/artist_parser.dart';

void main() {
  test('parses Featuring credits', () {
    final result = ArtistParser.parse('Morgan Wallen Featuring Post Malone');

    expect(result, ['Morgan Wallen', 'Post Malone']);
  });

  test('parses ampersand credits', () {
    final result = ArtistParser.parse(
      'David Guetta, Teddy Swims & Tones And I',
    );

    expect(result, ['David Guetta', 'Teddy Swims', 'Tones And I']);
  });

  test('parses multiple collaboration formats', () {
    final result = ArtistParser.parse(
      '¥\$: Ye & Ty Dolla \$ign Featuring Rich The Kid & Playboi Carti',
    );
    expect(result, [
      '¥\$',
      'Ye',
      'Ty Dolla \$ign',
      'Rich The Kid',
      'Playboi Carti',
    ]);
  });

  test('removes duplicate artist names', () {
    final result = ArtistParser.parse('Artist A & Artist A Featuring Artist B');

    expect(result, ['Artist A', 'Artist B']);
  });
}
