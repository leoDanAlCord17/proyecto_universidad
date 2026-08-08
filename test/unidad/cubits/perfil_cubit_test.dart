import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:activiti/compartido/errores.dart';
import 'package:activiti/funcionalidades/perfil/perfil_cubit.dart';
import 'package:activiti/funcionalidades/perfil/perfil_estado.dart';

import '../../helpers.dart';

// ─── Fixtures ─────────────────────────────────────────────────────────────────

const _tagsRespuesta = (
  tagPrincipal: 'Ingeniería',
  tagsSecundarios: <String>['Sistemas'],
);

PerfilCargado _cargado() => const PerfilCargado(
      tagPrincipal: 'Ingeniería',
      tagsSecundarios: ['Sistemas'],
      puedeEditarPerfil: true,
    );

// ─── Tests ────────────────────────────────────────────────────────────────────

void main() {
  late MockPerfilRepositorio repositorio;

  setUp(() {
    repositorio = MockPerfilRepositorio();
    registrarFallbacks();
  });

  PerfilCubit build() => PerfilCubit(repositorio);

  // ── cargar ─────────────────────────────────────────────────────────────────

  group('PerfilCubit.cargar', () {
    test('estado inicial es PerfilInicial', () {
      expect(build().state, isA<PerfilInicial>());
    });

    blocTest<PerfilCubit, PerfilEstado>(
      'emite [Cargando, Cargado] con tags y puedeEditarPerfil del repositorio',
      build: build,
      setUp: () {
        when(() => repositorio.obtenerTags(any()))
            .thenAnswer((_) async => _tagsRespuesta);
        when(() => repositorio.obtenerPuedeEditarPerfil())
            .thenAnswer((_) async => true);
      },
      act: (c) => c.cargar('user-1'),
      expect: () => [
        isA<PerfilCargando>(),
        isA<PerfilCargado>()
            .having((e) => e.tagPrincipal, 'tagPrincipal', 'Ingeniería')
            .having((e) => e.tagsSecundarios, 'tagsSecundarios', [
          'Sistemas'
        ]).having((e) => e.puedeEditarPerfil, 'puedeEditarPerfil', true),
      ],
    );

    blocTest<PerfilCubit, PerfilEstado>(
      'emite [Cargando, Error] cuando FallaServidor en obtenerTags',
      build: build,
      setUp: () {
        when(() => repositorio.obtenerTags(any()))
            .thenThrow(const FallaServidor('Sin conexión'));
        when(() => repositorio.obtenerPuedeEditarPerfil())
            .thenAnswer((_) async => false);
      },
      act: (c) => c.cargar('user-1'),
      expect: () => [
        isA<PerfilCargando>(),
        isA<PerfilError>().having((e) => e.mensaje, 'mensaje', 'Sin conexión'),
      ],
    );

    blocTest<PerfilCubit, PerfilEstado>(
      'emite [Cargando, Error] cuando FallaInesperada',
      build: build,
      setUp: () {
        when(() => repositorio.obtenerTags(any()))
            .thenThrow(const FallaInesperada('Error raro'));
        when(() => repositorio.obtenerPuedeEditarPerfil())
            .thenAnswer((_) async => false);
      },
      act: (c) => c.cargar('user-1'),
      expect: () => [
        isA<PerfilCargando>(),
        isA<PerfilError>(),
      ],
    );
  });

  // ── guardarPerfil ──────────────────────────────────────────────────────────

  group('PerfilCubit.guardarPerfil', () {
    const campos = <String, dynamic>{
      'primer_nombre': 'Leonardo',
      'primer_apellido': 'Alvarez',
    };

    blocTest<PerfilCubit, PerfilEstado>(
      'no hace nada si el estado no es Cargado',
      build: build,
      act: (c) => c.guardarPerfil(
        usuarioActual: usuarioEjemplo,
        campos: campos,
      ),
      expect: () => [],
    );

    blocTest<PerfilCubit, PerfilEstado>(
      'emite [Cargado(guardando=true), PerfilGuardado] al guardar con éxito',
      build: build,
      setUp: () {
        when(
          () => repositorio.actualizarPerfil(
            usuarioId: any(named: 'usuarioId'),
            datos: any(named: 'datos'),
          ),
        ).thenAnswer((_) async {});
      },
      seed: _cargado,
      act: (c) => c.guardarPerfil(
        usuarioActual: usuarioEjemplo,
        campos: campos,
      ),
      expect: () => [
        isA<PerfilCargado>()
            .having((e) => e.estaGuardando, 'estaGuardando', true),
        isA<PerfilGuardado>().having(
          (e) => e.usuarioActualizado.primerNombre,
          'primerNombre',
          'Leonardo',
        ),
      ],
    );

    blocTest<PerfilCubit, PerfilEstado>(
      'emite [guardando=true, Cargado(sin error), Cargado(con error)] cuando FallaServidor',
      build: build,
      setUp: () {
        when(
          () => repositorio.actualizarPerfil(
            usuarioId: any(named: 'usuarioId'),
            datos: any(named: 'datos'),
          ),
        ).thenThrow(const FallaServidor('DB error'));
      },
      seed: _cargado,
      act: (c) => c.guardarPerfil(
        usuarioActual: usuarioEjemplo,
        campos: campos,
      ),
      expect: () => [
        isA<PerfilCargado>()
            .having((e) => e.estaGuardando, 'estaGuardando', true),
        isA<PerfilCargado>()
            .having((e) => e.estaGuardando, 'estaGuardando', false)
            .having((e) => e.errorGuardado, 'errorGuardado', isNull),
        isA<PerfilCargado>()
            .having((e) => e.errorGuardado, 'errorGuardado', 'DB error'),
      ],
    );
  });

  // ── actualizarFoto ─────────────────────────────────────────────────────────

  group('PerfilCubit.actualizarFoto', () {
    blocTest<PerfilCubit, PerfilEstado>(
      'no hace nada si el estado no es Cargado',
      build: build,
      act: (c) => c.actualizarFoto(
        usuarioActual: usuarioEjemplo,
        nuevaUrl: 'https://ejemplo.com/avatars/auth-id-1.jpg',
      ),
      expect: () => [],
    );

    blocTest<PerfilCubit, PerfilEstado>(
      'emite PerfilGuardado con la nueva url al guardar con éxito',
      build: build,
      setUp: () {
        when(
          () => repositorio.actualizarPerfil(
            usuarioId: any(named: 'usuarioId'),
            datos: any(named: 'datos'),
          ),
        ).thenAnswer((_) async {});
      },
      seed: _cargado,
      act: (c) => c.actualizarFoto(
        usuarioActual: usuarioEjemplo,
        nuevaUrl: 'https://ejemplo.com/avatars/auth-id-1.jpg',
      ),
      expect: () => [
        isA<PerfilGuardado>().having(
          (e) => e.usuarioActualizado.urlAvatar,
          'urlAvatar',
          'https://ejemplo.com/avatars/auth-id-1.jpg',
        ),
      ],
      verify: (_) {
        final capturado = verify(
          () => repositorio.actualizarPerfil(
            usuarioId: any(named: 'usuarioId'),
            datos: captureAny(named: 'datos'),
          ),
        ).captured;
        final datos = capturado.first as Map<String, dynamic>;
        expect(
            datos['url_avatar'], 'https://ejemplo.com/avatars/auth-id-1.jpg');
      },
    );

    blocTest<PerfilCubit, PerfilEstado>(
      'permite quitar la foto pasando null',
      build: build,
      setUp: () {
        when(
          () => repositorio.actualizarPerfil(
            usuarioId: any(named: 'usuarioId'),
            datos: any(named: 'datos'),
          ),
        ).thenAnswer((_) async {});
      },
      seed: _cargado,
      act: (c) =>
          c.actualizarFoto(usuarioActual: usuarioEjemplo, nuevaUrl: null),
      expect: () => [
        isA<PerfilGuardado>()
            .having((e) => e.usuarioActualizado.urlAvatar, 'urlAvatar', isNull),
      ],
    );

    blocTest<PerfilCubit, PerfilEstado>(
      'emite error puntual cuando falla el guardado',
      build: build,
      setUp: () {
        when(
          () => repositorio.actualizarPerfil(
            usuarioId: any(named: 'usuarioId'),
            datos: any(named: 'datos'),
          ),
        ).thenThrow(const FallaServidor('No se pudo guardar la foto.'));
      },
      seed: _cargado,
      act: (c) => c.actualizarFoto(
        usuarioActual: usuarioEjemplo,
        nuevaUrl: 'https://ejemplo.com/avatars/auth-id-1.jpg',
      ),
      expect: () => [
        isA<PerfilCargado>().having(
          (e) => e.errorGuardado,
          'errorGuardado',
          'No se pudo guardar la foto.',
        ),
      ],
    );
  });

  // ── volverACargado ─────────────────────────────────────────────────────────

  group('PerfilCubit.volverACargado', () {
    blocTest<PerfilCubit, PerfilEstado>(
      'emite el estado PerfilCargado recibido como argumento',
      build: build,
      act: (c) => c.volverACargado(_cargado()),
      expect: () => [
        isA<PerfilCargado>()
            .having((e) => e.tagPrincipal, 'tagPrincipal', 'Ingeniería'),
      ],
    );
  });
}
