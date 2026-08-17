import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../limits/domain/permission_grant.dart';
import '../../../limits/presentation/providers/limits_providers.dart';
import '../../domain/friend_request.dart';
import '../../domain/profile.dart';
import '../providers/friends_providers.dart';
import '../widgets/profile_avatar.dart';

const _reportReasons = [
  'Spam',
  'Acoso o bullying',
  'Contenido inapropiado',
  'Se hace pasar por otra persona',
  'Otro',
];

class FriendProfileScreen extends ConsumerWidget {
  const FriendProfileScreen({super.key, required this.profile});

  final Profile profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(requireUserIdProvider);
    final actions = ref.watch(friendActionsControllerProvider);
    final grantActions = ref.watch(grantActionsControllerProvider);
    final mutualCount = ref.watch(mutualFriendsCountProvider(profile.id));

    final friendSince = ref.watch(acceptedFriendsProvider).maybeWhen(
          data: (list) {
            FriendRequest? match;
            for (final r in list) {
              if (r.isBetween(userId, profile.id)) {
                match = r;
                break;
              }
            }
            return match?.createdAt;
          },
          orElse: () => null,
        );

    final grantToThem = ref.watch(grantsIGaveProvider).maybeWhen(
          data: (list) {
            PermissionGrant? match;
            for (final g in list) {
              if (g.trusteeId == profile.id && g.status == GrantStatus.active) {
                match = g;
                break;
              }
            }
            return match;
          },
          orElse: () => null,
        );

    ref.listen(friendActionsControllerProvider, (previous, next) {
      final error = next.error;
      if (error != null) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(error.toString())));
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(profile.displayName),
        actions: [
          PopupMenuButton<String>(
            enabled: !actions.isLoading,
            onSelected: (value) {
              switch (value) {
                case 'remove':
                  _confirmRemoveFriend(context, ref);
                case 'block':
                  _confirmBlock(context, ref);
                case 'report':
                  _openReportSheet(context, ref);
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'remove',
                child: Text('Dejar de ser amigos'),
              ),
              PopupMenuItem(
                value: 'block',
                child: Text('Bloquear'),
              ),
              PopupMenuItem(
                value: 'report',
                child: Text('Reportar'),
              ),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Center(
            child: Column(
              children: [
                ProfileAvatar(profile: profile, radius: 44),
                const SizedBox(height: AppSpacing.sm),
                Text(profile.displayName,
                    style: Theme.of(context).textTheme.titleLarge),
                Text('@${profile.username}',
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(
                            color: Theme.of(context).colorScheme.outline)),
                const SizedBox(height: AppSpacing.xs),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: AppSpacing.sm,
                  children: [
                    if (friendSince != null)
                      Text(
                        'Amigos desde ${_formatDate(friendSince)}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    mutualCount.when(
                      data: (count) => count > 0
                          ? Text(
                              '$count ${count == 1 ? "amigo en común" : "amigos en común"}',
                              style: Theme.of(context).textTheme.bodySmall,
                            )
                          : const SizedBox.shrink(),
                      loading: () => const SizedBox.shrink(),
                      error: (_, _) => const SizedBox.shrink(),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Acceso para proponerte límites',
                            style: Theme.of(context).textTheme.titleSmall),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          grantToThem != null
                              ? '${profile.displayName} puede proponerte límites de tiempo.'
                              : '${profile.displayName} no puede proponerte límites todavía.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  grantToThem != null
                      ? OutlinedButton(
                          onPressed: grantActions.isLoading
                              ? null
                              : () => ref
                                  .read(grantActionsControllerProvider.notifier)
                                  .revoke(grantToThem.id),
                          child: const Text('Quitar'),
                        )
                      : FilledButton(
                          onPressed: grantActions.isLoading
                              ? null
                              : () => ref
                                  .read(grantActionsControllerProvider.notifier)
                                  .grantAccess(profile.id),
                          child: const Text('Dar acceso'),
                        ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/${date.year}';

  Future<void> _confirmRemoveFriend(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Dejar de ser amigos?'),
        content: Text(
          'Ya no podrás ver a ${profile.displayName} en tu lista de amigos, '
          'y se quita cualquier acceso que se hayan dado el uno al otro.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Dejar de ser amigos'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref
        .read(friendActionsControllerProvider.notifier)
        .removeFriend(profile.id);
    if (context.mounted && ref.read(friendActionsControllerProvider).error == null) {
      context.pop();
    }
  }

  Future<void> _confirmBlock(BuildContext context, WidgetRef ref) async {
    final scheme = Theme.of(context).colorScheme;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('¿Bloquear a ${profile.displayName}?'),
        content: const Text(
          'No podrá volver a agregarte ni proponerte límites, y deja de ser '
          'tu amigo.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: scheme.error),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Bloquear'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(friendActionsControllerProvider.notifier).blockUser(profile.id);
    if (context.mounted && ref.read(friendActionsControllerProvider).error == null) {
      context.pop();
    }
  }

  Future<void> _openReportSheet(BuildContext context, WidgetRef ref) async {
    final result = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(AppSpacing.md),
              child: Text('¿Por qué reportas esta cuenta?'),
            ),
            for (final reason in _reportReasons)
              ListTile(
                title: Text(reason),
                onTap: () => Navigator.of(context).pop(reason),
              ),
          ],
        ),
      ),
    );
    if (result == null) return;
    await ref.read(friendActionsControllerProvider.notifier).reportUser(
          otherUserId: profile.id,
          reason: result,
        );
    if (context.mounted && ref.read(friendActionsControllerProvider).error == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gracias, ya recibimos tu reporte.')),
      );
    }
  }
}
