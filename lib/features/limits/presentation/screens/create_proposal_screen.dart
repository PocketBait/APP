import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../friends/presentation/widgets/profile_avatar.dart';
import '../../domain/limit_proposal_app.dart';
import '../../domain/permission_grant.dart';
import '../providers/limits_providers.dart';
import '../widgets/app_icon.dart';

enum _DurationPreset {
  oneWeek('1 semana', Duration(days: 7)),
  twoWeeks('2 semanas', Duration(days: 14)),
  oneMonth('1 mes', Duration(days: 30));

  const _DurationPreset(this.label, this.duration);
  final String label;
  final Duration duration;
}

/// Formulario para que un amigo con acceso (`grant.trustee`) le proponga un
/// límite de tiempo al dueño del teléfono (`grant.owner`). Se manda como
/// "borrador" — no aplica nada hasta que el dueño lo acepte.
class CreateProposalScreen extends ConsumerStatefulWidget {
  const CreateProposalScreen({super.key, required this.grant});

  final PermissionGrant grant;

  @override
  ConsumerState<CreateProposalScreen> createState() =>
      _CreateProposalScreenState();
}

class _CreateProposalScreenState extends ConsumerState<CreateProposalScreen> {
  final Map<String, int> _selectedApps = {};
  _DurationPreset _duration = _DurationPreset.oneWeek;
  final _noteController = TextEditingController();

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  void _toggleApp(AppCatalogEntry entry, bool selected) {
    setState(() {
      if (selected) {
        _selectedApps[entry.identifier] = 30;
      } else {
        _selectedApps.remove(entry.identifier);
      }
    });
  }

  void _changeMinutes(String identifier, int delta) {
    setState(() {
      final current = _selectedApps[identifier] ?? 30;
      final next = (current + delta).clamp(5, 1440);
      _selectedApps[identifier] = next;
    });
  }

  Future<void> _submit() async {
    final apps = AppCatalog.entries
        .where((e) => _selectedApps.containsKey(e.identifier))
        .map((e) => LimitProposalApp(
              appIdentifier: e.identifier,
              appDisplayName: e.displayName,
              dailyLimitMinutes: _selectedApps[e.identifier]!,
            ))
        .toList();

    if (apps.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Elige al menos una app.')),
      );
      return;
    }

    final endsAt = DateTime.now().add(_duration.duration);
    final note = _noteController.text.trim();

    await ref.read(proposalActionsControllerProvider.notifier).createProposal(
          permissionGrantId: widget.grant.id,
          ownerId: widget.grant.ownerId,
          endsAt: endsAt,
          note: note.isEmpty ? null : note,
          apps: apps,
        );

    final error = ref.read(proposalActionsControllerProvider).error;
    if (!mounted) return;
    if (error != null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(error.toString())));
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Propuesta enviada a ${widget.grant.ownerProfile.displayName}.',
        ),
      ),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final actions = ref.watch(proposalActionsControllerProvider);
    final owner = widget.grant.ownerProfile;

    return Scaffold(
      appBar: AppBar(title: const Text('Proponer límite')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          Card(
            child: ListTile(
              leading: ProfileAvatar(profile: owner),
              title: Text(owner.displayName),
              subtitle: const Text('Recibirá esta propuesta para aceptar o rechazar'),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('Apps y minutos diarios',
              style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: AppSpacing.xs),
          ...AppCatalog.entries.map((entry) {
            final selected = _selectedApps.containsKey(entry.identifier);
            return Card(
              margin: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                child: Row(
                  children: [
                    Checkbox(
                      value: selected,
                      onChanged: (value) => _toggleApp(entry, value ?? false),
                    ),
                    AppIcon(appIdentifier: entry.identifier, size: 28),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(child: Text(entry.displayName)),
                    if (selected) ...[
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline),
                        onPressed: () => _changeMinutes(entry.identifier, -5),
                      ),
                      SizedBox(
                        width: 64,
                        child: Text(
                          '${_selectedApps[entry.identifier]} min',
                          textAlign: TextAlign.center,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline),
                        onPressed: () => _changeMinutes(entry.identifier, 5),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: AppSpacing.lg),
          Text('Duración', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.sm,
            children: _DurationPreset.values
                .map((preset) => ChoiceChip(
                      label: Text(preset.label),
                      selected: _duration == preset,
                      onSelected: (_) => setState(() => _duration = preset),
                    ))
                .toList(),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('Nota (opcional)', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: AppSpacing.xs),
          TextField(
            controller: _noteController,
            maxLength: 140,
            maxLines: 2,
            decoration: const InputDecoration(
              hintText: 'Ej. "Para que estudiemos para el examen 📚"',
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          FilledButton(
            onPressed: actions.isLoading ? null : _submit,
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
            child: actions.isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Enviar propuesta'),
          ),
        ],
      ),
    );
  }
}
