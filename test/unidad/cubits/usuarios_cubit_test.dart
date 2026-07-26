import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:activiti/compartido/errores.dart';
import 'package:activiti/funcionalidades/usuarios/usuario_item.dart';
import 'package:activiti/funcionalidades/usuarios/usuarios_cubit.dart';
import 'package:activiti/funcionalidades/usuarios/usuarios_estado.dart';

import '../../helpers.dart';

// ─── Fixtures ─────────────────────────────────────────────────────────────────

const _u1 = UsuarioItem(
  id: 'u-1',
  primerNombre: 'Leo',
  primerApellido: 'Alvarez',
  correo: 'leo@uni.edu',
  estatus: true,
);
const _u2 = UsuarioItem(
  id: 'u-2',
  primerNombre: 'Ana',
  primerApellido: 'Gomez',
  correo: 'ana@uni.edu',
  estatus: true,
  numeroIdentificacion: 'CI-12345',
);
const _u3 = UsuarioItem(
  id: 'u-3',
  primerNombre: 'Carlos',
  primerApellido: 'Ruiz',
  correo: 'carlos@uni.edu',
  estatus: false,
);

const _lista = [_u1, _u2, _u3];

UsuariosCargados _cargados() => const UsuariosCargados(
      usuarios: _lista,
      usuariosFiltrados: _lista,
      hayMas: false,
    );

// ─── Tests ────────────────────────────────────────────────────────────────────

