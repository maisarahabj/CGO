import 'dart:math' as math;

import '../models/edge_model.dart';
import '../models/navigation_graph_data.dart';
import '../models/node_model.dart';
import '../models/route_result.dart';

// Preserve compatibility with code that imported NavigationRepository here.
export '../data/navigation_repository.dart';

/// The movement represented by one user-facing CampusGO instruction.
enum NavigationInstructionType {
  start,
  straight,
  slightLeft,
  slightRight,
  left,
  right,
  uTurn,
  elevator,
  stairs,
  arrive,
}

/// One instruction displayed in the active-route panel.
class NavigationInstruction {
  const NavigationInstruction({
    required this.type,
    required this.title,
    required this.nodeId,
    this.subtitle,
    this.floorId,
    this.edgeId,
    this.distanceMetres,
  });

  final NavigationInstructionType type;
  final String title;
  final String nodeId;
  final String? subtitle;
  final String? floorId;
  final String? edgeId;
  final double? distanceMetres;

  bool get isFloorChange =>
      type == NavigationInstructionType.elevator ||
      type == NavigationInstructionType.stairs;

  String get debugDescription {
    final detail = subtitle?.trim();

    if (detail == null || detail.isEmpty) return title;

    return '$title — $detail';
  }
}

/// Translates a completed Dijkstra route into readable walking instructions.
///
/// The repository has already loaded every node and edge into [graph], so this
/// service does not read Supabase again. CampusGO's floor plane is X/Z: Y is
/// the physical height of the floor in the Spline scene.
class NavigationService {
  const NavigationService({this.reverseTurnDirection = true});

  /// CampusGO's Spline X/Z floor plane is reflected when interpreted as a
  /// conventional 2D X/Y plane. The Ruby-to-Lecturer's-Office route provides
  /// the physical calibration, so turn signs are reversed by default.
  ///
  /// Set this to false only if a future coordinate export changes that
  /// orientation. Rotation alone does not require changing this value.
  final bool reverseTurnDirection;

