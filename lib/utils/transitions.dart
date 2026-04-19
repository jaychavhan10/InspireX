import 'package:flutter/material.dart';

/// Custom page route with smooth fade and slide transition
class SmoothPageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;

  SmoothPageRoute({required this.page})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            // Fade animation
            final fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeInOut),
            );

            // Slide animation (from right)
            final slideAnimation = Tween<Offset>(
              begin: const Offset(0.3, 0.0),
              end: Offset.zero,
            ).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeInOut),
            );

            return FadeTransition(
              opacity: fadeAnimation,
              child: SlideTransition(
                position: slideAnimation,
                child: child,
              ),
            );
          },
          transitionDuration: const Duration(milliseconds: 400),
        );
}

/// Helper function to navigate with smooth transition
Future<T?> navigateSmoothly<T>(
  BuildContext context,
  Widget page, {
  bool replacement = false,
}) {
  if (replacement) {
    return Navigator.of(context).pushReplacement<T, T>(
      SmoothPageRoute<T>(page: page),
    );
  } else {
    return Navigator.of(context).push<T>(
      SmoothPageRoute<T>(page: page),
    );
  }
}

/// Helper function for named route navigation with smooth transition
Future<T?> navigateNamedSmoothly<T>(
  BuildContext context,
  String routeName, {
  Object? arguments,
  bool replacement = false,
}) {
  // This is for named routes defined in MaterialApp.routes
  // We'll use the standard navigation but could enhance later
  if (replacement) {
    return Navigator.pushReplacementNamed(context, routeName, arguments: arguments);
  } else {
    return Navigator.pushNamed(context, routeName, arguments: arguments);
  }
}

/// Pop with reverse animation
void popSmoothly(BuildContext context, {dynamic result}) {
  Navigator.pop(context, result);
}