void main() {
  late MockUsuariosRepositorio repositorio;

  setUp(() {
    repositorio = MockUsuariosRepositorio();
  });

  UsuariosCubit build() => UsuariosCubit(repositorio);

  // ── cargar ─────────────────────────────────────────────────────────────────

  group('UsuariosCubit.cargar', () {
    test('estado inicial es UsuariosInicial', () {
      expect(build().state, isA<UsuariosInicial>());
    });

    blocTest<UsuariosCubit, UsuariosEstado>(
      'emite [Cargando, Cargados] con usuarios y filtrados iguales',
      build: build,
      setUp: () {
        when(() => repositorio.obtenerUsuarios())
            .thenAnswer((_) async => (usuarios: _lista, hayMas: false));
      },
      act: (c) => c.cargar(),
      expect: () => [
        isA<UsuariosCargando>(),
        isA<UsuariosCargados>()
            .having((e) => e.usuarios, 'usuarios', _lista)
            .having((e) => e.usuariosFiltrados, 'usuariosFiltrados', _lista)
            .having((e) => e.hayMas, 'hayMas', false),
      ],
    );

    blocTest<UsuariosCubit, UsuariosEstado>(
      'emite Cargados con hayMas=true cuando el repo indica más páginas',
      build: build,
      setUp: () {
        when(() => repositorio.obtenerUsuarios())
            .thenAnswer((_) async => (usuarios: _lista, hayMas: true));
      },
      act: (c) => c.cargar(),
      expect: () => [
        isA<UsuariosCargando>(),
        isA<UsuariosCargados>().having((e) => e.hayMas, 'hayMas', true),
      ],
    );

    blocTest<UsuariosCubit, UsuariosEstado>(
      'emite [Cargando, Error] cuando FallaServidor',
      build: build,
      setUp: () {
        when(() => repositorio.obtenerUsuarios())
            .thenThrow(const FallaServidor('DB error'));
      },
      act: (c) => c.cargar(),
      expect: () => [
        isA<UsuariosCargando>(),
        isA<UsuariosError>().having((e) => e.mensaje, 'mensaje', 'DB error'),
      ],
    );

    blocTest<UsuariosCubit, UsuariosEstado>(
      'emite [Cargando, Error] cuando FallaInesperada',
      build: build,
      setUp: () {
        when(() => repositorio.obtenerUsuarios())
            .thenThrow(const FallaInesperada('Error inesperado'));
      },
      act: (c) => c.cargar(),
      expect: () => [
        isA<UsuariosCargando>(),
        isA<UsuariosError>(),
      ],
    );
  });

  // ── cargarMas ──────────────────────────────────────────────────────────────

  group('UsuariosCubit.cargarMas', () {
    blocTest<UsuariosCubit, UsuariosEstado>(
      'no emite nada si hayMas es false',
      build: build,
      seed: _cargados,
      act: (c) => c.cargarMas(),
      expect: () => [],
    );

    blocTest<UsuariosCubit, UsuariosEstado>(
      'no emite nada si el estado no es Cargados',
      build: build,
      act: (c) => c.cargarMas(),
      expect: () => [],
    );

    blocTest<UsuariosCubit, UsuariosEstado>(
      'emite [CargandoMas, Cargados] acumulando la segunda página',
      build: build,
      setUp: () {
        when(() => repositorio.obtenerUsuarios(offset: any(named: 'offset')))
            .thenAnswer((_) async => (usuarios: [_u3], hayMas: false));
      },
      seed: () => const UsuariosCargados(
        usuarios: [_u1, _u2],
        usuariosFiltrados: [_u1, _u2],
        hayMas: true,
      ),
      act: (c) => c.cargarMas(),
      expect: () => [
        isA<UsuariosCargandoMas>(),
        isA<UsuariosCargados>()
            .having((e) => e.usuarios.length, 'usuarios.length', 3)
            .having((e) => e.hayMas, 'hayMas', false),
      ],
    );

    blocTest<UsuariosCubit, UsuariosEstado>(
      'CargandoMas preserva seleccionados y modoSeleccion',
      build: build,
      setUp: () {
        when(() => repositorio.obtenerUsuarios(offset: any(named: 'offset')))
            .thenAnswer((_) async => (usuarios: [_u3], hayMas: false));
      },
      seed: () => const UsuariosCargados(
        usuarios: [_u1, _u2],
        usuariosFiltrados: [_u1, _u2],
        hayMas: true,
        modoSeleccion: true,
        seleccionados: {'u-1'},
      ),
      act: (c) => c.cargarMas(),
      expect: () => [
        isA<UsuariosCargandoMas>()
            .having((e) => e.seleccionados, 'seleccionados', {'u-1'}).having(
                (e) => e.modoSeleccion, 'modoSeleccion', true),
        isA<UsuariosCargados>()
            .having((e) => e.seleccionados, 'seleccionados', {'u-1'}).having(
                (e) => e.modoSeleccion, 'modoSeleccion', true),
      ],
    );

    blocTest<UsuariosCubit, UsuariosEstado>(
      'revierte al Cargados original si el repositorio falla',
      build: build,
      setUp: () {
        when(() => repositorio.obtenerUsuarios(offset: any(named: 'offset')))
            .thenThrow(const FallaServidor('Error de red'));
      },
      seed: () => const UsuariosCargados(
        usuarios: [_u1, _u2],
        usuariosFiltrados: [_u1, _u2],
        hayMas: true,
      ),
      act: (c) => c.cargarMas(),
      expect: () => [
        isA<UsuariosCargandoMas>(),
        isA<UsuariosCargados>()
            .having((e) => e.usuarios.length, 'usuarios.length', 2)
            .having((e) => e.hayMas, 'hayMas', true),
      ],
    );
  });

  // ── filtrar ────────────────────────────────────────────────────────────────

  group('UsuariosCubit.filtrar', () {
    blocTest<UsuariosCubit, UsuariosEstado>(
      'no hace nada si el estado no es Cargados',
      build: build,
      act: (c) => c.filtrar('leo'),
      expect: () => [],
    );

    blocTest<UsuariosCubit, UsuariosEstado>(
      'texto vacío después de filtrar restaura todos los usuarios',
      build: build,
      seed: () => const UsuariosCargados(
        usuarios: _lista,
        usuariosFiltrados: [_u1],
        hayMas: false,
      ),
      act: (c) => c.filtrar(''),
      expect: () => [
        isA<UsuariosCargados>()
            .having((e) => e.usuariosFiltrados.length, 'length', 3),
      ],
    );

    blocTest<UsuariosCubit, UsuariosEstado>(
      'texto solo espacios después de filtrar restaura todos',
      build: build,
      seed: () => const UsuariosCargados(
        usuarios: _lista,
        usuariosFiltrados: [_u2],
        hayMas: false,
      ),
      act: (c) => c.filtrar('   '),
      expect: () => [
        isA<UsuariosCargados>()
            .having((e) => e.usuariosFiltrados.length, 'length', 3),
      ],
    );

    blocTest<UsuariosCubit, UsuariosEstado>(
      'filtra por primerNombre (case-insensitive, parcial)',
      build: build,
      seed: _cargados,
      act: (c) => c.filtrar('leo'),
      expect: () => [
        isA<UsuariosCargados>().having(
          (e) => e.usuariosFiltrados.map((u) => u.id).toList(),
          'ids',
          ['u-1'],
        ),
      ],
    );

    blocTest<UsuariosCubit, UsuariosEstado>(
      'filtra por correo',
      build: build,
      seed: _cargados,
      act: (c) => c.filtrar('ana@'),
      expect: () => [
        isA<UsuariosCargados>().having(
          (e) => e.usuariosFiltrados.map((u) => u.id).toList(),
          'ids',
          ['u-2'],
        ),
      ],
    );

    blocTest<UsuariosCubit, UsuariosEstado>(
      'filtra por primerApellido',
      build: build,
      seed: _cargados,
      act: (c) => c.filtrar('ruiz'),
      expect: () => [
        isA<UsuariosCargados>().having(
          (e) => e.usuariosFiltrados.map((u) => u.id).toList(),
          'ids',
          ['u-3'],
        ),
      ],
    );

    blocTest<UsuariosCubit, UsuariosEstado>(
      'filtra por numeroIdentificacion (campo nullable)',
      build: build,
      seed: _cargados,
      act: (c) => c.filtrar('CI-12'),
      expect: () => [
        isA<UsuariosCargados>().having(
          (e) => e.usuariosFiltrados.map((u) => u.id).toList(),
          'ids',
          ['u-2'],
        ),
      ],
    );

    blocTest<UsuariosCubit, UsuariosEstado>(
      'sin coincidencia devuelve lista vacía',
      build: build,
      seed: _cargados,
      act: (c) => c.filtrar('zzzzz'),
      expect: () => [
        isA<UsuariosCargados>()
            .having((e) => e.usuariosFiltrados, 'usuariosFiltrados', isEmpty),
      ],
    );
  });

  // ── selección múltiple ─────────────────────────────────────────────────────

  group('UsuariosCubit.selección', () {
    blocTest<UsuariosCubit, UsuariosEstado>(
      'activarSeleccion establece modoSeleccion=true con el usuario dado',
      build: build,
      seed: _cargados,
      act: (c) => c.activarSeleccion('u-1'),
      expect: () => [
        isA<UsuariosCargados>()
            .having((e) => e.modoSeleccion, 'modoSeleccion', true)
            .having((e) => e.seleccionados, 'seleccionados', {'u-1'}),
      ],
    );

    blocTest<UsuariosCubit, UsuariosEstado>(
      'activarSeleccion no hace nada si el estado no es Cargados',
      build: build,
      act: (c) => c.activarSeleccion('u-1'),
      expect: () => [],
    );

    blocTest<UsuariosCubit, UsuariosEstado>(
      'toggleSeleccion agrega un usuario al set',
      build: build,
      seed: () => const UsuariosCargados(
        usuarios: _lista,
        usuariosFiltrados: _lista,
        hayMas: false,
        modoSeleccion: true,
        seleccionados: {'u-1'},
      ),
      act: (c) => c.toggleSeleccion('u-2'),
      expect: () => [
        isA<UsuariosCargados>()
            .having((e) => e.seleccionados, 'seleccionados', {'u-1', 'u-2'}),
      ],
    );

    blocTest<UsuariosCubit, UsuariosEstado>(
      'toggleSeleccion quita un usuario del set',
      build: build,
      seed: () => const UsuariosCargados(
        usuarios: _lista,
        usuariosFiltrados: _lista,
        hayMas: false,
        modoSeleccion: true,
        seleccionados: {'u-1', 'u-2'},
      ),
      act: (c) => c.toggleSeleccion('u-1'),
      expect: () => [
        isA<UsuariosCargados>()
            .having((e) => e.seleccionados, 'seleccionados', {'u-2'}),
      ],
    );

    blocTest<UsuariosCubit, UsuariosEstado>(
      'toggleSeleccion auto-sale del modo cuando el set queda vacío',
      build: build,
      seed: () => const UsuariosCargados(
        usuarios: _lista,
        usuariosFiltrados: _lista,
        hayMas: false,
        modoSeleccion: true,
        seleccionados: {'u-1'},
      ),
      act: (c) => c.toggleSeleccion('u-1'),
      expect: () => [
        isA<UsuariosCargados>()
            .having((e) => e.modoSeleccion, 'modoSeleccion', false)
            .having((e) => e.seleccionados, 'seleccionados', isEmpty),
      ],
    );

    blocTest<UsuariosCubit, UsuariosEstado>(
      'salirModoSeleccion limpia selección y desactiva modo',
      build: build,
      seed: () => const UsuariosCargados(
        usuarios: _lista,
        usuariosFiltrados: _lista,
        hayMas: false,
        modoSeleccion: true,
        seleccionados: {'u-1', 'u-2'},
      ),
      act: (c) => c.salirModoSeleccion(),
      expect: () => [
        isA<UsuariosCargados>()
            .having((e) => e.modoSeleccion, 'modoSeleccion', false)
            .having((e) => e.seleccionados, 'seleccionados', isEmpty),
      ],
    );
  });

  // ── acciones en lote ───────────────────────────────────────────────────────

  group('UsuariosCubit.suspenderLote', () {
    blocTest<UsuariosCubit, UsuariosEstado>(
      'no hace nada si seleccionados está vacío',
      build: build,
      seed: _cargados,
      act: (c) => c.suspenderLote(),
      expect: () => [],
    );

    blocTest<UsuariosCubit, UsuariosEstado>(
      'emite estaEjecutandoLote=true, llama al repo y recarga',
      build: build,
      setUp: () {
        when(() => repositorio.suspenderLote(any())).thenAnswer((_) async {});
        when(() => repositorio.obtenerUsuarios())
            .thenAnswer((_) async => (usuarios: _lista, hayMas: false));
      },
      seed: () => const UsuariosCargados(
        usuarios: _lista,
        usuariosFiltrados: _lista,
        hayMas: false,
        modoSeleccion: true,
        seleccionados: {'u-1', 'u-2'},
      ),
      act: (c) => c.suspenderLote(),
      verify: (_) {
        verify(() => repositorio.suspenderLote(any())).called(1);
        verify(() => repositorio.obtenerUsuarios()).called(1);
      },
    );

    blocTest<UsuariosCubit, UsuariosEstado>(
      'emite errorLote en Cargados cuando suspenderLote falla',
      build: build,
      setUp: () {
        when(() => repositorio.suspenderLote(any()))
            .thenThrow(const FallaServidor('Error al suspender'));
      },
      seed: () => const UsuariosCargados(
        usuarios: _lista,
        usuariosFiltrados: _lista,
        hayMas: false,
        modoSeleccion: true,
        seleccionados: {'u-1'},
      ),
      act: (c) => c.suspenderLote(),
      expect: () => [
        isA<UsuariosCargados>()
            .having((e) => e.estaEjecutandoLote, 'estaEjecutandoLote', true),
        isA<UsuariosCargados>()
            .having((e) => e.estaEjecutandoLote, 'estaEjecutandoLote', false)
            .having((e) => e.errorLote, 'errorLote', 'Error al suspender'),
      ],
    );
  });

  group('UsuariosCubit.asignarRolLote', () {
    blocTest<UsuariosCubit, UsuariosEstado>(
      'no hace nada si seleccionados está vacío',
      build: build,
      seed: _cargados,
      act: (c) => c.asignarRolLote('rol-1', 'admin-1'),
      expect: () => [],
    );

    blocTest<UsuariosCubit, UsuariosEstado>(
      'llama repositorio.asignarRolLote con los parámetros correctos y recarga',
      build: build,
      setUp: () {
        when(() => repositorio.asignarRolLote(any(), any(), any()))
            .thenAnswer((_) async {});
        when(() => repositorio.obtenerUsuarios())
            .thenAnswer((_) async => (usuarios: _lista, hayMas: false));
      },
      seed: () => const UsuariosCargados(
        usuarios: _lista,
        usuariosFiltrados: _lista,
        hayMas: false,
        modoSeleccion: true,
        seleccionados: {'u-1'},
      ),
      act: (c) => c.asignarRolLote('rol-1', 'admin-1'),
      verify: (_) {
        verify(() => repositorio.asignarRolLote(any(), 'rol-1', 'admin-1'))
            .called(1);
      },
    );

    blocTest<UsuariosCubit, UsuariosEstado>(
      'emite errorLote cuando asignarRolLote falla',
      build: build,
      setUp: () {
        when(() => repositorio.asignarRolLote(any(), any(), any()))
            .thenThrow(const FallaServidor('Sin permiso'));
      },
      seed: () => const UsuariosCargados(
        usuarios: _lista,
        usuariosFiltrados: _lista,
        hayMas: false,
        modoSeleccion: true,
        seleccionados: {'u-1'},
      ),
      act: (c) => c.asignarRolLote('rol-1', 'admin-1'),
      expect: () => [
        isA<UsuariosCargados>()
            .having((e) => e.estaEjecutandoLote, 'estaEjecutandoLote', true),
        isA<UsuariosCargados>()
            .having((e) => e.errorLote, 'errorLote', 'Sin permiso'),
      ],
    );
  });

  group('UsuariosCubit.asignarTagLote', () {
    blocTest<UsuariosCubit, UsuariosEstado>(
      'no hace nada si seleccionados está vacío',
      build: build,
      seed: _cargados,
      act: (c) => c.asignarTagLote('tag-1', 'admin-1'),
      expect: () => [],
    );

    blocTest<UsuariosCubit, UsuariosEstado>(
      'llama repositorio.asignarTagLote con los parámetros correctos y recarga',
      build: build,
      setUp: () {
        when(() => repositorio.asignarTagLote(any(), any(), any()))
            .thenAnswer((_) async {});
        when(() => repositorio.obtenerUsuarios())
            .thenAnswer((_) async => (usuarios: _lista, hayMas: false));
      },
      seed: () => const UsuariosCargados(
        usuarios: _lista,
        usuariosFiltrados: _lista,
        hayMas: false,
        modoSeleccion: true,
        seleccionados: {'u-2'},
      ),
      act: (c) => c.asignarTagLote('tag-p', 'admin-1'),
      verify: (_) {
        verify(() => repositorio.asignarTagLote(any(), 'tag-p', 'admin-1'))
            .called(1);
      },
    );
  });
}
