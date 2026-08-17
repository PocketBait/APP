import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/async_state_views.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../friends/presentation/providers/friends_providers.dart';
import '../../../friends/presentation/widgets/profile_avatar.dart';
import '../providers/limits_providers.dart';

/// Elegir a qué amigo(s) darles acceso para que te propongan límites de
/// tiempo. Solo aparecen amigos ya aceptados — es la misma regla que
/// impone la base de datos (ver policy de `permission_grants`).
class GrantAccessScreen extends ConsumerWidget {
  const GrantAccessScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final friends = ref.watch(acceptedFriendsProvider);
    final grantsIGave = ref.watch(grantsIGaveProvider);
    final userId = ref.watch(requireUserIdProvider);
    final actions = ref.watch(grantActionsControllerProvider);

    ref.listen(grantActionsControllerProvider, (previous, next) {
      final error = next.error;
      if (error != null) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(error.toString())));
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Dar acceso a un amigo')),
      body: friends.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(message: e.toString()),
        data: (friendList) {
          if (friendList.isEmpty) {
            return const EmptyStateView(
              icon: Icons.people_outline,
              title: 'Todavía no tienes amigos',
              subtitle: 'Agrega amigos primero desde la pestaña "Amigos".',
            );
          }
          final grantedIds = grantsIGave.maybeWhen(
            data: (list) => list.map((g) => g.trusteeId).toSet(),
            orElse: () => <String>{},
          );
          return ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: friendList.length,
            separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.xs),
            itemBuilder: (context, index) {
              final friend = friendList[index].otherProfile(userId);
              final alreadyGranted = grantedIds.contains(friend.id);
              return Card(
                child: ListTile(
                  leading: ProfileAvatar(profile: friend),
                  title: Text(friend.displayName),
                  subtitle: Text('@${friend.username}'),
                  trailing: alreadyGranted
                      ? const Chip(label: Text('Ya tiene acceso'))
                      : FilledButton(
                          onPressed: actions.isLoading
                              ? null
                              : () => ref
                                  .read(grantActionsControllerProvider.notifier)
                                  .grantAccess(friend.id),
                          child: const Text('Dar acceso'),
                        ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
