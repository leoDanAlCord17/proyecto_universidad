import 'package:flutter/material.dart';
import 'colores_app.dart';

final temaApp = ThemeData(
  useMaterial3: true,
  fontFamily: 'Outfit',
  scaffoldBackgroundColor: ColoresApp.fondo,

  // Deshabilita el gesto swipe-back de iOS en todas las plataformas.
  // CupertinoPageTransitionsBuilder (default en iOS) incluye un gesto
  // que arrastra la pantalla desde el borde izquierdo — no es deseable en
  // una PWA. ZoomPageTransitionsBuilder usa la transición Material 3 sin gestos.
  pageTransitionsTheme: const PageTransitionsTheme(
    builders: {
      TargetPlatform.android: ZoomPageTransitionsBuilder(),
      TargetPlatform.iOS: ZoomPageTransitionsBuilder(),
      TargetPlatform.fuchsia: ZoomPageTransitionsBuilder(),
      TargetPlatform.linux: ZoomPageTransitionsBuilder(),
      TargetPlatform.macOS: ZoomPageTransitionsBuilder(),
      TargetPlatform.windows: ZoomPageTransitionsBuilder(),
    },
  ),

  colorScheme: ColorScheme.fromSeed(
    seedColor: ColoresApp.acento,
    primary: ColoresApp.acento,
    surface: ColoresApp.superficiePrimaria,
    error: ColoresApp.rojo,
  ),

  // ─── SISTEMA DE TEXTOS (DESIGN TOKENS) ──────────────────────
  // Con esto no diseñas texto por texto, solo eliges la categoría.
  textTheme: const TextTheme(
    // Título: "Bienvenido"
    displaySmall: TextStyle(
      fontSize: 32,
      fontWeight: FontWeight.w900,
      color: ColoresApp.textoPrimario,
      letterSpacing: -0.5,
    ),
    // Subtítulo: "Sistema de asistencia..."
    bodyMedium: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: ColoresApp.textoTerciario,
    ),
    // Etiquetas de Inputs: "Correo institucional"
    titleSmall: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: ColoresApp.textoPrimario,
    ),
    // Enlaces/Acciones: "¿Olvidaste tu contraseña?" o "Regístrate"
    labelLarge: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w700,
      color: ColoresApp.acento,
    ),
    // Versión o textos muy pequeños: "v3.0..."
    bodySmall: TextStyle(
      fontSize: 12,
      color: ColoresApp.textoTerciario,
    ),
    // Títulos de tarjetas: nombre de evento, materia
    headlineSmall: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w700,
      color: ColoresApp.textoPrimario,
    ),
    // Subtítulos de tarjetas: horario, lugar, metadatos
    bodyLarge: TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w500,
      color: ColoresApp.textoSecundario,
    ),
    // Etiquetas pequeñas: insignias, nav labels
    labelSmall: TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w600,
      color: ColoresApp.textoTerciario,
    ),
  ),

  appBarTheme: const AppBarTheme(
    backgroundColor: ColoresApp.superficiePrimaria,
    foregroundColor: ColoresApp.textoPrimario,
    elevation: 0,
    centerTitle: false,
    titleTextStyle: TextStyle(
      color: ColoresApp.textoPrimario,
      fontSize: 17,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.3,
    ),
  ),

  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: ColoresApp.superficieSecund,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    // Bordes suavizados a 12px según la imagen de referencia
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: ColoresApp.bordeMedio),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: ColoresApp.bordeMedio),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: ColoresApp.acentoBorde, width: 1.5),
    ),
    hintStyle: const TextStyle(
      color: ColoresApp.textoTerciario,
      fontSize: 14,
    ),
  ),

  dividerTheme: const DividerThemeData(
    color: ColoresApp.bordesuave,
    thickness: 1,
    space: 1,
  ),
);
