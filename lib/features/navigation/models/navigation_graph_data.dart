import 'edge_model.dart';
import 'floor_model.dart';
import 'node_model.dart';

/// One consistent snapshot of the navigation data loaded from Supabase.
///
/// Keeping the lists together is important: Dijkstra should not accidentally
/// use nodes from one database request and edges from a later request.
class NavigationGraphData {
  NavigationGraphData({
    required List<FloorModel> floors,
    required List<NodeModel> nodes,
    required List<EdgeModel> edges,
  }) : floors = List.unmodifiable(floors),
       nodes = List.unmodifiable(nodes),
       edges = List.unmodifiable(edges),
       floorById = Map.unmodifiable({
         for (final floor in floors) floor.floorId: floor,
       }),
       nodeById = Map.unmodifiable({for (final node in nodes) node.nodeId: node}),
       edgeById = Map.unmodifiable({for (final edge in edges) edge.edgeId: edge});

  final List<FloorModel> floors;
  final List<NodeModel> nodes;
  final List<EdgeModel> edges;

  final Map<String, FloorModel> floorById;
  final Map<String, NodeModel> nodeById;
  final Map<String, EdgeModel> edgeById;

  /// Short verification text that can be printed after the first live load.
  String get debugSummary =>
      'Loaded ${floors.length} floors, ${nodes.length} active nodes, '
      '${edges.length} active edges. '
      'Invalid edges: ${invalidEdges.length}. '
      'Orphaned edges: ${orphanedEdges.length}.';

  /// Active rows that are missing an endpoint or a usable non-negative cost.
  List<EdgeModel> get invalidEdges =>
      edges.where((edge) => !edge.isUsableForRouting).toList(growable: false);

  /// Edges that refer to a node not present in this active graph snapshot.
  List<EdgeModel> get orphanedEdges => edges.where((edge) {
    return !nodeById.containsKey(edge.sourceNodeId) ||
        !nodeById.containsKey(edge.targetNodeId);
  }).toList(growable: false);
}
