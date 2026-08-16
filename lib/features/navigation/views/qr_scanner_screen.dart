import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/constants/app_assets.dart';

/// Temporary destination for the current-location QR button.
///
/// Camera scanning and QR-to-node resolution will be implemented at the QR
/// checkpoint. Keeping this as a real route now allows both guest and
/// registered-user navigation flows to be tested without pretending that the
/// scanner is already complete.
class QrScannerScreen extends StatelessWidget {
  const QrScannerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan QR Checkpoint')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SvgPicture.asset(AppAssets.scanQr, width: 72, height: 72),
              const SizedBox(height: 20),
              const Text(
                'The CampusGO QR scanner will open here.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF26333C),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Camera scanning and QR-to-location selection are not enabled '
                'yet.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 14,
                  color: Color(0xFF7E8791),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
