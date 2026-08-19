import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final signInState = ref.watch(signInControllerProvider);
    final scheme = Theme.of(context).colorScheme;

    final displayName =
        user?.userMetadata?['full_name'] as String? ?? 'Usuario';
    final email = user?.email ?? '';
    final avatarUrl = user?.userMetadata?['avatar_url'] as String?;

    return Scaffold(
      appBar: AppBar(title: const Text('Perfil')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        children: [
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: scheme.primaryContainer,
                  backgroundImage:
                      avatarUrl != null ? NetworkImage(avatarUrl) : null,
                  child: avatarUrl == null
                      ? Icon(Icons.person,
                          size: 40, color: scheme.onPrimaryContainer)
                      : null,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(displayName,
                    style: Theme.of(context).textTheme.titleLarge),
                if (email.isNotEmpty)
                  Text(email,
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: scheme.outline)),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          _SettingsTile(
            icon: Icons.person_outline,
            title: 'Account preferences',
            onTap: () => context.push('/profile/account'),
          ),
          _SettingsTile(
            icon: Icons.lock_outline,
            title: 'Sign in and security',
            onTap: () => context.push('/profile/security'),
          ),
          _SettingsTile(
            icon: Icons.shield_outlined,
            title: 'Data privacy',
            onTap: () => context.push('/profile/privacy'),
          ),
          _SettingsTile(
            icon: Icons.notifications_outlined,
            title: 'Notifications',
            onTap: () => context.push('/profile/notifications'),
          ),
          _SettingsTile(
            icon: Icons.language_outlined,
            title: 'Language',
            onTap: () => context.push('/profile/language'),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: Divider(),
          ),
          _SettingsTile(
            small: true,
            title: 'Help Center',
            onTap: () => context.push('/profile/help'),
          ),
          _SettingsTile(
            small: true,
            title: 'Privacy Policy',
            onTap: () => context.push('/profile/privacy-policy'),
          ),
          _SettingsTile(
            small: true,
            title: 'User Agreement',
            onTap: () => context.push('/profile/terms'),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.lg),
            child: Text(
              'PocketBait — versión 1.0.0 (Fase 1: sin dinero de por medio)',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: scheme.outline),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: OutlinedButton.icon(
              onPressed: signInState.isLoading
                  ? null
                  : () =>
                      ref.read(signInControllerProvider.notifier).signOut(),
              icon: const Icon(Icons.logout),
              label: const Text('Cerrar sesión'),
              style: OutlinedButton.styleFrom(
                foregroundColor: scheme.error,
                side: BorderSide(color: scheme.error),
                minimumSize: const Size.fromHeight(48),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    this.icon,
    required this.title,
    required this.onTap,
    this.small = false,
  });

  final IconData? icon;
  final String title;
  final VoidCallback onTap;
  final bool small;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      leading: icon != null ? Icon(icon, color: scheme.onSurface) : null,
      title: Text(
        title,
        style: small
            ? Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: scheme.outline)
            : Theme.of(context).textTheme.bodyLarge,
      ),
      trailing: Icon(Icons.chevron_right,
          color: scheme.outline, size: small ? 18 : 24),
      onTap: onTap,
    );
  }
}
