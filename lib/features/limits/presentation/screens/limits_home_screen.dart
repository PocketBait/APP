import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/friendly_date.dart';
import '../../../../core/widgets/async_state_views.dart';
import '../../domain/limit_proposal.dart';
import '../../domain/permission_grant.dart';
import '../../../friends/domain/profile.dart';
import '../../../friends/presentation/widgets/profile_avatar.dart';
import '../providers/limits_providers.dart';
import '../widgets/proposal_card.dart';

class LimitsHomeScreen extends StatelessWidget {
  const LimitsHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(title: const Text('Límites')),
        body: const Column(
          children: [
            _HeroSection(),
            TabBar(
              tabs: [
                Tab(text: 'Activos'),
                Tab(text: 'Pendientes'),
                Tab(text: 'Accesos'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [_ActiveTab(), _PendingTab(), _AccessTab()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Tarjeta destacada arriba de todo: lo más urgente que tienes ahora
/// mismo (una propuesta por responder), o si no hay nada urgente, un
/// resumen amigable de tu situación.
class _HeroSection extends ConsumerWidget {
  const _HeroSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final pending = ref.watch(proposalsAwaitingMyResponseProvider).valueOrNull;
    final active = ref.watch(activeLimitsOnMeProvider).valueOrNull;

    if (pending != null && pending.isNotEmpty) {
      final proposal = pending.first;
      final extra = pending.length - 1;
      return _HeroCard(
        color: scheme.primary,
        onColor: scheme.onPrimary,
        leading: ProfileAvatar(profile: proposal.proposerProfile, radius: 22),
        title: '${proposal.proposerProfile.displayName} te propuso un límite',
        subtitle: extra > 0
            ? 'Y tienes $extra ${extra == 1 ? "propuesta más" : "propuestas más"} esperando'
            : '¿La aceptas o la rechazas?',
        buttonLabel: 'Ver propuesta',
        onPressed: () => DefaultTabController.of(context).animateTo(1),
      );
    }

    if (active != null && active.isNotEmpty) {
      final nextToEnd = [...active]
        ..sort((a, b) => a.endsAt.compareTo(b.endsAt));
      final soonest = nextToEnd.first;
      return _HeroCard(
        color: scheme.surfaceContainerLow,
        onColor: scheme.onSurface,
        leading: Icon(Icons.shield_outlined, color: scheme.primary, size: 40),
        title: '${active.length} ${active.length == 1 ? "límite activo" : "límites activos"} '
            'cuidando tu tiempo',
        subtitle: '${friendlyRemaining(soonest.endsAt)} el de '
            '${soonest.proposerProfile.displayName}',
        buttonLabel: null,
        onPressed: null,
      );
    }

    return _HeroCard(
      color: scheme.surfaceContainerLow,
      onColor: scheme.onSurface,
      leading: Icon(Icons.emoji_people, color: scheme.primary, size: 40),
      title: 'Aún no tienes límites activos',
      subtitle: 'Dale acceso a un amigo para que te proponga uno',
      buttonLabel: 'Dar acceso',
      onPressed: () => context.push('/limits/grant-access'),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.color,
    required this.onColor,
    required this.leading,
    required this.title,
    required this.subtitle,
    required this.buttonLabel,
    required this.onPressed,
  });

  final Color color;
  final Color onColor;
  final Widget leading;
  final String title;
  final String subtitle;
  final String? buttonLabel;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(
          AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          leading,
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: onColor,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: onColor.withValues(alpha: 0.85)),
                ),
              ],
            ),
          ),
          if (buttonLabel != null)
            TextButton(
              onPressed: onPressed,
              style: TextButton.styleFrom(foregroundColor: onColor),
              child: Text(buttonLabel!),
            ),
        ],
      ),
    );
  }
}

class _ActiveTab extends ConsumerWidget {
  const _ActiveTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final active = ref.watch(activeLimitsOnMeProvider);
    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(myProposalsProvider),
      child: active.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(message: e.toString()),
        data: (list) => list.isEmpty
            ? ListView(children: const [
                SizedBox(height: 80),
                EmptyStateView(
                  icon: Icons.shield_outlined,
                  title: 'No tienes límites activos ahora mismo',
                  subtitle: 'Los que aceptes van a aparecer aquí.',
                ),
              ])
            : ListView.separated(
                padding: const EdgeInsets.all(AppSpacing.md),
                itemCount: list.length,
                separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
                itemBuilder: (context, index) => ProposalCard(
                  proposal: list[index],
                  counterpart: list[index].proposerProfile,
                  counterpartLabel: 'te puso este límite',
                ),
              ),
      ),
    );
  }
}

class _PendingTab extends ConsumerWidget {
  const _PendingTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pending = ref.watch(proposalsAwaitingMyResponseProvider);
    final proposalsIMade = ref.watch(proposalsIMadeProvider);
    final proposalActions = ref.watch(proposalActionsControllerProvider);

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(myProposalsProvider),
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          _SectionHeader(
            title: 'Debes responder',
            subtitle: 'Propuestas que te hicieron amigos con acceso',
          ),
          pending.when(
            loading: () => const LoadingView(),
            error: (e, _) => ErrorView(message: e.toString()),
            data: (list) => list.isEmpty
                ? const _EmptyRow('No tienes propuestas pendientes. 🎉')
                : Column(
                    children: list
                        .map((p) => Padding(
                              padding:
                                  const EdgeInsets.only(bottom: AppSpacing.sm),
                              child: ProposalCard(
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
                              ),
                            ))
                        .toList(),
                  ),
          ),
          const SizedBox(height: AppSpacing.lg),
          _SectionHeader(
            title: 'Propuestas que hiciste',
            subtitle: 'Seguimiento de lo que le propusiste a tus amigos',
          ),
          proposalsIMade.when(
            loading: () => const LoadingView(),
            error: (e, _) => ErrorView(message: e.toString()),
            data: (list) => list.isEmpty
                ? const _EmptyRow('Aún no le has propuesto nada a nadie.')
                : Column(
                    children: list
                        .map((p) => Padding(
                              padding:
                                  const EdgeInsets.only(bottom: AppSpacing.sm),
                              child: ProposalCard(
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
                              ),
                            ))
                        .toList(),
                  ),
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }
}

class _AccessTab extends ConsumerWidget {
  const _AccessTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final grantsIGave = ref.watch(grantsIGaveProvider);
    final grantsIReceived = ref.watch(grantsIReceivedProvider);
    final grantActions = ref.watch(grantActionsControllerProvider);

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(myGrantsProvider),
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
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
                return const _EmptyRow('No le has dado acceso a nadie todavía.');
              }
              return Column(
                children: activeGrants
                    .map((g) => _GrantTile(
                          profile: g.trusteeProfile,
                          trailing: TextButton(
                            onPressed: grantActions.isLoading
                                ? null
                                : () => ref
                                    .read(grantActionsControllerProvider.notifier)
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
                return const _EmptyRow('Ningún amigo te ha dado acceso todavía.');
              }
              return Column(
                children: activeGrants
                    .map((g) => _GrantTile(
                          profile: g.ownerProfile,
                          trailing: FilledButton.tonal(
                            onPressed: () =>
                                context.push('/limits/propose', extra: g),
                            child: const Text('Proponer'),
                          ),
                        ))
                    .toList(),
              );
            },
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
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
