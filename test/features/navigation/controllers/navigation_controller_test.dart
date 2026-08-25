import 'package:flutter_test/flutter_test.dart';
import 'package:campus_go/features/navigation/controllers/navigation_controller.dart';
import 'package:campus_go/features/navigation/data/navigation_repository.dart';
import 'package:campus_go/features/navigation/models/destination_model.dart';
import 'package:campus_go/features/navigation/models/edge_model.dart';
import 'package:campus_go/features/navigation/models/floor_model.dart';
import 'package:campus_go/features/navigation/models/navigation_graph_data.dart';
import 'package:campus_go/features/navigation/models/node_model.dart';

void main() {
  group('NavigationController', () {
    late _FakeNavigationRepository repository;
    late NavigationController controller;

    setUp(() {
      repository = _FakeNavigationRepository(_testGraph());
      controller = NavigationController(repository: repository);
    });

    tearDown(() {
      controller.dispose();
    });

    test(
      'loads the graph once and builds destinations from its nodes',
      () async {
        await Future.wait([controller.loadGraph(), controller.loadGraph()]);
        await controller.loadGraph();

        expect(repository.loadCount, 1);
        expect(repository.requestedAccessibilityValues, [false]);
        expect(controller.isReady, isTrue);
        expect(controller.destinations.map((item) => item.nodeId), [
          'A',
          'C',
          'B',
        ]);
      },
    );

    test('searches the cached destination list without another load', () async {
      await controller.loadGraph();

      final results = controller.searchDestinations('lab l8');

      expect(results.map((item) => item.nodeId), ['C']);
      expect(repository.loadCount, 1);
    });

    test('stores selected current and destination node IDs', () async {
      await controller.loadGraph();
      final byId = {
        for (final destination in controller.destinations)
          destination.nodeId: destination,
      };

      controller.selectCurrentLocation(byId['A']!);
      controller.selectDestination(byId['C']!);

      expect(controller.currentLocationNodeId, 'A');
      expect(controller.destinationNodeId, 'C');
      expect(controller.canCalculateRoute, isTrue);
    });

    test('uses only accessible edges when accessibility is enabled', () async {
      await controller.loadGraph();
      final byId = {
        for (final destination in controller.destinations)
          destination.nodeId: destination,
      };
      controller.selectCurrentLocation(byId['A']!);
      controller.selectDestination(byId['C']!);

      final result = controller.calculateRoute();

      expect(result, isNotNull);
      expect(result!.nodeIds, ['A', 'B', 'C']);
      expect(result.edgeIds, ['E_AB', 'E_BC']);
      expect(result.totalCost, 4);
      expect(controller.routeResult, same(result));
    });

    test('reuses the graph when accessibility is disabled', () async {
      await controller.loadGraph();
      final byId = {
        for (final destination in controller.destinations)
          destination.nodeId: destination,
      };
      controller.selectCurrentLocation(byId['A']!);
      controller.selectDestination(byId['C']!);
      controller.calculateRoute();

      controller.setAccessibleOnly(false);

      expect(controller.routeResult, isNull);
      final result = controller.calculateRoute();
      expect(result!.nodeIds, ['A', 'C']);
      expect(result.edgeIds, ['E_AC']);
      expect(result.totalCost, 1);
      expect(repository.loadCount, 1);
    });

    test('refreshes active edges before an explicit route calculation', () async {
      await controller.loadGraph();
      final byId = {
        for (final destination in controller.destinations)
          destination.nodeId: destination,
      };
      controller.selectCurrentLocation(byId['A']!);
      controller.selectDestination(byId['C']!);
      controller.setAccessibleOnly(false);

      repository.graph = _testGraphWithoutDirectEdge();

      final result = await controller.refreshGraphAndCalculateRoute();

      expect(repository.loadCount, 2);
      expect(result, isNotNull);
      expect(result!.nodeIds, ['A', 'B', 'C']);
      expect(result.edgeIds, ['E_AB', 'E_BC']);
      expect(result.totalCost, 4);
    });

    test('clears a selected node when its visible text is edited', () async {
      await controller.loadGraph();
      final location = controller.destinations.first;
      controller.selectCurrentLocation(location);

      controller.currentLocationTextChanged('${location.name} edited');

      expect(controller.currentLocationNodeId, isNull);
      expect(controller.canCalculateRoute, isFalse);
    });

    test('reports a missing destination instead of running Dijkstra', () async {
      await controller.loadGraph();
      controller.selectCurrentLocation(controller.destinations.first);

      final result = controller.calculateRoute();

      expect(result, isNull);
      expect(
        controller.message,
        'Select a destination from the search results.',
      );
    });
  });
}

