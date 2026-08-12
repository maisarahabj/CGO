// LOADS DA MAP

// Loads and controls the interactive Spline campus map.

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class HomeSplineMap extends StatefulWidget {
  const HomeSplineMap({required this.selectedFloor, super.key});

  final String selectedFloor;

  @override
  State<HomeSplineMap> createState() => _HomeSplineMapState();
}

class _HomeSplineMapState extends State<HomeSplineMap> {
  static const String _sceneUrl =
      'https://prod.spline.design/Aezweir8wJSnirTX/scene.splinecode';

  static const String _runtimeUrl =
      'https://unpkg.com/@splinetool/runtime@latest/build/runtime.js';

  late final WebViewController _controller;

  bool _isLoading = true;
  bool _isSplineReady = false;
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

    window.selectFloor = function(floorName) {
      const floorObject = spline.findObjectByName(floorName);

      if (!floorObject) {
        sendToFlutter('missing:' + floorName);
        return false;
      }

      spline.emitEvent('mouseUp', floorName);
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

    if (oldWidget.selectedFloor == widget.selectedFloor) {
      return;
    }

    _pendingFloor = widget.selectedFloor;

    if (_isSplineReady) {
      unawaited(_sendPendingFloor());
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
    final floor = _pendingFloor;

    if (!_isSplineReady || floor == null) {
      return;
    }

    _pendingFloor = null;

    try {
      await _controller.runJavaScript(
        'window.selectFloor(${jsonEncode(floor)});',
      );
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _loadError = 'Unable to switch to floor $floor: $error';
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
