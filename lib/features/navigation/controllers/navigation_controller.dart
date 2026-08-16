import 'package:flutter/foundation.dart';

import '../data/navigation_repository.dart';
import '../models/destination_model.dart';
import '../models/navigation_graph_data.dart';
import '../models/route_result.dart';
import '../services/dijkstra_service.dart';

/// Owns the state between the CampusGO home interface and the routing layer.
///
/// The home widgets do not read Supabase rows or run Dijkstra directly. They
/// tell this controller what the user selected, then listen for state changes.
class NavigationController extends ChangeNotifier {
  NavigationController({
    NavigationRepository? repository,
    DijkstraService dijkstraService = const DijkstraService(),
  }) : _repository = repository ?? NavigationRepository(),
       _dijkstraService = dijkstraService;

  final NavigationRepository _repository;
  final DijkstraService _dijkstraService;

  NavigationGraphData? _graph;
  List<DestinationModel> _destinations = const [];
  DestinationModel? _currentLocation;
  DestinationModel? _destination;
  RouteResult? _routeResult;
  Future<void>? _graphLoadFuture;
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

  /// Loads one complete graph and builds its destination list from those same
  /// node objects. Repeated or concurrent calls never duplicate the request.
  Future<void> loadGraph() {
    if (_graph != null) return Future.value();

    final activeLoad = _graphLoadFuture;
    if (activeLoad != null) return activeLoad;

    final newLoad = _performGraphLoad();
    _graphLoadFuture = newLoad;
    return newLoad;
  }

  Future<void> _performGraphLoad() async {
    _isLoadingGraph = true;
    _message = null;
    _notifyListenersSafely();

    try {
      // Load all active edges once. Accessibility filtering is applied to this
      // cached snapshot immediately before a route calculation.
      final graph = await _repository.loadGraph(accessibleOnly: false);

      _graph = graph;
      _destinations = _repository.buildSearchableDestinations(graph.nodes);
    } catch (error, stackTrace) {
      _message = 'CampusGO could not load its navigation locations.';
      debugPrint('Navigation graph load failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    } finally {
      _isLoadingGraph = false;
      _graphLoadFuture = null;
      _notifyListenersSafely();
    }
  }

  /// Filters the already-built destination list locally as the user types.
  List<DestinationModel> searchDestinations(
    String query, {
    int limit = 12,
  }) {
    return _repository.filterDestinations(
      destinations: _destinations,
      query: query,
      limit: limit,
    );
  }

  void selectCurrentLocation(DestinationModel location) {
    if (_currentLocation?.nodeId == location.nodeId) return;

    _currentLocation = location;
    _clearCalculatedRoute();
    _notifyListenersSafely();
  }

  void selectDestination(DestinationModel destination) {
    if (_destination?.nodeId == destination.nodeId) return;

    _destination = destination;
    _clearCalculatedRoute();
    _notifyListenersSafely();
  }

  /// Removes a stored selection when the user edits its visible text.
  void currentLocationTextChanged(String text) {
    final selection = _currentLocation;
    if (selection == null || text.trim() == selection.name) return;

    _currentLocation = null;
    _clearCalculatedRoute();
    _notifyListenersSafely();
  }

  /// Removes a stored selection when the user edits its visible text.
  void destinationTextChanged(String text) {
    final selection = _destination;
    if (selection == null || text.trim() == selection.name) return;

    _destination = null;
    _clearCalculatedRoute();
    _notifyListenersSafely();
  }

  /// A route calculated under one accessibility setting must not remain active
  /// after the user changes that setting.
  void setAccessibleOnly(bool value) {
    if (_accessibleOnly == value) return;

    _accessibleOnly = value;
    _clearCalculatedRoute();
    _notifyListenersSafely();
  }

  /// Validates the selections, filters the cached graph, and runs Dijkstra.
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
      _routeResult = null;
      _setMessage(
        _accessibleOnly
            ? 'No accessible route was found between those locations.'
            : 'No route was found between those locations.',
      );
      return null;
    }

    _routeResult = result;
    _message = null;
    _notifyListenersSafely();
    return result;
  }

  void _clearCalculatedRoute() {
    _routeResult = null;
    _message = null;
  }

  void _setMessage(String value) {
    _message = value;
    _notifyListenersSafely();
  }

  void _notifyListenersSafely() {
    if (!_isDisposed) notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}
