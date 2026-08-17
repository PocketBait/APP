import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../friends/presentation/providers/friends_providers.dart';
import '../../../limits/presentation/providers/limits_providers.dart';

/// Contenedor con la barra de navegación inferior (Límites / Amigos /
/// Perfil). `navigationShell` lo provee go_router (`StatefulShellRoute`) y
/// preserva el estado/scroll de cada pestaña al cambiar entre ellas.
class HomeShell extends ConsumerWidget {
  const HomeShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Cuántas cosas están esperando que el usuario las vea/responda en
    // cada pestaña — se usan para la bolita roja de notificación.
    final pendingProposals = ref
        .watch(proposalsAwaitingMyResponseProvider)
        .maybeWhen(data: (list) => list.length, orElse: () => 0);
    final pendingFriendRequests = ref
        .watch(incomingRequestsProvider)
        .maybeWhen(data: (list) => list.length, orElse: () => 0);

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) => navigationShell.goBranch(
          index,
          // Si ya estás en esa pestaña, vuelve a su raíz en vez de apilar.
          initialLocation: index == navigationShell.currentIndex,
        ),
        destinations: [
          _navDestination(
            icon: Icons.timer_outlined,
            selectedIcon: Icons.timer,
            label: 'Límites',
            badgeCount: pendingProposals,
          ),
          _navDestination(
            icon: Icons.people_outline,
            selectedIcon: Icons.people,
            label: 'Amigos',
            badgeCount: pendingFriendRequests,
          ),
          const NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}

/// `NavigationDestination` con una bolita roja de notificación (estilo
/// Instagram) cuando `badgeCount > 0`.
NavigationDestination _navDestination({
  required IconData icon,
  required IconData selectedIcon,
  required String label,
  required int badgeCount,
}) {
  return NavigationDestination(
    icon: Badge(
      isLabelVisible: badgeCount > 0,
      label: Text('$badgeCount'),
      child: Icon(icon),
    ),
    selectedIcon: Badge(
      isLabelVisible: badgeCount > 0,
      label: Text('$badgeCount'),
      child: Icon(selectedIcon),
    ),
    label: label,
  );
}