  List<NavigationInstruction> generateInstructions({
    required RouteResult route,
    required NavigationGraphData graph,
  }) {
    if (!route.hasRoute || route.nodeIds.isEmpty) {
      return const <NavigationInstruction>[];
    }

    final instructions = <NavigationInstruction>[];
    final announcedLandmarks = <String>{};
    final firstNodeId = route.nodeIds.first;
    final firstNode = graph.nodeById[firstNodeId];
    final startingFloor = _floorName(firstNodeId, firstNode, graph);

    instructions.add(
      NavigationInstruction(
        type: NavigationInstructionType.start,
        title: 'Start at ${_nodeLabel(firstNodeId, firstNode)}',
        subtitle: startingFloor,
        nodeId: firstNodeId,
        floorId: _floorId(firstNodeId, firstNode),
      ),
    );

    var edgeIndex = 0;
    var walkingSectionStarted = false;

    while (edgeIndex < route.edgeIds.length &&
        edgeIndex + 1 < route.nodeIds.length) {
      final currentEdge = graph.edgeById[route.edgeIds[edgeIndex]];
      final fromNodeId = route.nodeIds[edgeIndex];
      final toNodeId = route.nodeIds[edgeIndex + 1];

      // An instruction must describe the actual edge between these ordered
      // route nodes, never an unrelated edge that happens to share an index.
      if (!_edgeMatchesStep(currentEdge, fromNodeId, toNodeId)) {
        edgeIndex++;
        walkingSectionStarted = false;
        continue;
      }

      final verifiedEdge = currentEdge!;
      final connectorCategory = _connectorCategoryForStep(
        edge: verifiedEdge,
        fromNodeId: fromNodeId,
        toNodeId: toNodeId,
        graph: graph,
      );

      if (connectorCategory != null) {
        var finalConnectorEdgeIndex = edgeIndex;

        while (finalConnectorEdgeIndex + 1 < route.edgeIds.length &&
            finalConnectorEdgeIndex + 2 < route.nodeIds.length) {
          final nextEdgeIndex = finalConnectorEdgeIndex + 1;
          final nextEdge = graph.edgeById[
            route.edgeIds[nextEdgeIndex]
          ];
          final nextFromNodeId = route.nodeIds[nextEdgeIndex];
          final nextToNodeId = route.nodeIds[nextEdgeIndex + 1];

          if (!_edgeMatchesStep(nextEdge, nextFromNodeId, nextToNodeId) ||
              _connectorCategoryForStep(
                    edge: nextEdge,
                    fromNodeId: nextFromNodeId,
                    toNodeId: nextToNodeId,
                    graph: graph,
                  ) !=
                  connectorCategory) {
            break;
          }

          finalConnectorEdgeIndex++;
        }

        final fromNode = graph.nodeById[fromNodeId];
        final destinationNodeId = route.nodeIds[finalConnectorEdgeIndex + 1];
        final destinationNode = graph.nodeById[destinationNodeId];
        final fromFloor = _floorName(fromNodeId, fromNode, graph);
        final destinationFloor = _floorName(
          destinationNodeId,
          destinationNode,
          graph,
        );
        final isElevator = connectorCategory == 'elevator';

        instructions.add(
          NavigationInstruction(
            type: isElevator
                ? NavigationInstructionType.elevator
                : NavigationInstructionType.stairs,
            title: isElevator
                ? 'Take the Elevator to $destinationFloor'
                : 'Take the Stairs to $destinationFloor',
            subtitle: '$fromFloor to $destinationFloor',
            nodeId: destinationNodeId,
            floorId: _floorId(destinationNodeId, destinationNode),
            edgeId: verifiedEdge.edgeId,
          ),
        );

        edgeIndex = finalConnectorEdgeIndex + 1;
        walkingSectionStarted = false;
        continue;
      }

      final currentNodeId = route.nodeIds[edgeIndex];
      final currentNode = graph.nodeById[currentNodeId];
      final currentFloor = _floorName(currentNodeId, currentNode, graph);

      if (!walkingSectionStarted) {
        final walkingDistance = _walkingDistanceMetres(
          route: route,
          graph: graph,
          firstEdgeIndex: edgeIndex,
        );

        instructions.add(
          NavigationInstruction(
            type: NavigationInstructionType.straight,
            title: 'Continue Straight',
            subtitle: _walkingDetail(
              route: route,
              graph: graph,
              firstEdgeIndex: edgeIndex,
              floorName: currentFloor,
              announcedLandmarks: announcedLandmarks,
            ),
            nodeId: currentNodeId,
            floorId: _floorId(currentNodeId, currentNode),
            edgeId: verifiedEdge.edgeId,
            distanceMetres: walkingDistance,
          ),
        );

        walkingSectionStarted = true;
      }

      if (edgeIndex > 0) {
        final previousEdge = graph.edgeById[route.edgeIds[edgeIndex - 1]];
        final previousConnector = _connectorCategoryForStep(
          edge: previousEdge,
          fromNodeId: route.nodeIds[edgeIndex - 1],
          toNodeId: currentNodeId,
          graph: graph,
        );

        if (previousConnector == null) {
          final previousNodeId = route.nodeIds[edgeIndex - 1];
          final nextNodeId = route.nodeIds[edgeIndex + 1];
          final previousNode = graph.nodeById[previousNodeId];
          final nextNode = graph.nodeById[nextNodeId];

          if (previousNode != null &&
              currentNode != null &&
              nextNode != null &&
              _sameFloor(previousNode, currentNode, nextNode)) {
            final angle = _calculateTurnAngle(
              previousNode: previousNode,
              currentNode: currentNode,
              nextNode: nextNode,
            );
            final instructionType = angle == null
                ? null
                : _turnType(angle);

            if (instructionType != null) {
              instructions.add(
                NavigationInstruction(
                  type: instructionType,
                  title: _turnTitle(instructionType),
                  subtitle: _turnDetail(
                    currentNode: currentNode,
                    nextNode: nextNode,
                    outgoingEdge: verifiedEdge,
                    graph: graph,
                    route: route,
                  ),
                  nodeId: currentNodeId,
                  floorId: _floorId(currentNodeId, currentNode),
                  edgeId: verifiedEdge.edgeId,
                ),
              );

              // Start a fresh straight segment after a real junction so its
              // landmarks never describe a later corridor.
              if (nextNodeId != route.nodeIds.last) {
                final walkingDistance = _walkingDistanceMetres(
                  route: route,
                  graph: graph,
                  firstEdgeIndex: edgeIndex,
                );

                if (walkingDistance == null || walkingDistance >= 1) {
                  instructions.add(
                    NavigationInstruction(
                      type: NavigationInstructionType.straight,
                      title: 'Continue Straight',
                      subtitle: _walkingDetail(
                        route: route,
                        graph: graph,
                        firstEdgeIndex: edgeIndex,
                        floorName: currentFloor,
                        announcedLandmarks: announcedLandmarks,
                      ),
                      nodeId: currentNodeId,
                      floorId: _floorId(currentNodeId, currentNode),
                      edgeId: verifiedEdge.edgeId,
                      distanceMetres: walkingDistance,
                    ),
                  );
                }
              }
            }
          }
        }
      }

      edgeIndex++;
    }

    final destinationNodeId = route.nodeIds.last;
    final destinationNode = graph.nodeById[destinationNodeId];
    final destinationName = _nodeLabel(destinationNodeId, destinationNode);
    final destinationSide = _destinationSide(route: route, graph: graph);
    final destinationFloor = _floorName(
      destinationNodeId,
      destinationNode,
      graph,
    );

    instructions.add(
      NavigationInstruction(
        type: NavigationInstructionType.arrive,
        title: 'Arrive at $destinationName',
        subtitle: destinationSide == null
            ? destinationFloor
            : '$destinationFloor · On your $destinationSide',
        nodeId: destinationNodeId,
        floorId: _floorId(destinationNodeId, destinationNode),
      ),
    );

    return List<NavigationInstruction>.unmodifiable(instructions);
  }

