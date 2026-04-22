import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'theme_manager.dart';

import 'screens/login_screen.dart';
import 'screens/main_navigation_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeManager.themeMode,
      builder: (context, mode, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'InspireX',
          themeMode: mode,
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF6366F1), // Primary indigo seed
              brightness: Brightness.light,
            ).copyWith(
              primary: const Color(0xFF6366F1),
              secondary: const Color(0xFF818CF8),
              tertiary: const Color(0xFF4F46E5),
              surface: Colors.white,
              onSurface: const Color(0xFF1E293B),
            ),
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF6366F1),
              brightness: Brightness.dark,
            ).copyWith(
              primary: const Color(0xFF818CF8),
              secondary: const Color(0xFF6366F1),
              tertiary: const Color(0xFF4F46E5),
              surface: const Color(0xFF121212), // True black background
              surfaceContainer: const Color(0xFF1E1E1E), // Slightly lighter grey for cards
              surfaceContainerHighest: const Color(0xFF242424), // Even lighter for emphasis
              onSurface: const Color(0xFFFFFFFF), // Pure white text
              onSurfaceVariant: const Color(0xFF888888), // Muted grey for secondary text
              outline: const Color(0xFF333333), // Subtle dark grey borders
              outlineVariant: const Color(0xFF404040), // Slightly lighter borders
            ),
          ),
          initialRoute: '/login',
          routes: {
            '/login': (_) => const LoginScreen(),
            '/home': (_) => const MainNavigationScreen(),
          },
        );
      },
    );
  }
}
