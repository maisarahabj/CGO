// LOADS DA MAP

// Loads and controls the interactive Spline campus map.

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../navigation/models/node_model.dart';

class HomeSplineMap extends StatefulWidget {
  const HomeSplineMap({
    required this.selectedFloor,
    required this.selectionRequest,
    this.visibleRouteEdgeIds = const <String>{},
    this.visibleFloorNames = const <String>{},
    this.routeStartNode,
    this.routeDestinationNode,
    this.topGestureExclusionHeight = 0,
    super.key,
  });

  final String selectedFloor;

  /// Increases whenever a floor toggle is tapped.
  ///
  /// This means the selected floor can be requested again to recenter it.
  final int selectionRequest;

  /// Names of the Spline edge objects that form the route currently shown.
  ///
  /// Each value must exactly match an edge_id in Supabase and an object name
  /// in Spline, for example E_GN0_GN1.
  final Set<String> visibleRouteEdgeIds;

  /// Spline floor groups that should remain visible while a route is active.
  ///
  /// An empty set means normal browsing and restores every CampusGO floor.
  /// HomeScreen fills this from RouteResult.nodeIds only after navigation has
  /// actually been calculated, so choosing locations alone never hides floors.
  final Set<String> visibleFloorNames;

  /// Selected endpoints are sent to Spline as soon as they become available.
  /// Each marker is independent, so either one can appear before the route is
  /// calculated or before the other location has been selected.
  final NodeModel? routeStartNode;
  final NodeModel? routeDestinationNode;

  /// Height, in Flutter logical pixels, covered by a Flutter overlay at the
  /// top of the WebView. The HTML layer consumes native WebView gestures only
  /// inside this area, leaving the exposed map fully interactive.
  final double topGestureExclusionHeight;

  @override
  State<HomeSplineMap> createState() => _HomeSplineMapState();
}

class _HomeSplineMapState extends State<HomeSplineMap> {
  static const String _sceneUrl =
      'https://prod.spline.design/Aezweir8wJSnirTX/scene.splinecode';

  static const String _runtimeUrl =
      'https://unpkg.com/@splinetool/runtime@1.12.98/build/runtime.js';

  /// Must match the overview camera name in the published Spline scene.
  ///
  /// Spline controls its initial camera through Export -> Play Settings ->
  /// Camera. Set that option to Camera_Overview before publishing the scene.
  static const String _overviewCameraName = 'Camera_Overview';

  /// Optional Spline helper for explicitly replaying the overview camera.
  ///
  /// If this object exists, add a Mouse Up -> Switch Camera event that targets
  /// Camera_Overview. The app will replay that event once on startup. When the
  /// helper is absent, the overview configured in Play Settings is preserved.
  static const String _overviewCameraTriggerName = 'OVERVIEW_CAMERA_TRIGGER';

  /// Must be slightly longer than the camera transition configured in Spline.
  /// While a transition is running, the newest requested floor is queued.
  static const Duration _cameraTransitionDuration = Duration(
    milliseconds: 1100,
  );

  late final WebViewController _controller;

  bool _isLoading = true;
  bool _isSplineReady = false;
  bool _isSwitchingFloor = false;
  String? _pendingFloor;
  String? _loadError;

  String get _splineHtml {
    return '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">

  <meta
    name="viewport"
    content="width=device-width, initial-scale=1, maximum-scale=1"
  >

  <style>
    html,
    body {
      width: 100%;
      height: 100%;
      margin: 0;
      overflow: hidden;
      position: relative;
      background: #E8E8E8;
    }

    #canvas3d {
      width: 100%;
      height: 100%;
      display: block;
      touch-action: none;
    }

    #flutterGestureShield {
      position: absolute;
      top: 0;
      left: 0;
      width: 100%;
      height: 0;
      z-index: 2147483647;
      pointer-events: auto;
      touch-action: none;
      background: transparent;
    }
  </style>
</head>

