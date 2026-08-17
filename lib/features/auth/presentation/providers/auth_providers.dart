import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/providers/core_providers.dart';
import '../../data/auth_repository.dart';

/// Emite cada cambio de sesión (login, logout, refresh de token...). Es la
/// única fuente de verdad sobre si hay alguien autenticado — el router la
/// usa para decidir si mostrar el login o la app.
final authStateChangesProvider = StreamProvider<AuthState>((ref) {
  return ref.watch(authRepositoryProvider).onAuthStateChange;
});

/// Antes de que el stream emita su primer evento (fracción de segundo al
/// abrir la app), usamos la sesión síncrona actual como respaldo para no
/// mostrar un parpadeo hacia la pantalla de login si ya había sesión.
final isAuthenticatedProvider = Provider<bool>((ref) {
  final authState = ref.watch(authStateChangesProvider);
  return authState.maybeWhen(
    data: (state) => state.session != null,
    orElse: () => ref.watch(authRepositoryProvider).currentSession != null,
  );
});

/// El usuario autenticado actual, o null si no hay sesión.
final currentUserProvider = Provider<User?>((ref) {
  final authState = ref.watch(authStateChangesProvider);
  return authState.maybeWhen(
    data: (state) => state.session?.user,
    orElse: () => ref.watch(authRepositoryProvider).currentSession?.user,
  );
});

/// Atajo para pantallas que solo se muestran cuando SÍ hay sesión (todo lo
/// que está detrás del router guard) — evita repetir `!` por todos lados.
final requireUserIdProvider = Provider<String>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) {
    throw StateError('requireUserIdProvider leído sin sesión activa.');
  }
  return user.id;
});

/// Controla las acciones de login/logout y expone su estado de carga/error
/// para que la pantalla de login pueda mostrar un spinner o un snackbar.
class SignInController extends StateNotifier<AsyncValue<void>> {
  SignInController(this._repository) : super(const AsyncValue.data(null));

  final AuthRepository _repository;

  Future<void> signInWithGoogle() => _run(_repository.signInWithGoogle);

  Future<void> signInWithApple() => _run(_repository.signInWithApple);

  Future<void> signOut() => _run(_repository.signOut);

  Future<void> _run(Future<void> Function() action) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(action);
  }
}

final signInControllerProvider =
    StateNotifierProvider<SignInController, AsyncValue<void>>(
  (ref) => SignInController(ref.watch(authRepositoryProvider)),
);
