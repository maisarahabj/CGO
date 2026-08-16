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

  /// Name shown in search results and current-location labels.
  ///
  /// Most physical destinations have a human-readable `label`. The fallbacks
  /// prevent an incomplete row from producing an empty label in the UI.
  String get displayName {
    final candidates = [label, description, nodeCode, nodeId];

    for (final candidate in candidates) {
      final value = candidate?.trim();
      if (value != null && value.isNotEmpty) return value;
    }

    return nodeId;
  }

  /// Whether this node has a position that can later be sent to Spline.
  bool get hasCoordinates =>
      xCoord != null && yCoord != null && zCoord != null;

  /// Only active, labelled nodes should be offered to the user as destinations.
  /// Unlabelled junction nodes remain available to Dijkstra but stay out of
  /// destination search results.
  bool get isSearchableDestination =>
      isActive && label != null && label!.trim().isNotEmpty;

  /// Text used by the local destination filter.
  String get searchableText => [
    label,
    nodeCode,
    nodeType,
    description,
    tags,
    floorId,
  ].whereType<String>().join(' ').toLowerCase();

  /// Matches every word typed by the user, regardless of word order.
  bool matchesSearch(String query) {
    final terms = query
        .trim()
        .toLowerCase()
        .split(RegExp(r'\s+'))
        .where((term) => term.isNotEmpty);

    return terms.every(searchableText.contains);
  }

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
      tags: json['tags']?.toString(),
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
