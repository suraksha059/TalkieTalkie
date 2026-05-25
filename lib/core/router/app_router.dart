import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/talk/presentation/talk_screen.dart';
import '../../features/friends/presentation/friends_screen.dart';
import '../constants/app_colors.dart';

// Bottom navigation shell
class MainShell extends StatefulWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border(
            top: BorderSide(
              color: AppColors.surfaceLight.withValues(alpha: 0.5),
              width: 0.5,
            ),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() => _currentIndex = index);
            switch (index) {
              case 0:
                context.go('/talk');
                break;
              case 1:
                context.go('/friends');
                break;
            }
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.mic_rounded),
              activeIcon: Icon(Icons.mic_rounded),
              label: 'Talk',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.people_outline_rounded),
              activeIcon: Icon(Icons.people_rounded),
              label: 'Friends',
            ),
          ],
        ),
      ),
    );
  }
}

final _shellNavigatorKey = GlobalKey<NavigatorState>();
final _rootNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/talk',
    redirect: (context, state) {
      // Don't redirect while the auth state is still loading (initial boot)
      if (authState.isLoading) return null;

      final isLoggedIn = authState.valueOrNull != null;
      final isLoggingIn = state.matchedLocation == '/login';

      if (!isLoggedIn && !isLoggingIn) return '/login';
      if (isLoggedIn && isLoggingIn) return '/talk';
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: '/talk',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: TalkScreen()),
          ),
          GoRoute(
            path: '/friends',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: FriendsScreen()),
          ),
        ],
      ),
    ],
  );
});
