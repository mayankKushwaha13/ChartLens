class ArtistParser {
  static List<String> parse(String artistCredit) {
    var text = artistCredit.trim();

    // Normalize collaboration keywords.
    text = text.replaceAll(
      RegExp(r'\b(featuring|feat\.?|ft\.?|with)\b', caseSensitive: false),
      '|',
    );

    // Normalize common collaboration separators.
    text = text.replaceAll('&', '|');
    text = text.replaceAll(RegExp(r'\s+[xX]\s+'), '|');
    text = text.replaceAll(' / ', '|');
    text = text.replaceAll(',', '|');

    // Some Billboard credits use a colon to separate credited artists.
    text = text.replaceAll(':', '|');

    return text
        .split('|')
        .map((artist) => artist.trim())
        .where((artist) => artist.isNotEmpty)
        .toSet()
        .toList();
  }
}