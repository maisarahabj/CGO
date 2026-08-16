import 'package:campus_go/core/config/supabase_config.dart';
import 'package:campus_go/features/navigation/data/navigation_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  group('NavigationRepository live Supabase graph', () {
    late SupabaseClient client;
    late NavigationRepository repository;

    setUpAll(() {
      // Create an isolated client for this integration test. This deliberately
      // avoids calling the app's main() or Supabase.initialize().
      client = SupabaseClient(
        SupabaseConfig.url,
        SupabaseConfig.publishableKey,
      );
      repository = NavigationRepository(client: client);
    });

    tearDownAll(() {
      client.dispose();
    });

    test('loads the current graph without invalid or orphaned edges', () async {
      final graph = await repository.loadGraph();
      final destinations = repository.buildSearchableDestinations(graph.nodes);
      final invalidEdgeIds = graph.invalidEdges
          .map((edge) => edge.edgeId)
          .join(', ');
      final orphanedEdgeDescriptions = graph.orphanedEdges
          .map(
            (edge) =>
                '${edge.edgeId} '
                '(${edge.sourceNodeId} -> ${edge.targetNodeId})',
          )
          .join(', ');

      print('===== CAMPUSGO NAVIGATION GRAPH CHECK =====');
      print('floors = ${graph.floors.length}');
      print('nodes = ${graph.nodes.length}');
      print('edges = ${graph.edges.length}');
      print('destinations = ${destinations.length}');
      print('invalidEdges = ${graph.invalidEdges.length}');
      print('orphanedEdges = ${graph.orphanedEdges.length}');
      print('==========================================');

      expect(graph.floors.length, 6);
      expect(graph.nodes.length, 103);
      expect(graph.edges.length, 116);
      expect(destinations.length, 103);

      expect(
        graph.invalidEdges,
        isEmpty,
        reason: 'Invalid edges: $invalidEdgeIds',
      );

      expect(
        graph.orphanedEdges,
        isEmpty,
        reason: 'Orphaned edges: $orphanedEdgeDescriptions',
      );
    });
  });
}
