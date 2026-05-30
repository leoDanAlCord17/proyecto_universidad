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
  static const sombraTarjeta  = Color(0x0F5B3FD4);
  static const sombraAcento   = Color(0x1A5B3FD4);  // acento 10%
  static const sombraGeneral  = Color(0x1A000000);
  static const sombraBarrera  = Color(0x66000000);  // overlay oscuro de modales

  // ─── BORDES SEMÁNTICOS (transparencias) ───────────────
  static const bordeAviso     = Color(0x400F7EA0);   // teal  40%
  static const bordeExito     = Color(0x401A9462);   // verde 40%
  static const bordeError     = Color(0x40C23B3B);   // rojo  40%

  static const blanco = Color.fromARGB(255, 255, 255, 255);

  // ─── ESCÁNER QR (tema oscuro) ─────────────────────────────────────
  static const scannerFondo       = Color(0xFF0D0D1A);  // fondo cámara
  static const scannerOverlay     = Color(0xA6000000);  // máscara 65%
  static const scannerEsquina     = Color(0xFF00C9A7);  // marco listo
  static const scannerVerdeOscuro = Color(0xFF092B1A);  // tarjeta confirmado
  static const scannerAmbarOscuro = Color(0xFF2B1800);  // tarjeta ya registrado
  static const scannerRojoOscuro  = Color(0xFF2B0808);  // tarjeta inválido / sin acceso
  static const scannerAzulOscuro  = Color(0xFF0D1829);  // tarjeta no disponible
  static const scannerGris        = Color(0xFF607D8B);  // blueGrey base
  static const scannerGrisClaro   = Color(0xFF90A4AE);  // blueGrey 300
  static const scannerGrisOscuro  = Color(0xFF546E7A);  // blueGrey 600

  // ─── BORDES ADICIONALES ───────────────────────────────────────────
  static const bordeSutilVerde = Color(0x1A1A9462);   // verde  10%
  static const bordeSuaveVerde = Color(0x261A9462);   // verde  15%
}