import 'package:flutter/material.dart';

abstract final class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF173F5F)),
      scaffoldBackgroundColor: const Color(0xFFF8F9FA),
    );
  }
}
