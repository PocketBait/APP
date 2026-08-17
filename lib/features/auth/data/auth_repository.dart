import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/env.dart';
import '../../../core/utils/app_exception.dart';

/// Login con Google/Apple + sesión. Todo lo que toca los SDKs nativos de
/// cada proveedor vive acá — el resto de la app solo conoce
/// `onAuthStateChange` y `currentSession`.
class AuthRepository {
  AuthRepository(this._client);

  final SupabaseClient _client;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  Future<void>? _googleSignInReady;

  Stream<AuthState> get onAuthStateChange => _client.auth.onAuthStateChange;
  Session? get currentSession => _client.auth.currentSession;

  /// La URL "base" de la app publicada (origen + primer segmento de ruta,
  /// ej. `https://pocketbait.github.io/APP/`), sin importar en qué
  /// pantalla estemos parados. Se usa como `redirectTo` en los flujos que
  /// regresan del navegador (Google, reset de contraseña) para que
  /// siempre coincida con lo dado de alta en "Redirect URLs" de Supabase,
  /// en vez de depender de la URL exacta de la pantalla actual.
  String get _webAppBaseUrl {
    final uri = Uri.base;
    final basePath =
        uri.pathSegments.isNotEmpty ? '/${uri.pathSegments.first}/' : '/';
    return '${uri.origin}$basePath';
  }

  /// `initialize()` debe llamarse exactamente una vez y su future debe
  /// completarse antes de usar cualquier otro método de GoogleSignIn — lo
  /// memorizamos para que la primera llamada a `signInWithGoogle` lo haga
  /// de forma segura sin importar cuántas veces se invoque este método.
  Future<void> _ensureGoogleSignInReady() {
    return _googleSignInReady ??= _googleSignIn.initialize(
      clientId: Env.googleIosClientId,
      serverClientId: Env.googleWebClientId,
    );
  }

  Future<void> signInWithGoogle() async {
    // En web usamos el flujo de redirección estándar de OAuth (abre Google
    // en la misma pestaña y regresa) en vez del SDK nativo: es el que
    // funciona en un navegador y reutiliza el mismo Client ID "Web" que ya
    // configuramos como redirect URI en Google Cloud / Supabase.
    if (kIsWeb) {
      try {
        // Pasamos explícitamente a dónde regresar: sin esto, Supabase usa
        // el "Site URL" configurado en su dashboard (por default
        // localhost), que no coincide con donde esté publicada la app.
        await _client.auth.signInWithOAuth(
          OAuthProvider.google,
          redirectTo: _webAppBaseUrl,
        );
      } catch (error) {
        throw AppException.from(error);
      }
      return;
    }

    try {
      await _ensureGoogleSignInReady();
      final account = await _googleSignIn.authenticate();
      final idToken = account.authentication.idToken;
      if (idToken == null) {
        throw AppException(
          'Google no devolvió un token de identidad. Intenta de nuevo.',
        );
      }
      final authorization =
          await account.authorizationClient.authorizationForScopes(const []);

      await _client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: authorization?.accessToken,
      );
    } on GoogleSignInException catch (error) {
      // El usuario cerró el selector de cuenta: no es un error a mostrar.
      if (error.code == GoogleSignInExceptionCode.canceled) return;
      throw AppException.from(error);
    } catch (error) {
      throw AppException.from(error);
    }
  }

  Future<void> signInWithApple() async {
    try {
      // Supabase exige un nonce para verificar que el idToken de Apple fue
      // emitido para esta sesión específica y no reutilizado (replay).
      final rawNonce = _client.auth.generateRawNonce();
      final hashedNonce = sha256.convert(utf8.encode(rawNonce)).toString();

      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: const [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: hashedNonce,
      );

      final idToken = credential.identityToken;
      if (idToken == null) {
        throw AppException(
          'Apple no devolvió un token de identidad. Intenta de nuevo.',
        );
      }

      await _client.auth.signInWithIdToken(
        provider: OAuthProvider.apple,
        idToken: idToken,
        nonce: rawNonce,
      );
    } on SignInWithAppleAuthorizationException catch (error) {
      if (error.code == AuthorizationErrorCode.canceled) return;
      throw AppException.from(error);
    } catch (error) {
      throw AppException.from(error);
    }
  }

  /// Crea la cuenta con correo + contraseña. El resto de los datos
  /// (username, nombre, teléfono, fecha de nacimiento) se mandan como
  /// metadata y el trigger `handle_new_user` en la base de datos arma la
  /// fila de `profiles` con ellos.
  ///
  /// Devuelve `true` si Supabase requiere confirmar el correo antes de
  /// poder iniciar sesión (no hay sesión activa todavía justo después de
  /// registrarse); `false` si ya quedó con sesión iniciada.
  Future<bool> signUpWithEmail({
    required String email,
    required String password,
    required String username,
    required String fullName,
    required String phone,
    required DateTime dateOfBirth,
  }) async {
    try {
      final response = await _client.auth.signUp(
        email: email.trim(),
        password: password,
        // Sin esto, el link del correo de confirmación usa el "Site URL"
        // fijo del dashboard de Supabase en vez de a dónde sea que esté
        // publicada la app ahora mismo (mismo motivo que en signInWithGoogle
        // y resetPassword).
        emailRedirectTo: kIsWeb ? _webAppBaseUrl : null,
        data: {
          'username': username.trim().toLowerCase(),
          'full_name': fullName.trim(),
          'phone': phone.trim(),
          'date_of_birth': dateOfBirth.toIso8601String().split('T').first,
        },
      );
      return response.session == null;
    } catch (error) {
      throw AppException.from(error);
    }
  }

  /// Acepta correo o username en `identifier`. Si no trae "@" lo tratamos
  /// como username y lo resolvemos a un correo con una función de la base
  /// de datos antes de intentar el login — Supabase Auth solo sabe
  /// autenticar por correo.
  Future<void> signInWithEmailOrUsername({
    required String identifier,
    required String password,
  }) async {
    try {
      final trimmed = identifier.trim();
      String email;
      if (trimmed.contains('@')) {
        email = trimmed;
      } else {
        final resolved = await _client.rpc(
          'get_email_by_username',
          params: {'p_username': trimmed.toLowerCase()},
        ) as String?;
        if (resolved == null) {
          throw AppException('No encontramos una cuenta con ese usuario.');
        }
        email = resolved;
      }
      await _client.auth.signInWithPassword(email: email, password: password);
    } catch (error) {
      throw AppException.from(error);
    }
  }

  /// Manda el correo de "recuperar contraseña". El link de ese correo abre
  /// la app y dispara un evento `passwordRecovery` que el router usa para
  /// llevarte a la pantalla de "nueva contraseña".
  Future<void> resetPassword(String email) async {
    try {
      await _client.auth.resetPasswordForEmail(
        email.trim(),
        redirectTo: kIsWeb ? _webAppBaseUrl : null,
      );
    } catch (error) {
      throw AppException.from(error);
    }
  }

  /// Solo válido durante una sesión de recuperación (después de abrir el
  /// link del correo de "olvidé mi contraseña").
  Future<void> updatePassword(String newPassword) async {
    try {
      await _client.auth.updateUser(UserAttributes(password: newPassword));
    } catch (error) {
      throw AppException.from(error);
    }
  }

  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
      // En web nunca se inicializó el SDK nativo de Google (se usó
      // signInWithOAuth), así que no hay nada que cerrar ahí.
      if (!kIsWeb) {
        // No fallar el logout completo si la sesión de Google ya expiró.
        await _googleSignIn.signOut().catchError((_) {});
      }
    } catch (error) {
      throw AppException.from(error);
    }
  }
}
