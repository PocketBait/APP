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

  /// Busca usuarios por username o nombre para agregar como amigo.
  Future<List<Profile>> searchProfiles(
    String query, {
    required String excludeUserId,
  }) async {
    try {
      final trimmed = query.trim();
      if (trimmed.isEmpty) return [];
      final rows = await _client
          .from('profiles')
          .select()
          .or('username.ilike.%$trimmed%,display_name.ilike.%$trimmed%')
          .neq('id', excludeUserId)
          .limit(20);
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
}
