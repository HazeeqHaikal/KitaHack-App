import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:due/utils/constants.dart';

/// A reusable container that provides a frosted glass effect (Glassmorphism).
class GlassContainer extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? borderRadius;
  final Color? color;
  final Color? borderColor;
  final bool hasShadow;
  final VoidCallback? onTap;

  const GlassContainer({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.padding,
    this.margin,
    this.borderRadius,
    this.color,
    this.borderColor,
    this.hasShadow = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final br = BorderRadius.circular(
      borderRadius ?? AppConstants.borderRadiusM,
    );

    Widget content = Container(
      width: width,
      height: height,
      padding: padding ?? const EdgeInsets.all(AppConstants.spacingM),
      decoration: BoxDecoration(
        color: color ?? AppConstants.glassSurface,
        borderRadius: br,
        border: Border.all(
          color: borderColor ?? AppConstants.glassBorder,
          width: 1.0,
        ),
        boxShadow: hasShadow
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ]
            : null,
      ),
      child: child,
    );

    // Apply ink effect if onTap is provided
    if (onTap != null) {
      content = Material(
        color: Colors.transparent,
        child: InkWell(onTap: onTap, borderRadius: br, child: content),
      );
    }

    return Container(
      margin: margin,
      child: ClipRRect(
        borderRadius: br,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
          child: content,
        ),
      ),
    );
  }
}
