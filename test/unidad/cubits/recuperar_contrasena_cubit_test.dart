import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:activiti/compartido/errores.dart';
import 'package:activiti/funcionalidades/recuperar_contrasena/recuperar_contrasena_cubit.dart';
import 'package:activiti/funcionalidades/recuperar_contrasena/recuperar_contrasena_estado.dart';

import '../../helpers.dart';

void main() {
  late MockAutenticacionRepositorio repositorio;

  setUp(() {
    registrarFallbacks();
    repositorio = MockAutenticacionRepositorio();
  });

  RecuperarContrasenaCubit build() => RecuperarContrasenaCubit(repositorio);

  group('RecuperarContrasenaCubit.enviar', () {
    blocTest<RecuperarContrasenaCubit, RecuperarContrasenaEstado>(
      'emite Error cuando la cédula está vacía',
      build: build,
      act: (c) => c.enviar(''),
      expect: () => [
        isA<RecuperarContrasenaError>()
            .having((e) => e.mensaje, 'mensaje', 'Ingresa tu cédula.'),
      ],
    );

    blocTest<RecuperarContrasenaCubit, RecuperarContrasenaEstado>(
      'emite [Enviando, Enviado] en caso exitoso, sin importar si la cédula existe',
      build: build,
      setUp: () => when(() => repositorio.enviarCorreoRecuperacion(any()))
          .thenAnswer((_) async {}),
      act: (c) => c.enviar('  32727960  '),
      expect: () => [
        isA<RecuperarContrasenaEnviando>(),
        isA<RecuperarContrasenaEnviado>(),
      ],
      verify: (_) {
        verify(() => repositorio.enviarCorreoRecuperacion('32727960'))
            .called(1);
      },
    );

    blocTest<RecuperarContrasenaCubit, RecuperarContrasenaEstado>(
      'RecuperarContrasenaEnviado lleva el correo ya mostrado en la vista previa',
      build: build,
      setUp: () {
        when(() => repositorio.obtenerCorreoEnmascarado('32727960'))
            .thenAnswer((_) async => 'le***o@gm***.com');
        when(() => repositorio.enviarCorreoRecuperacion(any()))
            .thenAnswer((_) async {});
      },
      act: (c) async {
        await c.verificarCedula('32727960');
        await c.enviar('32727960');
      },
      expect: () => [
        isA<RecuperarContrasenaEnviando>(),
        isA<RecuperarContrasenaEnviado>()
            .having((e) => e.correo, 'correo', 'le***o@gm***.com'),
      ],
    );

    blocTest<RecuperarContrasenaCubit, RecuperarContrasenaEstado>(
      'RecuperarContrasenaEnviado.correo es null si nunca se resolvió una vista previa',
      build: build,
      setUp: () => when(() => repositorio.enviarCorreoRecuperacion(any()))
          .thenAnswer((_) async {}),
      act: (c) => c.enviar('32727960'),
      expect: () => [
        isA<RecuperarContrasenaEnviando>(),
        isA<RecuperarContrasenaEnviado>()
            .having((e) => e.correo, 'correo', isNull),
      ],
    );

    blocTest<RecuperarContrasenaCubit, RecuperarContrasenaEstado>(
      'emite [Enviando, Error] cuando el repositorio lanza FallaServidor',
      build: build,
      setUp: () => when(() => repositorio.enviarCorreoRecuperacion(any()))
          .thenThrow(const FallaServidor('Error de servidor.')),
      act: (c) => c.enviar('32727960'),
      expect: () => [
        isA<RecuperarContrasenaEnviando>(),
        isA<RecuperarContrasenaError>()
            .having((e) => e.mensaje, 'mensaje', 'Error de servidor.'),
      ],
    );
  });

  group('RecuperarContrasenaCubit.verificarCedula', () {
    test('deja correoPrevio en null con menos de 6 caracteres', () async {
      final cubit = build();
      await cubit.verificarCedula('123');
      expect(cubit.correoPrevio.value, isNull);
      verifyNever(() => repositorio.obtenerCorreoEnmascarado(any()));
      await cubit.close();
    });

    test('actualiza correoPrevio con el correo enmascarado del repositorio',
        () async {
      when(() => repositorio.obtenerCorreoEnmascarado('32727960'))
          .thenAnswer((_) async => 'l***z@g***.com');
      final cubit = build();
      await cubit.verificarCedula('32727960');
      expect(cubit.correoPrevio.value, 'l***z@g***.com');
      await cubit.close();
    });

    test('deja correoPrevio en null cuando la cédula no existe', () async {
      when(() => repositorio.obtenerCorreoEnmascarado('99999999'))
          .thenAnswer((_) async => null);
      final cubit = build();
      await cubit.verificarCedula('99999999');
      expect(cubit.correoPrevio.value, isNull);
      await cubit.close();
    });

    test('deja correoPrevio en null si el repositorio falla', () async {
      when(() => repositorio.obtenerCorreoEnmascarado('32727960'))
          .thenThrow(const FallaServidor('Sin conexión.'));
      final cubit = build();
      await cubit.verificarCedula('32727960');
      expect(cubit.correoPrevio.value, isNull);
      await cubit.close();
    });

    test('ignora una respuesta vieja si llegó una búsqueda más nueva',
        () async {
      final cubit = build();
      // La primera búsqueda queda "colgada" (nunca resuelve dentro de este
      // test) mientras la segunda sí resuelve — el resultado final debe ser
      // el de la segunda, no el de la primera cuando (si) llegara a resolver.
      when(() => repositorio.obtenerCorreoEnmascarado('11111111'))
          .thenAnswer((_) => Completer<String?>().future);
      when(() => repositorio.obtenerCorreoEnmascarado('22222222'))
          .thenAnswer((_) async => 'a***a@b***.com');

      final primera = cubit.verificarCedula('11111111');
      await cubit.verificarCedula('22222222');

      expect(cubit.correoPrevio.value, 'a***a@b***.com');
      unawaited(primera);
      await cubit.close();
    });
  });
}
