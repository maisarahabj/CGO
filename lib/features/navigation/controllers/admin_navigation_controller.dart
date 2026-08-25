import 'package:flutter/foundation.dart';

import '../../../core/exceptions/app_exception.dart';
import '../data/navigation_repository.dart';
import '../models/edge_model.dart';
import '../models/node_model.dart';
import '../models/qr_code_model.dart';

/// Admin-side state for CampusGO navigation resources.
///
/// QR and route management live beside the existing navigation graph and
/// scanner so both workflows reuse the same nodes, table names, models, and
/// Supabase client without changing the user map.
class AdminNavigationController extends ChangeNotifier {
  AdminNavigationController({NavigationRepository? repository})
    : _repository = repository ?? NavigationRepository();

  static const List<String> campusFloors = <String>[
    'G',
    'L1',
    'L3',
    'L6',
    'L8',
    'L9',
  ];

  final NavigationRepository _repository;

  List<QrCodeModel> _checkpoints = const <QrCodeModel>[];
  List<EdgeModel> _routeSegments = const <EdgeModel>[];
  List<NodeModel> _nodes = const <NodeModel>[];
  Map<String, NodeModel> _nodesById = const <String, NodeModel>{};

  String _searchQuery = '';
  String _selectedFloor = 'All';
  String? _errorMessage;
  bool _isLoading = false;
  bool _isSaving = false;
  bool _isDisposed = false;

  List<QrCodeModel> get checkpoints => List.unmodifiable(_checkpoints);
  List<EdgeModel> get routeSegments => List.unmodifiable(_routeSegments);
  List<NodeModel> get nodes => List.unmodifiable(_nodes);
  String get searchQuery => _searchQuery;
  String get selectedFloor => _selectedFloor;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;

  int get activeCheckpointCount =>
      _checkpoints.where((checkpoint) => checkpoint.isActive).length;

  int get openRouteCount =>
      _routeSegments.where((edge) => edge.isActive).length;

  int get closedRouteCount => _routeSegments.length - openRouteCount;

  List<QrCodeModel> get filteredCheckpoints {
    final query = _searchQuery.trim().toLowerCase();

    return _checkpoints.where((checkpoint) {
      final floor = floorForCheckpoint(checkpoint);
      final matchesFloor = _selectedFloor == 'All' || floor == _selectedFloor;

      if (!matchesFloor) return false;
      if (query.isEmpty) return true;

      final searchableText = <String>[
        checkpoint.qrId,
        checkpoint.qrValue ?? '',
        checkpoint.nodeId ?? '',
        checkpoint.locationDescription ?? '',
        nodeForCheckpoint(checkpoint)?.displayName ?? '',
        floor,
        checkpoint.isActive ? 'active' : 'inactive',
      ].join(' ').toLowerCase();

      final terms = query
          .split(RegExp(r'\s+'))
          .where((term) => term.isNotEmpty);

      return terms.every(searchableText.contains);
    }).toList(growable: false);
  }

  List<EdgeModel> get filteredRouteSegments {
    final query = _searchQuery.trim().toLowerCase();

    return _routeSegments.where((edge) {
      final floors = routeFloors(edge);
      final matchesFloor =
          _selectedFloor == 'All' || floors.contains(_selectedFloor);

      if (!matchesFloor) return false;
      if (query.isEmpty) return true;

      final searchableText = <String>[
        routeNameForEdge(edge),
        routeEndpointSummary(edge),
        routeTypeLabel(edge),
        routeFloorLabel(edge),
        edge.description ?? '',
        edge.closureReason ?? '',
        edge.isActive ? 'open active usable' : 'closed inactive unavailable',
        edge.isAccessible
            ? 'accessible oku suitable'
            : 'not accessible stairs',
      ].join(' ').toLowerCase();

      final terms = query
          .split(RegExp(r'\s+'))
          .where((term) => term.isNotEmpty);

      return terms.every(searchableText.contains);
    }).toList(growable: false);
  }

