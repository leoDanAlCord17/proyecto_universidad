import 'package:flutter/material.dart';

// Todos los colores de UniAsist en un solo lugar.
// Si el diseño cambia, solo se toca este archivo.
// Ningún widget escribe colores directamente con Color(0xFF...).
abstract class ColoresApp {

  // ─── MARCA ────────────────────────────────────────────
  static const acento      = Color(0xFF5B3FD4);
  static const acento2     = Color(0xFF8B6CF0);
  static const acentoClaro = Color(0xFFEDE9FB);
  static const acentoBorde = Color(0xFFB5A6F0);

  // ─── GRADIENTE ────────────────────────────────────────
  // Úsalo con: gradient: ColoresApp.degradadoPrincipal
  static const degradadoPrincipal = LinearGradient(
    colors: [acento, acento2],
    begin: Alignment.topLeft,
    end:   Alignment.bottomRight,
  );

  // ─── TEXTO ────────────────────────────────────────────
  static const textoPrimario   = Color(0xFF1C1830);
  static const textoSecundario = Color(0xFF6B6480);
  static const textoTerciario  = Color(0xFFA49EBB);

  // ─── SUPERFICIES ──────────────────────────────────────
  static const fondo              = Color(0xFFEEEDF5);
  static const superficiePrimaria = Color(0xFFFFFFFF);
  static const superficieSecund   = Color(0xFFF4F3F9);
  static const superficieTerciar  = Color(0xFFE8E6F2);

  // ─── BORDES ───────────────────────────────────────────
  static const bordesuave  = Color(0x145B3FD4);  // muy sutil
  static const bordeMedio  = Color(0x265B3FD4);  // visible
  static const bordeFuerte = Color(0xFFB5A6F0);  // énfasis

  // ─── SEMÁNTICOS ───────────────────────────────────────
  // Verde — éxito, presente, completado
  static const verde       = Color(0xFF1A9462);
  static const verdeClaro  = Color(0xFFE2F5EE);

  // Ámbar — advertencia, programado, anticipado
  static const ambar       = Color(0xFFB97010);
  static const ambarClaro  = Color(0xFFFDF2E0);

  // Rojo — error, ausente, cancelado
  static const rojo        = Color(0xFFC23B3B);
  static const rojoClaro   = Color(0xFFFBEAEA);

  // Teal — información, foráneo
  static const teal        = Color(0xFF0F7EA0);
  static const tealClaro   = Color(0xFFE2F3FA);

  // ─── SOMBRA ───────────────────────────────────────────
  static const sombraTarjeta = Color(0x0F5B3FD4);

  static const blanco = Color.fromARGB(255, 255, 255, 255);
}