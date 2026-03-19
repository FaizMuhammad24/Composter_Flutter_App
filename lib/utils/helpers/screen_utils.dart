import 'package:flutter/material.dart';

/// 📱 Screen Utilities - Aplikasi Monitoring Kompos
/// Helper functions untuk responsive design

class ScreenUtils {
  ScreenUtils._();

  // ==================== BREAKPOINTS ====================
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 900;

  // ==================== DEVICE TYPE CHECKS ====================
  /// Check if current device is mobile
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < mobileBreakpoint;
  }

  /// Check if current device is tablet
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= mobileBreakpoint && width < tabletBreakpoint;
  }

  /// Check if current device is desktop
  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= tabletBreakpoint;
  }

  // ==================== GRID HELPERS ====================
  /// Get cross axis count untuk GridView berdasarkan screen size
  static int getCrossAxisCount(BuildContext context, {int? mobile, int? tablet, int? desktop}) {
    if (isMobile(context)) return mobile ?? 1;
    if (isTablet(context)) return tablet ?? 2;
    return desktop ?? 3;
  }

  /// Get cross axis count untuk sensor grid (2 di mobile, 4 di tablet/desktop)
  static int getSensorGridCount(BuildContext context) {
    return isMobile(context) ? 2 : 4;
  }

  // ==================== SCREEN SIZE HELPERS ====================
  /// Get screen width
  static double screenWidth(BuildContext context) {
    return MediaQuery.of(context).size.width;
  }

  /// Get screen height
  static double screenHeight(BuildContext context) {
    return MediaQuery.of(context).size.height;
  }

  /// Get safe area padding top
  static double safeAreaTop(BuildContext context) {
    return MediaQuery.of(context).padding.top;
  }

  /// Get safe area padding bottom
  static double safeAreaBottom(BuildContext context) {
    return MediaQuery.of(context).padding.bottom;
  }

  // ==================== RESPONSIVE SPACING ====================
  /// Get responsive horizontal padding
  static double horizontalPadding(BuildContext context) {
    if (isMobile(context)) return 16.0;
    if (isTablet(context)) return 24.0;
    return 32.0;
  }

  /// Get responsive vertical padding
  static double verticalPadding(BuildContext context) {
    if (isMobile(context)) return 16.0;
    if (isTablet(context)) return 24.0;
    return 32.0;
  }

  // ==================== RESPONSIVE FONT SIZE ====================
  /// Get responsive font size multiplier
  static double fontSizeMultiplier(BuildContext context) {
    if (isMobile(context)) return 1.0;
    if (isTablet(context)) return 1.1;
    return 1.2;
  }
}
