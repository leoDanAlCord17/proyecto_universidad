import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:activiti/compartido/errores.dart';
import 'package:activiti/funcionalidades/autenticacion/auth_cubit.dart';
import 'package:activiti/funcionalidades/autenticacion/auth_estado.dart';

import '../../helpers.dart';

void main() {
  late MockAutenticacionRepositorio repositorio;
  late MockSession sesion;
  late MockUser mockUser;

  setUp(() {
    registrarFallbacks();
    repositorio = MockAutenticacionRepositorio();
    sesion = MockSession();
    mockUser = MockUser();
    when(() => mockUser.id).thenReturn('auth-id-1');
    when(() => sesion.user).thenReturn(mockUser);
    // AuthCubit constructor suscribe inmediatamente a este stream
    when(() => repositorio.flujoRecuperacionContrasena())
        .thenAnswer((_) => const Stream.empty());
  });

  AuthCubit build() => AuthCubit(repositorio);

  group('AuthCubit', () {
    test('estado inicial es AuthInicial', () {
      final cubit = build();
      expect(cubit.state, isA<AuthInicial>());
      cubit.close();
    });
  });

  group('AuthCubit.verificarSesion', () {
    blocTest<AuthCubit, AuthEstado>(
      'emite NoAutenticado cuando no hay sesión activa',
      build: build,
      setUp: () =>
          when(() => repositorio.obtenerSesionActual()).thenReturn(null),
      act: (c) => c.verificarSesion(),
      expect: () => [isA<NoAutenticado>()],
    );

    blocTest<AuthCubit, AuthEstado>(
      'emite Autenticado cuando hay sesión y perfil en la DB',
      build: build,
      setUp: () {
        when(() => repositorio.obtenerSesionActual()).thenReturn(sesion);
        when(() => repositorio.obtenerPerfil(any()))
            .thenAnswer((_) async => usuarioEjemplo);
        when(() => repositorio.actualizarTokenSesion(any(), any()))
            .thenAnswer((_) async {});
        when(() => repositorio.flujoTokenSesion(any()))
            .thenAnswer((_) => const Stream.empty());
      },
      act: (c) => c.verificarSesion(),
      expect: () => [
        isA<Autenticado>().having(
          (a) => a.usuario.correo,
          'correo',
          usuarioEjemplo.correo,
        ),
      ],
    );

    blocTest<AuthCubit, AuthEstado>(
      'consulta el perfil con el id del usuario de la sesión',
      build: build,
      setUp: () {
        when(() => repositorio.obtenerSesionActual()).thenReturn(sesion);
        when(() => repositorio.obtenerPerfil(any()))
            .thenAnswer((_) async => usuarioEjemplo);
        when(() => repositorio.actualizarTokenSesion(any(), any()))
            .thenAnswer((_) async {});
        when(() => repositorio.flujoTokenSesion(any()))
            .thenAnswer((_) => const Stream.empty());
      },
      act: (c) => c.verificarSesion(),
      verify: (_) {
        verify(() => repositorio.obtenerPerfil('auth-id-1')).called(1);
      },
    );

    blocTest<AuthCubit, AuthEstado>(
      'emite PerfilIncompleto cuando obtenerPerfil retorna null (perfil no creado)',
      build: build,
      setUp: () {
        when(() => repositorio.obtenerSesionActual()).thenReturn(sesion);
        when(() => repositorio.obtenerPerfil(any()))
            .thenAnswer((_) async => null);
      },
      act: (c) => c.verificarSesion(),
      expect: () => [isA<PerfilIncompleto>()],
    );

    blocTest<AuthCubit, AuthEstado>(
      'emite NoAutenticado cuando obtenerPerfil lanza FallaServidor (error real de DB)',
      build: build,
      setUp: () {
        when(() => repositorio.obtenerSesionActual()).thenReturn(sesion);
        when(() => repositorio.obtenerPerfil(any()))
            .thenThrow(const FallaServidor('Error de base de datos.'));
      },
      act: (c) => c.verificarSesion(),
      expect: () => [isA<NoAutenticado>()],
    );

    blocTest<AuthCubit, AuthEstado>(
      'emite NoAutenticado cuando obtenerPerfil lanza FallaInesperada',
      build: build,
      setUp: () {
        when(() => repositorio.obtenerSesionActual()).thenReturn(sesion);
        when(() => repositorio.obtenerPerfil(any()))
            .thenThrow(const FallaInesperada('Error de red.'));
      },
      act: (c) => c.verificarSesion(),
      expect: () => [isA<NoAutenticado>()],
    );

    // Reproduce la carrera del enlace de recuperación: cuando el usuario
    // entra desde el correo, el evento de recuperación llega (vía
    // flujoRecuperacionContrasena) y deja al cubit en RecuperandoContrasena
    // *antes* de que esta llamada (disparada sin condición al arrancar la
    // app, ver main.dart) termine de resolver el perfil. Sin el guard, esto
    // pisaba RecuperandoContrasena con Autenticado y sacaba al usuario de la
    // pantalla de nueva contraseña sin dejarlo escribirla.
    blocTest<AuthCubit, AuthEstado>(
      'no pisa RecuperandoContrasena con Autenticado (carrera al recuperar)',
      build: build,
      seed: RecuperandoContrasena.new,
      setUp: () {
        when(() => repositorio.obtenerSesionActual()).thenReturn(sesion);
        when(() => repositorio.obtenerPerfil('auth-id-1'))
            .thenAnswer((_) async => usuarioEjemplo);
      },
      act: (c) => c.verificarSesion(),
      expect: () => [],
      verify: (c) => expect(c.state, isA<RecuperandoContrasena>()),
    );

    // La única excepción: la llamada deliberada de NuevaContrasenaPantalla
    // justo después de guardar la nueva clave sí debe avanzar a Autenticado.
    blocTest<AuthCubit, AuthEstado>(
      'esPostRecuperacion:true sí avanza a Autenticado desde RecuperandoContrasena',
      build: build,
      seed: RecuperandoContrasena.new,
      setUp: () {
        when(() => repositorio.obtenerSesionActual()).thenReturn(sesion);
        when(() => repositorio.obtenerPerfil('auth-id-1'))
            .thenAnswer((_) async => usuarioEjemplo);
        when(() => repositorio.actualizarTokenSesion(any(), any()))
            .thenAnswer((_) async {});
        when(() => repositorio.flujoTokenSesion(any()))
            .thenAnswer((_) => const Stream<String?>.empty());
      },
      act: (c) => c.verificarSesion(esPostRecuperacion: true),
      expect: () => [isA<Autenticado>()],
    );
  });

  group('AuthCubit.actualizarUsuario', () {
    blocTest<AuthCubit, AuthEstado>(
      'emite Autenticado con el usuario indicado',
      build: build,
      act: (c) => c.actualizarUsuario(usuarioEjemplo),
      expect: () => [
        isA<Autenticado>().having(
          (a) => a.usuario.correo,
          'correo',
          usuarioEjemplo.correo,
        ),
      ],
    );
  });

  group('AuthCubit.cerrarSesion', () {
    blocTest<AuthCubit, AuthEstado>(
      'emite NoAutenticado tras cerrar sesión',
      build: build,
      setUp: () =>
          when(() => repositorio.cerrarSesion()).thenAnswer((_) async {}),
      act: (c) => c.cerrarSesion(),
      expect: () => [isA<NoAutenticado>()],
    );

    blocTest<AuthCubit, AuthEstado>(
      'llama cerrarSesion en el repositorio exactamente una vez',
      build: build,
      setUp: () =>
          when(() => repositorio.cerrarSesion()).thenAnswer((_) async {}),
      act: (c) => c.cerrarSesion(),
      verify: (_) {
        verify(() => repositorio.cerrarSesion()).called(1);
      },
    );
  });
}