  String _walkingDetail({
    required RouteResult route,
    required NavigationGraphData graph,
    required int firstEdgeIndex,
    required String floorName,
    required Set<String> announcedLandmarks,
  }) {
    final landmarks = <String>[];
    final excludedNodeIds = <String>{
      route.nodeIds.first,
      route.nodeIds.last,
    };

    for (var index = firstEdgeIndex;
        index < route.edgeIds.length && index + 1 < route.nodeIds.length;
        index++) {
      final edge = graph.edgeById[route.edgeIds[index]];
      final currentNodeId = route.nodeIds[index];
      final nextNodeId = route.nodeIds[index + 1];

      if (!_edgeMatchesStep(edge, currentNodeId, nextNodeId)) break;

      if (_connectorCategoryForStep(
            edge: edge,
            fromNodeId: currentNodeId,
            toNodeId: nextNodeId,
            graph: graph,
          ) !=
          null) {
        break;
      }

      if (index > firstEdgeIndex &&
          _hasTurnAtIndex(route: route, graph: graph, edgeIndex: index)) {
        break;
      }

      for (final routeNodeId in <String>[currentNodeId, nextNodeId]) {
        for (final landmark in _landmarksNear(
          nodeId: routeNodeId,
          graph: graph,
          excludedNodeIds: excludedNodeIds,
        )) {
          if (!announcedLandmarks.contains(landmark) &&
              !landmarks.contains(landmark)) {
            landmarks.add(landmark);
          }
          if (landmarks.length == 2) break;
        }

        if (landmarks.length == 2) break;
      }

      if (landmarks.length == 2) break;
    }

    announcedLandmarks.addAll(landmarks);

    if (landmarks.isEmpty) {
      return 'Follow the corridor on $floorName';
    }

    if (landmarks.length == 1) {
      return 'Walk past ${landmarks.first}';
    }

    return 'Walk past ${landmarks[0]} and ${landmarks[1]}';
  }

