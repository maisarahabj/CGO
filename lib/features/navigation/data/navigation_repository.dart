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

  static const String qrImageBucket = 'qr-checkpoints';
  static const int _maximumQrImageBytes = 5 * 1024 * 1024;

  static const String _floorColumns =
      'floor_id, level_number, floor_name, spline_url, is_accessible';

  static const String _nodeColumns =
      'node_id, floor_id, node_code, node_type, label, description, '
      'x_coord, y_coord, z_coord, tags, is_active';

  static const String _edgeColumns =
      'edge_id, source_node_id, target_node_id, traversal_cost, edge_type, '
      'description, distance_weight, is_accessible, is_active, closure_reason';

  static const String _qrColumns =
      'qr_id, node_id, qr_value, location_description, status, qr_image_path';

  /// Saves one completed route selection for the currently signed-in user.
  ///
  /// visit_id is supplied explicitly because the existing seeded records use
  /// string IDs such as v001 and the table may not generate its own key.
  /// Base-36 keeps the timestamp-based ID compact while retaining uniqueness.
  Future<void> recordVisit({required String destinationNodeId}) async {
    final normalizedNodeId = destinationNodeId.trim();

    if (normalizedNodeId.isEmpty) {
      throw const AppException(
        'A destination is required before saving visit history.',
      );
    }

    final currentUser = _client.auth.currentUser;

    if (currentUser == null) {
      throw const AppException(
        'Sign in before saving CampusGO visit history.',
      );
    }

    final visitedAt = DateTime.now().toUtc();
    final visitId = 'v${visitedAt.microsecondsSinceEpoch.toRadixString(36)}';

    try {
      await _client.from(DatabaseTables.visitHistories).insert(
        <String, dynamic>{
          'visit_id': visitId,
          'user_id': currentUser.id,
          'destination_node_id': normalizedNodeId,
          'visited_at': visitedAt.toIso8601String(),
        },
      );

      debugPrint(
        'CampusGO visit history saved: '
        'visit=$visitId, '
        'user=${currentUser.id}, '
        'destination=$normalizedNodeId.',
      );
    } on PostgrestException catch (error) {
      debugPrint(
        'CampusGO visit history insert rejected: '
        'code=${error.code}, message=${error.message}',
      );

      throw AppException(
        'Unable to save visit history: ${error.message}',
        cause: error,
      );
    } catch (error) {
      throw AppException('Unable to save visit history.', cause: error);
    }
  }

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

  /// Loads public route-closure announcements without adding those edges to
  /// the graph used for navigation.
  ///
  /// A dedicated Supabase SELECT policy exposes only inactive edges that have
  /// a nonblank closure reason. [fetchActiveEdges] continues to request
  /// `is_active = true`, so guests and registered users can read an alert
  /// without ever being routed through its closed segment.
  Future<List<EdgeModel>> fetchClosedRouteNotices() async {
    try {
      final rows = await _client
          .from(DatabaseTables.edges)
          .select(_edgeColumns)
          .eq('is_active', false)
          .order('edge_id');

      return rows
          .map((row) => EdgeModel.fromJson(Map<String, dynamic>.from(row)))
          .where((edge) => edge.closureReason?.trim().isNotEmpty == true)
          .toList(growable: false);
    } catch (error) {
      throw AppException('Unable to load closed route notices.', cause: error);
    }
  }

  /// Loads every navigation edge for the administrator, including closed
  /// edges. User and guest routing must continue using [fetchActiveEdges].
  Future<List<EdgeModel>> fetchManageableEdges() async {
    try {
      final rows = await _client
          .from(DatabaseTables.edges)
          .select(_edgeColumns)
          .order('edge_id');

      return rows
          .map((row) => EdgeModel.fromJson(Map<String, dynamic>.from(row)))
          .toList(growable: false);
    } catch (error) {
      throw AppException('Unable to load route segments.', cause: error);
    }
  }

  /// Opens or closes one existing edge without changing its accessibility.
  ///
  /// `is_active` answers whether the segment is currently usable.
  /// `is_accessible` remains an independent property and is deliberately not
  /// included in this update payload.
  Future<EdgeModel> updateEdgeActiveState({
    required String edgeId,
    required bool isActive,
    String? closureReason,
  }) async {
    final normalizedEdgeId = edgeId.trim();

    if (normalizedEdgeId.isEmpty) {
      throw const AppException('Select a route segment to manage.');
    }

    final normalizedReason = closureReason?.trim();

    if (!isActive && (normalizedReason == null || normalizedReason.isEmpty)) {
      throw const AppException('Select a reason before closing this route.');
    }

    if (_client.auth.currentUser == null) {
      throw const AppException(
        'Sign in with an administrator account before managing routes.',
      );
    }

    debugPrint(
      'CampusGO admin edge update requested: '
      'edge=$normalizedEdgeId, '
      'is_active=$isActive, '
      'closure_reason=${isActive ? 'null' : normalizedReason}',
    );

    try {
      final row = await _client
          .from(DatabaseTables.edges)
          .update(<String, dynamic>{
            'is_active': isActive,
            'closure_reason': isActive ? null : normalizedReason,
          })
          .eq('edge_id', normalizedEdgeId)
          .select(_edgeColumns)
          .maybeSingle();

      if (row == null) {
        throw const AppException(
          'Supabase did not return the updated route. Check that this account '
          'is an admin and that public.edges allows admins to UPDATE routes '
          'and SELECT closed routes.',
        );
      }

      final updated = EdgeModel.fromJson(Map<String, dynamic>.from(row));

      debugPrint(
        'CampusGO admin edge update saved: '
        'edge=${updated.edgeId}, '
        'is_active=${updated.isActive}, '
        'closure_reason=${updated.closureReason}',
      );

      return updated;
    } on AppException {
      rethrow;
    } on PostgrestException catch (error) {
      final operation = isActive ? 'reopen' : 'close';
      final databaseMessage = error.message.trim();
      final normalizedMessage = databaseMessage.toLowerCase();

      debugPrint(
        'CampusGO admin edge update failed: '
        'edge=$normalizedEdgeId, '
        'code=${error.code}, '
        'message=$databaseMessage, '
        'details=${error.details}, '
        'hint=${error.hint}',
      );

      if (error.code == '42501' ||
          normalizedMessage.contains('row-level security') ||
          normalizedMessage.contains('permission denied')) {
        throw AppException(
          'Supabase denied permission to $operation this route. Check the '
          'admin UPDATE and SELECT policies on public.edges and confirm that '
          'your profile role is admin.',
          cause: error,
        );
      }

      if (normalizedMessage.contains('closure_reason')) {
        throw AppException(
          'Supabase could not update closure_reason: $databaseMessage',
          cause: error,
        );
      }

      throw AppException(
        'Unable to $operation this route segment: $databaseMessage',
        cause: error,
      );
    } catch (error) {
      debugPrint(
        'CampusGO admin edge update failed unexpectedly: '
        'edge=$normalizedEdgeId, error=$error',
      );
      throw AppException(
        'Unable to ${isActive ? 'reopen' : 'close'} this route segment.',
        cause: error,
      );
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

  /// Loads all existing checkpoints, including inactive ones, for admins.
  ///
  /// Scanner lookups remain separate because an administrator must be able to
  /// see and reactivate records that a normal user cannot currently scan.
  Future<List<QrCodeModel>> fetchQrCheckpoints() async {
    try {
      final rows = await _client
          .from(DatabaseTables.qrCodes)
          .select(_qrColumns)
          .order('qr_id');

      return rows
          .map((row) => QrCodeModel.fromJson(Map<String, dynamic>.from(row)))
          .toList(growable: false);
    } catch (error) {
      throw AppException(
        _checkpointErrorMessage('Unable to load QR checkpoints', error),
        cause: error,
      );
    }
  }

  /// Updates the physical location represented by one existing checkpoint.
  ///
  /// qr_value is intentionally never changed here. The printed QR can contain
  /// a value such as CAMPUSGO_L8_LIFT while qr_id is displayed as QR005. Its
  /// physical code must continue scanning after the assigned node is changed.
  Future<QrCodeModel> updateQrCheckpoint({
    required String qrId,
    required String nodeId,
    required String locationDescription,
    required bool isActive,
    String? existingImagePath,
    Uint8List? imageBytes,
    String? imageExtension,
  }) async {
    final normalizedQrId = qrId.trim();
    final normalizedNodeId = nodeId.trim();
    final normalizedDescription = locationDescription.trim();

    if (normalizedQrId.isEmpty) {
      throw const AppException('A checkpoint ID is required.');
    }

    if (normalizedNodeId.isEmpty) {
      throw const AppException('Select a navigation node for this checkpoint.');
    }

    if (normalizedDescription.isEmpty) {
      throw const AppException('Enter a checkpoint location name.');
    }

    String? uploadedImagePath;

    try {
      if (imageBytes != null) {
        uploadedImagePath = await uploadQrCheckpointImage(
          qrId: normalizedQrId,
          imageBytes: imageBytes,
          extension: imageExtension,
        );
      }

      final row = await _client
          .from(DatabaseTables.qrCodes)
          .update(<String, dynamic>{
            'node_id': normalizedNodeId,
            'location_description': normalizedDescription,
            'status': isActive ? 'active' : 'inactive',
            if (uploadedImagePath != null) 'qr_image_path': uploadedImagePath,
          })
          .eq('qr_id', normalizedQrId)
          .select(_qrColumns)
          .single();

      final updated = QrCodeModel.fromJson(Map<String, dynamic>.from(row));
      final previousImagePath = existingImagePath?.trim();

      if (uploadedImagePath != null &&
          previousImagePath != null &&
          previousImagePath.isNotEmpty &&
          previousImagePath != uploadedImagePath) {
        await _tryDeleteQrCheckpointImage(previousImagePath);
      }

      return updated;
    } catch (error) {
      if (uploadedImagePath != null) {
        await _tryDeleteQrCheckpointImage(uploadedImagePath);
      }

      throw AppException(
        _checkpointErrorMessage(
          'Unable to update checkpoint $normalizedQrId',
          error,
        ),
        cause: error,
      );
    }
  }

  /// Creates a checkpoint and optionally links its uploaded QR image.
  ///
  /// Existing records keep their current qr_value. New checkpoints may use
  /// their generated QR ID as the scan value because findQrByValue already
  /// supports any exact, non-empty value stored in qr_codes.qr_value.
  Future<QrCodeModel> createQrCheckpoint({
    required String qrId,
    required String qrValue,
    required String nodeId,
    required String locationDescription,
    required bool isActive,
    Uint8List? imageBytes,
    String? imageExtension,
  }) async {
    final normalizedQrId = qrId.trim();
    final normalizedQrValue = qrValue.trim();
    final normalizedNodeId = nodeId.trim();
    final normalizedDescription = locationDescription.trim();

    if (normalizedQrId.isEmpty || normalizedQrValue.isEmpty) {
      throw const AppException('A checkpoint ID and QR value are required.');
    }

    if (normalizedNodeId.isEmpty) {
      throw const AppException('Select a navigation node for this checkpoint.');
    }

    if (normalizedDescription.isEmpty) {
      throw const AppException('Enter a checkpoint location name.');
    }

    String? uploadedImagePath;

    try {
      if (imageBytes != null) {
        uploadedImagePath = await uploadQrCheckpointImage(
          qrId: normalizedQrId,
          imageBytes: imageBytes,
          extension: imageExtension,
        );
      }

      final row = await _client
          .from(DatabaseTables.qrCodes)
          .insert(<String, dynamic>{
            'qr_id': normalizedQrId,
            'node_id': normalizedNodeId,
            'qr_value': normalizedQrValue,
            'location_description': normalizedDescription,
            'status': isActive ? 'active' : 'inactive',
            if (uploadedImagePath != null) 'qr_image_path': uploadedImagePath,
          })
          .select(_qrColumns)
          .single();

      return QrCodeModel.fromJson(Map<String, dynamic>.from(row));
    } catch (error) {
      if (uploadedImagePath != null) {
        await _tryDeleteQrCheckpointImage(uploadedImagePath);
      }

      throw AppException(
        _checkpointErrorMessage(
          'Unable to create checkpoint $normalizedQrId',
          error,
        ),
        cause: error,
      );
    }
  }

  /// Uploads an administrator-provided QR image and returns its bucket path.
  ///
  /// The path, rather than a permanent URL, is stored in qr_codes so the
  /// database remains independent of the project's Supabase domain.
  Future<String> uploadQrCheckpointImage({
    required String qrId,
    required Uint8List imageBytes,
    required String? extension,
  }) async {
    final normalizedQrId = qrId.trim().toUpperCase();
    final normalizedExtension = extension?.trim().toLowerCase();

    if (normalizedQrId.isEmpty) {
      throw const AppException('A checkpoint ID is required for image upload.');
    }

    if (imageBytes.isEmpty) {
      throw const AppException('The selected QR image is empty.');
    }

    if (imageBytes.lengthInBytes > _maximumQrImageBytes) {
      throw const AppException('Choose a QR image smaller than 5 MB.');
    }

    if (normalizedExtension == null ||
        !const <String>{'png', 'jpg', 'jpeg', 'webp'}
            .contains(normalizedExtension)) {
      throw const AppException('Choose a PNG, JPG, JPEG, or WEBP QR image.');
    }

    final timestamp = DateTime.now().microsecondsSinceEpoch;
    final imagePath = '$normalizedQrId/$timestamp.$normalizedExtension';
    final contentType = normalizedExtension == 'jpg' ||
            normalizedExtension == 'jpeg'
        ? 'image/jpeg'
        : 'image/$normalizedExtension';

    await _client.storage.from(qrImageBucket).uploadBinary(
          imagePath,
          imageBytes,
          fileOptions: FileOptions(contentType: contentType, upsert: false),
        );

    return imagePath;
  }

  /// Resolves an uploaded QR image in the public qr-checkpoints bucket.
  String? qrCheckpointImageUrl(String? imagePath) {
    final normalizedPath = imagePath?.trim();

    if (normalizedPath == null || normalizedPath.isEmpty) return null;

    return _client.storage.from(qrImageBucket).getPublicUrl(normalizedPath);
  }

  /// Best-effort cleanup never makes an otherwise successful save fail.
  Future<void> _tryDeleteQrCheckpointImage(String imagePath) async {
    try {
      await _client.storage.from(qrImageBucket).remove(<String>[imagePath]);
    } catch (error) {
      debugPrint('Unable to remove unused checkpoint image $imagePath: $error');
    }
  }

  String _checkpointErrorMessage(String action, Object error) {
    if (error is AppException && error.message.trim().isNotEmpty) {
      return '$action: ${error.message}';
    }

    if (error is PostgrestException && error.message.trim().isNotEmpty) {
      return '$action: ${error.message}';
    }

    if (error is StorageException && error.message.trim().isNotEmpty) {
      return '$action: ${error.message}';
    }

    return '$action. Please try again.';
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
