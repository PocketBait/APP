import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Acceso centralizado a las variables de entorno (ver `.env.example`).
///
/// Nunca leas `dotenv.env[...]` directamente fuera de este archivo — así,
/// si algún día cambiamos de dónde vienen los secretos (por ejemplo a
/// `--dart-define` en CI), solo se toca este archivo.
class Env {
  Env._();

  static Future<void> load() => dotenv.load(fileName: '.env');

  static String get supabaseUrl => _require('SUPABASE_URL');
  static String get supabasePublishableKey =>
      _require('SUPABASE_PUBLISHABLE_KEY');
  static String get googleWebClientId => _require('GOOGLE_WEB_CLIENT_ID');
  static String get googleIosClientId => _require('GOOGLE_IOS_CLIENT_ID');

  static String _require(String key) {
    final value = dotenv.env[key];
    if (value == null || value.isEmpty || value.startsWith('TU-')) {
      throw StateError(
        'Falta configurar "$key" en tu archivo .env local. '
        'Revisa docs/SETUP.md para saber de dónde sacar este valor.',
      );
    }
    return value;
  }
}
