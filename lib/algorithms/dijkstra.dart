import 'collaboration_graph.dart';
import 'min_heap.dart';

class DijkstraResult {
  final List<int> path;
  final double cost;

  const DijkstraResult({
    required this.path,
    required this.cost,
  });
}

class Dijkstra {
  static DijkstraResult shortestPath(
    CollaborationGraph graph,
    int startArtistId,
    int targetArtistId,
  ) {
    final artists = graph.getArtists();

    if (!artists.contains(startArtistId) ||
        !artists.contains(targetArtistId)) {
      return const DijkstraResult(
        path: [],
        cost: double.infinity,
      );
    }

    if (startArtistId == targetArtistId) {
      return DijkstraResult(
        path: [startArtistId],
        cost: 0,
      );
    }

    final distances = <int, double>{};
    final previous = <int, int?>{};

    for (final artist in artists) {
      distances[artist] = double.infinity;
      previous[artist] = null;
    }

    distances[startArtistId] = 0;

    final heap = MinHeap<_DijkstraNode>(
      compare: (a, b) =>
          a.distance.compareTo(b.distance),
    );

    heap.add(
      _DijkstraNode(
        artistId: startArtistId,
        distance: 0,
      ),
    );

    while (heap.length > 0) {
      final current = heap.removeMin();

      if (current.distance >
          distances[current.artistId]!) {
        continue;
      }

      if (current.artistId == targetArtistId) {
        break;
      }

      final neighbors =
          graph.getNeighbors(current.artistId);

      for (final entry in neighbors.entries) {
        final neighbor = entry.key;
        final collaborationCount = entry.value;

        if (collaborationCount <= 0) {
          continue;
        }

        final edgeCost =
            1.0 / collaborationCount;

        final newDistance =
            current.distance + edgeCost;

        if (newDistance <
            distances[neighbor]!) {
          distances[neighbor] = newDistance;
          previous[neighbor] =
              current.artistId;

          heap.add(
            _DijkstraNode(
              artistId: neighbor,
              distance: newDistance,
            ),
          );
        }
      }
    }

    if (distances[targetArtistId] ==
        double.infinity) {
      return const DijkstraResult(
        path: [],
        cost: double.infinity,
      );
    }

    final path = <int>[];
    int? current = targetArtistId;

    while (current != null) {
      path.add(current);
      current = previous[current];
    }

    return DijkstraResult(
      path: path.reversed.toList(),
      cost: distances[targetArtistId]!,
    );
  }
}

class _DijkstraNode {
  final int artistId;
  final double distance;

  const _DijkstraNode({
    required this.artistId,
    required this.distance,
  });
}