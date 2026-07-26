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

  group('AuthCubit', () {
    test('estado inicial es AuthInicial', () {
      final cubit = AuthCubit(repositorio);
      expect(cubit.state, isA<AuthInicial>());
      cubit.close();
    });
  });

  group('AuthCubit.verificarSesion', () {
    blocTest<AuthCubit, AuthEstado>(
      'emite NoAutenticado cuando no hay sesión activa',
      build: () {
        when(() => repositorio.obtenerSesionActual()).thenReturn(null);
        return AuthCubit(repositorio);
      },
      act: (c) => c.verificarSesion(),
      expect: () => [isA<NoAutenticado>()],
    );

    blocTest<AuthCubit, AuthEstado>(
      'emite Autenticado cuando hay sesión y perfil en la DB',
      build: () {
        when(() => repositorio.obtenerSesionActual()).thenReturn(sesion);
        when(() => repositorio.obtenerPerfil(any()))
            .thenAnswer((_) async => usuarioEjemplo);
        when(() => repositorio.actualizarTokenSesion(any(), any()))
            .thenAnswer((_) async {});
        when(() => repositorio.flujoTokenSesion(any()))
            .thenAnswer((_) => const Stream.empty());
        return AuthCubit(repositorio);
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
      build: () {
        when(() => repositorio.obtenerSesionActual()).thenReturn(sesion);
        when(() => repositorio.obtenerPerfil(any()))
            .thenAnswer((_) async => usuarioEjemplo);
        when(() => repositorio.actualizarTokenSesion(any(), any()))
            .thenAnswer((_) async {});
        when(() => repositorio.flujoTokenSesion(any()))
            .thenAnswer((_) => const Stream.empty());
        return AuthCubit(repositorio);
      },
      act: (c) => c.verificarSesion(),
      verify: (_) {
        verify(() => repositorio.obtenerPerfil('auth-id-1')).called(1);
      },
    );

    blocTest<AuthCubit, AuthEstado>(
      'emite PerfilIncompleto cuando obtenerPerfil retorna null (perfil no creado)',
      build: () {
        when(() => repositorio.obtenerSesionActual()).thenReturn(sesion);
        when(() => repositorio.obtenerPerfil(any()))
            .thenAnswer((_) async => null);
        return AuthCubit(repositorio);
      },
      act: (c) => c.verificarSesion(),
      expect: () => [isA<PerfilIncompleto>()],
    );

    blocTest<AuthCubit, AuthEstado>(
      'emite NoAutenticado cuando obtenerPerfil lanza FallaServidor (error real de DB)',
      build: () {
        when(() => repositorio.obtenerSesionActual()).thenReturn(sesion);
        when(() => repositorio.obtenerPerfil(any()))
            .thenThrow(const FallaServidor('Error de base de datos.'));
        return AuthCubit(repositorio);
      },
      act: (c) => c.verificarSesion(),
      expect: () => [isA<NoAutenticado>()],
    );

    blocTest<AuthCubit, AuthEstado>(
      'emite NoAutenticado cuando obtenerPerfil lanza FallaInesperada',
      build: () {
        when(() => repositorio.obtenerSesionActual()).thenReturn(sesion);
        when(() => repositorio.obtenerPerfil(any()))
            .thenThrow(const FallaInesperada('Error de red.'));
        return AuthCubit(repositorio);
      },
      act: (c) => c.verificarSesion(),
      expect: () => [isA<NoAutenticado>()],
    );
  });

  group('AuthCubit.actualizarUsuario', () {
    blocTest<AuthCubit, AuthEstado>(
      'emite Autenticado con el usuario indicado',
      build: () => AuthCubit(repositorio),
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
      build: () {
        when(() => repositorio.cerrarSesion()).thenAnswer((_) async {});
        return AuthCubit(repositorio);
      },
      act: (c) => c.cerrarSesion(),
      expect: () => [isA<NoAutenticado>()],
    );

    blocTest<AuthCubit, AuthEstado>(
      'llama cerrarSesion en el repositorio exactamente una vez',
      build: () {
        when(() => repositorio.cerrarSesion()).thenAnswer((_) async {});
        return AuthCubit(repositorio);
      },
      act: (c) => c.cerrarSesion(),
      verify: (_) {
        verify(() => repositorio.cerrarSesion()).called(1);
      },
    );
  });
}
