import 'dart:async' show TimeoutException;

import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uniasist/compartido/constantes.dart';
import 'package:uniasist/compartido/errores.dart';
import 'package:uniasist/compartido/traductor_errores.dart';

void main() {
  group('TraductorErrores.deAuth', () {
    test('statusCode 400 → correo o contraseña incorrectos', () {
      const e = AuthException('error', statusCode: '400');
      expect(TraductorErrores.deAuth(e), 'Correo o contraseña incorrectos.');
    });

    test('statusCode 422 → formato de correo inválido', () {
      const e = AuthException('error', statusCode: '422');
      expect(TraductorErrores.deAuth(e), 'El formato del correo no es válido.');
    });

    test('statusCode 429 → demasiados intentos', () {
      const e = AuthException('error', statusCode: '429');
      expect(
        TraductorErrores.deAuth(e),
        'Demasiados intentos. Espera unos minutos e intenta de nuevo.',
      );
    });

    test('statusCode 500 → error de conexión', () {
      const e = AuthException('error', statusCode: '500');
      expect(TraductorErrores.deAuth(e), MensajesError.conexion);
    });

    test('mensaje "already registered" → cuenta existente', () {
      const e = AuthException('User already registered');
      expect(
        TraductorErrores.deAuth(e),
        'Este correo ya tiene una cuenta. Inicia sesión.',
      );
    });

    test('mensaje "email not confirmed" → confirmar correo', () {
      const e = AuthException('email not confirmed');
      expect(
        TraductorErrores.deAuth(e),
        'Debes confirmar tu correo antes de ingresar.',
      );
    });

    test('mensaje "password should be" → contraseña corta con número', () {
      const e = AuthException('Password should be at least 6 characters');
      expect(
        TraductorErrores.deAuth(e),
        'La contraseña debe tener al menos 8 caracteres e incluir un número.',
      );
    });

    test('mensaje "signup is disabled" → registro no disponible', () {
      const e = AuthException('Signup is disabled');
      expect(
        TraductorErrores.deAuth(e),
        'El registro no está disponible en este momento.',
      );
    });

    test('mensaje "invalid" → credenciales incorrectas', () {
      const e = AuthException('invalid login credentials');
      expect(TraductorErrores.deAuth(e), 'Correo o contraseña incorrectos.');
    });

    test('mensaje desconocido sin statusCode → error inesperado', () {
      const e = AuthException('some unknown error');
      expect(TraductorErrores.deAuth(e), MensajesError.inesperado);
    });
  });

  group('TraductorErrores.dePostgres', () {
    test('código 23505 → registro duplicado', () {
      const e = PostgrestException(message: 'duplicate key', code: '23505');
      expect(TraductorErrores.dePostgres(e),
          'Ya existe un registro con esos datos.');
    });

    test('código 23503 → referencia inexistente', () {
      const e =
          PostgrestException(message: 'foreign key violation', code: '23503');
      expect(
        TraductorErrores.dePostgres(e),
        'La operación no es válida: referencia inexistente.',
      );
    });

    test('código 23502 → datos obligatorios faltantes', () {
      const e =
          PostgrestException(message: 'not null violation', code: '23502');
      expect(TraductorErrores.dePostgres(e), 'Faltan datos obligatorios.');
    });

    test('código 42501 → sin permiso', () {
      const e = PostgrestException(message: 'permission denied', code: '42501');
      expect(TraductorErrores.dePostgres(e), MensajesError.permiso);
    });

    test('código PGRST116 → no encontrado', () {
      const e = PostgrestException(message: 'not found', code: 'PGRST116');
      expect(TraductorErrores.dePostgres(e), 'No se encontraron resultados.');
    });

    test('código PGRST204 → no encontrado', () {
      const e = PostgrestException(message: 'no content', code: 'PGRST204');
      expect(TraductorErrores.dePostgres(e), 'No se encontraron resultados.');
    });

    test('código PGRST301 → sesión expirada', () {
      const e = PostgrestException(message: 'expired token', code: 'PGRST301');
      expect(TraductorErrores.dePostgres(e), MensajesError.sesion);
    });

    test('código desconocido → error inesperado', () {
      const e = PostgrestException(message: 'unknown error', code: '99999');
      expect(TraductorErrores.dePostgres(e), MensajesError.inesperado);
    });
  });

  group('TraductorErrores.lanzarInesperado', () {
    test('TimeoutException → lanza FallaRed con mensaje de timeout', () {
      expect(
        () => TraductorErrores.lanzarInesperado(TimeoutException('timed out')),
        throwsA(
          isA<FallaRed>()
              .having((e) => e.mensaje, 'mensaje', MensajesError.timeout),
        ),
      );
    });

    test('contiene "SocketException" → lanza FallaRed con mensaje de conexión',
        () {
      expect(
        () => TraductorErrores.lanzarInesperado(
          Exception('SocketException: connection refused'),
        ),
        throwsA(
          isA<FallaRed>()
              .having((e) => e.mensaje, 'mensaje', MensajesError.conexion),
        ),
      );
    });

    test('contiene "network" → lanza FallaRed con mensaje de conexión', () {
      expect(
        () => TraductorErrores.lanzarInesperado(Exception('network error')),
        throwsA(
          isA<FallaRed>()
              .having((e) => e.mensaje, 'mensaje', MensajesError.conexion),
        ),
      );
    });

    test('contiene "connection" → lanza FallaRed con mensaje de conexión', () {
      expect(
        () =>
            TraductorErrores.lanzarInesperado(Exception('connection timeout')),
        throwsA(
          isA<FallaRed>()
              .having((e) => e.mensaje, 'mensaje', MensajesError.conexion),
        ),
      );
    });

    test('error genérico → lanza FallaInesperada', () {
      expect(
        () => TraductorErrores.lanzarInesperado(Exception('some other error')),
        throwsA(isA<FallaInesperada>()),
      );
    });
  });
}