NavigationGraphData _testGraph() {
  const floor = FloorModel(floorId: 'L8', levelNumber: 8, floorName: 'Level 8');
  const nodes = [
    NodeModel(nodeId: 'A', floorId: 'L8', label: 'Alpha Room'),
    NodeModel(nodeId: 'B', floorId: 'L8', label: 'Main Lift'),
    NodeModel(nodeId: 'C', floorId: 'L8', label: 'Lab 801'),
    NodeModel(nodeId: 'J', floorId: 'L8'),
  ];
  const edges = [
    EdgeModel(
      edgeId: 'E_AC',
      sourceNodeId: 'A',
      targetNodeId: 'C',
      traversalCost: 1,
      isAccessible: false,
    ),
    EdgeModel(
      edgeId: 'E_AB',
      sourceNodeId: 'A',
      targetNodeId: 'B',
      traversalCost: 2,
    ),
    EdgeModel(
      edgeId: 'E_BC',
      sourceNodeId: 'B',
      targetNodeId: 'C',
      traversalCost: 2,
    ),
  ];

  return NavigationGraphData(floors: const [floor], nodes: nodes, edges: edges);
}

NavigationGraphData _testGraphWithoutDirectEdge() {
  final graph = _testGraph();

  return NavigationGraphData(
    floors: graph.floors,
    nodes: graph.nodes,
    edges: graph.edges.where((edge) => edge.edgeId != 'E_AC').toList(),
  );
}

class _FakeNavigationRepository implements NavigationRepository {
  _FakeNavigationRepository(this.graph);

  NavigationGraphData graph;
  int loadCount = 0;
  final List<bool> requestedAccessibilityValues = [];

  @override
  Future<NavigationGraphData> loadGraph({bool accessibleOnly = false}) async {
    loadCount++;
    requestedAccessibilityValues.add(accessibleOnly);
    return graphForRouting(graph: graph, accessibleOnly: accessibleOnly);
  }

  @override
  List<DestinationModel> buildSearchableDestinations(
    Iterable<NodeModel> nodes,
  ) {
    final destinations = nodes
        .where((node) => node.isSearchableDestination)
        .map((node) => DestinationModel(node: node))
        .toList();

    destinations.sort((first, second) {
      final byName = first.name.toLowerCase().compareTo(
        second.name.toLowerCase(),
      );
      return byName == 0 ? first.nodeId.compareTo(second.nodeId) : byName;
    });

    return List.unmodifiable(destinations);
  }

  @override
  List<DestinationModel> filterDestinations({
    required List<DestinationModel> destinations,
    required String query,
    int limit = 12,
  }) {
    if (limit <= 0) return const [];

    final normalizedQuery = query.trim();
    final matches = normalizedQuery.isEmpty
        ? destinations
        : destinations
              .where((destination) => destination.matchesSearch(query))
              .toList(growable: false);
    return matches.take(limit).toList(growable: false);
  }

  @override
  NavigationGraphData graphForRouting({
    required NavigationGraphData graph,
    required bool accessibleOnly,
  }) {
    if (!accessibleOnly) return graph;

    return NavigationGraphData(
      floors: graph.floors,
      nodes: graph.nodes,
      edges: graph.edges.where((edge) => edge.isAccessible).toList(),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