<body>
  <canvas id="canvas3d"></canvas>
  <div id="flutterGestureShield" aria-hidden="true"></div>

  <script type="module">
    import { Application } from '$_runtimeUrl';

    const canvas = document.getElementById('canvas3d');
    const flutterGestureShield = document.getElementById(
      'flutterGestureShield'
    );
    const spline = new Application(canvas);

    const routeBaseState = 'Base State';
    const routeVisibleState = 'ROUTE_VISIBLE';
    const startMarkerName = 'ROUTE_START_MARKER';
    const destinationMarkerName = 'ROUTE_DESTINATION_MARKER';
    const overviewCameraName = '$_overviewCameraName';
    const overviewCameraTriggerName = '$_overviewCameraTriggerName';

    function sendToFlutter(message) {
      if (window.SplineBridge) {
        window.SplineBridge.postMessage(message);
      }
    }

    const routeEdgeObjects = new Map();
    const visibleRouteEdges = new Set();

    const campusFloorNames = ['L9', 'L8', 'L6', 'L3', 'L1', 'G'];
    const floorObjects = new Map();

    function indexFloorObjects() {
      floorObjects.clear();

      campusFloorNames.forEach(function(floorName) {
        const floorObject = spline.findObjectByName(floorName);

        if (floorObject) {
          floorObjects.set(floorName, floorObject);
        } else {
          sendToFlutter('missing-floor-visibility:' + floorName);
        }
      });

      sendToFlutter('floor-indexed:' + floorObjects.size);
    }

    window.setVisibleFloors = function(floorNames) {
      if (!Array.isArray(floorNames)) {
        sendToFlutter('floor-visibility-error:Expected an array of floor names.');
        return false;
      }

      const requestedFloors = new Set(
        floorNames
          .map(function(floorName) {
            return String(floorName).trim();
          })
          .filter(function(floorName) {
            return campusFloorNames.includes(floorName);
          })
      );

      /*
       * Empty means no active route. Restore every floor for normal browsing.
       * A non-empty set means navigation is active, so only the floor groups
       * represented by RouteResult.nodeIds remain visible. route_edges and
       * route markers are top-level Spline objects and are not affected.
       */
      const showAllFloors = requestedFloors.size === 0;

      campusFloorNames.forEach(function(floorName) {
        const floorObject = floorObjects.get(floorName);

        if (!floorObject) {
          return;
        }

        if (showAllFloors || requestedFloors.has(floorName)) {
          floorObject.show();
        } else {
          floorObject.hide();
        }
      });

      spline.requestRender();

      sendToFlutter(
        'floors-updated:' +
          (showAllFloors ? 'ALL' : Array.from(requestedFloors).join(','))
      );

      return true;
    };

    function indexRouteEdges() {
      routeEdgeObjects.clear();

      spline.getAllObjects().forEach(function(object) {
        if (object.name && object.name.startsWith('E_')) {
          routeEdgeObjects.set(object.name, object);
        }
      });

      sendToFlutter('route-edge-indexed:' + routeEdgeObjects.size);
    }

    function consumeShieldGesture(event) {
      event.preventDefault();
      event.stopImmediatePropagation();
    }

    [
      'pointerdown',
      'pointermove',
      'pointerup',
      'pointercancel',
      'touchstart',
      'touchmove',
      'touchend',
      'touchcancel',
      'wheel'
    ].forEach(function(eventName) {
      flutterGestureShield.addEventListener(
        eventName,
        consumeShieldGesture,
        { capture: true, passive: false }
      );
    });

    window.setTopGestureExclusionHeight = function(height) {
      const requestedHeight = Number(height);
      const safeHeight = Number.isFinite(requestedHeight)
        ? Math.max(0, Math.ceil(requestedHeight))
        : 0;

      flutterGestureShield.style.height = safeHeight + 'px';
      sendToFlutter('gesture-shield:' + safeHeight);
      return true;
    };

    function findRouteEdge(edgeId) {
      return routeEdgeObjects.get(edgeId) ?? null;
    }

    function setRouteEdgeState(edgeObject, stateName) {
      try {
        /*
         * Assigning the state directly is deterministic. It does not depend
         * on the previous Key Down animation being reversible.
         */
        edgeObject.state = stateName;
        return true;
      } catch (error) {
        sendToFlutter(
          'route-error:' + edgeObject.name + ': ' + String(error)
        );
        return false;
      }
    }

    window.setRouteEdges = function(edgeIds) {
      if (!Array.isArray(edgeIds)) {
        sendToFlutter('route-error:Expected an array of edge IDs.');
        return false;
      }

      const requestedEdges = new Set(
        edgeIds
          .map(function(edgeId) {
            return String(edgeId).trim();
          })
          .filter(function(edgeId) {
            return edgeId.length > 0;
          })
      );

      /*
       * Reset only the edges that CampusGO made visible for the previous route.
       *
       * The full scene is indexed once after load, so route replacement does
       * not repeatedly traverse every object in the Spline scene.
       */
      visibleRouteEdges.forEach(function(edgeId) {
        const edgeObject = findRouteEdge(edgeId);

        if (edgeObject) {
          setRouteEdgeState(edgeObject, routeBaseState);
        }
      });

      visibleRouteEdges.clear();

      const missingEdges = [];

      /* Show only the edges belonging to the latest RouteResult. */
      requestedEdges.forEach(function(requestedEdge) {
        const edgeObject = findRouteEdge(requestedEdge);

        if (!edgeObject) {
          missingEdges.push(requestedEdge);
          return;
        }

        if (setRouteEdgeState(edgeObject, routeVisibleState)) {
          visibleRouteEdges.add(requestedEdge);
        }
      });

      spline.requestRender();

      sendToFlutter(
        'route-updated:' + Array.from(visibleRouteEdges).join(',')
      );

      /* Send missing IDs last so route-updated cannot erase the error. */
      missingEdges.forEach(function(edgeId) {
        sendToFlutter('missing-edge:' + edgeId);
      });

      return true;
    };

    function updateRouteMarker(markerName, endpoint) {
      const marker = spline.findObjectByName(markerName);

      if (!marker) {
        sendToFlutter('missing-marker:' + markerName);
        return false;
      }

      if (endpoint === null) {
        marker.hide();
        sendToFlutter('marker-hidden:' + markerName);
        return true;
      }

      const coordinates = [endpoint.x, endpoint.y, endpoint.z];
      const hasValidCoordinates = coordinates.every(Number.isFinite);

      if (!hasValidCoordinates) {
        marker.hide();
        sendToFlutter('marker-error:' + endpoint.nodeId);
        return false;
      }

      marker.position.x = endpoint.x;
      marker.position.y = endpoint.y;
      marker.position.z = endpoint.z;
      marker.show();

      sendToFlutter(
        'marker-positioned:' +
          markerName + ':' + endpoint.nodeId + ':' +
          endpoint.x + ',' + endpoint.y + ',' + endpoint.z
      );
      return true;
    }

    window.setRouteEndpoints = function(startEndpoint, destinationEndpoint) {
      updateRouteMarker(startMarkerName, startEndpoint);
      updateRouteMarker(destinationMarkerName, destinationEndpoint);
      spline.requestRender();
      sendToFlutter('markers-updated');
      return true;
    };

    /*
     * ---------------------------------------------------------------------
     * FLOOR CAMERA CONTROL
     * ---------------------------------------------------------------------
     * Flutter does not write directly to spline._camera.
     *
     * Every floor request replays the floor object's original Spline
     * Mouse Up -> Switch Camera event. This keeps Spline's own camera,
     * orbit, pan and zoom state in one system instead of mixing native
     * Spline camera control with a second custom camera tween.
     */

    /*
     * ---------------------------------------------------------------------
     * FLUTTER-ONLY FLOOR CAMERA EVENTS
     * ---------------------------------------------------------------------
     *
     * In the Spline editor each visible floor (L9, L8, L6, L3, L1, G)
     * already owns a Mouse Up -> Switch Camera event.
     *
     * We still want Flutter's floor buttons to reuse those authored events,
     * but we do NOT want a real tap/click on the visible floor geometry to
     * trigger the same camera switch.
     *
     * The runtime uses the same event object's dispatch() method for a real
     * Spline Mouse Up. So after the scene loads we wrap only those six floor
     * event dispatchers with a no-op. The original bound dispatch functions
     * are kept in a WeakMap. Flutter's replayMouseUpEvent() calls the saved
     * original directly, so the buttons still work while map clicks do not.
     *
     * This does NOT block pointer input on the canvas, therefore orbit, pan
     * and pinch/zoom continue to work normally.
     */
    const flutterControlledFloorNames = campusFloorNames;

    const originalFloorMouseUpDispatches = new WeakMap();

    function getMouseUpEventsForObject(object) {
      return (
        spline.eventManager?.handlers?.Basic?.eventsPerObjects?.MouseUp?.[
          object.uuid
        ] ?? []
      );
    }

    function installFlutterOnlyFloorMouseUpGuards() {
      flutterControlledFloorNames.forEach(function(floorName) {
        const floorObject = spline.findObjectByName(floorName);

        if (!floorObject) {
          sendToFlutter('floor-guard-missing:' + floorName);
          return;
        }

        const mouseUpEvents = getMouseUpEventsForObject(floorObject);

        if (!Array.isArray(mouseUpEvents) || mouseUpEvents.length === 0) {
          sendToFlutter('floor-guard-no-event:' + floorName);
          return;
        }

        mouseUpEvents.forEach(function(event) {
          if (originalFloorMouseUpDispatches.has(event)) {
            return;
          }

          if (typeof event.dispatch !== 'function') {
            sendToFlutter('floor-guard-invalid-event:' + floorName);
            return;
          }

          const originalDispatch = event.dispatch.bind(event);
          originalFloorMouseUpDispatches.set(event, originalDispatch);

          try {
            event.dispatch = function() {
              sendToFlutter('floor-map-click-blocked:' + floorName);
            };
          } catch (error) {
            sendToFlutter(
              'floor-guard-error:' + floorName + ':' + String(error)
            );
          }
        });

        sendToFlutter('floor-guard-ready:' + floorName);
      });
    }

    function replayMouseUpEvent(floorObject) {
      /*
       * A real canvas tap makes Spline call dispatch(), which restarts its
       * Switch Camera action. The public emitEvent() API instead calls
       * playFromCurrent(). After a floor has already finished once,
       * playFromCurrent() has nowhere left to move and the camera stays put.
       *
       * Use the same Basic Mouse Up event objects as a real tap and call their
       * replayable dispatch() method. The runtime version is pinned above so
       * this event-manager structure stays consistent.
       *
       * This is used for EVERY Flutter floor request. Replaying Spline's
       * original dispatcher lets the authored Switch Camera action reset the
       * view even after the user has orbited, panned or zoomed.
       */
      const mouseUpEvents = getMouseUpEventsForObject(floorObject);

      if (!Array.isArray(mouseUpEvents) || mouseUpEvents.length === 0) {
        return false;
      }

      mouseUpEvents.forEach(function(event) {
        /*
         * If the floor guard is installed, bypass its no-op wrapper and call
         * the original Spline dispatcher. This path is reachable only from
         * Flutter's explicit window.selectFloor(...) command.
         */
        const originalDispatch = originalFloorMouseUpDispatches.get(event);

        if (originalDispatch) {
          originalDispatch();
        } else {
          event.dispatch();
        }
      });

      return true;
    }

    window.selectFloor = function(floorName) {
      const floorObject = spline.findObjectByName(floorName);

      if (!floorObject) {
        sendToFlutter('missing:' + floorName);
        return false;
      }

      /*
       * Always let Spline perform the Switch Camera action itself.
       *
       * Do not cache or manually tween spline._camera here. A cached transform
       * can be captured while another floor transition or user gesture is
       * already changing the camera, which makes later recenter/floor requests
       * unreliable.
       */
      const replayed = replayMouseUpEvent(floorObject);

      if (!replayed) {
        sendToFlutter('missing-event:' + floorName);
        return false;
      }

      sendToFlutter('selected:' + floorName);
      return true;
    };

    function recognizedActiveCameraName() {
      /*
       * Reading the active camera is diagnostic only. Never overwrite
       * spline._camera, because Spline must continue to own orbit, pan,
       * pinch/zoom and authored Switch Camera transitions.
       *
       * Runtime versions do not expose the active authored camera name in
       * exactly the same place, so accept only known CampusGO camera names.
       */
      const knownNames = new Set([
        overviewCameraName,
        'Camera_L9',
        'Camera_L8',
        'Camera_L6',
        'Camera_L3',
        'Camera_L1',
        'Camera_G',
      ]);

      const candidates = [
        spline._camera?.name,
        spline._camera?.camera?.name,
        spline._camera?.object?.name,
        spline._camera?.parent?.name,
        spline.camera?.name,
      ];

      for (const candidate of candidates) {
        if (typeof candidate === 'string' && knownNames.has(candidate)) {
          return candidate;
        }
      }

      return null;
    }

    function activateStartupCamera() {
      const overviewCamera = spline.findObjectByName(overviewCameraName);

      if (!overviewCamera) {
        /*
         * Never fall back to HomeScreen's initial selected floor here.
         *
         * HomeScreen currently initializes its floor selector to L8, so a
         * startup floor fallback would override the intended overview and
         * reproduce the zoomed-in Level 8 startup.
         */
        sendToFlutter('startup-camera-missing:' + overviewCameraName);
        return false;
      }

      const overviewTrigger = spline.findObjectByName(
        overviewCameraTriggerName
      );

      if (overviewTrigger) {
        if (replayMouseUpEvent(overviewTrigger)) {
          sendToFlutter(
            'startup-camera-active:' + overviewCameraName + ':event'
          );
          return true;
        }

        sendToFlutter(
          'startup-camera-trigger-no-event:' + overviewCameraTriggerName
        );
      }

      const activeCameraName = recognizedActiveCameraName();

      if (activeCameraName === overviewCameraName) {
        sendToFlutter(
          'startup-camera-active:' + overviewCameraName + ':play-settings'
        );
        return true;
      }

      if (activeCameraName) {
        /*
         * Diagnose a wrong exported camera, but do not replace it with L8 or
         * any other floor. The lowest-risk startup source of truth is Spline's
         * Export -> Play Settings camera.
         */
        sendToFlutter(
          'startup-camera-wrong-default:' +
            activeCameraName + ':expected:' + overviewCameraName
        );
        return false;
      }

      /*
       * Some runtime builds do not expose the authored active camera name
       * through the private diagnostic fields above. In that case the code
       * deliberately leaves the exported Play Settings camera untouched.
       */
      sendToFlutter(
        'startup-camera-unverified:expected:' + overviewCameraName
      );
      return true;
    }

    spline
      .load('$_sceneUrl')
      .then(function() {
        /*
         * Disable the visible floor objects' physical Mouse Up camera
         * switches before Flutter receives the ready signal.
         */
        indexFloorObjects();
        installFlutterOnlyFloorMouseUpGuards();
        indexRouteEdges();
        activateStartupCamera();

        const startMarker = spline.findObjectByName(startMarkerName);
        const destinationMarker = spline.findObjectByName(
          destinationMarkerName
        );

        if (startMarker) startMarker.hide();
        if (destinationMarker) destinationMarker.hide();
        spline.requestRender();
        sendToFlutter('ready');
      })
      .catch(function(error) {
        sendToFlutter('error:' + String(error));
      });
  </script>
