import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/utils/app_exception.dart';
import '../domain/limit_proposal.dart';
import '../domain/limit_proposal_app.dart';
import '../domain/permission_grant.dart';

/// Toda la lógica de "dar acceso a un amigo" y "proponer/aceptar/rechazar
/// límites" pasa por acá. Igual que `FriendsRepository`, esto es un
/// envoltorio delgado sobre Supabase — la seguridad real vive en las
/// políticas RLS de `supabase/migrations`, esto solo arma las queries.
class LimitsRepository {
  LimitsRepository(this._client);

  final SupabaseClient _client;

  static const _grantSelect = '*, '
      'owner:profiles!permission_grants_owner_id_fkey(*), '
      'trustee:profiles!permission_grants_trustee_id_fkey(*)';

  static const _proposalSelect = '*, '
      'owner:profiles!limit_proposals_owner_id_fkey(*), '
      'proposer:profiles!limit_proposals_proposed_by_fkey(*), '
      'limit_proposal_apps(*)';

  // ---------------------------------------------------------------------
  // Accesos otorgados (permission_grants)
  // ---------------------------------------------------------------------

  /// Accesos donde el usuario participa: los que otorgó (es `owner`) y los
  /// que le otorgaron a él para poder proponer límites (es `trustee`).
  Future<List<PermissionGrant>> fetchMyGrants(String userId) async {
    try {
      final rows = await _client
          .from('permission_grants')
          .select(_grantSelect)
          .or('owner_id.eq.$userId,trustee_id.eq.$userId')
          .order('created_at', ascending: false);
      return (rows as List)
          .map((row) => PermissionGrant.fromJson(row as Map<String, dynamic>))
          .toList();
    } catch (error) {
      throw AppException.from(error);
    }
  }

  /// Le doy acceso a un amigo (`trusteeId`) para que me proponga límites.
  /// La base de datos exige que ya sean amigos aceptados (ver RLS).
  Future<void> grantAccess({
    required String ownerId,
    required String trusteeId,
  }) async {
    try {
      await _client.from('permission_grants').insert({
        'owner_id': ownerId,
        'trustee_id': trusteeId,
      });
    } catch (error) {
      throw AppException.from(error);
    }
  }

  Future<void> revokeGrant(String grantId) async {
    try {
      await _client.from('permission_grants').update({
        'status': 'revoked',
        'revoked_at': DateTime.now().toIso8601String(),
      }).eq('id', grantId);
    } catch (error) {
      throw AppException.from(error);
    }
  }

  // ---------------------------------------------------------------------
  // Propuestas de límite (limit_proposals + limit_proposal_apps)
  // ---------------------------------------------------------------------

  /// Propuestas donde el usuario participa: las que le proponen (es
  /// `owner`, debe aceptar/rechazar) y las que él mismo creó para un amigo.
  Future<List<LimitProposal>> fetchMyProposals(String userId) async {
    try {
      final rows = await _client
          .from('limit_proposals')
          .select(_proposalSelect)
          .or('owner_id.eq.$userId,proposed_by.eq.$userId')
          .order('created_at', ascending: false);
      return (rows as List)
          .map((row) => LimitProposal.fromJson(row as Map<String, dynamic>))
          .toList();
    } catch (error) {
      throw AppException.from(error);
    }
  }

  /// Crea una propuesta con sus apps en una sola operación lógica: primero
  /// la fila de `limit_proposals`, y con el id devuelto se insertan las
  /// filas de `limit_proposal_apps`. Si el segundo paso falla, se intenta
  /// cancelar la propuesta para no dejar un "borrador" huérfano.
  Future<void> createProposal({
    required String permissionGrantId,
    required String ownerId,
    required String proposedBy,
    required DateTime endsAt,
    DateTime? startsAt,
    String? note,
    required List<LimitProposalApp> apps,
  }) async {
    if (apps.isEmpty) {
      throw AppException('Agrega al menos una app con su límite.');
    }
    Map<String, dynamic>? inserted;
    try {
      inserted = await _client
          .from('limit_proposals')
          .insert({
            'permission_grant_id': permissionGrantId,
            'owner_id': ownerId,
            'proposed_by': proposedBy,
            'starts_at': startsAt?.toIso8601String(),
            'ends_at': endsAt.toIso8601String(),
            'note': note,
          })
          .select()
          .single();

      final proposalId = inserted['id'] as String;
      await _client
          .from('limit_proposal_apps')
          .insert(apps.map((app) => app.toInsertJson(proposalId)).toList());
    } catch (error) {
      if (inserted != null) {
        // Limpieza best-effort: no dejar una propuesta sin apps.
        await _client
            .from('limit_proposals')
            .update({'status': 'cancelled'}).eq('id', inserted['id']);
      }
      throw AppException.from(error);
    }
  }

  Future<void> respondToProposal({
    required String proposalId,
    required bool accept,
  }) async {
    try {
      await _client.from('limit_proposals').update({
        'status': accept ? 'accepted' : 'rejected',
        'responded_at': DateTime.now().toIso8601String(),
      }).eq('id', proposalId);
    } catch (error) {
      throw AppException.from(error);
    }
  }

  Future<void> cancelProposal(String proposalId) async {
    try {
      await _client
          .from('limit_proposals')
          .update({'status': 'cancelled'}).eq('id', proposalId);
    } catch (error) {
      throw AppException.from(error);
    }
  }
}
