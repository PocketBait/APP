import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../providers/profile_providers.dart';

const _confirmPhrase = 'ELIMINAR';

class DataPrivacyScreen extends ConsumerWidget {
  const DataPrivacyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final actions = ref.watch(accountActionsControllerProvider);

    ref.listen(accountActionsControllerProvider, (previous, next) {
      final error = next.error;
      if (error != null) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(error.toString())));
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Data privacy')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  Icon(Icons.privacy_tip_outlined, color: scheme.primary),
                  const SizedBox(width: AppSpacing.sm),
                  const Expanded(
                    child: Text(
                      'Tus datos (nombre, usuario, correo, celular, fecha '
                      'de nacimiento) solo se usan para que la app funcione '
                      'entre tú y tus amigos — nunca se venden a terceros.',
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text('Eliminar mi cuenta', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Se borra todo de forma permanente: tu perfil, tus amistades, '
            'los límites que propusiste o te propusieron, y los accesos '
            'que diste o recibiste. No se puede deshacer.',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: scheme.outline),
          ),
          const SizedBox(height: AppSpacing.md),
          OutlinedButton(
            onPressed: actions.isLoading
                ? null
                : () => _confirmDelete(context, ref),
            style: OutlinedButton.styleFrom(
              foregroundColor: scheme.error,
              side: BorderSide(color: scheme.error),
              minimumSize: const Size.fromHeight(48),
            ),
            child: const Text('Eliminar mi cuenta'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          final matches = controller.text.trim() == _confirmPhrase;
          return AlertDialog(
            title: const Text('¿Eliminar tu cuenta?'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Esto es permanente. Para confirmar, escribe ELIMINAR:',
                ),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: controller,
                  autofocus: true,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(hintText: 'ELIMINAR'),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: matches ? () => Navigator.of(context).pop(true) : null,
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error,
                ),
                child: const Text('Eliminar mi cuenta'),
              ),
            ],
          );
        },
      ),
    );
    controller.dispose();
    if (confirmed != true) return;

    await ref.read(accountActionsControllerProvider.notifier).deleteAccount();
    if (ref.read(accountActionsControllerProvider).error != null) return;

    // La cuenta ya no existe en el servidor — cierra la sesión local para
    // que el router te regrese a la pantalla de login.
    await ref.read(signInControllerProvider.notifier).signOut();
  }
}
