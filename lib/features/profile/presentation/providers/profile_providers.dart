import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/providers/core_providers.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/my_profile.dart';

/// Mi propio perfil completo (con phone/date_of_birth) — para la
/// pantalla de "Account preferences". `autoDispose` como el resto de los
/// datos que dependen de sesión.
final myProfileProvider = FutureProvider.autoDispose<MyProfile>((ref) {
  ref.watch(requireUserIdProvider); // se re-consulta si cambia la sesión
  return ref.watch(profileRepositoryProvider).fetchMyProfile();
});

/// Cuentas conectadas a mi sesión (Google/Apple/correo).
final linkedIdentitiesProvider = Provider.autoDispose<List<UserIdentity>>((ref) {
  ref.watch(authStateChangesProvider); // se refresca si cambia la sesión
  return ref.watch(profileRepositoryProvider).linkedIdentities;
});

/// Acciones de cuenta (editar perfil, cambiar contraseña, cerrar sesión
/// en todos lados, eliminar cuenta) con su estado de carga/error.
class AccountActionsController extends StateNotifier<AsyncValue<void>> {
  AccountActionsController(this._ref) : super(const AsyncValue.data(null));

  final Ref _ref;

  Future<void> updateProfile({
    required String username,
    required String displayName,
    required String phone,
    required DateTime dateOfBirth,
  }) =>
      _run(() {
        final repository = _ref.read(profileRepositoryProvider);
        final userId = _ref.read(requireUserIdProvider);
        return repository.updateMyProfile(
          userId: userId,
          username: username,
          displayName: displayName,
          phone: phone,
          dateOfBirth: dateOfBirth,
        );
      });

  Future<void> changePassword(String newPassword) => _run(
      () => _ref.read(profileRepositoryProvider).changePassword(newPassword));

  Future<void> signOutEverywhere() =>
      _run(() => _ref.read(profileRepositoryProvider).signOutEverywhere());

  Future<void> deleteAccount() =>
      _run(() => _ref.read(profileRepositoryProvider).deleteAccount());

  Future<void> _run(Future<void> Function() action) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(action);
    _ref.invalidate(myProfileProvider);
  }
}

final accountActionsControllerProvider = StateNotifierProvider.autoDispose<
    AccountActionsController, AsyncValue<void>>(
  (ref) => AccountActionsController(ref),
);
