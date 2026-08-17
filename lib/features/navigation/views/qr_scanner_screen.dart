import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../core/exceptions/app_exception.dart';
import '../data/navigation_repository.dart';
import '../models/node_model.dart';

/// Scans a CampusGO QR checkpoint and returns the linked active [NodeModel].
///
/// Real camera scans and the debug simulator controls both call
/// [_processScanValue]. This means the development button only replaces the
/// physical act of pointing a camera at a QR code; Supabase lookup, status
/// validation, node resolution, and the value returned to HomeScreen are real.
class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  static const List<String> _debugQrValues = [
    'CAMPUSGO_G_LIFT',
    'CAMPUSGO_L1_LIFT',
    'CAMPUSGO_L3_LIFT',
    'CAMPUSGO_L6_LIFT',
    'CAMPUSGO_L8_LIFT',
    'CAMPUSGO_L9_LIFT',
  ];

  final NavigationRepository _repository = NavigationRepository();

  late final MobileScannerController _scannerController =
      MobileScannerController(
        facing: CameraFacing.back,
        formats: const [BarcodeFormat.qrCode],
        detectionSpeed: DetectionSpeed.normal,
        detectionTimeoutMs: 750,
      );

  bool _isProcessing = false;
  String _statusMessage = 'Point the camera at a CampusGO QR checkpoint.';
  bool _statusIsError = false;
  String _debugQrValue = 'CAMPUSGO_L6_LIFT';

  String? _lastScanValue;
  DateTime? _lastScanTime;

  @override
  void dispose() {
    unawaited(_scannerController.dispose());
    super.dispose();
  }

  void _handleDetection(BarcodeCapture capture) {
    for (final barcode in capture.barcodes) {
      final rawValue = barcode.rawValue?.trim();
      if (rawValue == null || rawValue.isEmpty) continue;

      unawaited(_processScanValue(rawValue));
      return;
    }
  }

  /// Shared CampusGO QR pipeline used by both real and simulated scans.
  Future<void> _processScanValue(String rawValue) async {
    final normalizedValue = rawValue.trim();

    if (normalizedValue.isEmpty || _isProcessing) return;

    // Camera scanners can report the same visible QR repeatedly. A short
    // cooldown prevents duplicate Supabase requests and repeated error UI.
    final now = DateTime.now();
    final lastScanTime = _lastScanTime;
    if (_lastScanValue == normalizedValue &&
        lastScanTime != null &&
        now.difference(lastScanTime) < const Duration(seconds: 2)) {
      return;
    }

    _lastScanValue = normalizedValue;
    _lastScanTime = now;

    if (mounted) {
      setState(() {
        _isProcessing = true;
        _statusIsError = false;
        _statusMessage = 'Checking $normalizedValue...';
      });
    }

    await _stopScannerQuietly();

    var completedSuccessfully = false;

    try {
      // 1. qr_value -> qr_codes row.
      final qr = await _repository.findQrByValue(normalizedValue);

      if (qr == null) {
        _setStatus(
          'This QR code is not a registered CampusGO checkpoint.',
          isError: true,
        );
        return;
      }

      // 2. Reject known checkpoints that administrators have disabled.
      if (!qr.isActive) {
        _setStatus(
          'This CampusGO QR checkpoint is currently inactive.',
          isError: true,
        );
        return;
      }

      // 3. qr_codes.node_id -> active navigation node.
      final nodeId = qr.nodeId?.trim();
      if (nodeId == null || nodeId.isEmpty) {
        _setStatus(
          'This QR checkpoint is not linked to a navigation node.',
          isError: true,
        );
        return;
      }

      final node = await _repository.findActiveNodeById(nodeId);
      if (node == null) {
        _setStatus(
          'The location linked to this QR checkpoint is unavailable.',
          isError: true,
        );
        return;
      }

      // 4. Return the real NodeModel to HomeScreen. HomeScreen then feeds it
      // into its existing manual Current Location selection method.
      completedSuccessfully = true;
      if (mounted) {
        Navigator.of(context).pop<NodeModel>(node);
      }
    } on AppException catch (error, stackTrace) {
      debugPrint('CampusGO QR lookup failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      _setStatus(error.message, isError: true);
    } catch (error, stackTrace) {
      debugPrint('CampusGO QR processing failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      _setStatus(
        'CampusGO could not verify this QR checkpoint.',
        isError: true,
      );
    } finally {
      if (!completedSuccessfully && mounted) {
        setState(() {
          _isProcessing = false;
        });
        await _startScannerQuietly();
      }
    }
  }

  void _setStatus(String message, {required bool isError}) {
    if (!mounted) return;

    setState(() {
      _statusMessage = message;
      _statusIsError = isError;
    });
  }

  Future<void> _stopScannerQuietly() async {
    try {
      await _scannerController.stop();
    } catch (_) {
      // A simulator may not have an available camera. The debug scan path must
      // still be able to test the real Supabase and navigation logic.
    }
  }

  Future<void> _startScannerQuietly() async {
    try {
      await _scannerController.start();
    } catch (_) {
      // Keep the screen usable in debug mode even when the simulator camera is
      // unavailable. On a physical phone the camera should start normally.
    }
  }

  Widget _buildCameraError(BuildContext context, MobileScannerException error) {
    return Container(
      color: Colors.black,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.videocam_off_outlined,
            color: Colors.white,
            size: 52,
          ),
          const SizedBox(height: 14),
          const Text(
            'Camera unavailable',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            kDebugMode
                ? 'This is expected on some simulators. Use the Development '
                      'Test below to simulate a real QR value.'
                : 'Check camera permission and try again.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F9),
      appBar: AppBar(title: const Text('Scan QR Checkpoint')),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  MobileScanner(
                    controller: _scannerController,
                    onDetect: _handleDetection,
                    errorBuilder: _buildCameraError,
                  ),
                  IgnorePointer(
                    child: Center(
                      child: Container(
                        width: 230,
                        height: 230,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.white, width: 3),
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                  ),
                  if (_isProcessing)
                    Container(
                      color: Colors.black38,
                      alignment: Alignment.center,
                      child: const CircularProgressIndicator(),
                    ),
                ],
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    _statusMessage,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 14,
                      height: 1.35,
                      fontWeight: FontWeight.w600,
                      color: _statusIsError
                          ? const Color(0xFFB42318)
                          : const Color(0xFF26333C),
                    ),
                  ),
                  if (kDebugMode) ...[
                    const SizedBox(height: 18),
                    const Divider(height: 1),
                    const SizedBox(height: 14),
                    const Text(
                      'Development Test',
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF26333C),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Simulator only: this bypasses the camera, not the QR '
                      'logic. The selected value still goes through Supabase '
                      'and returns a real navigation node.',
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 12,
                        height: 1.35,
                        color: Color(0xFF7E8791),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButton<String>(
                            isExpanded: true,
                            value: _debugQrValue,
                            items: _debugQrValues
                                .map(
                                  (value) => DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(
                                      value,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                )
                                .toList(growable: false),
                            onChanged: _isProcessing
                                ? null
                                : (value) {
                                    if (value == null) return;
                                    setState(() {
                                      _debugQrValue = value;
                                    });
                                  },
                          ),
                        ),
                        const SizedBox(width: 12),
                        FilledButton.icon(
                          onPressed: _isProcessing
                              ? null
                              : () {
                                  unawaited(_processScanValue(_debugQrValue));
                                },
                          icon: const Icon(Icons.play_arrow),
                          label: const Text('Simulate scan'),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
