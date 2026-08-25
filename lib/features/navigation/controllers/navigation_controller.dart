import 'package:flutter/foundation.dart';

import '../models/destination_model.dart';
import '../models/edge_model.dart';
import '../models/navigation_graph_data.dart';
import '../models/route_result.dart';
import '../services/dijkstra_service.dart';
import '../services/navigation_service.dart';

/// Owns the state between the CampusGO home interface and the routing layer.
///
/// The home widgets do not read Supabase rows or run Dijkstra directly.
/// They tell this controller what the user selected, then listen for
/// state changes.
class NavigationController extends ChangeNotifier {
  NavigationController({
    NavigationRepository? repository,
    DijkstraService dijkstraService = const DijkstraService(),
    NavigationService navigationService = const NavigationService(),
  }) : _repository = repository ?? NavigationRepository(),
       _dijkstraService = dijkstraService,
       _navigationService = navigationService;

  final NavigationRepository _repository;

  final DijkstraService _dijkstraService;

  final NavigationService _navigationService;

  NavigationGraphData? _graph;

  List<DestinationModel> _destinations = const [];

  DestinationModel? _currentLocation;

  DestinationModel? _destination;

  RouteResult? _routeResult;

  List<NavigationInstruction> _instructions = const [];

  Future<bool>? _graphLoadFuture;

  bool _isLoadingGraph = false;

  bool _accessibleOnly = true;

  bool _isDisposed = false;

  String? _message;

  NavigationGraphData? get graph => _graph;

  List<DestinationModel> get destinations => _destinations;

  DestinationModel? get currentLocation => _currentLocation;

  DestinationModel? get destination => _destination;

  String? get currentLocationNodeId => _currentLocation?.nodeId;

  String? get destinationNodeId => _destination?.nodeId;

  RouteResult? get routeResult => _routeResult;

  List<NavigationInstruction> get instructions => _instructions;

  bool get isLoadingGraph => _isLoadingGraph;

  bool get isReady => _graph != null;

  bool get accessibleOnly => _accessibleOnly;

  String? get message => _message;

  bool get canCalculateRoute {
    return isReady &&
        !_isLoadingGraph &&
        _currentLocation != null &&
        _destination != null;
  }

  /// Loads one complete graph and builds its destination list from those
  /// same node objects.
  ///
  /// Repeated or concurrent calls never duplicate the request.
  Future<void> loadGraph() async {
    if (_graph != null) {
      return;
    }

    await _loadLatestGraph();
  }

  /// Public alerts are intentionally kept outside the active routing graph.
  /// Reading a closure never makes that inactive edge available to Dijkstra.
  Future<List<EdgeModel>> fetchClosedRouteNotices() {
    return _repository.fetchClosedRouteNotices();
  }

  /// Persists the destination of a successfully started registered-user route.
  ///
  /// HomeScreen calls this only after route calculation succeeds, keeping
  /// searches, guests, failed routes, and accessibility refreshes out of the
  /// user's visit history.
  Future<void> recordVisit({required String destinationNodeId}) {
    return _repository.recordVisit(destinationNodeId: destinationNodeId);
  }

  /// Reloads the current Supabase graph immediately before routing.
  ///
  /// The home screen keeps a cached graph for fast local destination search,
  /// but an administrator may close or reopen an edge after that cache was
  /// created. Every explicit Navigate action therefore obtains a fresh graph
  /// snapshot before Dijkstra runs.
  Future<RouteResult?> refreshGraphAndCalculateRoute() async {
    if (currentLocationNodeId == null ||
        destinationNodeId == null ||
        currentLocationNodeId == destinationNodeId) {
      return calculateRoute();
    }

    final didRefresh = await _loadLatestGraph();
    if (!didRefresh) return null;

    return calculateRoute();
  }

  Future<bool> _loadLatestGraph() {
    final activeLoad = _graphLoadFuture;
    if (activeLoad != null) return activeLoad;

    final newLoad = _performGraphLoad();
    _graphLoadFuture = newLoad;
    return newLoad;
  }

  Future<bool> _performGraphLoad() async {
    _isLoadingGraph = true;

    _message = null;

    _notifyListenersSafely();

    try {
      // Load every currently active edge. Accessibility filtering is applied
      // to this complete snapshot immediately before route calculation.
      final graph = await _repository.loadGraph(accessibleOnly: false);

      _graph = graph;

      _destinations = _repository.buildSearchableDestinations(graph.nodes);

      // Preserve both endpoint selections by node ID while replacing their
      // model instances with nodes from the fresh graph snapshot. QR-selected
      // current locations are supported even when they are not searchable.
      _currentLocation = _selectionFromGraph(
        graph: graph,
        nodeId: currentLocationNodeId,
      );
      _destination = _selectionFromGraph(
        graph: graph,
        nodeId: destinationNodeId,
      );

      return true;
    } catch (error, stackTrace) {
      _message = 'CampusGO could not load its navigation locations.';

      debugPrint('Navigation graph load failed: $error');

      debugPrintStack(stackTrace: stackTrace);

      return false;
    } finally {
      _isLoadingGraph = false;

      _graphLoadFuture = null;

      _notifyListenersSafely();
    }
  }

