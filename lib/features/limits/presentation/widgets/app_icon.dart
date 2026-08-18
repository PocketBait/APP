import 'package:flutter/material.dart';

/// Ícono + color representativo de cada app del catálogo (ver
/// `AppCatalog`). Vive en la capa de presentación (no en el dominio)
/// porque `IconData`/`Color` son de Flutter, no de la lógica de negocio.
///
/// Material Icons no incluye logos de marcas (no existe un ícono oficial
/// de Instagram/TikTok/etc.) — usamos un ícono genérico + un color propio
/// de cada app, suficiente para distinguirlas de un vistazo mientras no
/// haya integración real con Screen Time que traiga el ícono de verdad.
class AppVisual {
  const AppVisual(this.icon, this.color);
  final IconData icon;
  final Color color;
}

const _visuals = <String, AppVisual>{
  'com.instagram.app': AppVisual(Icons.camera_alt, Color(0xFFE1306C)),
  'com.tiktok.app': AppVisual(Icons.music_note, Color(0xFF010101)),
  'com.facebook.app': AppVisual(Icons.groups, Color(0xFF1877F2)),
  'com.google.youtube': AppVisual(Icons.play_circle_fill, Color(0xFFFF0000)),
  'com.x.app': AppVisual(Icons.tag, Color(0xFF000000)),
  'com.snapchat.app': AppVisual(Icons.chat_bubble, Color(0xFFFFFC00)),
  'com.whatsapp.app': AppVisual(Icons.chat, Color(0xFF25D366)),
  'com.reddit.app': AppVisual(Icons.forum, Color(0xFFFF4500)),
};

const _fallback = AppVisual(Icons.apps, Color(0xFF8E8E8E));

AppVisual visualFor(String appIdentifier) =>
    _visuals[appIdentifier] ?? _fallback;

/// Círculo de color con el ícono de la app adentro.
class AppIcon extends StatelessWidget {
  const AppIcon({super.key, required this.appIdentifier, this.size = 32});

  final String appIdentifier;
  final double size;

  @override
  Widget build(BuildContext context) {
    final visual = visualFor(appIdentifier);
    // El amarillo de Snapchat necesita texto/ícono oscuro para verse bien.
    final onColor =
        visual.color.computeLuminance() > 0.6 ? Colors.black87 : Colors.white;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: visual.color, shape: BoxShape.circle),
      child: Icon(visual.icon, color: onColor, size: size * 0.55),
    );
  }
}
