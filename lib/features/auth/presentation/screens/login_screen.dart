import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../providers/auth_providers.dart';

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final signInState = ref.watch(signInControllerProvider);
    final isLoading = signInState.isLoading;
    final scheme = Theme.of(context).colorScheme;

    ref.listen(signInControllerProvider, (previous, next) {
      final error = next.error;
      if (error != null) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(error.toString())));
      }
    });

    // Sign in with Apple, tal como está configurado acá (nativo, sin flujo
    // web de respaldo), solo funciona en iOS/macOS.
    final showAppleButton = !kIsWeb && Platform.isIOS;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            children: [
              const Spacer(flex: 3),
              Icon(Icons.timer_outlined, size: 64, color: scheme.primary),
              const SizedBox(height: AppSpacing.md),
              Text(
                'PocketBait',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Ponte límites de tiempo en pantalla con tus amigos,\n'
                'de mutuo acuerdo.',
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: scheme.outline),
              ),
              const Spacer(flex: 4),
              FilledButton.icon(
                onPressed: isLoading
                    ? null
                    : () => ref
                        .read(signInControllerProvider.notifier)
                        .signInWithGoogle(),
                icon: const Icon(Icons.g_mobiledata, size: 28),
                label: const Text('Continuar con Google'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                ),
              ),
              if (showAppleButton) ...[
                const SizedBox(height: AppSpacing.sm),
                OutlinedButton.icon(
                  onPressed: isLoading
                      ? null
                      : () => ref
                          .read(signInControllerProvider.notifier)
                          .signInWithApple(),
                  icon: const Icon(Icons.apple),
                  label: const Text('Continuar con Apple'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.md),
              if (isLoading) const CircularProgressIndicator(),
              const Spacer(),
              Text(
                'Al continuar aceptas que esta app es de uso entre amigos '
                'que dan su consentimiento explícito para cada límite.',
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: scheme.outline),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
          ),
        ),
      ),
    );
  }
}
