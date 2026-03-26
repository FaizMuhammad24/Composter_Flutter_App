import 'package:flutter/material.dart';

/// Sistem warna aplikasi - GUNAKAN INI DI SEMUA SCREENS
class AppColors {
  AppColors._();

  // Primary
  static const Color primary = Color(0xFF2D5016);
  static const Color primaryLight = Color(0xFF4A7C2B);
  
  // Sensor
  static const Color temperature = Color(0xFFFF6B35);
  static const Color humidity = Color(0xFF2196F3);
  static const Color ph = Color(0xFF9C27B0);
  static const Color gas = Color(0xFFE53935);

  // Status
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color error = Color(0xFFF44336);
  static const Color info = Color(0xFF2196F3); // Blue for info
  
  // Role Colors (Specific themes for each role)
  static const Color superAdminPrimary = Color(0xFFD32F2F); // Red
  static const Color superAdminBg = Color(0xFFFFEBEE);      // Lightest red
  static const Color adminPrimary = Color(0xFFFBC02D);      // Yellow/Amber
  static const Color adminBg = Color(0xFFFFF8E1);           // Lightest yellow
  static const Color admin = Color(0xFFFBC02D);
  static const Color superAdmin = Color(0xFFD32F2F);
  static const Color user = Color(0xFF2D5016); // User stays Green

  // Neutral
  static const Color background = Color(0xFFF5F5DC);
  static const Color surface = Colors.white;
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
}