  /// Loads checkpoint mappings and active assignable nodes together.
  Future<void> loadCheckpoints({bool showLoadingIndicator = true}) async {
    if (_isDisposed) return;

    if (showLoadingIndicator) _isLoading = true;
    _errorMessage = null;
    _notifyIfActive();

    try {
      final results = await Future.wait<Object>(<Future<Object>>[
        _repository.fetchQrCheckpoints(),
        _repository.fetchActiveNodes(),
      ]);

      if (_isDisposed) return;

      _checkpoints = results[0] as List<QrCodeModel>;
      _nodes = results[1] as List<NodeModel>;
      _nodesById = <String, NodeModel>{
        for (final node in _nodes) node.nodeId: node,
      };
    } catch (error) {
      if (_isDisposed) return;

      _errorMessage = _messageFor(
        error,
        fallback: 'Unable to load QR checkpoints.',
      );
    } finally {
      _isLoading = false;
      _notifyIfActive();
    }
  }

  /// Loads all edge rows for administration and the active node records used
  /// to turn their endpoint IDs into readable route information.
  Future<void> loadRouteSegments({bool showLoadingIndicator = true}) async {
    if (_isDisposed) return;

    if (showLoadingIndicator) _isLoading = true;
    _errorMessage = null;
    _notifyIfActive();

    try {
      final results = await Future.wait<Object>(<Future<Object>>[
        _repository.fetchManageableEdges(),
        _repository.fetchActiveNodes(),
      ]);

      if (_isDisposed) return;

      final routeSegments = results[0] as List<EdgeModel>;
      _nodes = results[1] as List<NodeModel>;
      _nodesById = <String, NodeModel>{
        for (final node in _nodes) node.nodeId: node,
      };

      routeSegments.sort((first, second) {
        final firstFloor = routeFloorLabel(first);
        final secondFloor = routeFloorLabel(second);
        final floorComparison = firstFloor.compareTo(secondFloor);

        if (floorComparison != 0) return floorComparison;

        final nameComparison = routeNameForEdge(first).toLowerCase().compareTo(
          routeNameForEdge(second).toLowerCase(),
        );

        if (nameComparison != 0) return nameComparison;
        return first.edgeId.compareTo(second.edgeId);
      });

      _routeSegments = List<EdgeModel>.unmodifiable(routeSegments);
    } catch (error) {
      if (_isDisposed) return;

      _errorMessage = _messageFor(
        error,
        fallback: 'Unable to load route segments.',
      );
    } finally {
      _isLoading = false;
      _notifyIfActive();
    }
  }

  void setSearchQuery(String query) {
    if (_searchQuery == query) return;

    _searchQuery = query;
    _notifyIfActive();
  }

  void setSelectedFloor(String floor) {
    final normalizedFloor = floor.trim().toUpperCase();
    final nextFloor = normalizedFloor == 'ALL' ? 'All' : normalizedFloor;

    if (nextFloor != 'All' && !campusFloors.contains(nextFloor)) return;
    if (_selectedFloor == nextFloor) return;

    _selectedFloor = nextFloor;
    _notifyIfActive();
  }

  NodeModel? nodeForCheckpoint(QrCodeModel checkpoint) {
    final nodeId = checkpoint.nodeId?.trim();
    if (nodeId == null || nodeId.isEmpty) return null;

    return _nodesById[nodeId];
  }

  /// Existing checkpoints without uploaded images continue using app assets.
  String? imageUrlForCheckpoint(QrCodeModel? checkpoint) {
    if (checkpoint == null) return null;

    return _repository.qrCheckpointImageUrl(checkpoint.qrImagePath);
  }

  NodeModel? nodeById(String? nodeId) {
    if (nodeId == null || nodeId.trim().isEmpty) return null;

    return _nodesById[nodeId.trim()];
  }

  EdgeModel? routeById(String? edgeId) {
    final normalizedEdgeId = edgeId?.trim();
    if (normalizedEdgeId == null || normalizedEdgeId.isEmpty) return null;

    for (final edge in _routeSegments) {
      if (edge.edgeId == normalizedEdgeId) return edge;
    }

    return null;
  }

