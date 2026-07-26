import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:activiti/compartido/errores.dart';
import 'package:activiti/funcionalidades/revision_usuarios/revision_usuario_item.dart';
import 'package:activiti/funcionalidades/revision_usuarios/revision_usuarios_cubit.dart';
import 'package:activiti/funcionalidades/revision_usuarios/revision_usuarios_estado.dart';

import '../../helpers.dart';

// ─── Fixtures ─────────────────────────────────────────────────────────────────

const _ru1 = RevisionUsuarioItem(
  id: 'ru-1',
  primerNombre: 'Leo',
  primerApellido: 'Alvarez',
  correo: 'leo@uni.edu',
);
const _ru2 = RevisionUsuarioItem(
  id: 'ru-2',
  primerNombre: 'Ana',
  primerApellido: 'Gomez',
  correo: 'ana@uni.edu',
);
const _ru3 = RevisionUsuarioItem(
  id: 'ru-3',
  primerNombre: 'Carlos',
  primerApellido: 'Ruiz',
  correo: 'carlos@uni.edu',
);

const _lista = [_ru1, _ru2];

RevisionUsuariosCargados _cargados() => const RevisionUsuariosCargados(
      usuarios: _lista,
      hayMas: false,
    );

// ─── Tests ────────────────────────────────────────────────────────────────────

