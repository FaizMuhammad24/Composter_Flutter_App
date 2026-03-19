import 'package:flutter/material.dart';
import '../../../constants/app_colors.dart';
import '../../../constants/app_spacing.dart';

/// Card konsisten untuk seluruh aplikasi
class CustomCard extends StatelessWidget {
  final Widget child;
  final Color? color;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final double? elevation;
  final Gradient? gradient;

  const CustomCard({
    Key? key,
    required this.child,
    this.color,
    this.padding,
    this.margin,
    this.onTap,
    this.elevation,
    this.gradient,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final cardChild = Container(
      padding: padding ?? const EdgeInsets.all(AppSpacing.paddingCard),
      decoration: gradient != null
          ? BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            )
          : null,
      child: child,
    );

    return Container(
      margin: margin,
      child: Card(
        color: gradient != null ? Colors.transparent : (color ?? AppColors.surface),
        elevation: elevation ?? AppSpacing.elevation2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        child: onTap != null
            ? InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                child: cardChild,
              )
            : cardChild,
      ),
    );
  }
}
