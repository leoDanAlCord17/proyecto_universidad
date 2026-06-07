import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:uniasist/compartido/constantes.dart';
import 'package:uniasist/compartido/errores.dart';
import 'package:uniasist/funcionalidades/autenticacion/login_cubit.dart';
import 'package:uniasist/funcionalidades/autenticacion/login_estado.dart';

import '../../helpers.dart';

void main() {
  late MockAutenticacionRepositorio repositorio;

  setUp(() {
    registrarFallbacks();
    repositorio = MockAutenticacionRepositorio();
  });

  group('LoginCubit', () {
    test('estado inicial es LoginInicial', () {
      final cubit = LoginCubit(repositorio);
      expect(cubit.state, isA<LoginInicial>());
      cubit.close();
    });

    blocTest<LoginCubit, LoginEstado>(
      'emite LoginError cuando correo está vacío',
      build: () => LoginCubit(repositorio),
      act: (c) => c.ingresar('', 'clave123'),
      expect: () => [
        isA<LoginError>().having(
          (e) => e.mensaje,
          'mensaje',
          'Por favor, llena todos los campos.',
        ),
      ],
    );

    blocTest<LoginCubit, LoginEstado>(
      'emite LoginError cuando correo es solo espacios',
      build: () => LoginCubit(repositorio),
      act: (c) => c.ingresar('   ', 'clave123'),
      expect: () => [isA<LoginError>()],
    );

    blocTest<LoginCubit, LoginEstado>(
      'emite LoginError cuando clave está vacía',
      build: () => LoginCubit(repositorio),
      act: (c) => c.ingresar('leo@uni.edu', ''),
      expect: () => [isA<LoginError>()],
    );

    blocTest<LoginCubit, LoginEstado>(
      'no llama el repositorio cuando los campos son inválidos',
      build: () => LoginCubit(repositorio),
      act: (c) => c.ingresar('', ''),
      verify: (_) {
        verifyNever(() => repositorio.iniciarSesion(any(), any()));
      },
    );

    blocTest<LoginCubit, LoginEstado>(
      'emite [LoginCargando, LoginExito] en caso exitoso',
      build: () {
        when(() => repositorio.iniciarSesion(any(), any()))
            .thenAnswer((_) async => MockAuthResponse());
        return LoginCubit(repositorio);
      },
      act: (c) => c.ingresar('leo@uni.edu', 'clave123'),
      expect: () => [isA<LoginCargando>(), isA<LoginExito>()],
    );

    blocTest<LoginCubit, LoginEstado>(
      'llama el repositorio con correo sin espacios',
      build: () {
        when(() => repositorio.iniciarSesion(any(), any()))
            .thenAnswer((_) async => MockAuthResponse());
        return LoginCubit(repositorio);
      },
      act: (c) => c.ingresar('  leo@uni.edu  ', 'clave123'),
      verify: (_) {
        verify(() => repositorio.iniciarSesion('leo@uni.edu', 'clave123'))
            .called(1);
      },
    );

    blocTest<LoginCubit, LoginEstado>(
      'emite [LoginCargando, LoginError] propagando el mensaje de FallaAutenticacion',
      build: () {
        when(() => repositorio.iniciarSesion(any(), any())).thenThrow(
            const FallaAutenticacion('Correo o contraseña incorrectos.'));
        return LoginCubit(repositorio);
      },
      act: (c) => c.ingresar('leo@uni.edu', 'clave123'),
      expect: () => [
        isA<LoginCargando>(),
        isA<LoginError>().having(
          (e) => e.mensaje,
          'mensaje',
          'Correo o contraseña incorrectos.',
        ),
      ],
    );

    blocTest<LoginCubit, LoginEstado>(
      'emite [LoginCargando, LoginError] al recibir FallaInesperada',
      build: () {
        when(() => repositorio.iniciarSesion(any(), any()))
            .thenThrow(const FallaInesperada('Sin conexión.'));
        return LoginCubit(repositorio);
      },
      act: (c) => c.ingresar('leo@uni.edu', 'clave123'),
      expect: () => [
        isA<LoginCargando>(),
        isA<LoginError>().having(
          (e) => e.mensaje,
          'mensaje',
          MensajesError.inesperado,
        ),
      ],
    );
  });
}