  DestinationModel? _selectionFromGraph({
    required NavigationGraphData graph,
    required String? nodeId,
  }) {
    if (nodeId == null) return null;

    final node = graph.nodeById[nodeId];
    return node == null ? null : DestinationModel(node: node);
  }

  /// Filters the already-built destination list locally as the user types.
  List<DestinationModel> searchDestinations(String query, {int limit = 12}) {
    return _repository.filterDestinations(
      destinations: _destinations,
      query: query,
      limit: limit,
    );
  }

  void selectCurrentLocation(DestinationModel location) {
    if (_currentLocation?.nodeId == location.nodeId) {
      return;
    }

    _currentLocation = location;

    _clearCalculatedRoute();

    _notifyListenersSafely();
  }

  void selectDestination(DestinationModel destination) {
    if (_destination?.nodeId == destination.nodeId) {
      return;
    }

    _destination = destination;

    _clearCalculatedRoute();

    _notifyListenersSafely();
  }

  /// Removes a stored selection when the user edits its visible text.
  void currentLocationTextChanged(String text) {
    final selection = _currentLocation;

    if (selection == null || text.trim() == selection.name) {
      return;
    }

    _currentLocation = null;

    _clearCalculatedRoute();

    _notifyListenersSafely();
  }

  /// Removes a stored selection when the user edits its visible text.
  void destinationTextChanged(String text) {
    final selection = _destination;

    if (selection == null || text.trim() == selection.name) {
      return;
    }

    _destination = null;

    _clearCalculatedRoute();

    _notifyListenersSafely();
  }

  /// A route calculated under one accessibility setting must not remain
  /// active after the user changes that setting.
  void setAccessibleOnly(bool value) {
    if (_accessibleOnly == value) {
      return;
    }

    _accessibleOnly = value;

    _clearCalculatedRoute();

    _notifyListenersSafely();
  }

  /// Validates the selections, filters the cached graph, runs Dijkstra, and
  /// generates instructions from the same graph snapshot for the visible UI.
  RouteResult? calculateRoute() {
    final graph = _graph;

    final startNodeId = currentLocationNodeId;

    final endNodeId = destinationNodeId;

    if (graph == null) {
      _setMessage('Navigation locations are still loading.');

      return null;
    }

    if (startNodeId == null) {
      _setMessage('Select your current location from the search results.');

      return null;
    }

    if (endNodeId == null) {
      _setMessage('Select a destination from the search results.');

      return null;
    }

    if (startNodeId == endNodeId) {
      _clearCalculatedRoute();

      _setMessage(
        'Your current location and destination are the same. '
        'Please choose a different destination.',
      );

      return null;
    }

    final routingGraph = _repository.graphForRouting(
      graph: graph,
      accessibleOnly: _accessibleOnly,
    );

    final result = _dijkstraService.findShortestRoute(
      graph: routingGraph,
      startNodeId: startNodeId,
      destinationNodeId: endNodeId,
    );

    if (!result.hasRoute) {
      _clearCalculatedRoute();

      _setMessage(
        _accessibleOnly
            ? 'No accessible route was found between those locations.'
            : 'No route was found between those locations.',
      );

      return null;
    }

    _routeResult = result;

    _instructions = _navigationService.generateInstructions(
      route: result,
      graph: routingGraph,
    );

    _message = null;

    _notifyListenersSafely();

    if (kDebugMode) {
      debugPrint('================ CAMPUSGO ROUTE TRACE ================');

      for (var index = 0;
          index < result.edgeIds.length && index + 1 < result.nodeIds.length;
          index++) {
        final edge = routingGraph.edgeById[result.edgeIds[index]];

        debugPrint(
          '${index + 1}. '
          '${result.nodeIds[index]} -> ${result.nodeIds[index + 1]} '
          '| edge: ${result.edgeIds[index]} '
          '| type: ${edge?.edgeType ?? 'unknown'} '
          '| accessible: ${edge?.isAccessible ?? false}',
        );
      }

      debugPrint('======================================================');
      debugPrint('========== CAMPUSGO NAVIGATION INSTRUCTIONS ==========');

      for (var index = 0; index < _instructions.length; index++) {
        debugPrint('${index + 1}. ${_instructions[index].debugDescription}');
      }

      debugPrint('======================================================');
    }

    return result;
  }

  /// Ends the currently displayed route without clearing the user's
  /// selected Current Location or Destination.
  ///
  /// This lets HomeScreen return to the normal input panel while preserving
  /// the selections for another route.
  void clearRoute() {
    if (_routeResult == null && _message == null) {
      return;
    }

    _clearCalculatedRoute();

    _notifyListenersSafely();
  }

  void _clearCalculatedRoute() {
    _routeResult = null;

    _instructions = const [];

    _message = null;
  }

  void _setMessage(String value) {
    _message = value;

    _notifyListenersSafely();
  }

  void _notifyListenersSafely() {
    if (!_isDisposed) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _isDisposed = true;

    super.dispose();
  }
}