  /// Adds actual edge distances only until the next turn or floor connector.
  /// CampusGO's existing ETA panel uses 100 scene distance units per metre.
  double? _walkingDistanceMetres({
    required RouteResult route,
    required NavigationGraphData graph,
    required int firstEdgeIndex,
  }) {
    var totalSceneDistance = 0.0;
    var hasMeasuredEdge = false;

    for (var index = firstEdgeIndex;
        index < route.edgeIds.length && index + 1 < route.nodeIds.length;
        index++) {
      final edge = graph.edgeById[route.edgeIds[index]];
      final fromNodeId = route.nodeIds[index];
      final toNodeId = route.nodeIds[index + 1];

      if (!_edgeMatchesStep(edge, fromNodeId, toNodeId)) break;

      if (_connectorCategoryForStep(
            edge: edge,
            fromNodeId: fromNodeId,
            toNodeId: toNodeId,
            graph: graph,
          ) !=
          null) {
        break;
      }

      if (index > firstEdgeIndex &&
          _hasTurnAtIndex(route: route, graph: graph, edgeIndex: index)) {
        break;
      }

      final distanceWeight = edge!.distanceWeight;

      if (distanceWeight != null && distanceWeight > 0) {
        totalSceneDistance += distanceWeight;
        hasMeasuredEdge = true;
        continue;
      }

      final fromNode = graph.nodeById[fromNodeId];
      final toNode = graph.nodeById[toNodeId];
      final fromX = fromNode?.xCoord;
      final fromZ = fromNode?.zCoord;
      final toX = toNode?.xCoord;
      final toZ = toNode?.zCoord;

      if (fromX != null && fromZ != null && toX != null && toZ != null) {
        final differenceX = toX - fromX;
        final differenceZ = toZ - fromZ;

        totalSceneDistance += math.sqrt(
          differenceX * differenceX + differenceZ * differenceZ,
        );
        hasMeasuredEdge = true;
      }
    }

    if (!hasMeasuredEdge) return null;

    return totalSceneDistance / 100;
  }

  bool _hasTurnAtIndex({
    required RouteResult route,
    required NavigationGraphData graph,
    required int edgeIndex,
  }) {
    if (edgeIndex <= 0 || edgeIndex + 1 >= route.nodeIds.length) {
      return false;
    }

    final previous = graph.nodeById[route.nodeIds[edgeIndex - 1]];
    final current = graph.nodeById[route.nodeIds[edgeIndex]];
    final next = graph.nodeById[route.nodeIds[edgeIndex + 1]];

    if (previous == null || current == null || next == null) return false;
    if (!_sameFloor(previous, current, next)) return false;

    final angle = _calculateTurnAngle(
      previousNode: previous,
      currentNode: current,
      nextNode: next,
    );

    return angle != null && _turnType(angle) != null;
  }

  String _turnDetail({
    required NodeModel currentNode,
    required NodeModel nextNode,
    required EdgeModel outgoingEdge,
    required NavigationGraphData graph,
    required RouteResult route,
  }) {
    final nextType = nextNode.nodeType?.trim().toLowerCase();

    if (nextType == 'lift' || nextType == 'elevator') {
      return 'Head towards the elevator';
    }

    if (nextNode.nodeId == route.nodeIds.last) {
      return 'Head towards ${nextNode.displayName}';
    }

    final landmarks = _landmarksNear(
      nodeId: currentNode.nodeId,
      graph: graph,
      excludedNodeIds: <String>{route.nodeIds.first, route.nodeIds.last},
    );

    if (landmarks.isNotEmpty) return 'At the junction near ${landmarks.first}';

    final edgeDescription = outgoingEdge.description?.trim();

    if (edgeDescription != null &&
        _hasUsefulDirectionDescription(edgeDescription)) {
      return _cleanDescription(edgeDescription);
    }

    final description = currentNode.description?.trim();

    if (description != null && _hasUsefulDirectionDescription(description)) {
      return _cleanDescription(description);
    }

    return 'At the corridor junction';
  }

