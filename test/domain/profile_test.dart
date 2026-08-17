import 'package:flutter_test/flutter_test.dart';
import 'package:pocketbait/features/friends/domain/profile.dart';

void main() {
  group('Profile', () {
    test('fromJson parsea los campos de la fila de Supabase', () {
      final profile = Profile.fromJson({
        'id': 'abc-123',
        'username': 'roberto',
        'display_name': 'Roberto López',
        'avatar_url': null,
      });

      expect(profile.id, 'abc-123');
      expect(profile.username, 'roberto');
      expect(profile.displayName, 'Roberto López');
      expect(profile.avatarUrl, isNull);
    });

    test('initials usa la primera letra del nombre y del apellido', () {
      final profile = Profile.fromJson({
        'id': '1',
        'username': 'roberto',
        'display_name': 'Roberto López',
      });

      expect(profile.initials, 'RL');
    });

    test('initials con un solo nombre usa solo esa letra', () {
      final profile = Profile.fromJson({
        'id': '1',
        'username': 'roberto',
        'display_name': 'Roberto',
      });

      expect(profile.initials, 'R');
    });
  });
}
