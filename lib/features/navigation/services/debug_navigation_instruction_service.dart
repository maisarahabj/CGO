import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DebugNavigationInstructionService {
  DebugNavigationInstructionService({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<void> printInstructions({
    required List<String> nodeIds,
    required List<String> edgeIds,
  }) async {
    try {
      if (nodeIds.isEmpty) {
        debugPrint('[Navigation Instructions] No route nodes were provided.');

        return;
      }

      if (edgeIds.length != nodeIds.length - 1) {
        debugPrint(
          '[Navigation Instructions] Route mismatch: '
          '${nodeIds.length} nodes and ${edgeIds.length} edges.',
        );
      }

      final nodeRows = await _client
          .from('nodes')
          .select()
          .inFilter('node_id', nodeIds);

      final edgeRows = edgeIds.isEmpty
          ? <Map<String, dynamic>>[]
          : await _client.from('edges').select().inFilter('edge_id', edgeIds);

      final nodesById = <String, Map<String, dynamic>>{};

      for (final rawNode in nodeRows) {
        final node = Map<String, dynamic>.from(rawNode);

        final nodeId = node['node_id']?.toString();

        if (nodeId == null || nodeId.isEmpty) {
          continue;
        }

        nodesById[nodeId] = node;
      }

      final edgesById = <String, Map<String, dynamic>>{};

      for (final rawEdge in edgeRows) {
        final edge = Map<String, dynamic>.from(rawEdge);

        final edgeId = edge['edge_id']?.toString();

        if (edgeId == null || edgeId.isEmpty) {
          continue;
        }

        edgesById[edgeId] = edge;
      }

      _printRouteSummary(
        nodeIds: nodeIds,
        edgeIds: edgeIds,
        nodesById: nodesById,
        edgesById: edgesById,
      );

      final missingCoordinates = nodeIds.where((nodeId) {
        final node = nodesById[nodeId];

        if (node == null) {
          return true;
        }

        return _coordinatesFor(node) == null;
      }).toList();

      if (missingCoordinates.isNotEmpty) {
        debugPrint(
          '[Navigation Instructions] Node coordinates were not '
          'found for ${missingCoordinates.length} route nodes.',
        );

        debugPrint(
          '[Navigation Instructions] Elevator and floor instructions '
          'will still work, but left/right turns cannot be calculated.',
        );

        debugPrint(
          '[Navigation Instructions] Missing coordinates: '
          '${missingCoordinates.join(', ')}',
        );
      }

      final instructions = _generateInstructions(
        nodeIds: nodeIds,
        edgeIds: edgeIds,
        nodesById: nodesById,
        edgesById: edgesById,
      );

      debugPrint('');
      debugPrint('========== CAMPUSGO NAVIGATION INSTRUCTIONS ==========');

      for (var index = 0; index < instructions.length; index++) {
        debugPrint('${index + 1}. ${instructions[index]}');
      }

      debugPrint('======================================================');

      debugPrint('');
    } catch (error, stackTrace) {
      debugPrint(
        '[Navigation Instructions] Failed to generate instructions: '
        '$error',
      );

      debugPrintStack(stackTrace: stackTrace);
    }
  }

  void _printRouteSummary({
    required List<String> nodeIds,
    required List<String> edgeIds,
    required Map<String, Map<String, dynamic>> nodesById,
    required Map<String, Map<String, dynamic>> edgesById,
  }) {
    debugPrint('');
    debugPrint('================ CAMPUSGO ROUTE TRACE ================');

    debugPrint('Nodes: ${nodeIds.join(' → ')}');

    for (var index = 0; index < edgeIds.length; index++) {
      if (index + 1 >= nodeIds.length) {
        break;
      }

      final edgeId = edgeIds[index];

      final edge = edgesById[edgeId];

      final fromNodeId = nodeIds[index];
      final toNodeId = nodeIds[index + 1];

      final edgeType = _normalizedEdgeType(edge);

      final description = edge?['description']?.toString() ?? 'No description';

      final accessible = edge?['is_accessible'];

      debugPrint(
        '${index + 1}. '
        '$fromNodeId → $toNodeId '
        '| edge: $edgeId '
        '| type: $edgeType '
        '| description: $description '
        '| accessible: $accessible',
      );
    }

    debugPrint('======================================================');

    debugPrint('');
  }

  List<String> _generateInstructions({
    required List<String> nodeIds,
    required List<String> edgeIds,
    required Map<String, Map<String, dynamic>> nodesById,
    required Map<String, Map<String, dynamic>> edgesById,
  }) {
    final instructions = <String>[];

    final firstNodeId = nodeIds.first;

    final firstNode = nodesById[firstNodeId];

    final startingFloor = _floorName(firstNodeId, firstNode);

    instructions.add(
      'Start at ${_nodeLabel(firstNodeId, firstNode)} '
      'on $startingFloor.',
    );

    var edgeIndex = 0;

    var walkingSectionStarted = false;

    while (edgeIndex < edgeIds.length) {
      if (edgeIndex + 1 >= nodeIds.length) {
        break;
      }

      final currentEdge = edgesById[edgeIds[edgeIndex]];

      final edgeType = _normalizedEdgeType(currentEdge);

      if (_isFloorConnector(edgeType)) {
        var finalConnectorEdgeIndex = edgeIndex;

        while (finalConnectorEdgeIndex + 1 < edgeIds.length) {
          final nextEdge = edgesById[edgeIds[finalConnectorEdgeIndex + 1]];

          final nextType = _normalizedEdgeType(nextEdge);

          if (nextType != edgeType) {
            break;
          }

          finalConnectorEdgeIndex++;
        }

        final destinationNodeId = nodeIds[finalConnectorEdgeIndex + 1];

        final destinationNode = nodesById[destinationNodeId];

        final destinationFloor = _floorName(destinationNodeId, destinationNode);

        if (edgeType == 'elevator' || edgeType == 'lift') {
          instructions.add('Take the elevator to $destinationFloor.');
        } else {
          instructions.add('Take the stairs to $destinationFloor.');
        }

        edgeIndex = finalConnectorEdgeIndex + 1;

        walkingSectionStarted = false;

        continue;
      }

      final currentNodeId = nodeIds[edgeIndex];

      final currentNode = nodesById[currentNodeId];

      final currentFloor = _floorName(currentNodeId, currentNode);

      if (!walkingSectionStarted) {
        instructions.add('Follow the corridor on $currentFloor.');

        walkingSectionStarted = true;
      }

      if (edgeIndex > 0) {
        final previousEdge = edgesById[edgeIds[edgeIndex - 1]];

        final previousEdgeType = _normalizedEdgeType(previousEdge);

        if (!_isFloorConnector(previousEdgeType)) {
          final previousNodeId = nodeIds[edgeIndex - 1];

          final nextNodeId = nodeIds[edgeIndex + 1];

          final previousNode = nodesById[previousNodeId];

          final nextNode = nodesById[nextNodeId];

          if (previousNode != null &&
              currentNode != null &&
              nextNode != null &&
              _sameFloor(
                previousNodeId,
                currentNodeId,
                nextNodeId,
                previousNode,
                currentNode,
                nextNode,
              )) {
            final angle = _calculateTurnAngle(
              previousNode: previousNode,
              currentNode: currentNode,
              nextNode: nextNode,
            );

            if (angle != null) {
              final turnInstruction = _turnInstruction(angle);

              if (turnInstruction != null) {
                instructions.add(
                  '$turnInstruction at '
                  '${_nodeLabel(currentNodeId, currentNode)}.',
                );
              }
            }
          }
        }
      }

      edgeIndex++;
    }

    final destinationNodeId = nodeIds.last;

    final destinationNode = nodesById[destinationNodeId];

    final destinationLabel = _nodeLabel(destinationNodeId, destinationNode);

    final destinationSide = _destinationSide(
      nodeIds: nodeIds,
      nodesById: nodesById,
    );

    if (destinationSide == null) {
      instructions.add('Arrive at $destinationLabel.');
    } else {
      instructions.add('Arrive at $destinationLabel on your $destinationSide.');
    }

    return instructions;
  }

  bool _sameFloor(
    String previousNodeId,
    String currentNodeId,
    String nextNodeId,
    Map<String, dynamic> previousNode,
    Map<String, dynamic> currentNode,
    Map<String, dynamic> nextNode,
  ) {
    final previousFloor = _floorId(previousNodeId, previousNode);

    final currentFloor = _floorId(currentNodeId, currentNode);

    final nextFloor = _floorId(nextNodeId, nextNode);

    return previousFloor == currentFloor && currentFloor == nextFloor;
  }

  double? _calculateTurnAngle({
    required Map<String, dynamic> previousNode,
    required Map<String, dynamic> currentNode,
    required Map<String, dynamic> nextNode,
  }) {
    final previous = _coordinatesFor(previousNode);

    final current = _coordinatesFor(currentNode);

    final next = _coordinatesFor(nextNode);

    if (previous == null || current == null || next == null) {
      return null;
    }

    final incomingX = current.x - previous.x;

    final incomingY = current.y - previous.y;

    final outgoingX = next.x - current.x;

    final outgoingY = next.y - current.y;

    if ((incomingX == 0 && incomingY == 0) ||
        (outgoingX == 0 && outgoingY == 0)) {
      return null;
    }

    final cross = (incomingX * outgoingY) - (incomingY * outgoingX);

    final dot = (incomingX * outgoingX) + (incomingY * outgoingY);

    return math.atan2(cross, dot) * 180 / math.pi;
  }

  String? _turnInstruction(double angle) {
    final absoluteAngle = angle.abs();

    if (absoluteAngle < 25) {
      return null;
    }

    if (absoluteAngle < 60) {
      return angle > 0 ? 'Bear left' : 'Bear right';
    }

    if (absoluteAngle < 135) {
      return angle > 0 ? 'Turn left' : 'Turn right';
    }

    return 'Make a U-turn';
  }

  String? _destinationSide({
    required List<String> nodeIds,
    required Map<String, Map<String, dynamic>> nodesById,
  }) {
    if (nodeIds.length < 3) {
      return null;
    }

    final previousNodeId = nodeIds[nodeIds.length - 3];

    final corridorNodeId = nodeIds[nodeIds.length - 2];

    final destinationNodeId = nodeIds.last;

    final previousNode = nodesById[previousNodeId];

    final corridorNode = nodesById[corridorNodeId];

    final destinationNode = nodesById[destinationNodeId];

    if (previousNode == null ||
        corridorNode == null ||
        destinationNode == null) {
      return null;
    }

    if (!_sameFloor(
      previousNodeId,
      corridorNodeId,
      destinationNodeId,
      previousNode,
      corridorNode,
      destinationNode,
    )) {
      return null;
    }

    final angle = _calculateTurnAngle(
      previousNode: previousNode,
      currentNode: corridorNode,
      nextNode: destinationNode,
    );

    if (angle == null || angle.abs() < 25) {
      return null;
    }

    return angle > 0 ? 'left' : 'right';
  }

  _MapCoordinates? _coordinatesFor(Map<String, dynamic> node) {
    const coordinatePairs = <List<String>>[
      ['map_x', 'map_y'],
      ['floor_x', 'floor_y'],
      ['position_x', 'position_z'],
      ['spline_x', 'spline_z'],
      ['x', 'z'],
      ['position_x', 'position_y'],
      ['x', 'y'],
    ];

    for (final coordinatePair in coordinatePairs) {
      final x = _asDouble(node[coordinatePair[0]]);

      final y = _asDouble(node[coordinatePair[1]]);

      if (x != null && y != null) {
        return _MapCoordinates(x: x, y: y);
      }
    }

    return null;
  }

  double? _asDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    if (value is String) {
      return double.tryParse(value);
    }

    return null;
  }

  bool _isFloorConnector(String edgeType) {
    return edgeType == 'elevator' || edgeType == 'lift' || edgeType == 'stairs';
  }

  String _normalizedEdgeType(Map<String, dynamic>? edge) {
    return edge?['edge_type']?.toString().trim().toLowerCase() ?? 'walkway';
  }

  String _nodeLabel(String nodeId, Map<String, dynamic>? node) {
    const labelColumns = <String>[
      'label',
      'node_label',
      'name',
      'node_name',
      'destination_name',
      'display_name',
    ];

    if (node != null) {
      for (final column in labelColumns) {
        final value = node[column]?.toString().trim();

        if (value != null && value.isNotEmpty) {
          return value;
        }
      }
    }

    return nodeId;
  }

  String _floorId(String nodeId, Map<String, dynamic>? node) {
    const floorColumns = <String>['floor_id', 'floor', 'level'];

    if (node != null) {
      for (final column in floorColumns) {
        final value = node[column]?.toString().trim();

        if (value != null && value.isNotEmpty) {
          return value;
        }
      }
    }

    return nodeId.split('_').first;
  }

  String _floorName(String nodeId, Map<String, dynamic>? node) {
    final floorId = _floorId(nodeId, node).toUpperCase();

    if (floorId == 'G') {
      return 'Ground Floor';
    }

    if (floorId.startsWith('L')) {
      return 'Level ${floorId.substring(1)}';
    }

    return floorId;
  }
}

class _MapCoordinates {
  const _MapCoordinates({required this.x, required this.y});

  final double x;

  final double y;
}
