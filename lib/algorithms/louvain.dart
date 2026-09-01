import 'collaboration_graph.dart';

class LouvainCommunity {
  final List<int> artists;
  final double modularity;

  const LouvainCommunity({
    required this.artists,
    required this.modularity,
  });
}

class Louvain {
  static List<LouvainCommunity> detect(
    CollaborationGraph graph,
  ) {
    final originalGraph =
        _WeightedGraph.fromCollaborationGraph(graph);

    if (originalGraph.nodes.isEmpty) {
      return [];
    }

    var currentGraph = originalGraph;

    var currentMembers = <int, Set<int>>{
      for (final node in currentGraph.nodes)
        node: {node},
    };

    while (true) {
      final labels = _localMoving(currentGraph);

      final communities = <int, Set<int>>{};

      for (final node in currentGraph.nodes) {
        final community = labels[node]!;

        communities.putIfAbsent(
          community,
          () => <int>{},
        );

        communities[community]!
            .addAll(currentMembers[node]!);
      }

      final hasChanges = communities.length <
          currentGraph.nodes.length;

      if (!hasChanges) {
        return _buildResults(
          communities,
          originalGraph,
        );
      }

      final aggregated =
          _aggregate(currentGraph, labels);

      if (aggregated.nodes.length >=
          currentGraph.nodes.length) {
        return _buildResults(
          communities,
          originalGraph,
        );
      }

      final nextMembers = <int, Set<int>>{};

      for (final entry in communities.entries) {
        nextMembers[entry.key] = entry.value;
      }

      currentGraph = aggregated;
      currentMembers = nextMembers;

      if (currentGraph.nodes.length == 1) {
        return _buildResults(
          currentMembers,
          originalGraph,
        );
      }
    }
  }

  static Map<int, int> _localMoving(
    _WeightedGraph graph,
  ) {
    final nodes = graph.nodes.toList();

    final community = <int, int>{};

    for (final node in nodes) {
      community[node] = node;
    }

    final totalWeight = graph.totalWeight;

    if (totalWeight <= 0) {
      return community;
    }

    final communityDegree = <int, double>{};

    for (final node in nodes) {
      final id = community[node]!;

      communityDegree[id] =
          (communityDegree[id] ?? 0) +
              graph.degree(node);
    }

    var moved = true;
    var pass = 0;

    while (moved && pass < 100) {
      moved = false;
      pass++;

      for (final node in nodes) {
        final currentCommunity =
            community[node]!;

        final nodeDegree =
            graph.degree(node);

        communityDegree[currentCommunity] =
            (communityDegree[currentCommunity] ?? 0) -
                nodeDegree;

        final candidateCommunities =
            <int>{};

        for (final neighbor
            in graph.neighbors(node).keys) {
          if (neighbor == node) {
            continue;
          }

          candidateCommunities.add(
            community[neighbor]!,
          );
        }

        var bestCommunity =
            currentCommunity;

        var bestGain = 0.0;

        for (final candidate
            in candidateCommunities) {
          final weightToCommunity =
              graph.weightToCommunity(
            node,
            candidate,
            community,
          );

          final gain =
              weightToCommunity /
                      totalWeight -
                  (communityDegree[candidate] ??
                          0) *
                      nodeDegree /
                      (2 *
                          totalWeight *
                          totalWeight);

          if (gain > bestGain) {
            bestGain = gain;
            bestCommunity = candidate;
          }
        }

        community[node] = bestCommunity;

        communityDegree[bestCommunity] =
            (communityDegree[bestCommunity] ?? 0) +
                nodeDegree;

        if (bestCommunity != currentCommunity) {
          moved = true;
        }
      }
    }

    return community;
  }

  static _WeightedGraph _aggregate(
    _WeightedGraph graph,
    Map<int, int> labels,
  ) {
    final aggregated = _WeightedGraph();

    for (final community in labels.values.toSet()) {
      aggregated.addNode(community);
    }

    final edgeWeights =
        <String, double>{};

    for (final node in graph.nodes) {
      for (final entry
          in graph.neighbors(node).entries) {
        final neighbor = entry.key;

        if (node > neighbor) {
          continue;
        }

        final communityA =
            labels[node]!;

        final communityB =
            labels[neighbor]!;

        final first =
            communityA < communityB
                ? communityA
                : communityB;

        final second =
            communityA < communityB
                ? communityB
                : communityA;

        final key = '$first:$second';

        edgeWeights[key] =
            (edgeWeights[key] ?? 0) +
                entry.value;
      }
    }

    for (final entry in edgeWeights.entries) {
      final parts = entry.key.split(':');

      final first = int.parse(parts[0]);
      final second = int.parse(parts[1]);

      aggregated.addEdge(
        first,
        second,
        entry.value,
      );
    }

    return aggregated;
  }

