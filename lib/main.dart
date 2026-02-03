import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'core/router.dart';
import 'shared/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print("✅ Firebase initialized successfully");
  } catch (e, stackTrace) {
    print("❌ Firebase initialization failed: $e");
    print("Stack trace: $stackTrace");
  }

  runApp(const ProviderScope(child: MinispireApp()));
}

class MinispireApp extends StatelessWidget {
  const MinispireApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Mini Inspire',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark, // Default to dark theme for painters
      routerConfig: appRouter,
      builder: (context, child) {
        // Wrap the entire app to dismiss keyboard when tapping outside text fields
        return GestureDetector(
          onTap: () {
            // Unfocus any text field to hide the keyboard
            FocusScope.of(context).unfocus();
          },
          child: child,
        );
      },
    );
  }
}