  /// Finds an existing graph edge without assuming which endpoint Supabase
  /// stores first. Selecting map nodes never creates a new navigation edge.
  EdgeModel? routeBetweenNodes(String firstNodeId, String secondNodeId) {
    final first = firstNodeId.trim();
    final second = secondNodeId.trim();

    if (first.isEmpty || second.isEmpty || first == second) return null;

    for (final edge in _routeSegments) {
      final source = edge.sourceNodeId?.trim();
      final target = edge.targetNodeId?.trim();

      if ((source == first && target == second) ||
          (source == second && target == first)) {
        return edge;
      }
    }

    return null;
  }

  List<String> routeFloors(EdgeModel edge) {
    final floors = <String>[];

    void addFloor(String? nodeId) {
      final floor = _floorForNode(nodeById(nodeId), nodeId);
      if (floor != null && !floors.contains(floor)) floors.add(floor);
    }

    addFloor(edge.sourceNodeId);
    addFloor(edge.targetNodeId);

    return List<String>.unmodifiable(floors);
  }

  String routeFloorLabel(EdgeModel edge) {
    final floors = routeFloors(edge);

    if (floors.isEmpty) return 'Campus';
    return floors.join('–');
  }

  String routeTypeLabel(EdgeModel edge) {
    switch (edge.edgeType?.trim().toLowerCase()) {
      case 'elevator':
      case 'lift':
        return 'Lift';
      case 'stairs':
      case 'staircase':
        return 'Staircase';
      case 'walkway':
      case 'corridor':
        return 'Corridor';
      case 'classroom':
        return 'Classroom access';
      case 'office':
        return 'Office access';
      case 'washroom':
        return 'Washroom access';
      case 'auditorium':
        return 'Auditorium access';
      case 'facility':
        return 'Facility access';
      default:
        final edgeType = edge.edgeType?.trim();
        return edgeType == null || edgeType.isEmpty
            ? 'Route segment'
            : _titleCase(edgeType);
    }
  }

  String routeNameForEdge(EdgeModel edge) {
    final floors = routeFloors(edge);
    final type = routeTypeLabel(edge);

    if (floors.length > 1 && (type == 'Lift' || type == 'Staircase')) {
      return '$type between ${_fullFloorName(floors.first)} and '
          '${_fullFloorName(floors.last)}';
    }

    final description = _meaningfulDescription(edge.description);
    if (description != null) return _titleCase(description);

    final source = _specificNodeName(nodeById(edge.sourceNodeId));
    final target = _specificNodeName(nodeById(edge.targetNodeId));
    final endpointNames = <String>{
      if (source != null) source,
      if (target != null) target,
    }.toList(growable: false);

    if (endpointNames.length == 2) {
      return '${endpointNames.first} – ${endpointNames.last}';
    }

    if (endpointNames.length == 1) {
      return type == 'Corridor'
          ? '${endpointNames.first} Corridor'
          : '${endpointNames.first} $type';
    }

    final floorName = floors.isEmpty
        ? 'Campus'
        : _fullFloorName(floors.first);
    return '$floorName $type';
  }

  String routeEndpointSummary(EdgeModel edge) {
    final source = _friendlyNodeName(edge.sourceNodeId);
    final target = _friendlyNodeName(edge.targetNodeId);

    if (source == target) {
      return '${routeFloorLabel(edge)} route segment';
    }

    return '$source → $target';
  }

  String floorForCheckpoint(QrCodeModel checkpoint) {
    final node = nodeForCheckpoint(checkpoint);
    final floorId = node?.floorId?.trim().toUpperCase();

    if (floorId != null && floorId.isNotEmpty) return floorId;

    final nodeId = checkpoint.nodeId?.trim();
    if (nodeId == null || !nodeId.contains('_')) return '-';

    return nodeId.split('_').first.toUpperCase();
  }

