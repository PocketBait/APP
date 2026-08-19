/// Mi propio perfil, con TODOS los campos (incluidos `phone` y
/// `dateOfBirth`, que son privados — nadie más los puede leer). Distinto
/// de `Profile` (en `features/friends`), que solo trae las columnas
/// públicas y se usa para mostrar a *otras* personas.
class MyProfile {
  const MyProfile({
    required this.id,
    required this.username,
    required this.displayName,
    this.avatarUrl,
    this.phone,
    this.dateOfBirth,
  });

  final String id;
  final String username;
  final String displayName;
  final String? avatarUrl;
  final String? phone;
  final DateTime? dateOfBirth;

  factory MyProfile.fromJson(Map<String, dynamic> json) => MyProfile(
        id: json['id'] as String,
        username: json['username'] as String,
        displayName: json['display_name'] as String,
        avatarUrl: json['avatar_url'] as String?,
        phone: json['phone'] as String?,
        dateOfBirth: json['date_of_birth'] == null
            ? null
            : DateTime.parse(json['date_of_birth'] as String),
      );
}
