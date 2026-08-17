/// Una app + límite diario dentro de una propuesta (tabla
/// `limit_proposal_apps`). `appIdentifier` es el bundle id (iOS) o package
/// name (Android) — hoy se elige de un catálogo fijo (ver `AppCatalog`)
/// porque leer la lista real de apps instaladas requiere los módulos
/// nativos de Screen Time / UsageStats (roadmap, no en esta fase).
class LimitProposalApp {
  const LimitProposalApp({
    required this.appIdentifier,
    required this.appDisplayName,
    required this.dailyLimitMinutes,
    this.id,
  });

  final String? id;
  final String appIdentifier;
  final String appDisplayName;
  final int dailyLimitMinutes;

  factory LimitProposalApp.fromJson(Map<String, dynamic> json) =>
      LimitProposalApp(
        id: json['id'] as String?,
        appIdentifier: json['app_identifier'] as String,
        appDisplayName: json['app_display_name'] as String,
        dailyLimitMinutes: json['daily_limit_minutes'] as int,
      );

  Map<String, dynamic> toInsertJson(String proposalId) => {
        'proposal_id': proposalId,
        'app_identifier': appIdentifier,
        'app_display_name': appDisplayName,
        'daily_limit_minutes': dailyLimitMinutes,
      };
}

/// Catálogo fijo de apps candidatas para la v1 (sin acceso todavía a la
/// lista real de apps instaladas en el teléfono del dueño).
class AppCatalogEntry {
  const AppCatalogEntry(this.identifier, this.displayName);
  final String identifier;
  final String displayName;
}

abstract final class AppCatalog {
  static const entries = [
    AppCatalogEntry('com.instagram.app', 'Instagram'),
    AppCatalogEntry('com.tiktok.app', 'TikTok'),
    AppCatalogEntry('com.facebook.app', 'Facebook'),
    AppCatalogEntry('com.google.youtube', 'YouTube'),
    AppCatalogEntry('com.x.app', 'X (Twitter)'),
    AppCatalogEntry('com.snapchat.app', 'Snapchat'),
    AppCatalogEntry('com.whatsapp.app', 'WhatsApp'),
    AppCatalogEntry('com.reddit.app', 'Reddit'),
  ];
}
