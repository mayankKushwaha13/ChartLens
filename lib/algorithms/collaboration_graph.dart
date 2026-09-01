class CollaborationGraph {
  final Map<int, Map<int, int>> _adjacency = {};

  void addArtist(int artistId) {
    _adjacency.putIfAbsent(artistId, () => {});
  }

  void addCollaboration(
    int artist1Id,
    int artist2Id, {
    int weight = 1,
  }) {
    if (artist1Id == artist2Id) {
      return;
    }

    addArtist(artist1Id);
    addArtist(artist2Id);

    _adjacency[artist1Id]![artist2Id] =
        (_adjacency[artist1Id]![artist2Id] ?? 0) + weight;

    _adjacency[artist2Id]![artist1Id] =
        (_adjacency[artist2Id]![artist1Id] ?? 0) + weight;
  }

  List<int> getArtists() {
    return _adjacency.keys.toList();
  }

  Map<int, int> getNeighbors(int artistId) {
    return Map.unmodifiable(
      _adjacency[artistId] ?? {},
    );
  }

  int getArtistCount() {
    return _adjacency.length;
  }

  int getCollaborationCount(int artist1Id, int artist2Id) {
    return _adjacency[artist1Id]?[artist2Id] ?? 0;
  }

  int getDegree(int artistId) {
    return _adjacency[artistId]?.length ?? 0;
  }

  int getWeightedDegree(int artistId) {
    final neighbors = _adjacency[artistId];

    if (neighbors == null) {
      return 0;
    }

    return neighbors.values.fold(
      0,
      (total, weight) => total + weight,
    );
  }

  List<Map<String, dynamic>> getEdges() {
    final edges = <Map<String, dynamic>>[];
    final seen = <String>{};

    for (final artist1 in _adjacency.keys) {
      for (final entry
          in _adjacency[artist1]!.entries) {
        final artist2 = entry.key;
        final weight = entry.value;

        final smaller =
            artist1 < artist2 ? artist1 : artist2;
        final larger =
            artist1 < artist2 ? artist2 : artist1;

        final key = '$smaller-$larger';

        if (seen.contains(key)) {
          continue;
        }

        seen.add(key);

        edges.add({
          'artist1_id': smaller,
          'artist2_id': larger,
          'weight': weight,
        });
      }
    }

    return edges;
  }
}