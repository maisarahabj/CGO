import '../models/navigation_graph_data.dart';
import '../models/route_result.dart';

/// Calculates the lowest-cost route through one navigation graph snapshot.
///
/// The repository must apply accessibility filtering before passing the graph
/// here. This service remains focused only on shortest-path calculation.
class DijkstraService {
  const DijkstraService();

  /// Returns ordered node IDs, ordered edge IDs, and the total routing cost.
  ///
  /// Normal CampusGO edges are added in both directions. Inactive, malformed,
  /// negatively weighted, and orphaned edges are ignored defensively.
  RouteResult findShortestRoute({
    required NavigationGraphData graph,
    required String startNodeId,
    required String destinationNodeId,
  }) {
    final start = startNodeId.trim();
    final destination = destinationNodeId.trim();

    if (!graph.nodeById.containsKey(start) ||
        !graph.nodeById.containsKey(destination)) {
      return RouteResult.noRoute();
    }

    if (start == destination) {
      return RouteResult(
        nodeIds: [start],
        edgeIds: const [],
        totalCost: 0,
      );
    }

    final adjacencyList = _buildAdjacencyList(graph);
    final bestCostByNode = <String, double>{
      for (final node in graph.nodes) node.nodeId: double.infinity,
    };
    final previousNodeByNode = <String, String>{};
    final previousEdgeByNode = <String, String>{};
    final queue = _MinPriorityQueue();

    bestCostByNode[start] = 0;
    queue.add(_QueueEntry(nodeId: start, totalCost: 0));

    while (queue.isNotEmpty) {
      final current = queue.removeFirst();
      final currentBestCost = bestCostByNode[current.nodeId]!;

      // A node may enter the queue more than once when a cheaper route is
      // discovered. Ignore an older entry whose cost is no longer the best.
      if (current.totalCost > currentBestCost) continue;

      // The cheapest destination entry has now reached the front of the
      // queue, so no later route can improve it.
      if (current.nodeId == destination) break;

      for (final connection in adjacencyList[current.nodeId]!) {
        final candidateCost = current.totalCost + connection.cost;
        final knownCost = bestCostByNode[connection.targetNodeId]!;

        if (candidateCost >= knownCost) continue;

        bestCostByNode[connection.targetNodeId] = candidateCost;
        previousNodeByNode[connection.targetNodeId] = current.nodeId;
        previousEdgeByNode[connection.targetNodeId] = connection.edgeId;
        queue.add(
          _QueueEntry(
            nodeId: connection.targetNodeId,
            totalCost: candidateCost,
          ),
        );
      }
    }

    final destinationCost = bestCostByNode[destination]!;
    if (destinationCost.isInfinite) {
      return RouteResult.noRoute();
    }

    return _reconstructRoute(
      startNodeId: start,
      destinationNodeId: destination,
      totalCost: destinationCost,
      previousNodeByNode: previousNodeByNode,
      previousEdgeByNode: previousEdgeByNode,
    );
  }

  Map<String, List<_GraphConnection>> _buildAdjacencyList(
    NavigationGraphData graph,
  ) {
    final adjacencyList = <String, List<_GraphConnection>>{
      for (final node in graph.nodes) node.nodeId: <_GraphConnection>[],
    };

    for (final edge in graph.edges) {
      final sourceNodeId = edge.sourceNodeId?.trim();
      final targetNodeId = edge.targetNodeId?.trim();
      final cost = edge.routingCost;

      if (!edge.isUsableForRouting ||
          sourceNodeId == null ||
          targetNodeId == null ||
          cost == null ||
          !adjacencyList.containsKey(sourceNodeId) ||
          !adjacencyList.containsKey(targetNodeId)) {
        continue;
      }

      adjacencyList[sourceNodeId]!.add(
        _GraphConnection(
          targetNodeId: targetNodeId,
          edgeId: edge.edgeId,
          cost: cost,
        ),
      );

      adjacencyList[targetNodeId]!.add(
        _GraphConnection(
          targetNodeId: sourceNodeId,
          edgeId: edge.edgeId,
          cost: cost,
        ),
      );
    }

    return adjacencyList;
  }

