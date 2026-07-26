import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:activiti/compartido/errores.dart';
import 'package:activiti/funcionalidades/nueva_contrasena/nueva_contrasena_cubit.dart';
import 'package:activiti/funcionalidades/nueva_contrasena/nueva_contrasena_estado.dart';

import '../../helpers.dart';

void main() {
  late MockAutenticacionRepositorio repositorio;

  setUp(() {
    repositorio = MockAutenticacionRepositorio();
    registrarFallbacks();
  });

  NuevaContrasenaCubit build() => NuevaContrasenaCubit(repositorio);

  group('NuevaContrasenaCubit', () {
    test('estado inicial es NuevaContrasenaInicial', () {
      expect(build().state, isA<NuevaContrasenaInicial>());
    });

    blocTest<NuevaContrasenaCubit, NuevaContrasenaEstado>(
      'emite Error cuando la clave tiene menos de 6 caracteres',
      build: build,
      act: (c) => c.cambiar(nuevaClave: '12345', confirmacion: '12345'),
      expect: () => [
        isA<NuevaContrasenaError>().having(
          (e) => e.mensaje,
          'mensaje',
          contains('6 caracteres'),
        ),
      ],
    );

    blocTest<NuevaContrasenaCubit, NuevaContrasenaEstado>(
      'emite Error cuando las contraseñas no coinciden',
      build: build,
      act: (c) => c.cambiar(nuevaClave: 'clave123', confirmacion: 'otraClave'),
      expect: () => [
        isA<NuevaContrasenaError>().having(
          (e) => e.mensaje,
          'mensaje',
          contains('no coinciden'),
        ),
      ],
    );

    blocTest<NuevaContrasenaCubit, NuevaContrasenaEstado>(
      'no llama el repositorio cuando la validación falla',
      build: build,
      act: (c) => c.cambiar(nuevaClave: '123', confirmacion: '123'),
      verify: (_) {
        verifyNever(() => repositorio.actualizarContrasena(any()));
      },
    );

    blocTest<NuevaContrasenaCubit, NuevaContrasenaEstado>(
      'emite [Guardando, Guardada] cuando la operación tiene éxito',
      build: build,
      setUp: () {
        when(() => repositorio.actualizarContrasena(any()))
            .thenAnswer((_) async {});
      },
      act: (c) => c.cambiar(nuevaClave: 'clave1234', confirmacion: 'clave1234'),
      expect: () => [
        isA<NuevaContrasenaGuardando>(),
        isA<NuevaContrasenaGuardada>(),
      ],
    );

    blocTest<NuevaContrasenaCubit, NuevaContrasenaEstado>(
      'emite [Guardando, Error] cuando FallaAutenticacion',
      build: build,
      setUp: () {
        when(() => repositorio.actualizarContrasena(any()))
            .thenThrow(const FallaAutenticacion('Token expirado'));
      },
      act: (c) => c.cambiar(nuevaClave: 'clave1234', confirmacion: 'clave1234'),
      expect: () => [
        isA<NuevaContrasenaGuardando>(),
        isA<NuevaContrasenaError>()
            .having((e) => e.mensaje, 'mensaje', 'Token expirado'),
      ],
    );

    blocTest<NuevaContrasenaCubit, NuevaContrasenaEstado>(
      'emite [Guardando, Error] cuando FallaInesperada',
      build: build,
      setUp: () {
        when(() => repositorio.actualizarContrasena(any()))
            .thenThrow(const FallaInesperada('Sin red'));
      },
      act: (c) => c.cambiar(nuevaClave: 'clave1234', confirmacion: 'clave1234'),
      expect: () => [
        isA<NuevaContrasenaGuardando>(),
        isA<NuevaContrasenaError>(),
      ],
    );
  });
}
