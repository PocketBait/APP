import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../providers/profile_providers.dart';

String _providerLabel(String provider) => switch (provider) {
      'google' => 'Google',
      'apple' => 'Apple',
      'email' => 'Correo y contraseña',
      _ => provider,
    };

IconData _providerIcon(String provider) => switch (provider) {
      'google' => Icons.g_mobiledata,
      'apple' => Icons.apple,
      'email' => Icons.email_outlined,
      _ => Icons.link,
    };

class SecurityScreen extends ConsumerStatefulWidget {
  const SecurityScreen({super.key});

  @override
  ConsumerState<SecurityScreen> createState() => _SecurityScreenState();
}

class _SecurityScreenState extends ConsumerState<SecurityScreen> {
  final _passwordFormKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    if (!(_passwordFormKey.currentState?.validate() ?? false)) return;
    await ref
        .read(accountActionsControllerProvider.notifier)
        .changePassword(_passwordController.text);
    if (!mounted) return;
    if (ref.read(accountActionsControllerProvider).error == null) {
      _passwordController.clear();
      _confirmController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Contraseña actualizada.')),
      );
    }
  }

  Future<void> _signOutEverywhere() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Cerrar sesión en todos los dispositivos?'),
        content: const Text(
          'Vas a tener que volver a iniciar sesión aquí y en cualquier '
          'otro lugar donde hayas entrado a tu cuenta.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(accountActionsControllerProvider.notifier).signOutEverywhere();
  }

  @override
  Widget build(BuildContext context) {
    final identities = ref.watch(linkedIdentitiesProvider);
    final actions = ref.watch(accountActionsControllerProvider);
    final scheme = Theme.of(context).colorScheme;

    ref.listen(accountActionsControllerProvider, (previous, next) {
      final error = next.error;
      if (error != null) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(error.toString())));
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Sign in and security')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Text('Cambiar contraseña',
              style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: AppSpacing.xs),
          Form(
            key: _passwordFormKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _passwordController,
                  enabled: !actions.isLoading,
                  obscureText: _obscure,
                  decoration: InputDecoration(
                    labelText: 'Contraseña nueva',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(_obscure
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                  validator: (value) => (value == null || value.length < 6)
                      ? 'Mínimo 6 caracteres'
                      : null,
                ),
                const SizedBox(height: AppSpacing.sm),
                TextFormField(
                  controller: _confirmController,
                  enabled: !actions.isLoading,
                  obscureText: _obscure,
                  decoration: const InputDecoration(
                    labelText: 'Confirmar contraseña',
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                  validator: (value) => value != _passwordController.text
                      ? 'Las contraseñas no coinciden'
                      : null,
                ),
                const SizedBox(height: AppSpacing.sm),
                FilledButton(
                  onPressed: actions.isLoading ? null : _changePassword,
                  child: const Text('Actualizar contraseña'),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text('Cuentas conectadas',
              style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: AppSpacing.xs),
          Card(
            child: Column(
              children: identities
                  .map((identity) => ListTile(
                        leading: Icon(_providerIcon(identity.provider)),
                        title: Text(_providerLabel(identity.provider)),
                      ))
                  .toList(),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text('Sesiones', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: AppSpacing.xs),
          OutlinedButton(
            onPressed: actions.isLoading ? null : _signOutEverywhere,
            style: OutlinedButton.styleFrom(
              foregroundColor: scheme.error,
              side: BorderSide(color: scheme.error),
              minimumSize: const Size.fromHeight(48),
            ),
            child: const Text('Cerrar sesión en todos los dispositivos'),
          ),
        ],
      ),
    );
  }
}
