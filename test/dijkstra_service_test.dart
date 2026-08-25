import 'package:campus_go/core/config/supabase_config.dart';
import 'package:campus_go/features/navigation/data/navigation_repository.dart';
import 'package:campus_go/features/navigation/models/edge_model.dart';
import 'package:campus_go/features/navigation/models/navigation_graph_data.dart';
import 'package:campus_go/features/navigation/models/node_model.dart';
import 'package:campus_go/features/navigation/services/dijkstra_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  const dijkstra = DijkstraService();

  group('DijkstraService route behaviour', () {
    test('treats a normal edge as bidirectional', () {
      final graph = _graph(
        nodeIds: const ['A', 'B'],
        edges: const [
          EdgeModel(
            edgeId: 'E_A_B',
            sourceNodeId: 'A',
            targetNodeId: 'B',
            traversalCost: 4,
          ),
        ],
      );

      final route = dijkstra.findShortestRoute(
        graph: graph,
        startNodeId: 'B',
        destinationNodeId: 'A',
      );

      expect(route.nodeIds, ['B', 'A']);
      expect(route.edgeIds, ['E_A_B']);
      expect(route.totalCost, 4);
    });

    test('prefers traversal cost and falls back to distance weight', () {
      final graph = _graph(
        nodeIds: const ['A', 'B', 'C'],
        edges: const [
          EdgeModel(
            edgeId: 'E_A_B',
            sourceNodeId: 'A',
            targetNodeId: 'B',
            traversalCost: 10,
            distanceWeight: 1,
          ),
          EdgeModel(
            edgeId: 'E_B_C',
            sourceNodeId: 'B',
            targetNodeId: 'C',
            distanceWeight: 3,
          ),
        ],
      );

      final route = dijkstra.findShortestRoute(
        graph: graph,
        startNodeId: 'A',
        destinationNodeId: 'C',
      );

      expect(route.nodeIds, ['A', 'B', 'C']);
      expect(route.edgeIds, ['E_A_B', 'E_B_C']);
      expect(route.totalCost, 13);
    });

    test('ignores inactive and otherwise unusable edges', () {
      final graph = _graph(
        nodeIds: const ['A', 'B', 'C'],
        edges: const [
          EdgeModel(
            edgeId: 'E_INACTIVE_A_B',
            sourceNodeId: 'A',
            targetNodeId: 'B',
            traversalCost: 1,
            isActive: false,
          ),
          EdgeModel(
            edgeId: 'E_UNUSABLE_A_B',
            sourceNodeId: 'A',
            targetNodeId: 'B',
          ),
          EdgeModel(
            edgeId: 'E_A_C',
            sourceNodeId: 'A',
            targetNodeId: 'C',
            traversalCost: 2,
          ),
          EdgeModel(
            edgeId: 'E_C_B',
            sourceNodeId: 'C',
            targetNodeId: 'B',
            traversalCost: 2,
          ),
        ],
      );

      final route = dijkstra.findShortestRoute(
        graph: graph,
        startNodeId: 'A',
        destinationNodeId: 'B',
      );

      expect(route.nodeIds, ['A', 'C', 'B']);
      expect(route.edgeIds, ['E_A_C', 'E_C_B']);
      expect(route.totalCost, 4);
    });

    test(
      'chooses a longer open route after the shortest segment closes',
      () {
        const edges = [
          EdgeModel(
            edgeId: 'E_A_B',
            sourceNodeId: 'A',
            targetNodeId: 'B',
            traversalCost: 1,
          ),
          EdgeModel(
            edgeId: 'E_B_D',
            sourceNodeId: 'B',
            targetNodeId: 'D',
            traversalCost: 1,
          ),
          EdgeModel(
            edgeId: 'E_A_C',
            sourceNodeId: 'A',
            targetNodeId: 'C',
            traversalCost: 2,
          ),
          EdgeModel(
            edgeId: 'E_C_D',
            sourceNodeId: 'C',
            targetNodeId: 'D',
            traversalCost: 2,
          ),
        ];

        final openGraph = _graph(
          nodeIds: const ['A', 'B', 'C', 'D'],
          edges: edges,
        );

        final shortestOpenRoute = dijkstra.findShortestRoute(
          graph: openGraph,
          startNodeId: 'A',
          destinationNodeId: 'D',
        );

        expect(shortestOpenRoute.nodeIds, ['A', 'B', 'D']);
        expect(shortestOpenRoute.edgeIds, ['E_A_B', 'E_B_D']);
        expect(shortestOpenRoute.totalCost, 2);

        final closedGraph = _graph(
          nodeIds: const ['A', 'B', 'C', 'D'],
          edges: [
            edges[0],
            const EdgeModel(
              edgeId: 'E_B_D',
              sourceNodeId: 'B',
              targetNodeId: 'D',
              traversalCost: 1,
              isActive: false,
              closureReason: 'Maintenance work',
            ),
            edges[2],
            edges[3],
          ],
        );

        final rerouted = dijkstra.findShortestRoute(
          graph: closedGraph,
          startNodeId: 'A',
          destinationNodeId: 'D',
        );

        expect(rerouted.nodeIds, ['A', 'C', 'D']);
        expect(rerouted.edgeIds, ['E_A_C', 'E_C_D']);
        expect(rerouted.totalCost, 4);
        expect(rerouted.edgeIds, isNot(contains('E_B_D')));
      },
    );

    test('returns one node when start and destination are the same', () {
      final graph = _graph(nodeIds: const ['A']);

      final route = dijkstra.findShortestRoute(
        graph: graph,
        startNodeId: 'A',
        destinationNodeId: 'A',
      );

      expect(route.hasRoute, isTrue);
      expect(route.nodeIds, ['A']);
      expect(route.edgeIds, isEmpty);
      expect(route.totalCost, 0);
    });

    test('returns no route when the destination cannot be reached', () {
      final graph = _graph(nodeIds: const ['A', 'B']);

      final route = dijkstra.findShortestRoute(
        graph: graph,
        startNodeId: 'A',
        destinationNodeId: 'B',
      );

      expect(route.hasRoute, isFalse);
      expect(route.nodeIds, isEmpty);
      expect(route.edgeIds, isEmpty);
      expect(route.totalCost, 0);
    });
  });

  group('DijkstraService with the live CampusGO graph', () {
    late SupabaseClient client;
    late NavigationGraphData graph;

    setUpAll(() async {
      client = SupabaseClient(
        SupabaseConfig.url,
        SupabaseConfig.publishableKey,
      );
      final repository = NavigationRepository(client: client);
      graph = await repository.loadGraph();
    });

    tearDownAll(() {
      client.dispose();
    });

    test('finds the expected same-floor L8 route', () {
      final route = dijkstra.findShortestRoute(
        graph: graph,
        startNodeId: 'L8_N1',
        destinationNodeId: 'L8_N12',
      );

      print('===== L8 DIJKSTRA ROUTE CHECK =====');
      print('nodeIds = ${route.nodeIds.join(' -> ')}');
      print('edgeIds = ${route.edgeIds.join(' -> ')}');
      print('totalCost = ${route.totalCost}');
      print('===================================');

      expect(route.hasRoute, isTrue);
      expect(route.nodeIds, ['L8_N1', 'L8_N2', 'L8_N8', 'L8_N9', 'L8_N12']);
      expect(route.edgeIds, [
        'E_L8N1_L8N2',
        'E_L8N2_L8N8',
        'E_L8N8_L8N9',
        'E_L8N9_L8N12',
      ]);
      expect(route.totalCost, closeTo(1935.77, 0.001));
    });
  });
}

NavigationGraphData _graph({
  required List<String> nodeIds,
  List<EdgeModel> edges = const [],
}) {
  return NavigationGraphData(
    floors: const [],
    nodes: nodeIds.map((nodeId) => NodeModel(nodeId: nodeId)).toList(),
    edges: edges,
  );
}
