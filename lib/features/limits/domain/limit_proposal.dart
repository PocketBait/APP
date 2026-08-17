import '../../friends/domain/profile.dart';
import 'limit_proposal_app.dart';

enum ProposalStatus { pending, accepted, rejected, cancelled }

ProposalStatus proposalStatusFromString(String value) => switch (value) {
      'pending' => ProposalStatus.pending,
      'accepted' => ProposalStatus.accepted,
      'rejected' => ProposalStatus.rejected,
      'cancelled' => ProposalStatus.cancelled,
      _ => throw ArgumentError('Estado de propuesta desconocido: $value'),
    };

/// El "borrador" de límites que un amigo autorizado (`proposedBy`) le
/// propone al dueño del teléfono (`ownerId`). Solo aplica de verdad si el
/// dueño la acepta (tabla `limit_proposals`).
class LimitProposal {
  const LimitProposal({
    required this.id,
    required this.permissionGrantId,
    required this.ownerId,
    required this.proposedBy,
    required this.status,
    required this.endsAt,
    required this.createdAt,
    required this.ownerProfile,
    required this.proposerProfile,
    this.startsAt,
    this.note,
    this.apps = const [],
  });

  final String id;
  final String permissionGrantId;
  final String ownerId;
  final String proposedBy;
  final ProposalStatus status;
  final DateTime? startsAt;
  final DateTime endsAt;
  final String? note;
  final DateTime createdAt;
  final Profile ownerProfile;
  final Profile proposerProfile;
  final List<LimitProposalApp> apps;

  factory LimitProposal.fromJson(Map<String, dynamic> json) => LimitProposal(
        id: json['id'] as String,
        permissionGrantId: json['permission_grant_id'] as String,
        ownerId: json['owner_id'] as String,
        proposedBy: json['proposed_by'] as String,
        status: proposalStatusFromString(json['status'] as String),
        startsAt: json['starts_at'] == null
            ? null
            : DateTime.parse(json['starts_at'] as String),
        endsAt: DateTime.parse(json['ends_at'] as String),
        note: json['note'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
        ownerProfile: Profile.fromJson(json['owner'] as Map<String, dynamic>),
        proposerProfile:
            Profile.fromJson(json['proposer'] as Map<String, dynamic>),
        apps: (json['limit_proposal_apps'] as List? ?? [])
            .map((e) => LimitProposalApp.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  bool get isActive =>
      status == ProposalStatus.accepted && endsAt.isAfter(DateTime.now());

  bool isAwaitingResponseFrom(String userId) =>
      ownerId == userId && status == ProposalStatus.pending;

  Duration get remaining => endsAt.difference(DateTime.now());
}