  String locationNameForCheckpoint(QrCodeModel checkpoint) {
    final description = checkpoint.locationDescription?.trim();
    if (description != null && description.isNotEmpty) return description;

    final node = nodeForCheckpoint(checkpoint);
    if (node != null) return node.displayName;

    return checkpoint.nodeId?.trim().isNotEmpty == true
        ? checkpoint.nodeId!.trim()
        : 'Unassigned checkpoint';
  }

  List<NodeModel> nodesForFloor(String floor) {
    final normalizedFloor = floor.trim().toUpperCase();

    final floorNodes = _nodes.where((node) {
      final nodeFloor = node.floorId?.trim().toUpperCase();
      final inferredFloor = node.nodeId.split('_').first.toUpperCase();

      return (nodeFloor ?? inferredFloor) == normalizedFloor;
    }).toList();

    floorNodes.sort((first, second) {
      final firstHasLabel = first.label?.trim().isNotEmpty == true;
      final secondHasLabel = second.label?.trim().isNotEmpty == true;

      if (firstHasLabel != secondHasLabel) return firstHasLabel ? -1 : 1;

      final labelComparison = first.displayName.toLowerCase().compareTo(
        second.displayName.toLowerCase(),
      );

      if (labelComparison != 0) return labelComparison;

      return first.nodeId.compareTo(second.nodeId);
    });

    return floorNodes;
  }

  String get nextCheckpointId {
    var highestNumber = 0;

    for (final checkpoint in _checkpoints) {
      final match = RegExp(
        r'^QR(\d+)$',
        caseSensitive: false,
      ).firstMatch(checkpoint.qrId.trim());

      final value = int.tryParse(match?.group(1) ?? '');
      if (value != null && value > highestNumber) highestNumber = value;
    }

    return 'QR${(highestNumber + 1).toString().padLeft(3, '0')}';
  }

  Future<bool> updateCheckpoint({
    required QrCodeModel checkpoint,
    required String nodeId,
    required String locationDescription,
    required bool isActive,
    Uint8List? imageBytes,
    String? imageExtension,
  }) async {
    if (_isSaving || _isDisposed) return false;

    _isSaving = true;
    _errorMessage = null;
    _notifyIfActive();

    try {
      final updated = await _repository.updateQrCheckpoint(
        qrId: checkpoint.qrId,
        nodeId: nodeId,
        locationDescription: locationDescription,
        isActive: isActive,
        existingImagePath: checkpoint.qrImagePath,
        imageBytes: imageBytes,
        imageExtension: imageExtension,
      );

      if (_isDisposed) return false;

      _checkpoints = _checkpoints
          .map((item) => item.qrId == updated.qrId ? updated : item)
          .toList(growable: false);

      return true;
    } catch (error) {
      if (!_isDisposed) {
        _errorMessage = _messageFor(
          error,
          fallback: 'Unable to update this checkpoint.',
        );
      }

      return false;
    } finally {
      _isSaving = false;
      _notifyIfActive();
    }
  }

  Future<bool> createCheckpoint({
    required String qrId,
    required String qrValue,
    required String nodeId,
    required String locationDescription,
    required bool isActive,
    Uint8List? imageBytes,
    String? imageExtension,
  }) async {
    if (_isSaving || _isDisposed) return false;

    _isSaving = true;
    _errorMessage = null;
    _notifyIfActive();

    try {
      final created = await _repository.createQrCheckpoint(
        qrId: qrId,
        qrValue: qrValue,
        nodeId: nodeId,
        locationDescription: locationDescription,
        isActive: isActive,
        imageBytes: imageBytes,
        imageExtension: imageExtension,
      );

      if (_isDisposed) return false;

      _checkpoints = <QrCodeModel>[..._checkpoints, created]
        ..sort((first, second) => first.qrId.compareTo(second.qrId));

      return true;
    } catch (error) {
      if (!_isDisposed) {
        _errorMessage = _messageFor(
          error,
          fallback: 'Unable to create this checkpoint.',
        );
      }

      return false;
    } finally {
      _isSaving = false;
      _notifyIfActive();
    }
  }

