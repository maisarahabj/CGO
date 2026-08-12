// Loads the updated Spline URL
// Enables Spline’s JavaScript/WebGL content
// Shows a loading indicator until the page finishes loading

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class HomeSplineMap extends StatefulWidget {
  const HomeSplineMap({required this.selectedFloor, super.key});

  final String selectedFloor;

  @override
  State<HomeSplineMap> createState() => _HomeSplineMapState();
}

class _HomeSplineMapState extends State<HomeSplineMap> {
  static final Uri _splineUri = Uri.parse(
    'https://my.spline.design/'
    'cgomapfloorsnodesedgescopy-OuE2XwgEEXGFkqtVvxQ9WN7d/',
  );

  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFFE8E8E8))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (!mounted) return;

            setState(() {
              _isLoading = true;
            });
          },
          onPageFinished: (_) {
            if (!mounted) return;

            setState(() {
              _isLoading = false;
            });
          },
        ),
      )
      ..loadRequest(_splineUri);
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
        ],
      ),
    );
  }
}
