/// Ordered output that will be produced by Dijkstra in the next stage.
///
/// Node IDs are used for instruction and marker calculations. Edge IDs are
/// sent to Spline so that the matching route objects become visible.
class RouteResult {
  RouteResult({
    required List<String> nodeIds,
    required List<String> edgeIds,
    required this.totalCost,
  }) : nodeIds = List.unmodifiable(nodeIds),
       edgeIds = List.unmodifiable(edgeIds);

  factory RouteResult.noRoute() {
    return RouteResult(nodeIds: const [], edgeIds: const [], totalCost: 0);
  }

  final List<String> nodeIds;
  final List<String> edgeIds;
  final double totalCost;

  bool get hasRoute => nodeIds.isNotEmpty;
}
