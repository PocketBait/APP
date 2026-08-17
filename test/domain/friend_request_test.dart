import 'package:flutter_test/flutter_test.dart';
import 'package:pocketbait/features/friends/domain/friend_request.dart';

Map<String, dynamic> _profileJson(String id, String username) => {
      'id': id,
      'username': username,
      'display_name': username,
      'avatar_url': null,
    };

FriendRequest _requestJson({required String status}) => FriendRequest.fromJson({
      'id': 'req-1',
      'requester_id': 'user-a',
      'addressee_id': 'user-b',
      'status': status,
      'created_at': '2026-01-01T00:00:00Z',
      'requester': _profileJson('user-a', 'ana'),
      'addressee': _profileJson('user-b', 'beto'),
    });

void main() {
  group('FriendRequest', () {
    test('otherProfile devuelve al addressee cuando el actual es requester',
        () {
      final request = _requestJson(status: 'pending');
      expect(request.otherProfile('user-a').username, 'beto');
    });

    test('otherProfile devuelve al requester cuando el actual es addressee',
        () {
      final request = _requestJson(status: 'pending');
      expect(request.otherProfile('user-b').username, 'ana');
    });

    test('isIncomingFor solo es true para el addressee mientras esté pending',
        () {
      final request = _requestJson(status: 'pending');
      expect(request.isIncomingFor('user-b'), isTrue);
      expect(request.isIncomingFor('user-a'), isFalse);
    });

    test('isIncomingFor es false si ya fue respondida', () {
      final request = _requestJson(status: 'accepted');
      expect(request.isIncomingFor('user-b'), isFalse);
    });

    test('isOutgoingFrom solo es true para el requester mientras esté pending',
        () {
      final request = _requestJson(status: 'pending');
      expect(request.isOutgoingFrom('user-a'), isTrue);
      expect(request.isOutgoingFrom('user-b'), isFalse);
    });
  });

  group('relationshipWith', () {
    test('friends cuando la solicitud entre ambos está accepted', () {
      final result = relationshipWith(
        myId: 'user-a',
        otherId: 'user-b',
        myRequests: [_requestJson(status: 'accepted')],
      );
      expect(result, FriendRelationship.friends);
    });

    test('requestSentByMe cuando yo soy el requester y sigue pending', () {
      final result = relationshipWith(
        myId: 'user-a',
        otherId: 'user-b',
        myRequests: [_requestJson(status: 'pending')],
      );
      expect(result, FriendRelationship.requestSentByMe);
    });

    test('requestReceivedFromThem cuando yo soy el addressee y sigue pending',
        () {
      final result = relationshipWith(
        myId: 'user-b',
        otherId: 'user-a',
        myRequests: [_requestJson(status: 'pending')],
      );
      expect(result, FriendRelationship.requestReceivedFromThem);
    });

    test('none si la única solicitud entre ambos fue rechazada o cancelada',
        () {
      for (final status in ['declined', 'cancelled']) {
        final result = relationshipWith(
          myId: 'user-a',
          otherId: 'user-b',
          myRequests: [_requestJson(status: status)],
        );
        expect(result, FriendRelationship.none, reason: 'status=$status');
      }
    });

    test('none cuando no hay ninguna solicitud entre ambos', () {
      final result = relationshipWith(
        myId: 'user-a',
        otherId: 'user-c',
        myRequests: [_requestJson(status: 'accepted')],
      );
      expect(result, FriendRelationship.none);
    });
  });
}
