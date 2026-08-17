import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/async_state_views.dart';
import '../../domain/limit_proposal.dart';
import '../../domain/permission_grant.dart';
import '../../../friends/domain/profile.dart';
import '../../../friends/presentation/widgets/profile_avatar.dart';
import '../providers/limits_providers.dart';
import '../widgets/proposal_card.dart';

class LimitsHomeScreen extends ConsumerWidget {
  const LimitsHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pending = ref.watch(proposalsAwaitingMyResponseProvider);
    final active = ref.watch(activeLimitsOnMeProvider);
    final grantsIGave = ref.watch(grantsIGaveProvider);
    final grantsIReceived = ref.watch(grantsIReceivedProvider);
    final proposalsIMade = ref.watch(proposalsIMadeProvider);
    final proposalActions = ref.watch(proposalActionsControllerProvider);
    final grantActions = ref.watch(grantActionsControllerProvider);

    Future<void> refreshAll() async {
      ref.invalidate(myProposalsProvider);
      ref.invalidate(myGrantsProvider);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Límites')),
      body: RefreshIndicator(
        onRefresh: refreshAll,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            _SectionHeader(
              title: 'Debo responder',
              subtitle: 'Propuestas que te hicieron amigos con acceso',
            ),
            pending.when(
              loading: () => const LoadingView(),
              error: (e, _) => ErrorView(message: e.toString()),
              data: (list) => list.isEmpty
                  ? const _EmptyRow('No tienes propuestas pendientes.')
                  : Column(
                      children: list
                          .map((p) => ProposalCard(
                                proposal: p,
                                counterpart: p.proposerProfile,
                                counterpartLabel: 'te propone este límite',
                                trailing: Row(
                                  children: [
                                    Expanded(
                                      child: FilledButton(
                                        onPressed: proposalActions.isLoading
                                            ? null
                                            : () => ref
                                                .read(
                                                    proposalActionsControllerProvider
                                                        .notifier)
                                                .respond(
                                                    proposalId: p.id,
                                                    accept: true),
                                        child: const Text('Aceptar'),
                                      ),
                                    ),
                                    const SizedBox(width: AppSpacing.sm),
                                    Expanded(
                                      child: OutlinedButton(
                                        onPressed: proposalActions.isLoading
                                            ? null
                                            : () => ref
                                                .read(
                                                    proposalActionsControllerProvider
                                                        .notifier)
                                                .respond(
                                                    proposalId: p.id,
                                                    accept: false),
                                        child: const Text('Rechazar'),
                                      ),
                                    ),
                                  ],
                                ),
                              ))
                          .toList(),
                    ),
            ),
            const SizedBox(height: AppSpacing.lg),
            _SectionHeader(
              title: 'Mis límites activos',
              subtitle: 'Lo que ya aceptaste y sigue vigente',
            ),
            active.when(
              loading: () => const LoadingView(),
              error: (e, _) => ErrorView(message: e.toString()),
              data: (list) => list.isEmpty
                  ? const _EmptyRow('No tienes límites activos ahora mismo.')
                  : Column(
                      children: list
                          .map((p) => ProposalCard(
                                proposal: p,
                                counterpart: p.proposerProfile,
                                counterpartLabel: 'te puso este límite',
                              ))
                          .toList(),
                    ),
            ),
            const SizedBox(height: AppSpacing.lg),
            _SectionHeader(
              title: 'Le doy acceso a',
              subtitle: 'Amigos que pueden proponerte límites a ti',
              action: TextButton.icon(
                onPressed: () => context.push('/limits/grant-access'),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Dar acceso'),
              ),
            ),
            grantsIGave.when(
              loading: () => const LoadingView(),
              error: (e, _) => ErrorView(message: e.toString()),
              data: (list) {
                final activeGrants =
                    list.where((g) => g.status == GrantStatus.active).toList();
                if (activeGrants.isEmpty) {
                  return const _EmptyRow(
                      'No le has dado acceso a nadie todavía.');
                }
                return Column(
                  children: activeGrants
                      .map((g) => _GrantTile(
                            profile: g.trusteeProfile,
                            trailing: TextButton(
                              onPressed: grantActions.isLoading
                                  ? null
                                  : () => ref
                                      .read(grantActionsControllerProvider
                                          .notifier)
                                      .revoke(g.id),
                              child: const Text('Quitar'),
                            ),
                          ))
                      .toList(),
                );
              },
            ),
            const SizedBox(height: AppSpacing.lg),
            _SectionHeader(
              title: 'Tengo acceso sobre',
              subtitle: 'Amigos a los que puedes proponerles un límite',
            ),
            grantsIReceived.when(
              loading: () => const LoadingView(),
              error: (e, _) => ErrorView(message: e.toString()),
              data: (list) {
                final activeGrants =
                    list.where((g) => g.status == GrantStatus.active).toList();
                if (activeGrants.isEmpty) {
                  return const _EmptyRow(
                      'Ningún amigo te ha dado acceso todavía.');
                }
                return Column(
                  children: activeGrants
                      .map((g) => _GrantTile(
                            profile: g.ownerProfile,
                            trailing: FilledButton.tonal(
                              onPressed: () => context.push(
                                '/limits/propose',
                                extra: g,
                              ),
                              child: const Text('Proponer'),
                            ),
                          ))
                      .toList(),
                );
              },
            ),
            const SizedBox(height: AppSpacing.lg),
            _SectionHeader(
              title: 'Propuestas que hice',
              subtitle: 'Seguimiento de lo que le propusiste a tus amigos',
            ),
            proposalsIMade.when(
              loading: () => const LoadingView(),
              error: (e, _) => ErrorView(message: e.toString()),
              data: (list) => list.isEmpty
                  ? const _EmptyRow('Aún no le has propuesto nada a nadie.')
                  : Column(
                      children: list
                          .map((p) => ProposalCard(
                                proposal: p,
                                counterpart: p.ownerProfile,
                                counterpartLabel:
                                    _proposalStatusLabel(p.status),
                                trailing: p.status == ProposalStatus.pending
                                    ? Align(
                                        alignment: Alignment.centerRight,
                                        child: TextButton(
                                          onPressed: proposalActions.isLoading
                                              ? null
                                              : () => ref
                                                  .read(
                                                      proposalActionsControllerProvider
                                                          .notifier)
                                                  .cancel(p.id),
                                          child: const Text('Cancelar'),
                                        ),
                                      )
                                    : null,
                              ))
                          .toList(),
                    ),
            ),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }
}

String _proposalStatusLabel(ProposalStatus status) => switch (status) {
      ProposalStatus.pending => 'esperando su respuesta…',
      ProposalStatus.accepted => 'aceptó tu propuesta ✅',
      ProposalStatus.rejected => 'rechazó tu propuesta',
      ProposalStatus.cancelled => 'propuesta cancelada',
    };

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.subtitle, this.action});

  final String title;
  final String? subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        )),
                if (subtitle != null)
                  Text(subtitle!,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: scheme.outline)),
              ],
            ),
          ),
          ?action,
        ],
      ),
    );
  }
}

class _EmptyRow extends StatelessWidget {
  const _EmptyRow(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Text(
        text,
        style: Theme.of(context)
            .textTheme
            .bodyMedium
            ?.copyWith(color: Theme.of(context).colorScheme.outline),
      ),
    );
  }
}

class _GrantTile extends StatelessWidget {
  const _GrantTile({
    required this.profile,
    required this.trailing,
  });

  final Profile profile;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: ListTile(
        leading: ProfileAvatar(profile: profile),
        title: Text(profile.displayName),
        subtitle: Text('@${profile.username}'),
        trailing: trailing,
      ),
    );
  }
}
