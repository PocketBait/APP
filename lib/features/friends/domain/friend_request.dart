import 'profile.dart';

enum FriendRequestStatus { pending, accepted, declined, cancelled }

FriendRequestStatus statusFromString(String value) => switch (value) {
      'pending' => FriendRequestStatus.pending,
      'accepted' => FriendRequestStatus.accepted,
      'declined' => FriendRequestStatus.declined,
      'cancelled' => FriendRequestStatus.cancelled,
      _ => throw ArgumentError('Estado de solicitud desconocido: $value'),
    };

/// Solicitud de amistad (tabla `friend_requests`). Una vez `accepted`, esta
/// misma fila representa la amistad — no hay una tabla separada.
///
/// `requesterProfile`/`addresseeProfile` vienen embebidos desde Postgres
/// (join implícito vía foreign key) para no tener que hacer una segunda
/// consulta por cada fila.
class FriendRequest {
  const FriendRequest({
    required this.id,
    required this.requesterId,
    required this.addresseeId,
    required this.status,
    required this.createdAt,
    required this.requesterProfile,
    required this.addresseeProfile,
  });

  final String id;
  final String requesterId;
  final String addresseeId;
  final FriendRequestStatus status;
  final DateTime createdAt;
  final Profile requesterProfile;
  final Profile addresseeProfile;

  factory FriendRequest.fromJson(Map<String, dynamic> json) => FriendRequest(
        id: json['id'] as String,
        requesterId: json['requester_id'] as String,
        addresseeId: json['addressee_id'] as String,
        status: statusFromString(json['status'] as String),
        createdAt: DateTime.parse(json['created_at'] as String),
        requesterProfile:
            Profile.fromJson(json['requester'] as Map<String, dynamic>),
        addresseeProfile:
            Profile.fromJson(json['addressee'] as Map<String, dynamic>),
      );

  /// El perfil de "la otra persona" relativo a `currentUserId`.
  Profile otherProfile(String currentUserId) =>
      requesterId == currentUserId ? addresseeProfile : requesterProfile;

  bool isIncomingFor(String userId) =>
      addresseeId == userId && status == FriendRequestStatus.pending;

  bool isOutgoingFrom(String userId) =>
      requesterId == userId && status == FriendRequestStatus.pending;

  /// true si esta fila es exactamente entre estas dos personas (en
  /// cualquier orden).
  bool isBetween(String userId, String otherUserId) =>
      (requesterId == userId && addresseeId == otherUserId) ||
      (requesterId == otherUserId && addresseeId == userId);
}

/// Con qué situación te encuentras respecto a otra persona — se usa para
/// decidir qué botón mostrar en resultados de búsqueda ("Agregar" solo
/// tiene sentido en `none`).
enum FriendRelationship {
  none,
  friends,
  requestSentByMe,
  requestReceivedFromThem,
}

/// Calcula la relación con `otherId` a partir de tus solicitudes ya
/// conocidas (`myRequests`), sin volver a consultar la base de datos.
FriendRelationship relationshipWith({
  required String myId,
  required String otherId,
  required List<FriendRequest> myRequests,
}) {
  for (final request in myRequests) {
    if (!request.isBetween(myId, otherId)) continue;
    switch (request.status) {
      case FriendRequestStatus.accepted:
        return FriendRelationship.friends;
      case FriendRequestStatus.pending:
        return request.requesterId == myId
            ? FriendRelationship.requestSentByMe
            : FriendRelationship.requestReceivedFromThem;
      case FriendRequestStatus.declined:
      case FriendRequestStatus.cancelled:
        continue; // no impide volver a intentarlo
    }
  }
  return FriendRelationship.none;
}
