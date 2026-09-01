import '../repositories/artist_repository.dart';
import 'collaboration_graph.dart';

class CollaborationGraphBuilder {
  static Future<CollaborationGraph> build(
    ArtistRepository repository,
  ) async {
    final pairs =
        await repository.getCollaborationPairs();

    final graph = CollaborationGraph();

    for (final pair in pairs) {
      final artist1Id =
          (pair['artist1_id'] as num).toInt();

      final artist2Id =
          (pair['artist2_id'] as num).toInt();

      final weight =
          (pair['collaboration_count'] as num).toInt();

      graph.addCollaboration(
        artist1Id,
        artist2Id,
        weight: weight,
      );
    }

    return graph;
  }
}