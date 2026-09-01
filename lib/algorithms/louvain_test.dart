import 'collaboration_graph.dart';
import 'louvain.dart';

void main() {
  final graph = CollaborationGraph();

  graph.addCollaboration(1, 2, weight: 5);
  graph.addCollaboration(1, 3, weight: 5);
  graph.addCollaboration(2, 3, weight: 5);

  graph.addCollaboration(4, 5, weight: 5);
  graph.addCollaboration(4, 6, weight: 5);
  graph.addCollaboration(5, 6, weight: 5);

  graph.addCollaboration(3, 4, weight: 1);

  final communities = Louvain.detect(graph);

  for (final community in communities) {
    print(
      'Community: ${community.artists} '
      '| Modularity: ${community.modularity.toStringAsFixed(4)}',
    );
  }
}