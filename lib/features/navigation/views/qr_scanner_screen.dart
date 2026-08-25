import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../core/exceptions/app_exception.dart';
import '../data/navigation_repository.dart';
import '../models/node_model.dart';

/// Scans a CampusGO QR checkpoint and returns the linked active [NodeModel].
class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
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

  /// Resolves a real camera scan through the CampusGO QR pipeline.
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
      // The controller may already be stopped while the screen is closing.
    }
  }

  Future<void> _startScannerQuietly() async {
    try {
      await _scannerController.start();
    } catch (_) {
      // The error builder gives the user camera-permission guidance.
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
          const Text(
            'Check camera permission and try again.',
            textAlign: TextAlign.center,
            style: TextStyle(
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
              child: Text(
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
            ),
          ],
        ),
      ),
    );
  }
}
