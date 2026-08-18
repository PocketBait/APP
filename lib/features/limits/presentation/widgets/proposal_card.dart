import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/friendly_date.dart';
import '../../../friends/domain/profile.dart';
import '../../../friends/presentation/widgets/profile_avatar.dart';
import '../../domain/limit_proposal.dart';
import 'app_icon.dart';

/// Tarjeta reusada para mostrar una propuesta de límite: quién la hizo /
/// recibe, las apps con sus minutos diarios, y hasta cuándo dura.
/// `trailing` se usa para los botones de acción (aceptar/rechazar/cancelar),
/// que cambian según el contexto de cada pantalla.
class ProposalCard extends StatelessWidget {
  const ProposalCard({
    super.key,
    required this.proposal,
    required this.counterpart,
    required this.counterpartLabel,
    this.trailing,
  });

  final LimitProposal proposal;
  final Profile counterpart;
  final String counterpartLabel;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ProfileAvatar(profile: counterpart, radius: 18),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        counterpart.displayName,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      Text(
                        counterpartLabel,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: scheme.outline),
                      ),
                    ],
                  ),
                ),
                _CountdownPill(endsAt: proposal.endsAt),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Column(
              children: proposal.apps
                  .map((app) => Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                        child: Row(
                          children: [
                            AppIcon(appIdentifier: app.appIdentifier, size: 28),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Text(
                                app.appDisplayName,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ),
                            Text(
                              '${app.dailyLimitMinutes} min/día',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: scheme.outline,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ],
                        ),
                      ))
                  .toList(),
            ),
            if (proposal.note?.isNotEmpty == true) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                '"${proposal.note}"',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: scheme.outline, fontStyle: FontStyle.italic),
              ),
            ],
            if (trailing != null) ...[
              const SizedBox(height: AppSpacing.sm),
              trailing!,
            ],
          ],
        ),
      ),
    );
  }
}

class _CountdownPill extends StatelessWidget {
  const _CountdownPill({required this.endsAt});
  final DateTime endsAt;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        friendlyRemaining(endsAt),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: scheme.outline,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}
