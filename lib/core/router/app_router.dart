import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/sign_up_screen.dart';
import '../../features/auth/presentation/screens/update_password_screen.dart';
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

// Rutas accesibles sin sesión activa (formularios de login/registro).
const _publicRoutes = {'/login', '/signup', '/forgot-password'};

final routerProvider = Provider<GoRouter>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);

  // Recordamos el último evento de auth para poder distinguir "sesión
  // normal" de "sesión de recuperación de contraseña" dentro del
  // redirect — GoRouter no nos da el evento directamente, solo el estado
  // de sesión actual.
  AuthChangeEvent? lastAuthEvent;
  final refreshStream = authRepository.onAuthStateChange.map((state) {
    lastAuthEvent = state.event;
    return state;
  });

  return GoRouter(
    initialLocation: '/',
    refreshListenable: GoRouterRefreshStream(refreshStream),
    redirect: (context, state) {
      final isAuthenticated = authRepository.currentSession != null;
      final location = state.matchedLocation;

      // El link del correo "olvidé mi contraseña" crea una sesión
      // temporal y dispara este evento — hay que llevar a la pantalla de
      // nueva contraseña en vez de a la app normal.
      if (lastAuthEvent == AuthChangeEvent.passwordRecovery &&
          location != '/update-password') {
        return '/update-password';
      }

      if (location == '/update-password') {
        // Solo se puede estar aquí con una sesión (de recuperación)
        // activa; si no, no tiene caso mostrarla.
        return isAuthenticated ? null : '/login';
      }

      if (!isAuthenticated && !_publicRoutes.contains(location)) {
        return '/login';
      }
      if (isAuthenticated && _publicRoutes.contains(location)) {
        return '/';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignUpScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/update-password',
        builder: (context, state) => const UpdatePasswordScreen(),
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
