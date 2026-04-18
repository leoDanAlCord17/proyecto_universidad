import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:uniasist/compartido/constantes.dart';
import 'package:uniasist/compartido/errores.dart';
import 'package:uniasist/funcionalidades/autenticacion/usuario.dart';
import 'package:uniasist/funcionalidades/crear_usuario/crear_usuario_cubit.dart';
import 'package:uniasist/funcionalidades/crear_usuario/crear_usuario_estado.dart';

import '../../helpers.dart';

void main() {
  late MockAutenticacionRepositorio repositorio;
  late MockSession sesion;
  late MockUser mockUser;

  setUp(() {
    registrarFallbacks();
    repositorio = MockAutenticacionRepositorio();
    sesion      = MockSession();
    mockUser    = MockUser();
    when(() => mockUser.id).thenReturn('auth-id-1');
    when(() => mockUser.email).thenReturn('leo@uni.edu');
    when(() => sesion.user).thenReturn(mockUser);
  });

  group('CrearUsuarioCubit.correoSesion', () {
    test('retorna el correo cuando hay sesión activa', () {
      when(() => repositorio.obtenerSesionActual()).thenReturn(sesion);
      final cubit = CrearUsuarioCubit(repositorio);
      expect(cubit.correoSesion, 'leo@uni.edu');
      cubit.close();
    });

    test('retorna cadena vacía cuando no hay sesión', () {
      when(() => repositorio.obtenerSesionActual()).thenReturn(null);
      final cubit = CrearUsuarioCubit(repositorio);
      expect(cubit.correoSesion, '');
      cubit.close();
    });
  });

  group('CrearUsuarioCubit.guardarPerfil', () {
    test('estado inicial es CrearUsuarioInicial', () {
      when(() => repositorio.obtenerSesionActual()).thenReturn(sesion);
      final cubit = CrearUsuarioCubit(repositorio);
      expect(cubit.state, isA<CrearUsuarioInicial>());
      cubit.close();
    });

    blocTest<CrearUsuarioCubit, CrearUsuarioEstado>(
      'emite CrearUsuarioError cuando primerNombre está vacío',
      build: () {
        when(() => repositorio.obtenerSesionActual()).thenReturn(sesion);
        return CrearUsuarioCubit(repositorio);
      },
      act: (c) => c.guardarPerfil(primerNombre: '', primerApellido: 'Alvarez'),
      expect: () => [isA<CrearUsuarioError>()],
    );

    blocTest<CrearUsuarioCubit, CrearUsuarioEstado>(
      'emite CrearUsuarioError cuando primerNombre es solo espacios',
      build: () {
        when(() => repositorio.obtenerSesionActual()).thenReturn(sesion);
        return CrearUsuarioCubit(repositorio);
      },
      act: (c) =>
          c.guardarPerfil(primerNombre: '   ', primerApellido: 'Alvarez'),
      expect: () => [isA<CrearUsuarioError>()],
    );

    blocTest<CrearUsuarioCubit, CrearUsuarioEstado>(
      'emite CrearUsuarioError cuando primerApellido está vacío',
      build: () {
        when(() => repositorio.obtenerSesionActual()).thenReturn(sesion);
        return CrearUsuarioCubit(repositorio);
      },
      act: (c) => c.guardarPerfil(primerNombre: 'Leo', primerApellido: ''),
      expect: () => [isA<CrearUsuarioError>()],
    );

    blocTest<CrearUsuarioCubit, CrearUsuarioEstado>(
      'emite CrearUsuarioError cuando no hay sesión activa',
      build: () {
        when(() => repositorio.obtenerSesionActual()).thenReturn(null);
        return CrearUsuarioCubit(repositorio);
      },
      act: (c) =>
          c.guardarPerfil(primerNombre: 'Leo', primerApellido: 'Alvarez'),
      expect: () => [
        isA<CrearUsuarioError>().having(
          (e) => e.mensaje,
          'mensaje',
          'No hay sesión activa. Vuelve a registrarte.',
        ),
      ],
    );

    blocTest<CrearUsuarioCubit, CrearUsuarioEstado>(
      'emite [CrearUsuarioCargando, CrearUsuarioExito] en caso exitoso',
      build: () {
        when(() => repositorio.obtenerSesionActual()).thenReturn(sesion);
        when(() => repositorio.crearPerfilUsuario(any()))
            .thenAnswer((_) async {});
        return CrearUsuarioCubit(repositorio);
      },
      act: (c) =>
          c.guardarPerfil(primerNombre: 'Leo', primerApellido: 'Alvarez'),
      expect: () => [isA<CrearUsuarioCargando>(), isA<CrearUsuarioExito>()],
    );

    blocTest<CrearUsuarioCubit, CrearUsuarioEstado>(
      'guarda el perfil con nombre y apellido con trim aplicado',
      build: () {
        when(() => repositorio.obtenerSesionActual()).thenReturn(sesion);
        when(() => repositorio.crearPerfilUsuario(any()))
            .thenAnswer((_) async {});
        return CrearUsuarioCubit(repositorio);
      },
      act: (c) => c.guardarPerfil(
        primerNombre:   '  Leo  ',
        primerApellido: '  Alvarez  ',
      ),
      verify: (_) {
        final capturado = verify(
          () => repositorio.crearPerfilUsuario(captureAny()),
        ).captured;
        final usuario = capturado.first as Usuario;
        expect(usuario.primerNombre,   'Leo');
        expect(usuario.primerApellido, 'Alvarez');
      },
    );

    blocTest<CrearUsuarioCubit, CrearUsuarioEstado>(
      'emite [CrearUsuarioCargando, CrearUsuarioError] al recibir FallaServidor',
      build: () {
        when(() => repositorio.obtenerSesionActual()).thenReturn(sesion);
        when(() => repositorio.crearPerfilUsuario(any()))
            .thenThrow(const FallaServidor('Ya existe un registro con esos datos.'));
        return CrearUsuarioCubit(repositorio);
      },
      act: (c) =>
          c.guardarPerfil(primerNombre: 'Leo', primerApellido: 'Alvarez'),
      expect: () => [
        isA<CrearUsuarioCargando>(),
        isA<CrearUsuarioError>().having(
          (e) => e.mensaje,
          'mensaje',
          'Ya existe un registro con esos datos.',
        ),
      ],
    );

    blocTest<CrearUsuarioCubit, CrearUsuarioEstado>(
      'emite [CrearUsuarioCargando, CrearUsuarioError] al recibir FallaInesperada',
      build: () {
        when(() => repositorio.obtenerSesionActual()).thenReturn(sesion);
        when(() => repositorio.crearPerfilUsuario(any()))
            .thenThrow(const FallaInesperada('Sin conexión.'));
        return CrearUsuarioCubit(repositorio);
      },
      act: (c) =>
          c.guardarPerfil(primerNombre: 'Leo', primerApellido: 'Alvarez'),
      expect: () => [
        isA<CrearUsuarioCargando>(),
        isA<CrearUsuarioError>().having(
          (e) => e.mensaje,
          'mensaje',
          MensajesError.inesperado,
        ),
      ],
    );
  });
}
