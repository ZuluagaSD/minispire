import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../features/home/home_screen.dart';
import '../features/inspiration/inspiration_screen.dart';
import '../features/chat/chat_screen.dart';
import '../features/gallery/gallery_screen.dart';

/// App routing configuration
final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    ShellRoute(
      builder: (context, state, child) => MainShell(child: child),
      routes: [
        GoRoute(
          path: '/',
          name: 'home',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: HomeScreen(),
          ),
        ),
        GoRoute(
          path: '/generate',
          name: 'generate',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: InspirationScreen(),
          ),
        ),
        GoRoute(
          path: '/chat',
          name: 'chat',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: ChatScreen(),
          ),
        ),
        GoRoute(
          path: '/gallery',
          name: 'gallery',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: GalleryScreen(),
          ),
        ),
      ],
    ),
  ],
);

/// Main shell with bottom navigation
class MainShell extends StatelessWidget {
  final Widget child;

  const MainShell({super.key, required this.child});

  int _calculateSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    if (location.startsWith('/generate')) return 1;
    if (location.startsWith('/chat')) return 2;
    if (location.startsWith('/gallery')) return 3;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _calculateSelectedIndex(context),
        onDestinationSelected: (index) {
          switch (index) {
            case 0:
              context.go('/');
              break;
            case 1:
              context.go('/generate');
              break;
            case 2:
              context.go('/chat');
              break;
            case 3:
              context.go('/gallery');
              break;
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.auto_awesome_outlined),
            selectedIcon: Icon(Icons.auto_awesome),
            label: 'Generate',
          ),
          NavigationDestination(
            icon: Icon(Icons.chat_outlined),
            selectedIcon: Icon(Icons.chat),
            label: 'Coach',
          ),
          NavigationDestination(
            icon: Icon(Icons.collections_outlined),
            selectedIcon: Icon(Icons.collections),
            label: 'Gallery',
          ),
        ],
      ),
    );
  }
}