void main() {
  late MockRevisionUsuariosRepositorio repositorio;

  setUp(() {
    repositorio = MockRevisionUsuariosRepositorio();
  });

  RevisionUsuariosCubit build() => RevisionUsuariosCubit(repositorio);

  // ── cargar ─────────────────────────────────────────────────────────────────

  group('RevisionUsuariosCubit.cargar', () {
    test('estado inicial es RevisionUsuariosInicial', () {
      expect(build().state, isA<RevisionUsuariosInicial>());
    });

    blocTest<RevisionUsuariosCubit, RevisionUsuariosEstado>(
      'emite [Cargando, Cargados] con hayMas=false',
      build: build,
      setUp: () {
        when(() => repositorio.obtenerPendientes())
            .thenAnswer((_) async => (usuarios: _lista, hayMas: false));
      },
      act: (c) => c.cargar(),
      expect: () => [
        isA<RevisionUsuariosCargando>(),
        isA<RevisionUsuariosCargados>()
            .having((e) => e.usuarios.length, 'usuarios.length', 2)
            .having((e) => e.hayMas, 'hayMas', false),
      ],
    );

    blocTest<RevisionUsuariosCubit, RevisionUsuariosEstado>(
      'emite Cargados con hayMas=true cuando el repo indica más páginas',
      build: build,
      setUp: () {
        when(() => repositorio.obtenerPendientes())
            .thenAnswer((_) async => (usuarios: _lista, hayMas: true));
      },
      act: (c) => c.cargar(),
      expect: () => [
        isA<RevisionUsuariosCargando>(),
        isA<RevisionUsuariosCargados>().having((e) => e.hayMas, 'hayMas', true),
      ],
    );

    blocTest<RevisionUsuariosCubit, RevisionUsuariosEstado>(
      'emite [Cargando, Error] cuando FallaServidor',
      build: build,
      setUp: () {
        when(() => repositorio.obtenerPendientes())
            .thenThrow(const FallaServidor('DB error'));
      },
      act: (c) => c.cargar(),
      expect: () => [
        isA<RevisionUsuariosCargando>(),
        isA<RevisionUsuariosError>()
            .having((e) => e.mensaje, 'mensaje', 'DB error'),
      ],
    );

    blocTest<RevisionUsuariosCubit, RevisionUsuariosEstado>(
      'emite [Cargando, Error] cuando FallaRed',
      build: build,
      setUp: () {
        when(() => repositorio.obtenerPendientes())
            .thenThrow(const FallaRed('Sin conexión'));
      },
      act: (c) => c.cargar(),
      expect: () => [
        isA<RevisionUsuariosCargando>(),
        isA<RevisionUsuariosError>()
            .having((e) => e.mensaje, 'mensaje', 'Sin conexión'),
      ],
    );
  });

  // ── cargarMas ──────────────────────────────────────────────────────────────

  group('RevisionUsuariosCubit.cargarMas', () {
    blocTest<RevisionUsuariosCubit, RevisionUsuariosEstado>(
      'no emite nada si hayMas es false',
      build: build,
      seed: _cargados,
      act: (c) => c.cargarMas(),
      expect: () => [],
    );

    blocTest<RevisionUsuariosCubit, RevisionUsuariosEstado>(
      'no emite nada si el estado no es Cargados',
      build: build,
      act: (c) => c.cargarMas(),
      expect: () => [],
    );

    blocTest<RevisionUsuariosCubit, RevisionUsuariosEstado>(
      'emite [CargandoMas, Cargados] acumulando la segunda página',
      build: build,
      setUp: () {
        when(() => repositorio.obtenerPendientes(offset: any(named: 'offset')))
            .thenAnswer((_) async => (usuarios: [_ru3], hayMas: false));
      },
      seed: () => const RevisionUsuariosCargados(
        usuarios: [_ru1, _ru2],
        hayMas: true,
      ),
      act: (c) => c.cargarMas(),
      expect: () => [
        isA<RevisionUsuariosCargandoMas>(),
        isA<RevisionUsuariosCargados>()
            .having((e) => e.usuarios.length, 'usuarios.length', 3)
            .having((e) => e.hayMas, 'hayMas', false),
      ],
    );

    blocTest<RevisionUsuariosCubit, RevisionUsuariosEstado>(
      'revierte al Cargados original si el repositorio falla',
      build: build,
      setUp: () {
        when(() => repositorio.obtenerPendientes(offset: any(named: 'offset')))
            .thenThrow(const FallaServidor('Error de red'));
      },
      seed: () => const RevisionUsuariosCargados(
        usuarios: [_ru1, _ru2],
        hayMas: true,
      ),
      act: (c) => c.cargarMas(),
      expect: () => [
        isA<RevisionUsuariosCargandoMas>(),
        isA<RevisionUsuariosCargados>()
            .having((e) => e.usuarios.length, 'usuarios.length', 2)
            .having((e) => e.hayMas, 'hayMas', true),
      ],
    );
  });

  // ── aprobar ────────────────────────────────────────────────────────────────

  group('RevisionUsuariosCubit.aprobar', () {
    blocTest<RevisionUsuariosCubit, RevisionUsuariosEstado>(
      'no hace nada si el estado no es Cargados',
      build: build,
      act: (c) => c.aprobar('ru-1'),
      expect: () => [],
    );

    blocTest<RevisionUsuariosCubit, RevisionUsuariosEstado>(
      'emite usuarioIdProcessando → recarga tras éxito',
      build: build,
      setUp: () {
        when(() => repositorio.aprobar(any())).thenAnswer((_) async {});
        when(() => repositorio.obtenerPendientes())
            .thenAnswer((_) async => (usuarios: [_ru2], hayMas: false));
      },
      seed: _cargados,
      act: (c) => c.aprobar('ru-1'),
      expect: () => [
        isA<RevisionUsuariosCargados>()
            .having((e) => e.usuarioIdProcessando, 'processando', 'ru-1'),
        isA<RevisionUsuariosCargando>(),
        isA<RevisionUsuariosCargados>()
            .having((e) => e.usuarios.length, 'usuarios.length', 1)
            .having((e) => e.usuarioIdProcessando, 'processando', null),
      ],
    );

    blocTest<RevisionUsuariosCubit, RevisionUsuariosEstado>(
      'emite errorOperacion cuando aprobar falla',
      build: build,
      setUp: () {
        when(() => repositorio.aprobar(any()))
            .thenThrow(const FallaServidor('Sin permiso'));
      },
      seed: _cargados,
      act: (c) => c.aprobar('ru-1'),
      expect: () => [
        isA<RevisionUsuariosCargados>()
            .having((e) => e.usuarioIdProcessando, 'processando', 'ru-1'),
        isA<RevisionUsuariosCargados>()
            .having((e) => e.errorOperacion, 'errorOperacion', 'Sin permiso')
            .having((e) => e.usuarioIdProcessando, 'processando', null),
      ],
    );
  });

  // ── rechazar ───────────────────────────────────────────────────────────────

  group('RevisionUsuariosCubit.rechazar', () {
    blocTest<RevisionUsuariosCubit, RevisionUsuariosEstado>(
      'no hace nada si el estado no es Cargados',
      build: build,
      act: (c) => c.rechazar('ru-1'),
      expect: () => [],
    );

    blocTest<RevisionUsuariosCubit, RevisionUsuariosEstado>(
      'emite usuarioIdProcessando → recarga tras éxito',
      build: build,
      setUp: () {
        when(() => repositorio.rechazar(any())).thenAnswer((_) async {});
        when(() => repositorio.obtenerPendientes())
            .thenAnswer((_) async => (usuarios: [_ru2], hayMas: false));
      },
      seed: _cargados,
      act: (c) => c.rechazar('ru-1'),
      expect: () => [
        isA<RevisionUsuariosCargados>()
            .having((e) => e.usuarioIdProcessando, 'processando', 'ru-1'),
        isA<RevisionUsuariosCargando>(),
        isA<RevisionUsuariosCargados>()
            .having((e) => e.usuarios.length, 'usuarios.length', 1)
            .having((e) => e.usuarioIdProcessando, 'processando', null),
      ],
    );

    blocTest<RevisionUsuariosCubit, RevisionUsuariosEstado>(
      'emite errorOperacion cuando rechazar falla',
      build: build,
      setUp: () {
        when(() => repositorio.rechazar(any()))
            .thenThrow(const FallaServidor('Sin permiso'));
      },
      seed: _cargados,
      act: (c) => c.rechazar('ru-1'),
      expect: () => [
        isA<RevisionUsuariosCargados>()
            .having((e) => e.usuarioIdProcessando, 'processando', 'ru-1'),
        isA<RevisionUsuariosCargados>()
            .having((e) => e.errorOperacion, 'errorOperacion', 'Sin permiso')
            .having((e) => e.usuarioIdProcessando, 'processando', null),
      ],
    );
  });
}
