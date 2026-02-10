import 'package:flutter/material.dart';

/// Custom page route transitions for smooth navigation
class RouteTransitions {
  /// Fade transition - most subtle and professional
  static PageRouteBuilder<T> fadeTransition<T>({
    required Widget page,
    RouteSettings? settings,
    Duration duration = const Duration(milliseconds: 300),
  }) {
    return PageRouteBuilder<T>(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: CurvedAnimation(
            parent: animation,
            curve: Curves.easeInOutCubicEmphasized,
          ),
          child: child,
        );
      },
    );
  }

  /// Slide from bottom transition - iOS-style, natural feel
  static PageRouteBuilder<T> slideFromBottomTransition<T>({
    required Widget page,
    RouteSettings? settings,
    Duration duration = const Duration(milliseconds: 350),
  }) {
    return PageRouteBuilder<T>(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(0.0, 1.0);
        const end = Offset.zero;
        final tween = Tween(begin: begin, end: end);
        final offsetAnimation = animation.drive(
          tween.chain(CurveTween(curve: Curves.easeInOutCubicEmphasized)),
        );

        return SlideTransition(position: offsetAnimation, child: child);
      },
    );
  }

  /// Scale + fade transition - modern, polished
  static PageRouteBuilder<T> scaleFadeTransition<T>({
    required Widget page,
    RouteSettings? settings,
    Duration duration = const Duration(milliseconds: 300),
  }) {
    return PageRouteBuilder<T>(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.easeInOutCubicEmphasized,
        );

        return FadeTransition(
          opacity: curvedAnimation,
          child: ScaleTransition(
            scale: Tween<double>(
              begin: 0.92,
              end: 1.0,
            ).animate(curvedAnimation),
            child: child,
          ),
        );
      },
    );
  }

  /// Shared axis transition - Material Design 3
  static PageRouteBuilder<T> sharedAxisTransition<T>({
    required Widget page,
    RouteSettings? settings,
    Duration duration = const Duration(milliseconds: 300),
  }) {
    return PageRouteBuilder<T>(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(0.03, 0.0);
        const end = Offset.zero;
        const reversedBegin = Offset(-0.03, 0.0);

        final offsetAnimation = animation.drive(
          Tween(
            begin: begin,
            end: end,
          ).chain(CurveTween(curve: Curves.easeInOutCubicEmphasized)),
        );

        final secondaryOffsetAnimation = secondaryAnimation.drive(
          Tween(
            begin: end,
            end: reversedBegin,
          ).chain(CurveTween(curve: Curves.easeInOutCubicEmphasized)),
        );

        final fadeAnimation = CurvedAnimation(
          parent: animation,
          curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
        );

        final secondaryFadeAnimation = CurvedAnimation(
          parent: secondaryAnimation,
          curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
        );

        return SlideTransition(
          position: offsetAnimation,
          child: FadeTransition(
            opacity: fadeAnimation,
            child: SlideTransition(
              position: secondaryOffsetAnimation,
              child: FadeTransition(
                opacity: Tween<double>(
                  begin: 1.0,
                  end: 0.6,
                ).animate(secondaryFadeAnimation),
                child: child,
              ),
            ),
          ),
        );
      },
    );
  }

  /// Helper method to get the default transition for the app
  static PageRouteBuilder<T> defaultTransition<T>({
    required Widget page,
    RouteSettings? settings,
  }) {
    return fadeTransition<T>(page: page, settings: settings);
  }
}

/// Extension method for easy navigation with custom transitions
extension NavigatorExtensions on NavigatorState {
  /// Push with fade transition
  Future<T?> pushWithFade<T>(Widget page) {
    return push<T>(RouteTransitions.fadeTransition(page: page));
  }

  /// Push named with fade transition
  Future<T?> pushNamedWithFade<T>(String routeName, {Object? arguments}) {
    return pushNamed<T>(routeName, arguments: arguments);
  }

  /// Replace with fade transition
  Future<T?> pushReplacementWithFade<T, TO>(Widget page, {TO? result}) {
    return pushReplacement<T, TO>(
      RouteTransitions.fadeTransition(page: page),
      result: result,
    );
  }
}
