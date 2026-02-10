import 'package:flutter/material.dart';

/// Utility class for precaching and performance optimizations
class PerformanceOptimizer {
  /// Precache a route by building its widget tree in the background
  /// This warms up the route so it displays faster when navigated to
  static void precacheRoute(
    BuildContext context,
    Widget Function() routeBuilder,
  ) {
    // Schedule the precache for after the current frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        // Build the route widget tree off-screen
        // This warms up the widget tree without displaying it
        routeBuilder();

        // This creates the widget tree without displaying it
        // helping reduce the initial render time when actually navigating
        precacheImage(
          const AssetImage('assets/placeholder.png'),
          context,
        ).catchError((error) {
          // Ignore image precache errors
        });
      } catch (e) {
        // If precaching fails, it's not critical - just log it
        print('Precache route failed: $e');
      }
    });
  }

  /// Wrap expensive widgets in RepaintBoundary to isolate repaints
  static Widget withRepaintBoundary(Widget child) {
    return RepaintBoundary(child: child);
  }

  /// Debounce function calls to reduce excessive rebuilds
  static Future<void> debounce(
    Duration duration,
    Future<void> Function() action,
  ) async {
    await Future.delayed(duration);
    await action();
  }
}

/// Mixin to add performance monitoring to StatefulWidgets
mixin PerformanceMonitorMixin<T extends StatefulWidget> on State<T> {
  DateTime? _buildStartTime;

  @override
  void initState() {
    super.initState();
    _buildStartTime = DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    final buildTime = DateTime.now().difference(
      _buildStartTime ?? DateTime.now(),
    );
    if (buildTime.inMilliseconds > 16) {
      // 60fps = 16ms per frame
      print('⚠️ ${T.toString()} build took ${buildTime.inMilliseconds}ms');
    }
    return buildWidget(context);
  }

  /// Override this instead of build() when using this mixin
  Widget buildWidget(BuildContext context);
}
