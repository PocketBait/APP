import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/friends/presentation/screens/add_friend_screen.dart';
import '../../features/friends/presentation/screens/friends_screen.dart';
import '../../features/home/presentation/screens/home_shell.dart';
import '../../features/limits/domain/permission_grant.dart';
import '../../features/limits/presentation/screens/create_proposal_screen.dart';
import '../../features/limits/presentation/screens/grant_access_screen.dart';
import '../../features/limits/presentation/screens/limits_home_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../providers/core_providers.dart';
import 'go_router_refresh_stream.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);

  return GoRouter(
    initialLocation: '/',
    refreshListenable:
        GoRouterRefreshStream(authRepository.onAuthStateChange),
    redirect: (context, state) {
      final isAuthenticated = authRepository.currentSession != null;
      final isLoggingIn = state.matchedLocation == '/login';

      if (!isAuthenticated && !isLoggingIn) return '/login';
      if (isAuthenticated && isLoggingIn) return '/';
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            HomeShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/',
              builder: (context, state) => const LimitsHomeScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/friends',
              builder: (context, state) => const FriendsScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/profile',
              builder: (context, state) => const ProfileScreen(),
            ),
          ]),
        ],
      ),
      // Pantallas "modales": se apilan por encima del shell (sin barra de
      // navegación inferior), por eso no viven dentro de las branches.
      GoRoute(
        path: '/friends/add',
        builder: (context, state) => const AddFriendScreen(),
      ),
      GoRoute(
        path: '/limits/grant-access',
        builder: (context, state) => const GrantAccessScreen(),
      ),
      GoRoute(
        path: '/limits/propose',
        builder: (context, state) =>
            CreateProposalScreen(grant: state.extra as PermissionGrant),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(child: Text('Ruta no encontrada: ${state.uri}')),
    ),
  );
});
