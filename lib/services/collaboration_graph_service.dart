import '../algorithms/collaboration_graph.dart';
import '../algorithms/collaboration_graph_builder.dart';
import '../algorithms/dijkstra.dart';
import '../algorithms/graph_traversal.dart';
import '../repositories/artist_repository.dart';

class CollaborationGraphService {
  final ArtistRepository repository;

  CollaborationGraphService(this.repository);

  Future<CollaborationGraph> buildGraph() {
    return CollaborationGraphBuilder.build(repository);
  }

  Future<List<int>> getBfsTraversal(
    int artistId,
  ) async {
    final graph = await buildGraph();

    return GraphTraversal.bfs(
      graph,
      artistId,
    );
  }

  Future<List<int>> getDfsTraversal(
    int artistId,
  ) async {
    final graph = await buildGraph();

    return GraphTraversal.dfs(
      graph,
      artistId,
    );
  }

  Future<List<int>> getShortestPath(
    int artist1Id,
    int artist2Id,
  ) async {
    final graph = await buildGraph();

    return GraphTraversal.shortestPath(
      graph,
      artist1Id,
      artist2Id,
    );
  }

  Future<int> getCollaborationDistance(
    int artist1Id,
    int artist2Id,
  ) async {
    final graph = await buildGraph();

    return GraphTraversal.collaborationDistance(
      graph,
      artist1Id,
      artist2Id,
    );
  }

  Future<DijkstraResult> getStrongestRoute(
    int artist1Id,
    int artist2Id,
  ) async {
    final graph = await buildGraph();

    return Dijkstra.shortestPath(
      graph,
      artist1Id,
      artist2Id,
    );
  }
}