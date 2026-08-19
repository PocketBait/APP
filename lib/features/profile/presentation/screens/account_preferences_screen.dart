import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/async_state_views.dart';
import '../../domain/my_profile.dart';
import '../providers/profile_providers.dart';

final _usernameRegExp = RegExp(r'^[a-z0-9_]{3,20}$');

class AccountPreferencesScreen extends ConsumerStatefulWidget {
  const AccountPreferencesScreen({super.key});

  @override
  ConsumerState<AccountPreferencesScreen> createState() =>
      _AccountPreferencesScreenState();
}

class _AccountPreferencesScreenState
    extends ConsumerState<AccountPreferencesScreen> {
  final _formKey = GlobalKey<FormState>();
  final _displayNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _phoneController = TextEditingController();
  DateTime? _dateOfBirth;
  bool _prefilled = false;

  static final DateTime _maxDateOfBirth =
      DateTime.now().subtract(const Duration(days: 365 * 13 + 4));

  @override
  void dispose() {
    _displayNameController.dispose();
    _usernameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _prefill(MyProfile profile) {
    if (_prefilled) return;
    _prefilled = true;
    _displayNameController.text = profile.displayName;
    _usernameController.text = profile.username;
    _phoneController.text = profile.phone ?? '';
    _dateOfBirth = profile.dateOfBirth;
  }

  Future<void> _pickDateOfBirth() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateOfBirth ?? _maxDateOfBirth,
      firstDate: DateTime(1900),
      lastDate: _maxDateOfBirth,
      helpText: 'Fecha de nacimiento',
    );
    if (picked != null) setState(() => _dateOfBirth = picked);
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_dateOfBirth == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona tu fecha de nacimiento.')),
      );
      return;
    }
    await ref.read(accountActionsControllerProvider.notifier).updateProfile(
          username: _usernameController.text,
          displayName: _displayNameController.text,
          phone: _phoneController.text,
          dateOfBirth: _dateOfBirth!,
        );
    if (!mounted) return;
    if (ref.read(accountActionsControllerProvider).error == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Datos actualizados.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(myProfileProvider);
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
      appBar: AppBar(title: const Text('Account preferences')),
      body: profileAsync.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(
          message: e.toString(),
          onRetry: () => ref.invalidate(myProfileProvider),
        ),
        data: (profile) {
          _prefill(profile);
          final dateFormat = _dateOfBirth == null
              ? 'Selecciona tu fecha de nacimiento'
              : '${_dateOfBirth!.day.toString().padLeft(2, '0')}/'
                  '${_dateOfBirth!.month.toString().padLeft(2, '0')}/'
                  '${_dateOfBirth!.year}';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _displayNameController,
                    enabled: !actions.isLoading,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Nombre completo',
                      prefixIcon: Icon(Icons.badge_outlined),
                    ),
                    validator: (value) =>
                        (value == null || value.trim().length < 2)
                            ? 'Ingresa tu nombre completo'
                            : null,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextFormField(
                    controller: _usernameController,
                    enabled: !actions.isLoading,
                    autocorrect: false,
                    decoration: const InputDecoration(
                      labelText: 'Usuario',
                      prefixIcon: Icon(Icons.alternate_email),
                      helperText: '3-20 caracteres: minúsculas, números o "_"',
                    ),
                    validator: (value) {
                      final v = value?.trim().toLowerCase() ?? '';
                      if (!_usernameRegExp.hasMatch(v)) {
                        return 'Usuario inválido (solo minúsculas, números, "_")';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextFormField(
                    controller: _phoneController,
                    enabled: !actions.isLoading,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Celular',
                      prefixIcon: Icon(Icons.phone_outlined),
                    ),
                    validator: (value) =>
                        (value == null || value.trim().length < 7)
                            ? 'Ingresa un número de celular válido'
                            : null,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  InkWell(
                    onTap: actions.isLoading ? null : _pickDateOfBirth,
                    borderRadius: BorderRadius.circular(12),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Fecha de nacimiento',
                        prefixIcon: Icon(Icons.cake_outlined),
                      ),
                      child: Text(dateFormat),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  FilledButton(
                    onPressed: actions.isLoading ? null : _submit,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                    ),
                    child: actions.isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Guardar cambios'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
