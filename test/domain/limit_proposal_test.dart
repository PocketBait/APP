import 'package:flutter_test/flutter_test.dart';
import 'package:pocketbait/features/limits/domain/limit_proposal.dart';

Map<String, dynamic> _profileJson(String id) => {
      'id': id,
      'username': id,
      'display_name': id,
      'avatar_url': null,
    };

Map<String, dynamic> _proposalJson({
  required String status,
  required String endsAt,
  List<Map<String, dynamic>> apps = const [],
}) =>
    {
      'id': 'prop-1',
      'permission_grant_id': 'grant-1',
      'owner_id': 'owner-1',
      'proposed_by': 'friend-1',
      'status': status,
      'starts_at': null,
      'ends_at': endsAt,
      'note': null,
      'created_at': '2026-01-01T00:00:00Z',
      'owner': _profileJson('owner-1'),
      'proposer': _profileJson('friend-1'),
      'limit_proposal_apps': apps,
    };

void main() {
  group('LimitProposal', () {
    test('isActive es true solo si fue aceptada y no ha vencido', () {
      final future = DateTime.now().add(const Duration(days: 1));
      final proposal = LimitProposal.fromJson(
        _proposalJson(status: 'accepted', endsAt: future.toIso8601String()),
      );
      expect(proposal.isActive, isTrue);
    });

    test('isActive es false si ya venció aunque esté accepted', () {
      final past = DateTime.now().subtract(const Duration(days: 1));
      final proposal = LimitProposal.fromJson(
        _proposalJson(status: 'accepted', endsAt: past.toIso8601String()),
      );
      expect(proposal.isActive, isFalse);
    });

    test('isActive es false si sigue pending, sin importar la fecha', () {
      final future = DateTime.now().add(const Duration(days: 1));
      final proposal = LimitProposal.fromJson(
        _proposalJson(status: 'pending', endsAt: future.toIso8601String()),
      );
      expect(proposal.isActive, isFalse);
    });

    test('isAwaitingResponseFrom solo es true para el owner mientras esté pending',
        () {
      final future = DateTime.now().add(const Duration(days: 1));
      final proposal = LimitProposal.fromJson(
        _proposalJson(status: 'pending', endsAt: future.toIso8601String()),
      );
      expect(proposal.isAwaitingResponseFrom('owner-1'), isTrue);
      expect(proposal.isAwaitingResponseFrom('friend-1'), isFalse);
    });

    test('apps se parsean desde limit_proposal_apps embebido', () {
      final future = DateTime.now().add(const Duration(days: 1));
      final proposal = LimitProposal.fromJson(_proposalJson(
        status: 'accepted',
        endsAt: future.toIso8601String(),
        apps: [
          {
            'id': 'app-1',
            'app_identifier': 'com.instagram.app',
            'app_display_name': 'Instagram',
            'daily_limit_minutes': 30,
          },
        ],
      ));
      expect(proposal.apps, hasLength(1));
      expect(proposal.apps.single.appDisplayName, 'Instagram');
      expect(proposal.apps.single.dailyLimitMinutes, 30);
    });
  });
}
