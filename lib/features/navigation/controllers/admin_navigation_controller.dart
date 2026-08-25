import 'dart:typed_data';

import 'package:flutter/foundation.dart';

import '../../../core/exceptions/app_exception.dart';
import '../data/navigation_repository.dart';
import '../models/node_model.dart';
import '../models/qr_code_model.dart';

/// Admin-side state for CampusGO navigation resources.
///
/// QR management lives beside the existing navigation graph and scanner so it
/// can reuse the same nodes, table names, models, and Supabase client. Route
/// management can later extend this controller without changing the user map.
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
  List<NodeModel> _nodes = const <NodeModel>[];
  Map<String, NodeModel> _nodesById = const <String, NodeModel>{};

  String _searchQuery = '';
  String _selectedFloor = 'All';
  String? _errorMessage;
  bool _isLoading = false;
  bool _isSaving = false;
  bool _isDisposed = false;

  List<QrCodeModel> get checkpoints => List.unmodifiable(_checkpoints);
  List<NodeModel> get nodes => List.unmodifiable(_nodes);
  String get searchQuery => _searchQuery;
  String get selectedFloor => _selectedFloor;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;

  int get activeCheckpointCount =>
      _checkpoints.where((checkpoint) => checkpoint.isActive).length;

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
