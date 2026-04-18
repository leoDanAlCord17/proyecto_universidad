import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:uniasist/compartido/constantes.dart';
import 'package:uniasist/compartido/errores.dart';
import 'package:uniasist/funcionalidades/autenticacion/registro_cubit.dart';
import 'package:uniasist/funcionalidades/autenticacion/registro_estado.dart';

import '../../helpers.dart';

void main() {
  late MockAutenticacionRepositorio repositorio;

  setUp(() {
    registrarFallbacks();
    repositorio = MockAutenticacionRepositorio();
  });

  group('RegistroCubit', () {
    test('estado inicial es RegistroInicial', () {
      final cubit = RegistroCubit(repositorio);
      expect(cubit.state, isA<RegistroInicial>());
      cubit.close();
    });

    blocTest<RegistroCubit, RegistroEstado>(
      'emite RegistroError cuando correo está vacío',
      build: () => RegistroCubit(repositorio),
      act: (c) => c.registrarse('', 'clave123', 'clave123'),
      expect: () => [
        isA<RegistroError>().having(
          (e) => e.mensaje,
          'mensaje',
          'Por favor, llena todos los campos.',
        ),
      ],
    );

    blocTest<RegistroCubit, RegistroEstado>(
      'emite RegistroError cuando clave está vacía',
      build: () => RegistroCubit(repositorio),
      act: (c) => c.registrarse('leo@uni.edu', '', ''),
      expect: () => [isA<RegistroError>()],
    );

    blocTest<RegistroCubit, RegistroEstado>(
      'emite RegistroError cuando las contraseñas no coinciden',
      build: () => RegistroCubit(repositorio),
      act: (c) => c.registrarse('leo@uni.edu', 'clave123', 'clave456'),
      expect: () => [
        isA<RegistroError>().having(
          (e) => e.mensaje,
          'mensaje',
          'Las contraseñas no coinciden.',
        ),
      ],
    );

    blocTest<RegistroCubit, RegistroEstado>(
      'emite RegistroError cuando contraseña tiene menos de 6 caracteres',
      build: () => RegistroCubit(repositorio),
      act: (c) => c.registrarse('leo@uni.edu', '123', '123'),
      expect: () => [
        isA<RegistroError>().having(
          (e) => e.mensaje,
          'mensaje',
          'La contraseña debe tener al menos 6 caracteres.',
        ),
      ],
    );

    blocTest<RegistroCubit, RegistroEstado>(
      'no llama el repositorio cuando los campos son inválidos',
      build: () => RegistroCubit(repositorio),
      act: (c) => c.registrarse('', '', ''),
      verify: (_) {
        verifyNever(() => repositorio.registrarse(any(), any()));
      },
    );

    blocTest<RegistroCubit, RegistroEstado>(
      'emite [RegistroCargando, RegistroExito] en caso exitoso',
      build: () {
        when(() => repositorio.registrarse(any(), any()))
            .thenAnswer((_) async => MockAuthResponse());
        return RegistroCubit(repositorio);
      },
      act: (c) => c.registrarse('leo@uni.edu', 'clave123', 'clave123'),
      expect: () => [isA<RegistroCargando>(), isA<RegistroExito>()],
    );

    blocTest<RegistroCubit, RegistroEstado>(
      'emite [RegistroCargando, RegistroError] al recibir FallaAutenticacion',
      build: () {
        when(() => repositorio.registrarse(any(), any()))
            .thenThrow(
              const FallaAutenticacion('Este correo ya tiene una cuenta.'),
            );
        return RegistroCubit(repositorio);
      },
      act: (c) => c.registrarse('leo@uni.edu', 'clave123', 'clave123'),
      expect: () => [
        isA<RegistroCargando>(),
        isA<RegistroError>().having(
          (e) => e.mensaje,
          'mensaje',
          'Este correo ya tiene una cuenta.',
        ),
      ],
    );

    blocTest<RegistroCubit, RegistroEstado>(
      'emite [RegistroCargando, RegistroError] al recibir FallaInesperada',
      build: () {
        when(() => repositorio.registrarse(any(), any()))
            .thenThrow(const FallaInesperada('Sin conexión.'));
        return RegistroCubit(repositorio);
      },
      act: (c) => c.registrarse('leo@uni.edu', 'clave123', 'clave123'),
      expect: () => [
        isA<RegistroCargando>(),
        isA<RegistroError>().having(
          (e) => e.mensaje,
          'mensaje',
          MensajesError.inesperado,
        ),
      ],
    );
  });
}
