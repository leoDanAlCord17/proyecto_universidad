import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
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
    when(() => repositorio.flujoRecuperacionContrasena())
        .thenAnswer((_) => const Stream<bool>.empty());
  });

  AuthCubit build() => AuthCubit(repositorio);

  group('AuthCubit.verificarSesion', () {
    blocTest<AuthCubit, AuthEstado>(
      'emite NoAutenticado cuando no hay sesión',
      build: build,
      setUp: () => when(() => repositorio.obtenerSesionActual())
          .thenReturn(null),
      act: (c) => c.verificarSesion(),
      expect: () => [isA<NoAutenticado>()],
    );

    blocTest<AuthCubit, AuthEstado>(
      'emite Autenticado con sesión normal y perfil aprobado',
      build: build,
      setUp: () {
        when(() => repositorio.obtenerSesionActual()).thenReturn(sesion);
        when(() => repositorio.obtenerPerfil('auth-id-1'))
            .thenAnswer((_) async => usuarioEjemplo);
        when(() => repositorio.actualizarTokenSesion(any(), any()))
            .thenAnswer((_) async {});
        when(() => repositorio.flujoTokenSesion(any()))
            .thenAnswer((_) => const Stream<String?>.empty());
      },
      act: (c) => c.verificarSesion(),
      expect: () => [isA<Autenticado>()],
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
}
