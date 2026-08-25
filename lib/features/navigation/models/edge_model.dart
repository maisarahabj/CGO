/// Represents one row from the `public.edges` table in Supabase.
class EdgeModel {
  const EdgeModel({
    required this.edgeId,
    this.sourceNodeId,
    this.targetNodeId,
    this.traversalCost,
    this.edgeType,
    this.description,
    this.distanceWeight,
    this.isAccessible = true,
    this.isActive = true,
    this.closureReason,
  });

  final String edgeId;
  final String? sourceNodeId;
  final String? targetNodeId;
  final double? traversalCost;
  final String? edgeType;
  final String? description;
  final double? distanceWeight;
  final bool isAccessible;
  final bool isActive;
  final String? closureReason;

  /// The number Dijkstra should minimise.
  ///
  /// `traversal_cost` is preferred because it may include a walking penalty
  /// for stairs or lifts. `distance_weight` is a safe fallback for older rows.
  double? get routingCost {
    final value = traversalCost ?? distanceWeight;

    if (value == null || value.isNaN || value.isInfinite || value < 0) {
      return null;
    }

    return value;
  }

  /// A row can participate in the graph only when its endpoints and cost are
  /// present. Inactive rows are intentionally excluded.
  bool get isUsableForRouting {
    final source = sourceNodeId?.trim();
    final target = targetNodeId?.trim();

    return isActive &&
        source != null &&
        source.isNotEmpty &&
        target != null &&
        target.isNotEmpty &&
        source != target &&
        routingCost != null;
  }

  /// Returns the node on the opposite end of this edge.
  /// Campus corridors are treated as two-way unless we later add a direction
  /// column to the database.
  String? otherNodeId(String nodeId) {
    if (nodeId == sourceNodeId) return targetNodeId;
    if (nodeId == targetNodeId) return sourceNodeId;
    return null;
  }

  /// Converts one Supabase edges row into an EdgeModel.
  factory EdgeModel.fromJson(Map<String, dynamic> json) {
    return EdgeModel(
      edgeId: json['edge_id'] as String,
      sourceNodeId: json['source_node_id'] as String?,
      targetNodeId: json['target_node_id'] as String?,
      traversalCost: (json['traversal_cost'] as num?)?.toDouble(),
      edgeType: json['edge_type'] as String?,
      description: json['description'] as String?,
      distanceWeight: (json['distance_weight'] as num?)?.toDouble(),
      isAccessible: json['is_accessible'] as bool? ?? true,
      isActive: json['is_active'] as bool? ?? true,
      closureReason: json['closure_reason'] as String?,
    );
  }

  /// Converts this model back into Supabase column names.
  Map<String, dynamic> toJson() {
    return {
      'edge_id': edgeId,
      'source_node_id': sourceNodeId,
      'target_node_id': targetNodeId,
      'traversal_cost': traversalCost,
      'edge_type': edgeType,
      'description': description,
      'distance_weight': distanceWeight,
      'is_accessible': isAccessible,
      'is_active': isActive,
      'closure_reason': closureReason,
    };
  }
}
