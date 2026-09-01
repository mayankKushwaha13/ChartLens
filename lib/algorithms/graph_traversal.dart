import 'collaboration_graph.dart';

class GraphTraversal {
  static List<int> bfs(
    CollaborationGraph graph,
    int startArtistId,
  ) {
    final visited = <int>{};
    final queue = <int>[];
    final result = <int>[];

    if (!graph.getArtists().contains(startArtistId)) {
      return result;
    }

    visited.add(startArtistId);
    queue.add(startArtistId);

    var index = 0;

    while (index < queue.length) {
      final current = queue[index++];
      result.add(current);

      for (final neighbor
          in graph.getNeighbors(current).keys) {
        if (!visited.contains(neighbor)) {
          visited.add(neighbor);
          queue.add(neighbor);
        }
      }
    }

    return result;
  }

  static List<int> dfs(
    CollaborationGraph graph,
    int startArtistId,
  ) {
    final visited = <int>{};
    final result = <int>[];

    if (!graph.getArtists().contains(startArtistId)) {
      return result;
    }

    void visit(int artistId) {
      visited.add(artistId);
      result.add(artistId);

      for (final neighbor
          in graph.getNeighbors(artistId).keys) {
        if (!visited.contains(neighbor)) {
          visit(neighbor);
        }
      }
    }

    visit(startArtistId);

    return result;
  }

  static List<int> shortestPath(
    CollaborationGraph graph,
    int startArtistId,
    int targetArtistId,
  ) {
    if (!graph.getArtists().contains(startArtistId) ||
        !graph.getArtists().contains(targetArtistId)) {
      return [];
    }

    if (startArtistId == targetArtistId) {
      return [startArtistId];
    }

    final visited = <int>{startArtistId};
    final queue = <int>[startArtistId];
    final parent = <int, int?>{
      startArtistId: null,
    };

    var index = 0;

    while (index < queue.length) {
      final current = queue[index++];

      for (final neighbor
          in graph.getNeighbors(current).keys) {
        if (visited.contains(neighbor)) {
          continue;
        }

        visited.add(neighbor);
        parent[neighbor] = current;

        if (neighbor == targetArtistId) {
          final path = <int>[];
          int? currentNode = targetArtistId;

          while (currentNode != null) {
            path.add(currentNode);
            currentNode = parent[currentNode];
          }

          return path.reversed.toList();
        }

        queue.add(neighbor);
      }
    }

    return [];
  }

  static int collaborationDistance(
    CollaborationGraph graph,
    int startArtistId,
    int targetArtistId,
  ) {
    final path = shortestPath(
      graph,
      startArtistId,
      targetArtistId,
    );

    if (path.isEmpty) {
      return -1;
    }

    return path.length - 1;
  }
}