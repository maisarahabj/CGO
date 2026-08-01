/// Represents one row from the `public.nodes` table in Supabase.
class NodeModel {
  const NodeModel({
    required this.nodeId,
    this.floorId,
    this.nodeCode,
    this.nodeType,
    this.label,
    this.description,
    this.xCoord,
    this.yCoord,
    this.zCoord,
    this.tags,
    this.isActive = true,
  });

  final String nodeId;
  final String? floorId;
  final String? nodeCode;
  final String? nodeType;
  final String? label;
  final String? description;
  final double? xCoord;
  final double? yCoord;
  final double? zCoord;
  final String? tags;
  final bool isActive;

  /// Converts a Supabase nodes row into a NodeModel.
  factory NodeModel.fromJson(Map<String, dynamic> json) {
    return NodeModel(
      nodeId: json['node_id'] as String,
      floorId: json['floor_id'] as String?,
      nodeCode: json['node_code'] as String?,
      nodeType: json['node_type'] as String?,
      label: json['label'] as String?,
      description: json['description'] as String?,
      xCoord: (json['x_coord'] as num?)?.toDouble(),
      yCoord: (json['y_coord'] as num?)?.toDouble(),
      zCoord: (json['z_coord'] as num?)?.toDouble(),
      tags: json['tags'] as String?,
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  /// Converts this model back into Supabase column names.
  Map<String, dynamic> toJson() {
    return {
      'node_id': nodeId,
      'floor_id': floorId,
      'node_code': nodeCode,
      'node_type': nodeType,
      'label': label,
      'description': description,
      'x_coord': xCoord,
      'y_coord': yCoord,
      'z_coord': zCoord,
      'tags': tags,
      'is_active': isActive,
    };
  }
}
