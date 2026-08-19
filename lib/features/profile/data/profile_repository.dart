import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/utils/app_exception.dart';
import '../domain/my_profile.dart';

/// Todo lo relacionado a "mi propia cuenta" (editar datos, seguridad,
/// privacidad) — distinto de `FriendsRepository`, que trata con perfiles
/// de *otras* personas.
class ProfileRepository {
  ProfileRepository(this._client);

  final SupabaseClient _client;

  /// Trae todos mis campos, incluidos los privados (`phone`,
  /// `date_of_birth`) — pasa por `get_my_profile` porque el acceso normal
  /// a la tabla `profiles` está limitado a columnas públicas (ver
  /// migración 0005).
  Future<MyProfile> fetchMyProfile() async {
    try {
      final row = await _client.rpc('get_my_profile');
      return MyProfile.fromJson(row as Map<String, dynamic>);
    } catch (error) {
      throw AppException.from(error);
    }
  }

  Future<void> updateMyProfile({
    required String userId,
    required String username,
    required String displayName,
    required String phone,
    required DateTime dateOfBirth,
  }) async {
    try {
      await _client.from('profiles').update({
        'username': username.trim().toLowerCase(),
        'display_name': displayName.trim(),
        'phone': phone.trim(),
        'date_of_birth': dateOfBirth.toIso8601String().split('T').first,
      }).eq('id', userId);
    } catch (error) {
      throw AppException.from(error);
    }
  }

  Future<void> changePassword(String newPassword) async {
    try {
      await _client.auth.updateUser(UserAttributes(password: newPassword));
    } catch (error) {
      throw AppException.from(error);
    }
  }

  /// Cierra la sesión en TODOS los dispositivos donde hayas iniciado
  /// sesión, no solo este.
  Future<void> signOutEverywhere() async {
    try {
      await _client.auth.signOut(scope: SignOutScope.global);
    } catch (error) {
      throw AppException.from(error);
    }
  }

  /// Cuentas (Google/Apple/correo) conectadas a mi sesión actual.
  List<UserIdentity> get linkedIdentities =>
      _client.auth.currentUser?.identities ?? const [];

  /// Borra la cuenta por completo (cascada: perfil, amigos, propuestas,
  /// accesos, bloqueos, reportes) — irreversible.
  Future<void> deleteAccount() async {
    try {
      await _client.rpc('delete_own_account');
    } catch (error) {
      throw AppException.from(error);
    }
  }
}
