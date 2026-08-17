import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/database_tables.dart';
import '../../../core/exceptions/app_exception.dart';
import '../models/destination_model.dart';
import '../models/edge_model.dart';
import '../models/floor_model.dart';
import '../models/navigation_graph_data.dart';
import '../models/node_model.dart';
import '../models/qr_code_model.dart';

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

  static const String _qrColumns =
      'qr_id, node_id, qr_value, location_description, status';

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
  ///
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

  /// Loads active navigation edges.
  ///
  /// When [accessibleOnly] is false:
  /// - every active edge is returned.
  ///
  /// When [accessibleOnly] is true:
  /// - only edges where is_accessible = true are returned.
  ///
  /// Supabase is the source of truth for whether an edge is accessible.
  /// Dart does not infer accessibility from edge_type or node_type.
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
  ///
  /// Accessibility filtering is controlled entirely by the
  /// edges.is_accessible value from Supabase.
  Future<NavigationGraphData> loadGraph({bool accessibleOnly = false}) async {
    final results = await Future.wait<Object>([
      fetchFloors(),
      fetchActiveNodes(),
      fetchActiveEdges(accessibleOnly: accessibleOnly),
    ]);

    final graph = NavigationGraphData(
      floors: results[0] as List<FloorModel>,
      nodes: results[1] as List<NodeModel>,
      edges: results[2] as List<EdgeModel>,
    );

    return graphForRouting(graph: graph, accessibleOnly: accessibleOnly);
  }

  /// Creates the graph snapshot that may be passed to Dijkstra.
  ///
  /// This method is useful when the controller already has the full graph
  /// loaded in memory and the user changes the accessibility toggle.
  ///
  /// Accessibility OFF:
  ///   all active edges remain available.
  ///
  /// Accessibility ON:
  ///   only edges where is_accessible = true remain available.
  NavigationGraphData graphForRouting({
    required NavigationGraphData graph,
    required bool accessibleOnly,
  }) {
    if (!accessibleOnly) {
      return graph;
    }

    return NavigationGraphData(
      floors: graph.floors,
      nodes: graph.nodes,
      edges: graph.edges
          .where((edge) => edge.isAccessible)
          .toList(growable: false),
    );
  }

  /// Finds one CampusGO QR checkpoint by the exact value stored inside the QR.
  ///
  /// Example:
  /// CAMPUSGO_L6_LIFT
  ///        ↓
  /// qr_codes
  ///        ↓
  /// L6_N1
  ///
  /// Inactive checkpoints are also returned so the scanner can distinguish
  /// between "unknown QR" and "known but inactive QR".
  Future<QrCodeModel?> findQrByValue(String qrValue) async {
    final normalizedValue = qrValue.trim();

    if (normalizedValue.isEmpty) {
      return null;
    }

    try {
      final row = await _client
          .from(DatabaseTables.qrCodes)
          .select(_qrColumns)
          .eq('qr_value', normalizedValue)
          .maybeSingle();

      // TEMPORARY DEBUG:
      // This tells us exactly what Supabase returned for the QR lookup.
      debugPrint('QR DEBUG: requested="$normalizedValue", returned=$row');

      if (row == null) {
        return null;
      }

      return QrCodeModel.fromJson(Map<String, dynamic>.from(row));
    } catch (error) {
      throw AppException(
        'Unable to verify that CampusGO QR checkpoint.',
        cause: error,
      );
    }
  }

  /// Resolves the node_id obtained from the QR table into the existing
  /// navigation NodeModel.
  ///
  /// Example:
  /// L6_N1
  ///   ↓
  /// nodes table
  ///   ↓
  /// NodeModel
  Future<NodeModel?> findActiveNodeById(String nodeId) async {
    final normalizedId = nodeId.trim();

    if (normalizedId.isEmpty) {
      return null;
    }

    try {
      final row = await _client
          .from(DatabaseTables.nodes)
          .select(_nodeColumns)
          .eq('node_id', normalizedId)
          .eq('is_active', true)
          .maybeSingle();

      if (row == null) {
        return null;
      }

      return NodeModel.fromJson(Map<String, dynamic>.from(row));
    } catch (error) {
      throw AppException(
        'Unable to find that CampusGO location.',
        cause: error,
      );
    }
  }

  /// Loads the labelled node list once.
  ///
  /// The UI can then filter it locally instead of sending one Supabase request
  /// for every character the user types.
  Future<List<DestinationModel>> fetchSearchableDestinations() async {
    final nodes = await fetchActiveNodes();

    return buildSearchableDestinations(nodes);
  }

  /// Derives searchable locations from nodes that are already loaded as part
  /// of the navigation graph.
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

      if (nameComparison != 0) {
        return nameComparison;
      }

      return first.nodeId.compareTo(second.nodeId);
    });

    return List.unmodifiable(destinations);
  }

  /// Pure in-memory search used after the searchable destinations are loaded.
  List<DestinationModel> filterDestinations({
    required List<DestinationModel> destinations,
    required String query,
    int limit = 12,
  }) {
    if (limit <= 0) {
      return const [];
    }

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
