// LOADS DA MAP

// Loads and controls the interactive Spline campus map.

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class HomeSplineMap extends StatefulWidget {
  const HomeSplineMap({
    required this.selectedFloor,
    required this.selectionRequest,
    this.visibleRouteEdgeIds = const <String>{},
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

  @override
  State<HomeSplineMap> createState() => _HomeSplineMapState();
}

class _HomeSplineMapState extends State<HomeSplineMap> {
  static const String _sceneUrl =
      'https://prod.spline.design/Aezweir8wJSnirTX/scene.splinecode';

  static const String _runtimeUrl =
      'https://unpkg.com/@splinetool/runtime@1.12.98/build/runtime.js';

  /// Must be slightly longer than the camera transition configured in Spline.
  /// While a transition is running, the newest requested floor is queued.
  static const Duration _cameraTransitionDuration = Duration(milliseconds: 900);

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
      background: #E8E8E8;
    }

    #canvas3d {
      width: 100%;
      height: 100%;
      display: block;
      touch-action: none;
    }
  </style>
</head>

<body>
  <canvas id="canvas3d"></canvas>

  <script type="module">
    import { Application } from '$_runtimeUrl';

    const canvas = document.getElementById('canvas3d');
    const spline = new Application(canvas);

    function sendToFlutter(message) {
      if (window.SplineBridge) {
        window.SplineBridge.postMessage(message);
      }
    }

    /*
     * Tracks the route edges that this WebView has already made visible.
     * Spline itself still starts every edge in its hidden Base State.
     */
    const visibleRouteEdges = new Set();

    function findRouteEdge(edgeId) {
      const edgeObject = spline.findObjectByName(edgeId);

      if (!edgeObject) {
        sendToFlutter('missing-edge:' + edgeId);
        return null;
      }

      return edgeObject;
    }

    function showRouteEdge(edgeId) {
      const edgeObject = findRouteEdge(edgeId);

      if (!edgeObject) {
        return false;
      }

      /*
       * Run the Key Down transition configured on this specific Spline edge:
       * Base State (0% opacity) -> ROUTE_VISIBLE (100% opacity).
       */
      spline.emitEvent('keyDown', edgeObject.uuid);
      return true;
    }

    function hideRouteEdge(edgeId) {
      const edgeObject = findRouteEdge(edgeId);

      if (!edgeObject) {
        return false;
      }

      /* Reverse the transition so the edge returns to its hidden Base State. */
      spline.emitEventReverse('keyDown', edgeObject.uuid);
      return true;
    }

    window.setRouteEdges = function(edgeIds) {
      if (!Array.isArray(edgeIds)) {
        sendToFlutter('route-error:Expected an array of edge IDs.');
        return false;
      }

      const requestedEdges = new Set(edgeIds);

      /* Hide edges that are not part of the newly requested route. */
      Array.from(visibleRouteEdges).forEach(function(currentEdge) {
        if (!requestedEdges.has(currentEdge)) {
          hideRouteEdge(currentEdge);
          visibleRouteEdges.delete(currentEdge);
        }
      });

      /* Show only edges that are new to the requested route. */
      requestedEdges.forEach(function(requestedEdge) {
        if (!visibleRouteEdges.has(requestedEdge)) {
          if (showRouteEdge(requestedEdge)) {
            visibleRouteEdges.add(requestedEdge);
          }
        }
      });

      sendToFlutter(
        'route-updated:' + Array.from(visibleRouteEdges).join(',')
      );

      return true;
    };

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
       */
      const mouseUpEvents =
        spline.eventManager?.handlers?.Basic?.eventsPerObjects?.MouseUp?.[
          floorObject.uuid
        ];

      if (!Array.isArray(mouseUpEvents) || mouseUpEvents.length === 0) {
        return false;
      }

      mouseUpEvents.forEach(function(event) {
        event.dispatch();
      });

      return true;
    }

    window.selectFloor = function(floorName) {
      const floorObject = spline.findObjectByName(floorName);

      if (!floorObject) {
        sendToFlutter('missing:' + floorName);
        return false;
      }

      const replayed = replayMouseUpEvent(floorObject);

      if (!replayed) {
        sendToFlutter('missing-event:' + floorName);
        return false;
      }

      sendToFlutter('selected:' + floorName);

      return true;
    };

    spline
      .load('$_sceneUrl')
      .then(function() {
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

    unawaited(_loadFreshSplineScene());
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

    if (!setEquals(
      oldWidget.visibleRouteEdgeIds,
      widget.visibleRouteEdgeIds,
    )) {
      if (_isSplineReady) {
        unawaited(_sendRouteEdges());
      }
    }
  }

  void _handleSplineMessage(JavaScriptMessage message) {
    if (!mounted) return;

    final value = message.message;

    if (value == 'ready') {
      setState(() {
        _isSplineReady = true;
        _isLoading = false;
        _loadError = null;
      });

      unawaited(_sendPendingFloor());
      unawaited(_sendRouteEdges());
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

  Future<void> _sendRouteEdges() async {
    if (!_isSplineReady) {
      return;
    }

    // Sorting is not required by Spline, but makes the JavaScript command
    // deterministic and easier to inspect while debugging.
    final edgeIds = widget.visibleRouteEdgeIds.toList()..sort();

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

  Future<void> _loadFreshSplineScene() async {
    try {
      await _controller.clearCache();
      await _controller.clearLocalStorage();

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
