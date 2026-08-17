import 'package:flutter/material.dart';

/// Tema visual único de PocketBait. Centralizado acá para que ninguna
/// pantalla defina colores "a mano" — así la app se ve consistente y es
/// trivial ajustar la identidad visual más adelante.
///
/// Inspirado en el lenguaje visual de Instagram: fondo blanco/negro plano,
/// texto en negro/gris (nada de superficies "pintadas" de color como hace
/// Material por default), y el color de marca reservado solo para lo que
/// importa — botones principales, links, seleccionado en la barra inferior
/// y la bolita de notificación.
abstract final class AppTheme {
  // Verde-azulado: el acento de marca de PocketBait. A propósito NO es el
  // azul de Instagram — tomamos de ahí la simpleza de la estructura, no
  // la paleta. Es el único color "fuerte" en toda la app.
  static const _accent = Color(0xFF0F766E);
  static const _accentDark = Color(0xFF2DD4BF);

  // Rojo tipo Instagram para errores y la bolita de notificación.
  static const _error = Color(0xFFED4956);

  static ThemeData light() => _base(_lightScheme);
  static ThemeData dark() => _base(_darkScheme);

  static final _lightScheme = ColorScheme.light(
    primary: _accent,
    onPrimary: Colors.white,
    primaryContainer: _accent,
    onPrimaryContainer: Colors.white,
    secondary: _accent,
    surface: Colors.white,
    onSurface: const Color(0xFF0A0A0A),
    surfaceContainerLow: const Color(0xFFFAFAFA),
    surfaceContainerHighest: const Color(0xFFF2F2F2),
    outline: const Color(0xFF8E8E8E),
    outlineVariant: const Color(0xFFDBDBDB),
    error: _error,
    onError: Colors.white,
  );

  static final _darkScheme = ColorScheme.dark(
    primary: _accentDark,
    onPrimary: Colors.black,
    primaryContainer: _accentDark,
    onPrimaryContainer: Colors.black,
    secondary: _accentDark,
    surface: const Color(0xFF000000),
    onSurface: const Color(0xFFF5F5F5),
    surfaceContainerLow: const Color(0xFF1A1A1A),
    surfaceContainerHighest: const Color(0xFF262626),
    outline: const Color(0xFF8E8E8E),
    outlineVariant: const Color(0xFF262626),
    error: _error,
    onError: Colors.black,
  );

  static ThemeData _base(ColorScheme scheme) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      dividerColor: scheme.outlineVariant,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: scheme.onSurface,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
      // Tarjetas planas con un borde delgado en vez de un fondo "pintado"
      // — es lo que le da el aire limpio/minimalista, no relleno de color.
      cardTheme: CardThemeData(
        elevation: 0,
        color: scheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: scheme.outlineVariant),
        ),
        margin: EdgeInsets.zero,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          side: BorderSide(color: scheme.outlineVariant),
          foregroundColor: scheme.onSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: scheme.primary),
      ),
      // Campos de texto rellenos en gris muy claro, sin borde visible —
      // el mismo look que el formulario de login de Instagram.
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerLow,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      // Chips tipo "outline" (contorno, sin relleno) en vez de pastillas
      // de color sólido.
      chipTheme: ChipThemeData(
        backgroundColor: scheme.surface,
        side: BorderSide(color: scheme.outlineVariant),
        labelStyle: TextStyle(color: scheme.onSurface, fontSize: 13),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      ),
      // Barra inferior sin la "pastilla" de indicador de Material — el
      // ícono relleno + el color de acento ya marcan la pestaña activa,
      // igual que en Instagram.
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surface,
        indicatorColor: Colors.transparent,
        elevation: 0,
        height: 62,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontSize: 11,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? scheme.onSurface : scheme.outline,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? scheme.onSurface : scheme.outline,
          );
        }),
      ),
      badgeTheme: BadgeThemeData(
        backgroundColor: scheme.error,
        textColor: scheme.onError,
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        thickness: 1,
        space: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: scheme.onSurface,
        contentTextStyle: TextStyle(color: scheme.surface),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
}

/// Espaciados consistentes (evita "16, 12, 18..." repartidos por el código).
abstract final class AppSpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
}