  RouteResult _reconstructRoute({
    required String startNodeId,
    required String destinationNodeId,
    required double totalCost,
    required Map<String, String> previousNodeByNode,
    required Map<String, String> previousEdgeByNode,
  }) {
    final reversedNodeIds = <String>[destinationNodeId];
    final reversedEdgeIds = <String>[];
    var currentNodeId = destinationNodeId;

    while (currentNodeId != startNodeId) {
      final previousNodeId = previousNodeByNode[currentNodeId];
      final previousEdgeId = previousEdgeByNode[currentNodeId];

      // This should not happen after a finite destination cost, but returning
      // noRoute keeps corrupted predecessor data from producing a partial path.
      if (previousNodeId == null || previousEdgeId == null) {
        return RouteResult.noRoute();
      }

      reversedEdgeIds.add(previousEdgeId);
      reversedNodeIds.add(previousNodeId);
      currentNodeId = previousNodeId;
    }

    return RouteResult(
      nodeIds: reversedNodeIds.reversed.toList(growable: false),
      edgeIds: reversedEdgeIds.reversed.toList(growable: false),
      totalCost: totalCost,
    );
  }
}

class _GraphConnection {
  const _GraphConnection({
    required this.targetNodeId,
    required this.edgeId,
    required this.cost,
  });

  final String targetNodeId;
  final String edgeId;
  final double cost;
}

class _QueueEntry {
  const _QueueEntry({required this.nodeId, required this.totalCost});

  final String nodeId;
  final double totalCost;
}

/// Small binary min-heap used to retrieve the currently cheapest node.
///
/// This avoids adding another package dependency for one priority queue.
class _MinPriorityQueue {
  final List<_QueueEntry> _entries = [];

  bool get isNotEmpty => _entries.isNotEmpty;

  void add(_QueueEntry entry) {
    _entries.add(entry);
    _moveUp(_entries.length - 1);
  }

  _QueueEntry removeFirst() {
    final first = _entries.first;
    final last = _entries.removeLast();

    if (_entries.isNotEmpty) {
      _entries[0] = last;
      _moveDown(0);
    }

    return first;
  }

  void _moveUp(int index) {
    var childIndex = index;

    while (childIndex > 0) {
      final parentIndex = (childIndex - 1) ~/ 2;
      if (_compare(_entries[childIndex], _entries[parentIndex]) >= 0) break;

      _swap(childIndex, parentIndex);
      childIndex = parentIndex;
    }
  }

  void _moveDown(int index) {
    var parentIndex = index;

    while (true) {
      final leftChildIndex = parentIndex * 2 + 1;
      final rightChildIndex = leftChildIndex + 1;
      var smallestIndex = parentIndex;

      if (leftChildIndex < _entries.length &&
          _compare(_entries[leftChildIndex], _entries[smallestIndex]) < 0) {
        smallestIndex = leftChildIndex;
      }

      if (rightChildIndex < _entries.length &&
          _compare(_entries[rightChildIndex], _entries[smallestIndex]) < 0) {
        smallestIndex = rightChildIndex;
      }

      if (smallestIndex == parentIndex) break;

      _swap(parentIndex, smallestIndex);
      parentIndex = smallestIndex;
    }
  }

  int _compare(_QueueEntry first, _QueueEntry second) {
    final costComparison = first.totalCost.compareTo(second.totalCost);
    if (costComparison != 0) return costComparison;

    // The node ID tie-breaker makes equal-cost test results deterministic.
    return first.nodeId.compareTo(second.nodeId);
  }

  void _swap(int firstIndex, int secondIndex) {
    final temporary = _entries[firstIndex];
    _entries[firstIndex] = _entries[secondIndex];
    _entries[secondIndex] = temporary;
  }
}
