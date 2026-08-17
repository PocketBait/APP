import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/async_state_views.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../providers/friends_providers.dart';
import '../widgets/profile_avatar.dart';

class FriendsScreen extends StatelessWidget {
  const FriendsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Amigos'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Mis amigos'),
              Tab(text: 'Solicitudes'),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => context.push('/friends/add'),
          icon: const Icon(Icons.person_add_alt),
          label: const Text('Agregar'),
        ),
        body: const TabBarView(
          children: [_FriendsTab(), _RequestsTab()],
        ),
      ),
    );
  }
}

class _FriendsTab extends ConsumerWidget {
  const _FriendsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final friends = ref.watch(acceptedFriendsProvider);
    final userId = ref.watch(requireUserIdProvider);

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(friendRequestsProvider),
      child: friends.when(
        loading: () => const LoadingView(),
        error: (error, _) => ErrorView(
          message: error.toString(),
          onRetry: () => ref.invalidate(friendRequestsProvider),
        ),
        data: (list) {
          if (list.isEmpty) {
            return ListView(
              children: const [
                SizedBox(height: 80),
                EmptyStateView(
                  icon: Icons.people_outline,
                  title: 'Todavía no tienes amigos en PocketBait',
                  subtitle:
                      'Agrégalos por su usuario para empezar a ponerse '
                      'límites de tiempo de pantalla, de mutuo acuerdo.',
                ),
              ],
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: list.length,
            separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.xs),
            itemBuilder: (context, index) {
              final friend = list[index].otherProfile(userId);
              return Card(
                child: ListTile(
                  leading: ProfileAvatar(profile: friend),
                  title: Text(friend.displayName),
                  subtitle: Text('@${friend.username}'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () =>
                      context.push('/friends/profile', extra: friend),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _RequestsTab extends ConsumerWidget {
  const _RequestsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final incoming = ref.watch(incomingRequestsProvider);
    final outgoing = ref.watch(outgoingRequestsProvider);
    final actions = ref.watch(friendActionsControllerProvider);
    final userId = ref.watch(requireUserIdProvider);

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(friendRequestsProvider),
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          Text('Recibidas', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: AppSpacing.xs),
          incoming.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
              child: LoadingView(),
            ),
            error: (error, _) => ErrorView(message: error.toString()),
            data: (list) {
              if (list.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  child: Text('No tienes solicitudes nuevas.'),
                );
              }
              return Column(
                children: list.map((request) {
                  final from = request.otherProfile(userId);
                  return Card(
                    margin: const EdgeInsets.only(bottom: AppSpacing.xs),
                    child: ListTile(
                      leading: ProfileAvatar(profile: from),
                      title: Text(from.displayName),
                      subtitle: Text('@${from.username}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.check_circle),
                            color: Theme.of(context).colorScheme.primary,
                            tooltip: 'Aceptar',
                            onPressed: actions.isLoading
                                ? null
                                : () => ref
                                    .read(friendActionsControllerProvider
                                        .notifier)
                                    .respond(
                                        requestId: request.id, accept: true),
                          ),
                          IconButton(
                            icon: const Icon(Icons.cancel_outlined),
                            color: Theme.of(context).colorScheme.error,
                            tooltip: 'Rechazar',
                            onPressed: actions.isLoading
                                ? null
                                : () => ref
                                    .read(friendActionsControllerProvider
                                        .notifier)
                                    .respond(
                                        requestId: request.id, accept: false),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('Enviadas', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: AppSpacing.xs),
          outgoing.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
              child: LoadingView(),
            ),
            error: (error, _) => ErrorView(message: error.toString()),
            data: (list) {
              if (list.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  child: Text('No tienes solicitudes esperando respuesta.'),
                );
              }
              return Column(
                children: list.map((request) {
                  final to = request.otherProfile(userId);
                  return Card(
                    margin: const EdgeInsets.only(bottom: AppSpacing.xs),
                    child: ListTile(
                      leading: ProfileAvatar(profile: to),
                      title: Text(to.displayName),
                      subtitle: const Text('Esperando respuesta…'),
                      trailing: TextButton(
                        onPressed: actions.isLoading
                            ? null
                            : () => ref
                                .read(friendActionsControllerProvider.notifier)
                                .cancel(request.id),
                        child: const Text('Cancelar'),
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}