  bool _hasUsefulDirectionDescription(String description) {
    final cleaned = _cleanDescription(description).toLowerCase();

    return cleaned.isNotEmpty &&
        cleaned != 'walkway' &&
        cleaned != 'hallway' &&
        cleaned != 'corridor' &&
        cleaned != 'hallway classroom' &&
        cleaned != 'hallway side';
  }

  List<String> _landmarksNear({
    required String nodeId,
    required NavigationGraphData graph,
    required Set<String> excludedNodeIds,
  }) {
    const landmarkTypes = <String>{
      'classroom',
      'office',
      'facility',
      'washroom',
      'surau',
    };
    final names = <String>[];

    for (final edge in graph.edges) {
      final neighbourId = edge.otherNodeId(nodeId);

      if (neighbourId == null || excludedNodeIds.contains(neighbourId)) {
        continue;
      }

      final neighbour = graph.nodeById[neighbourId];
      final nodeType = neighbour?.nodeType?.trim().toLowerCase();

      if (neighbour == null || !landmarkTypes.contains(nodeType)) continue;

      final label = neighbour.displayName.trim();

      if (label.isNotEmpty && !names.contains(label)) names.add(label);
    }

    return names;
  }

  bool _sameFloor(NodeModel first, NodeModel second, NodeModel third) {
    return _floorId(first.nodeId, first) == _floorId(second.nodeId, second) &&
        _floorId(second.nodeId, second) == _floorId(third.nodeId, third);
  }

  double? _calculateTurnAngle({
    required NodeModel previousNode,
    required NodeModel currentNode,
    required NodeModel nextNode,
  }) {
    final previousX = previousNode.xCoord;
    final previousZ = previousNode.zCoord;
    final currentX = currentNode.xCoord;
    final currentZ = currentNode.zCoord;
    final nextX = nextNode.xCoord;
    final nextZ = nextNode.zCoord;

    if (previousX == null ||
        previousZ == null ||
        currentX == null ||
        currentZ == null ||
        nextX == null ||
        nextZ == null) {
      return null;
    }

    final incomingX = currentX - previousX;
    final incomingZ = currentZ - previousZ;
    final outgoingX = nextX - currentX;
    final outgoingZ = nextZ - currentZ;

    if ((incomingX == 0 && incomingZ == 0) ||
        (outgoingX == 0 && outgoingZ == 0)) {
      return null;
    }

    var cross = (incomingX * outgoingZ) - (incomingZ * outgoingX);
    final dot = (incomingX * outgoingX) + (incomingZ * outgoingZ);

    if (reverseTurnDirection) cross = -cross;

    return math.atan2(cross, dot) * 180 / math.pi;
  }

  NavigationInstructionType? _turnType(double angle) {
    final absoluteAngle = angle.abs();

    if (absoluteAngle < 25) return null;

    if (absoluteAngle < 60) {
      return angle > 0
          ? NavigationInstructionType.slightLeft
          : NavigationInstructionType.slightRight;
    }

    if (absoluteAngle < 135) {
      return angle > 0
          ? NavigationInstructionType.left
          : NavigationInstructionType.right;
    }

    return NavigationInstructionType.uTurn;
  }

  String _turnTitle(NavigationInstructionType type) {
    switch (type) {
      case NavigationInstructionType.slightLeft:
        return 'Bear Left';
      case NavigationInstructionType.slightRight:
        return 'Bear Right';
      case NavigationInstructionType.left:
        return 'Turn Left';
      case NavigationInstructionType.right:
        return 'Turn Right';
      case NavigationInstructionType.uTurn:
        return 'Make a U-turn';
      default:
        return 'Continue Straight';
    }
  }

