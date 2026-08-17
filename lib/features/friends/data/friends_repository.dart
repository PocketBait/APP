import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/utils/app_exception.dart';
import '../domain/friend_request.dart';
import '../domain/profile.dart';

/// Toda la app habla con `friend_requests`/`profiles` a través de este
/// repositorio — ninguna pantalla arma queries de Supabase directamente.
/// Eso mantiene las políticas de RLS como única fuente de verdad: si algo
/// falla acá, es porque la base de datos lo rechazó, no porque la UI se
/// "olvidó" de filtrar.
class FriendsRepository {
  FriendsRepository(this._client);

  final SupabaseClient _client;

  static const _requestSelect =
      '*, requester:profiles!friend_requests_requester_id_fkey(*), '
      'addressee:profiles!friend_requests_addressee_id_fkey(*)';

  /// Busca usuarios por username o nombre para agregar como amigo. Pasa
  /// por la función `search_profiles` (no una query directa a `profiles`)
  /// porque ella ya excluye a quien te bloqueó o bloqueaste, y calcula
  /// cuántos amigos en común tienen.
  Future<List<Profile>> searchProfiles(String query) async {
    try {
      final trimmed = query.trim();
      if (trimmed.isEmpty) return [];
      final rows = await _client.rpc(
        'search_profiles',
        params: {'p_query': trimmed},
      );
      return (rows as List)
          .map((row) => Profile.fromJson(row as Map<String, dynamic>))
          .toList();
    } catch (error) {
      throw AppException.from(error);
    }
  }

  /// Todas las solicitudes (pendientes, aceptadas, etc.) donde el usuario
  /// actual participa, en cualquiera de los dos lados.
  Future<List<FriendRequest>> fetchMyFriendRequests(String userId) async {
    try {
      final rows = await _client
          .from('friend_requests')
          .select(_requestSelect)
          .or('requester_id.eq.$userId,addressee_id.eq.$userId')
          .order('created_at', ascending: false);
      return (rows as List)
          .map((row) => FriendRequest.fromJson(row as Map<String, dynamic>))
          .toList();
    } catch (error) {
      throw AppException.from(error);
    }
  }

  Future<void> sendFriendRequest({
    required String requesterId,
    required String addresseeId,
  }) async {
    try {
      await _client.from('friend_requests').insert({
        'requester_id': requesterId,
        'addressee_id': addresseeId,
      });
    } catch (error) {
      throw AppException.from(error);
    }
  }

  Future<void> respondToFriendRequest({
    required String requestId,
    required bool accept,
  }) async {
    try {
      await _client.from('friend_requests').update({
        'status': accept ? 'accepted' : 'declined',
        'responded_at': DateTime.now().toIso8601String(),
      }).eq('id', requestId);
    } catch (error) {
      throw AppException.from(error);
    }
  }

  Future<void> cancelFriendRequest(String requestId) async {
    try {
      await _client
          .from('friend_requests')
          .update({'status': 'cancelled'}).eq('id', requestId);
    } catch (error) {
      throw AppException.from(error);
    }
  }

  /// Termina la amistad (borra la fila entre las dos personas, sin
  /// importar quién la haya iniciado originalmente). La base de datos
  /// revoca solita cualquier acceso activo entre ambos (ver trigger
  /// `on_friend_request_deleted`).
  Future<void> removeFriend({
    required String userId,
    required String otherUserId,
  }) async {
    try {
      await _client.from('friend_requests').delete().or(
          'and(requester_id.eq.$userId,addressee_id.eq.$otherUserId),'
          'and(requester_id.eq.$otherUserId,addressee_id.eq.$userId)');
    } catch (error) {
      throw AppException.from(error);
    }
  }

  Future<void> blockUser({
    required String blockerId,
    required String blockedId,
  }) async {
    try {
      await _client.from('blocks').insert({
        'blocker_id': blockerId,
        'blocked_id': blockedId,
      });
    } catch (error) {
      throw AppException.from(error);
    }
  }

  Future<void> reportUser({
    required String reporterId,
    required String reportedId,
    required String reason,
    String? details,
  }) async {
    try {
      await _client.from('reports').insert({
        'reporter_id': reporterId,
        'reported_id': reportedId,
        'reason': reason,
        'details': details,
      });
    } catch (error) {
      throw AppException.from(error);
    }
  }

  /// Cuántos amigos en común tienes con `otherUserId` — para mostrar en
  /// su perfil.
  Future<int> mutualFriendsCount(String otherUserId) async {
    try {
      final result = await _client.rpc(
        'mutual_friends_count',
        params: {'p_other_id': otherUserId},
      );
      return (result as num).toInt();
    } catch (error) {
      throw AppException.from(error);
    }
  }
}