  static List<LouvainCommunity> _buildResults(
    Map<int, Set<int>> communities,
    _WeightedGraph originalGraph,
  ) {
    final modularity =
        _calculateModularity(
      originalGraph,
      communities,
    );

    final results = communities.values
        .where((artists) => artists.isNotEmpty)
        .map(
          (artists) => LouvainCommunity(
            artists: artists.toList()..sort(),
            modularity: modularity,
          ),
        )
        .toList();

    results.sort(
      (a, b) => b.artists.length
          .compareTo(a.artists.length),
    );

    return results;
  }

  static double _calculateModularity(
    _WeightedGraph graph,
    Map<int, Set<int>> communities,
  ) {
    final totalWeight = graph.totalWeight;

    if (totalWeight <= 0) {
      return 0;
    }

    final nodeCommunity = <int, int>{};

    for (final entry in communities.entries) {
      for (final node in entry.value) {
        nodeCommunity[node] = entry.key;
      }
    }

    final communityInternalWeight =
        <int, double>{};

    final communityDegree =
        <int, double>{};

    for (final node in graph.nodes) {
      final community =
          nodeCommunity[node];

      if (community == null) {
        continue;
      }

      communityDegree[community] =
          (communityDegree[community] ?? 0) +
              graph.degree(node);

      for (final entry
          in graph.neighbors(node).entries) {
        final neighbor = entry.key;

        if (node > neighbor) {
          continue;
        }

        if (nodeCommunity[neighbor] ==
            community) {
          communityInternalWeight[community] =
              (communityInternalWeight[
                          community] ??
                      0) +
                  entry.value;
        }
      }
    }

    var modularity = 0.0;

    for (final community
        in communityInternalWeight.keys) {
      final internalWeight =
          communityInternalWeight[community] ??
              0;

      final degree =
          communityDegree[community] ?? 0;

      modularity +=
          internalWeight / totalWeight -
              (degree /
                      (2 * totalWeight)) *
                  (degree /
                      (2 * totalWeight));
    }

    return modularity;
  }
}

class _WeightedGraph {
  final Map<int, Map<int, double>> _adjacency =
      {};

  _WeightedGraph();

  Set<int> get nodes =>
      _adjacency.keys.toSet();

  double get totalWeight {
    var total = 0.0;

    for (final node in nodes) {
      for (final entry
          in neighbors(node).entries) {
        total += entry.value;
      }
    }

    return total / 2;
  }

  void addNode(int node) {
    _adjacency.putIfAbsent(
      node,
      () => {},
    );
  }

  void addEdge(
    int a,
    int b,
    double weight,
  ) {
    addNode(a);
    addNode(b);

    _adjacency[a]![b] =
        (_adjacency[a]![b] ?? 0) + weight;

    if (a != b) {
      _adjacency[b]![a] =
          (_adjacency[b]![a] ?? 0) + weight;
    }
  }

  Map<int, double> neighbors(int node) {
    return _adjacency[node] ?? {};
  }

  double degree(int node) {
    var total = 0.0;

    for (final entry
        in neighbors(node).entries) {
      total += entry.value;

      if (entry.key == node) {
        total += entry.value;
      }
    }

    return total;
  }

  double weightToCommunity(
    int node,
    int community,
    Map<int, int> labels,
  ) {
    var total = 0.0;

    for (final entry
        in neighbors(node).entries) {
      if (entry.key == node) {
        continue;
      }

      if (labels[entry.key] == community) {
        total += entry.value;
      }
    }

    return total;
  }

  factory _WeightedGraph.fromCollaborationGraph(
    CollaborationGraph graph,
  ) {
    final result = _WeightedGraph();

    for (final node in graph.getArtists()) {
      result.addNode(node);

      for (final entry
          in graph.getNeighbors(node).entries) {
        if (node <= entry.key) {
          result.addEdge(
            node,
            entry.key,
            entry.value.toDouble(),
          );
        }
      }
    }

    return result;
  }
}