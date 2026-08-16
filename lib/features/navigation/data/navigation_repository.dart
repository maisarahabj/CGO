import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/database_tables.dart';
import '../../../core/exceptions/app_exception.dart';
import '../models/destination_model.dart';
import '../models/edge_model.dart';
import '../models/floor_model.dart';
import '../models/navigation_graph_data.dart';
import '../models/node_model.dart';

/// The only navigation class that reads graph data directly from Supabase.
///
/// Views and controllers work with Dart models instead of raw database maps.
/// This keeps table names, column names, and filtering rules in one place.
class NavigationRepository {
  NavigationRepository({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  static const String _floorColumns =
      'floor_id, level_number, floor_name, spline_url, is_accessible';
  static const String _nodeColumns =
      'node_id, floor_id, node_code, node_type, label, description, '
      'x_coord, y_coord, z_coord, tags, is_active';
  static const String _edgeColumns =
      'edge_id, source_node_id, target_node_id, traversal_cost, edge_type, '
      'description, distance_weight, is_accessible, is_active';

  /// Loads the floors that exist in the CampusGO map.
  Future<List<FloorModel>> fetchFloors() async {
    try {
      final rows = await _client
          .from(DatabaseTables.floors)
          .select(_floorColumns)
          .order('level_number');

      return rows
          .map((row) => FloorModel.fromJson(Map<String, dynamic>.from(row)))
          .toList(growable: false);
    } catch (error) {
      throw AppException('Unable to load navigation floors.', cause: error);
    }
  }

  /// Loads every active node, including hidden corridor junctions.
  /// Junctions are needed by Dijkstra even though they are not shown in search.
  Future<List<NodeModel>> fetchActiveNodes() async {
    try {
      final rows = await _client
          .from(DatabaseTables.nodes)
          .select(_nodeColumns)
          .eq('is_active', true)
          .order('node_id');

      return rows
          .map((row) => NodeModel.fromJson(Map<String, dynamic>.from(row)))
          .toList(growable: false);
    } catch (error) {
      throw AppException('Unable to load navigation nodes.', cause: error);
    }
  }

  /// Loads active walking, lift, stair, auditorium, and other route edges.
  ///
  /// Accessibility filtering happens before the list reaches Dijkstra. When
  /// [accessibleOnly] is true, a stair row marked inaccessible cannot be used.
  Future<List<EdgeModel>> fetchActiveEdges({
    bool accessibleOnly = false,
  }) async {
    try {
      final rows = await _client
          .from(DatabaseTables.edges)
          .select(_edgeColumns)
          .eq('is_active', true)
          .order('edge_id');

      final edges = rows
          .map((row) => EdgeModel.fromJson(Map<String, dynamic>.from(row)))
          .where((edge) => !accessibleOnly || edge.isAccessible)
          .toList(growable: false);

      return edges;
    } catch (error) {
      throw AppException('Unable to load navigation edges.', cause: error);
    }
  }

  /// Loads one internally consistent graph snapshot for Dijkstra.
  Future<NavigationGraphData> loadGraph({
    bool accessibleOnly = false,
  }) async {
    final results = await Future.wait<Object>([
      fetchFloors(),
      fetchActiveNodes(),
      fetchActiveEdges(accessibleOnly: accessibleOnly),
    ]);

    return NavigationGraphData(
      floors: results[0] as List<FloorModel>,
      nodes: results[1] as List<NodeModel>,
      edges: results[2] as List<EdgeModel>,
    );
  }

  /// Resolves a QR or manually selected node ID to one active node.
  Future<NodeModel?> findActiveNodeById(String nodeId) async {
    final normalizedId = nodeId.trim();
    if (normalizedId.isEmpty) return null;

    try {
      final row = await _client
          .from(DatabaseTables.nodes)
          .select(_nodeColumns)
          .eq('node_id', normalizedId)
          .eq('is_active', true)
          .maybeSingle();

      if (row == null) return null;
      return NodeModel.fromJson(Map<String, dynamic>.from(row));
    } catch (error) {
      throw AppException('Unable to find that CampusGO location.', cause: error);
    }
  }

  /// Loads the labelled node list once. The UI can then filter it instantly as
  /// the user types instead of sending one network request for every letter.
  Future<List<DestinationModel>> fetchSearchableDestinations() async {
    final nodes = await fetchActiveNodes();
    return buildSearchableDestinations(nodes);
  }

  /// Derives search results from nodes that have already been loaded as part of
  /// [loadGraph], avoiding a second request for the same node rows.
  List<DestinationModel> buildSearchableDestinations(
    Iterable<NodeModel> nodes,
  ) {
    final destinations = nodes
        .where((node) => node.isSearchableDestination)
        .map((node) => DestinationModel(node: node))
        .toList();

    destinations.sort((first, second) {
      final nameComparison = first.name.toLowerCase().compareTo(
        second.name.toLowerCase(),
      );

      if (nameComparison != 0) return nameComparison;
      return first.nodeId.compareTo(second.nodeId);
    });

    return List.unmodifiable(destinations);
  }

  /// Pure in-memory search used after [fetchSearchableDestinations].
  List<DestinationModel> filterDestinations({
    required List<DestinationModel> destinations,
    required String query,
    int limit = 12,
  }) {
    if (limit <= 0) return const [];

    final normalizedQuery = query.trim();
    if (normalizedQuery.isEmpty) {
      return destinations.take(limit).toList(growable: false);
    }

    return destinations
        .where((destination) => destination.matchesSearch(normalizedQuery))
        .take(limit)
        .toList(growable: false);
  }
}