  String? _destinationSide({
    required RouteResult route,
    required NavigationGraphData graph,
  }) {
    if (route.nodeIds.length < 3) return null;

    final previous = graph.nodeById[route.nodeIds[route.nodeIds.length - 3]];
    final corridor = graph.nodeById[route.nodeIds[route.nodeIds.length - 2]];
    final destination = graph.nodeById[route.nodeIds.last];

    if (previous == null || corridor == null || destination == null) {
      return null;
    }

    if (!_sameFloor(previous, corridor, destination)) return null;

    final angle = _calculateTurnAngle(
      previousNode: previous,
      currentNode: corridor,
      nextNode: destination,
    );

    if (angle == null || angle.abs() < 25) return null;

    return angle > 0 ? 'left' : 'right';
  }

  bool _edgeMatchesStep(
    EdgeModel? edge,
    String fromNodeId,
    String toNodeId,
  ) {
    if (edge == null || !edge.isActive) return false;

    return edge.otherNodeId(fromNodeId) == toNodeId;
  }

  /// Floor changes are identified from the actual ordered edge and endpoints.
  /// A same-floor waypoint beside a staircase is not itself a stair journey.
  String? _connectorCategoryForStep({
    required EdgeModel? edge,
    required String fromNodeId,
    required String toNodeId,
    required NavigationGraphData graph,
  }) {
    if (!_edgeMatchesStep(edge, fromNodeId, toNodeId)) return null;

    final fromNode = graph.nodeById[fromNodeId];
    final toNode = graph.nodeById[toNodeId];

    if (_floorId(fromNodeId, fromNode) == _floorId(toNodeId, toNode)) {
      return null;
    }

    final explicitCategory = _connectorCategory(_normalizedEdgeType(edge));

    if (explicitCategory != null) return explicitCategory;

    final sourceType = fromNode?.nodeType?.trim().toLowerCase() ?? '';
    final targetType = toNode?.nodeType?.trim().toLowerCase() ?? '';
    final description = edge?.description?.trim().toLowerCase() ?? '';
    final connectorText = '$sourceType $targetType $description';

    if (connectorText.contains('elevator') ||
        connectorText.contains('lift')) {
      return 'elevator';
    }

    if (connectorText.contains('stair')) return 'stairs';

    return null;
  }

  String? _connectorCategory(String edgeType) {
    switch (edgeType) {
      case 'elevator':
      case 'lift':
        return 'elevator';
      case 'stair':
      case 'stairs':
      case 'staircase':
      case 'stairway':
        return 'stairs';
      default:
        return null;
    }
  }

  String _normalizedEdgeType(EdgeModel? edge) {
    return edge?.edgeType?.trim().toLowerCase() ?? 'walkway';
  }

  String _nodeLabel(String nodeId, NodeModel? node) {
    return node?.displayName ?? nodeId;
  }

  String _floorId(String nodeId, NodeModel? node) {
    final floorId = node?.floorId?.trim();

    if (floorId != null && floorId.isNotEmpty) return floorId;

    return nodeId.split('_').first;
  }

  String _floorName(
    String nodeId,
    NodeModel? node,
    NavigationGraphData graph,
  ) {
    final floorId = _floorId(nodeId, node);
    final knownFloor = graph.floorById[floorId];

    if (knownFloor != null) return knownFloor.displayName;

    final normalizedFloor = floorId.toUpperCase();

    if (normalizedFloor == 'G') return 'Ground Floor';

    if (normalizedFloor.startsWith('L')) {
      return 'Level ${normalizedFloor.substring(1)}';
    }

    return floorId;
  }

  String _cleanDescription(String description) {
    final cleaned = description
        .replaceFirst(RegExp(r'^(?:L\d+|G)\s+', caseSensitive: false), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    if (cleaned.isEmpty) return 'At the corridor junction';

    return cleaned[0].toUpperCase() + cleaned.substring(1);
  }
}
