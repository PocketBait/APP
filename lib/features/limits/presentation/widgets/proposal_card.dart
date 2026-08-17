import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../friends/domain/profile.dart';
import '../../../friends/presentation/widgets/profile_avatar.dart';
import '../../domain/limit_proposal.dart';

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
    // Formato numérico a propósito: DateFormat con nombres de mes (MMM)
    // requiere inicializar datos de localización aparte; dd/MM/yyyy no.
    final dateFormat = DateFormat('dd/MM/yyyy');

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
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: proposal.apps
                  .map((app) => Chip(
                        label: Text(
                          '${app.appDisplayName} · ${app.dailyLimitMinutes} min/día',
                        ),
                      ))
                  .toList(),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Hasta el ${dateFormat.format(proposal.endsAt)}'
              '${proposal.note?.isNotEmpty == true ? ' · "${proposal.note}"' : ''}',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: scheme.outline),
            ),
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
