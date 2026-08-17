import 'package:supabase_flutter/supabase_flutter.dart';

/// Envuelve errores de Supabase/Postgres en un mensaje entendible para el
/// usuario, sin perder el error original (útil para logs/depuración).
///
/// Los repositorios (`*_repository.dart`) son los únicos que deben atrapar
/// excepciones "crudas" y convertirlas a `AppException` — así la capa de
/// UI nunca necesita saber qué es un `PostgrestException`.
class AppException implements Exception {
  AppException(this.message, {this.cause});

  final String message;
  final Object? cause;

  factory AppException.from(Object error) {
    if (error is AppException) return error;

    if (error is AuthException) {
      return AppException(_authMessage(error), cause: error);
    }

    if (error is PostgrestException) {
      return AppException(_postgrestMessage(error), cause: error);
    }

    return AppException(
      'Algo salió mal. Revisa tu conexión e intenta de nuevo.',
      cause: error,
    );
  }

  static String _authMessage(AuthException error) {
    final code = error.code;
    if (code == 'invalid_credentials') {
      return 'No pudimos verificar tu identidad. Intenta iniciar sesión de nuevo.';
    }
    return 'No pudimos completar el inicio de sesión (${error.message}).';
  }

  static String _postgrestMessage(PostgrestException error) {
    // 42501 = RLS bloqueó la operación (el usuario intentó algo sin permiso).
    if (error.code == '42501' || error.message.contains('row-level security')) {
      return 'No tienes permiso para hacer esa acción.';
    }
    // 23505 = violación de constraint UNIQUE (ej. solicitud duplicada).
    if (error.code == '23505') {
      return 'Eso ya existe — puede que ya lo hayas hecho antes.';
    }
    // 23514 = violación de CHECK constraint (ej. datos fuera de rango).
    if (error.code == '23514') {
      return 'Algunos datos no son válidos. Revísalos e intenta de nuevo.';
    }
    return 'No se pudo completar la operación. Intenta de nuevo.';
  }

  @override
  String toString() => 'AppException: $message${cause != null ? ' ($cause)' : ''}';
}
