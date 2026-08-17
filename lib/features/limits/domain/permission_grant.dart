import '../../friends/domain/profile.dart';

enum GrantStatus { active, revoked }

GrantStatus grantStatusFromString(String value) => switch (value) {
      'active' => GrantStatus.active,
      'revoked' => GrantStatus.revoked,
      _ => throw ArgumentError('Estado de acceso desconocido: $value'),
    };

/// Representa "le doy acceso a un amigo para que me proponga límites de
/// tiempo" (tabla `permission_grants`). Sin una fila `active` de estas,
/// nadie puede crear una propuesta contra ti — la base de datos lo exige.
class PermissionGrant {
  const PermissionGrant({
    required this.id,
    required this.ownerId,
    required this.trusteeId,
    required this.status,
    required this.createdAt,
    required this.ownerProfile,
    required this.trusteeProfile,
  });

  final String id;
  final String ownerId;
  final String trusteeId;
  final GrantStatus status;
  final DateTime createdAt;
  final Profile ownerProfile;
  final Profile trusteeProfile;

  factory PermissionGrant.fromJson(Map<String, dynamic> json) =>
      PermissionGrant(
        id: json['id'] as String,
        ownerId: json['owner_id'] as String,
        trusteeId: json['trustee_id'] as String,
        status: grantStatusFromString(json['status'] as String),
        createdAt: DateTime.parse(json['created_at'] as String),
        ownerProfile: Profile.fromJson(json['owner'] as Map<String, dynamic>),
        trusteeProfile:
            Profile.fromJson(json['trustee'] as Map<String, dynamic>),
      );

  /// true si `userId` es quien recibiría los límites (dueño del teléfono).
  bool isOwnedBy(String userId) => ownerId == userId;
}
