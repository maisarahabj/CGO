import 'node_model.dart';

/// A user-facing destination derived from an active, labelled navigation node.
///
/// Dijkstra navigates to node IDs, so a separate rooms table is not required
/// for the first prototype. A classroom, facility, lift lobby, or auditorium
/// can be searchable when its row in `nodes` has a useful label.
class DestinationModel {
  const DestinationModel({required this.node});

  final NodeModel node;

  String get nodeId => node.nodeId;
  String get name => node.displayName;
  String? get floorId => node.floorId;
  String? get nodeType => node.nodeType;
  String? get description => node.description;

  bool matchesSearch(String query) => node.matchesSearch(query);
}
