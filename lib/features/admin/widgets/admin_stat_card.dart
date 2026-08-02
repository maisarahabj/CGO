import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/constants/app_assets.dart';

/// One task row inside the administrator dashboard summary card.
class AdminStatCard extends StatelessWidget {
  const AdminStatCard({
    required this.label,
    required this.count,
    required this.onPressed,
    super.key,
  });

  final String label;
  final int count;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E1E1E),
                    height: 1.15,
                  ),
                ),
              ),
              Container(
                constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: const BoxDecoration(
                  color: Color(0xFFFF3F46),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '$count',
                  style: const TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    height: 1,
                  ),
                ),
              ),
              const SizedBox(width: 9),
              SvgPicture.asset(
                AppAssets.moreRightArrow,
                width: 9,
                height: 16,
                fit: BoxFit.contain,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