  /// Updates availability and the persisted closure reason, then reloads the
  /// administrator list so its status reflects the actual database response.
  Future<bool> updateRouteAvailability({
    required EdgeModel edge,
    required bool isActive,
    String? closureReason,
  }) async {
    if (_isSaving || _isDisposed) return false;

    _isSaving = true;
    _errorMessage = null;
    _notifyIfActive();

    try {
      final updated = await _repository.updateEdgeActiveState(
        edgeId: edge.edgeId,
        isActive: isActive,
        closureReason: closureReason,
      );

      if (_isDisposed) return false;

      _routeSegments = _routeSegments
          .map((item) => item.edgeId == updated.edgeId ? updated : item)
          .toList(growable: false);

      await loadRouteSegments(showLoadingIndicator: false);
      return true;
    } catch (error) {
      if (!_isDisposed) {
        _errorMessage = _messageFor(
          error,
          fallback: 'Unable to update this route segment.',
        );
      }

      return false;
    } finally {
      _isSaving = false;
      _notifyIfActive();
    }
  }

  String _friendlyNodeName(String? nodeId) {
    final node = nodeById(nodeId);
    final specificName = _specificNodeName(node);

    if (specificName != null) return specificName;

    final floor = _floorForNode(node, nodeId);
    final nodeType = node?.nodeType?.trim().toLowerCase();
    final suffix = switch (nodeType) {
      'elevator' || 'lift' => 'lift point',
      'stairs' || 'staircase' => 'staircase point',
      _ => 'route point',
    };

    return floor == null
        ? _titleCase(suffix)
        : '${_fullFloorName(floor)} $suffix';
  }

  String? _specificNodeName(NodeModel? node) {
    if (node == null) return null;

    final label = node.label?.trim();
    if (label != null && label.isNotEmpty) return _titleCase(label);

    final description = _meaningfulDescription(node.description);
    if (description != null) return _titleCase(description);

    return null;
  }

  String? _floorForNode(NodeModel? node, String? nodeId) {
    final storedFloor = node?.floorId?.trim().toUpperCase();
    if (storedFloor != null && campusFloors.contains(storedFloor)) {
      return storedFloor;
    }

    final normalizedNodeId = (node?.nodeId ?? nodeId)?.trim().toUpperCase();
    if (normalizedNodeId == null || normalizedNodeId.isEmpty) return null;

    for (final floor in campusFloors) {
      if (normalizedNodeId == floor ||
          normalizedNodeId.startsWith('${floor}_') ||
          normalizedNodeId.startsWith('${floor}N')) {
        return floor;
      }
    }

    return null;
  }

  String? _meaningfulDescription(String? value) {
    final description = value?.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (description == null || description.isEmpty) return null;

    const genericDescriptions = <String>{
      'walkway',
      'corridor',
      'stairs',
      'staircase',
      'elevator',
      'lift',
      'classroom',
      'office',
      'washroom',
      'auditorium',
      'facility',
      'utility',
    };

    return genericDescriptions.contains(description.toLowerCase())
        ? null
        : description;
  }

  String _fullFloorName(String floor) {
    return floor == 'G' ? 'Ground Floor' : 'Level ${floor.substring(1)}';
  }

  String _titleCase(String value) {
    final words = value
        .replaceAll(RegExp(r'[_-]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim()
        .split(' ');

    return words.map((word) {
      if (word.isEmpty) return word;

      final upper = word.toUpperCase();
      if (const <String>{'HR', 'OKU', 'PG', 'MATLAB'}.contains(upper)) {
        return upper;
      }

      return '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}';
    }).join(' ');
  }

  String _messageFor(Object error, {required String fallback}) {
    if (error is AppException && error.message.trim().isNotEmpty) {
      return error.message;
    }

    return fallback;
  }

  void _notifyIfActive() {
    if (!_isDisposed) notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}
