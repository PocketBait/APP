import 'dart:convert';

import 'package:crypto/crypto.dart';
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

  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
      // No fallar el logout completo si la sesión de Google ya expiró.
      await _googleSignIn.signOut().catchError((_) {});
    } catch (error) {
      throw AppException.from(error);
    }
  }
}
