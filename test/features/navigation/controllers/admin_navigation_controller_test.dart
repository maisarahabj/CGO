import 'package:campus_go/features/navigation/controllers/admin_navigation_controller.dart';
import 'package:campus_go/features/navigation/data/navigation_repository.dart';
import 'package:campus_go/features/navigation/models/edge_model.dart';
import 'package:campus_go/features/navigation/models/node_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AdminNavigationController route management', () {
    late _FakeAdminNavigationRepository repository;
    late AdminNavigationController controller;

    setUp(() {
      repository = _FakeAdminNavigationRepository();
      controller = AdminNavigationController(repository: repository);
    });

    tearDown(() {
      controller.dispose();
    });

    test('derives readable names without exposing edge IDs', () async {
      await controller.loadRouteSegments();

      final lift = controller.routeById('E_L9N1_L8N1')!;
      final java = controller.routeById('E_L8N9_L8N12')!;

      expect(
        controller.routeNameForEdge(lift),
        'Lift between Level 9 and Level 8',
      );
      expect(controller.routeNameForEdge(java), 'Java');
      expect(controller.routeEndpointSummary(java), contains('Java'));
    });

    test('floor filtering includes a cross-floor edge on either floor', () async {
      await controller.loadRouteSegments();

      controller.setSelectedFloor('L8');
      expect(
        controller.filteredRouteSegments.map((edge) => edge.edgeId),
        containsAll(<String>['E_L9N1_L8N1', 'E_L8N9_L8N12']),
      );

      controller.setSelectedFloor('L9');
      expect(
        controller.filteredRouteSegments.map((edge) => edge.edgeId),
        <String>['E_L9N1_L8N1'],
      );
    });

    test('closing a route changes is_active but preserves accessibility', () async {
      await controller.loadRouteSegments();
      final lift = controller.routeById('E_L9N1_L8N1')!;

      final succeeded = await controller.updateRouteAvailability(
        edge: lift,
        isActive: false,
      );

      final closedLift = controller.routeById(lift.edgeId)!;
      expect(succeeded, isTrue);
      expect(closedLift.isActive, isFalse);
      expect(closedLift.isAccessible, isTrue);
      expect(repository.lastUpdatedEdgeId, lift.edgeId);
      expect(repository.lastUpdatedActiveValue, isFalse);
    });
  });
}

class _FakeAdminNavigationRepository implements NavigationRepository {
  final List<NodeModel> _nodes = const <NodeModel>[
    NodeModel(nodeId: 'L9_N1', floorId: 'L9', nodeType: 'elevator'),
    NodeModel(nodeId: 'L8_N1', floorId: 'L8', nodeType: 'elevator'),
    NodeModel(nodeId: 'L8_N9', floorId: 'L8', nodeType: 'walkway'),
    NodeModel(nodeId: 'L8_N12', floorId: 'L8', label: 'Java'),
  ];

  List<EdgeModel> _edges = const <EdgeModel>[
    EdgeModel(
      edgeId: 'E_L9N1_L8N1',
      sourceNodeId: 'L9_N1',
      targetNodeId: 'L8_N1',
      traversalCost: 1000,
      edgeType: 'elevator',
      description: 'L9 L8 elevator',
      isAccessible: true,
      isActive: true,
    ),
    EdgeModel(
      edgeId: 'E_L8N9_L8N12',
      sourceNodeId: 'L8_N9',
      targetNodeId: 'L8_N12',
      traversalCost: 150,
      edgeType: 'classroom',
      description: 'java',
      isAccessible: true,
      isActive: true,
    ),
  ];

  String? lastUpdatedEdgeId;
  bool? lastUpdatedActiveValue;

  @override
  Future<List<EdgeModel>> fetchManageableEdges() async =>
      List<EdgeModel>.from(_edges);

  @override
  Future<List<NodeModel>> fetchActiveNodes() async => _nodes;

  @override
  Future<EdgeModel> updateEdgeActiveState({
    required String edgeId,
    required bool isActive,
  }) async {
    lastUpdatedEdgeId = edgeId;
    lastUpdatedActiveValue = isActive;

    final existing = _edges.singleWhere((edge) => edge.edgeId == edgeId);
    final updatedJson = existing.toJson()..['is_active'] = isActive;
    final updated = EdgeModel.fromJson(updatedJson);

    _edges = _edges
        .map((edge) => edge.edgeId == edgeId ? updated : edge)
        .toList(growable: false);

    return updated;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
