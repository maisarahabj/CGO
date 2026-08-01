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
    };
  }
}
