import 'package:flutter/material.dart';

/// 🔲 Border Radius Constants - Aplikasi Monitoring Kompos
/// Gunakan class ini untuk konsistensi border radius di seluruh aplikasi

class AppRadius {
  AppRadius._();

  // ==================== RADIUS VALUES ====================
  /// Small - 8px
  static const double sm = 8.0;

  /// Medium - 12px (Default untuk cards)
  static const double md = 12.0;

  /// Large - 16px
  static const double lg = 16.0;

  /// Extra Large - 24px
  static const double xl = 24.0;

  /// Circle - 100px (untuk avatar, dll)
  static const double circle = 100.0;

  // ==================== BORDER RADIUS OBJECTS ====================
  /// Small BorderRadius
  static BorderRadius borderRadiusSm = BorderRadius.circular(sm);

  /// Medium BorderRadius (Default)
  static BorderRadius borderRadiusMd = BorderRadius.circular(md);

  /// Large BorderRadius
  static BorderRadius borderRadiusLg = BorderRadius.circular(lg);

  /// Extra Large BorderRadius
  static BorderRadius borderRadiusXl = BorderRadius.circular(xl);

  /// Circle BorderRadius
  static BorderRadius borderRadiusCircle = BorderRadius.circular(circle);

  // ==================== ROUNDED RECTANGLE BORDERS ====================
  /// Small RoundedRectangleBorder
  static RoundedRectangleBorder shapeSm = RoundedRectangleBorder(
    borderRadius: borderRadiusSm,
  );

  /// Medium RoundedRectangleBorder
  static RoundedRectangleBorder shapeMd = RoundedRectangleBorder(
    borderRadius: borderRadiusMd,
  );

  /// Large RoundedRectangleBorder
  static RoundedRectangleBorder shapeLg = RoundedRectangleBorder(
    borderRadius: borderRadiusLg,
  );

  /// Extra Large RoundedRectangleBorder
  static RoundedRectangleBorder shapeXl = RoundedRectangleBorder(
    borderRadius: borderRadiusXl,
  );
}