</body>
</html>
''';
  }

  @override
  void initState() {
    super.initState();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFFE8E8E8))
      ..addJavaScriptChannel(
        'SplineBridge',
        onMessageReceived: _handleSplineMessage,
      );

    unawaited(_loadSplineScene());
  }

  @override
  void didUpdateWidget(covariant HomeSplineMap oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.selectionRequest != widget.selectionRequest) {
      _pendingFloor = widget.selectedFloor;

      if (_isSplineReady) {
        unawaited(_sendPendingFloor());
      }
    }

    if (!setEquals(oldWidget.visibleRouteEdgeIds, widget.visibleRouteEdgeIds)) {
      if (_isSplineReady) {
        unawaited(_sendRouteEdges());
      }
    }

    if (!setEquals(oldWidget.visibleFloorNames, widget.visibleFloorNames)) {
      if (_isSplineReady) {
        unawaited(_sendVisibleFloors());
      }
    }

    final startChanged =
        oldWidget.routeStartNode?.nodeId != widget.routeStartNode?.nodeId;
    final destinationChanged =
        oldWidget.routeDestinationNode?.nodeId !=
        widget.routeDestinationNode?.nodeId;

    if ((startChanged || destinationChanged) && _isSplineReady) {
      unawaited(_sendRouteEndpoints());
    }

    if (oldWidget.topGestureExclusionHeight !=
            widget.topGestureExclusionHeight &&
        _isSplineReady) {
      unawaited(_sendTopGestureExclusionHeight());
    }
  }

  void _handleSplineMessage(JavaScriptMessage message) {
    if (!mounted) return;

    final value = message.message;

    debugPrint('SplineBridge received: $value');

    if (value == 'ready') {
      setState(() {
        _isSplineReady = true;
        _isLoading = false;
        _loadError = null;
      });

      unawaited(_sendPendingFloor());

      if (widget.visibleRouteEdgeIds.isNotEmpty) {
        unawaited(_sendRouteEdges());
      }

      // Enforce the Flutter route state after every scene load. Empty restores
      // all floors; a calculated route sends only its relevant floor groups.
      unawaited(_sendVisibleFloors());
      unawaited(_sendRouteEndpoints());
      unawaited(_sendTopGestureExclusionHeight());
      return;
    }

    if (value.startsWith('gesture-shield:')) {
      return;
    }

    if (value.startsWith('startup-camera-')) {
      // The startup camera diagnostic has already been included in the
      // SplineBridge debug message printed above.
      return;
    }

    if (value.startsWith('selected:')) {
      setState(() {
        _loadError = null;
      });
      return;
    }

    if (value.startsWith('missing:')) {
      final missingObject = value.substring('missing:'.length);

      setState(() {
        _loadError = 'Spline could not find the floor object "$missingObject".';
      });
      return;
    }

    if (value.startsWith('missing-event:')) {
      final floor = value.substring('missing-event:'.length);

      setState(() {
        _loadError =
            'Spline found floor "$floor", but it has no Mouse Up event.';
      });
      return;
    }

    if (value.startsWith('floor-indexed:') ||
        value.startsWith('floors-updated:')) {
      return;
    }

    if (value.startsWith('missing-floor-visibility:')) {
      final floor = value.substring('missing-floor-visibility:'.length);

      setState(() {
        _loadError = 'Spline could not find the floor group "$floor".';
      });
      return;
    }

    if (value.startsWith('floor-visibility-error:')) {
      final errorMessage = value.substring('floor-visibility-error:'.length);

      setState(() {
        _loadError = 'Unable to update floor visibility: $errorMessage';
      });
      return;
    }

    if (value.startsWith('route-edge-indexed:')) {
      return;
    }

    if (value.startsWith('route-updated:')) {
      setState(() {
        _loadError = null;
      });
      return;
    }

    if (value.startsWith('missing-edge:')) {
      final edgeId = value.substring('missing-edge:'.length);

      setState(() {
        _loadError = 'Spline could not find the route edge "$edgeId".';
      });
      return;
    }

    if (value.startsWith('missing-marker:')) {
      final markerName = value.substring('missing-marker:'.length);
      debugPrint(
        'Spline route marker "$markerName" has not been added to the scene.',
      );
      return;
    }

    if (value.startsWith('marker-error:')) {
      final nodeId = value.substring('marker-error:'.length);
      debugPrint('Spline route marker has invalid coordinates for $nodeId.');
      return;
    }

    if (value.startsWith('marker-hidden:') ||
        value.startsWith('marker-positioned:')) {
      // The full message has already been printed by the debugPrint above.
      return;
    }

    if (value == 'markers-updated') {
      return;
    }

    if (value.startsWith('route-error:')) {
      final errorMessage = value.substring('route-error:'.length);

      setState(() {
        _loadError = 'Unable to update route: $errorMessage';
      });
      return;
    }

    if (value.startsWith('error:')) {
      final errorMessage = value.substring('error:'.length);

      setState(() {
        _isLoading = false;
        _isSplineReady = false;
        _loadError = 'Spline failed to load: $errorMessage';
      });
    }
  }

  Future<void> _sendPendingFloor() async {
    if (!_isSplineReady || _isSwitchingFloor) {
      return;
    }

    final floor = _pendingFloor;

    if (floor == null) {
      return;
    }

    _pendingFloor = null;
    _isSwitchingFloor = true;

    try {
      await _controller.runJavaScript(
        'window.selectFloor(${jsonEncode(floor)});',
      );

      // JavaScript receives the command immediately, but Spline's visual
      // camera transition continues afterward. Wait before sending another.
      await Future<void>.delayed(_cameraTransitionDuration);
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _loadError = 'Unable to switch to floor $floor: $error';
      });
    } finally {
      _isSwitchingFloor = false;

      // If another button was tapped during the previous transition, run the
      // newest request now instead of losing it.
      if (_pendingFloor != null) {
        unawaited(_sendPendingFloor());
      }
    }
  }

  Future<void> _sendVisibleFloors() async {
    if (!_isSplineReady) {
      return;
    }

    // Empty is intentional: JavaScript interprets it as "show all floors".
    final floorNames = widget.visibleFloorNames.toList()..sort();

    debugPrint('Spline floor visibility sending: ${jsonEncode(floorNames)}');

    try {
      await _controller.runJavaScript(
        'window.setVisibleFloors(${jsonEncode(floorNames)});',
      );
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _loadError = 'Unable to update route floor visibility: $error';
      });
    }
  }

  Future<void> _sendRouteEdges() async {
    if (!_isSplineReady) {
      return;
    }

    // Sorting is not required by Spline, but makes the JavaScript command
    // deterministic and easier to inspect while debugging.
    final edgeIds = widget.visibleRouteEdgeIds.toList()..sort();

    debugPrint('Spline route sending: ${jsonEncode(edgeIds)}');

    try {
      await _controller.runJavaScript(
        'window.setRouteEdges(${jsonEncode(edgeIds)});',
      );
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _loadError = 'Unable to display the route: $error';
      });
    }
  }

  Map<String, Object>? _encodeRouteEndpoint(NodeModel? node) {
    if (node == null) return null;

    if (!node.hasCoordinates) {
      debugPrint(
        'Spline route marker skipped because ${node.nodeId} has no complete '
        'coordinates.',
      );
      return null;
    }

    return <String, Object>{
      'nodeId': node.nodeId,
      'x': node.xCoord!,
      'y': node.yCoord!,
      'z': node.zCoord!,
    };
  }

  Future<void> _sendRouteEndpoints() async {
    if (!_isSplineReady) return;

    // Markers describe selected locations, not whether a route already
    // exists. Null hides only the corresponding unselected marker.
    final startPayload = _encodeRouteEndpoint(widget.routeStartNode);
    final destinationPayload = _encodeRouteEndpoint(
      widget.routeDestinationNode,
    );

    debugPrint(
      'Spline route endpoints sending: '
      'start=${jsonEncode(startPayload)}, '
      'destination=${jsonEncode(destinationPayload)}',
    );

    try {
      await _controller.runJavaScript(
        'window.setRouteEndpoints('
        '${jsonEncode(startPayload)}, ${jsonEncode(destinationPayload)}'
        ');',
      );
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _loadError = 'Unable to position the route markers: $error';
      });
    }
  }

  Future<void> _sendTopGestureExclusionHeight() async {
    if (!_isSplineReady) return;

    final requestedHeight = widget.topGestureExclusionHeight;
    final safeHeight = requestedHeight.isFinite && requestedHeight > 0
        ? requestedHeight
        : 0.0;

    try {
      await _controller.runJavaScript(
        'window.setTopGestureExclusionHeight($safeHeight);',
      );
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _loadError = 'Unable to isolate map gestures: $error';
      });
    }
  }

  Future<void> _loadSplineScene() async {
    try {
      /*
       * Do not clear WebView cache or local storage on every HomeSplineMap
       * creation. The Spline runtime and scene assets are static production
       * resources and should be allowed to reuse the WebView cache.
       */
      await _controller.loadHtmlString(
        _splineHtml,
        baseUrl: 'https://prod.spline.design/',
      );
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _isSplineReady = false;
        _loadError = 'Unable to open the campus map: $error';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Interactive campus map for ${widget.selectedFloor}',
      child: Stack(
        fit: StackFit.expand,
        children: [
          const ColoredBox(color: Color(0xFFE8E8E8)),
          WebViewWidget(controller: _controller),
          if (_isLoading)
            const ColoredBox(
              color: Color(0xFFE8E8E8),
              child: Center(child: CircularProgressIndicator()),
            ),
          if (_loadError != null)
            ColoredBox(
              color: const Color(0xFFE8E8E8),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(_loadError!, textAlign: TextAlign.center),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
