/// Perfil público de un usuario (tabla `profiles`).
class Profile {
  const Profile({
    required this.id,
    required this.username,
    required this.displayName,
    this.avatarUrl,
    this.mutualFriendsCount = 0,
  });

  final String id;
  final String username;
  final String displayName;
  final String? avatarUrl;

  /// Solo viene lleno cuando el perfil salió de `search_profiles` (la
  /// búsqueda de gente nueva) — en cualquier otro contexto queda en 0.
  final int mutualFriendsCount;

  factory Profile.fromJson(Map<String, dynamic> json) => Profile(
        id: json['id'] as String,
        username: json['username'] as String,
        displayName: json['display_name'] as String,
        avatarUrl: json['avatar_url'] as String?,
        mutualFriendsCount:
            (json['mutual_friends_count'] as num?)?.toInt() ?? 0,
      );

  String get initials {
    final parts = displayName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    final first = parts.first[0];
    final last = parts.length > 1 ? parts.last[0] : '';
    return (first + last).toUpperCase();
  }
}
