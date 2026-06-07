import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:uniasist/compartido/errores.dart';
import 'package:uniasist/funcionalidades/tags/tag.dart';
import 'package:uniasist/funcionalidades/tags/tags_cubit.dart';
import 'package:uniasist/funcionalidades/tags/tags_estado.dart';

import '../../helpers.dart';

// ─── Fixtures ─────────────────────────────────────────────────────────────────

const _t1 = Tag(
  id:           'tag-1',
  nombre:       'Ingeniería',
  tipo:         'principal',
  estatus:      true,
  descripcion:  'Facultad de Ingeniería',
  totalUsuarios: 10,
);
const _t2 = Tag(
  id:           'tag-2',
  nombre:       'Sistemas',
  tipo:         'secundario',
  estatus:      true,
  descripcion:  'Carrera de Sistemas',
  totalUsuarios: 5,
);
const _t3 = Tag(
  id:           'tag-3',
  nombre:       'Medicina',
  tipo:         'principal',
  estatus:      false,
  descripcion:  'Facultad de Medicina',
  totalUsuarios: 0,
);

const _lista = [_t1, _t2, _t3];

TagsCargados _cargados() => const TagsCargados(
  tags:          _lista,
  tagsFiltrados: _lista,
  hayMas:        false,
);

// ─── Tests ────────────────────────────────────────────────────────────────────

void main() {
  late MockTagsRepositorio repositorio;

  setUp(() {
    repositorio = MockTagsRepositorio();
  });

  TagsCubit build() => TagsCubit(repositorio);

  // ── cargarTags ─────────────────────────────────────────────────────────────

  group('TagsCubit.cargarTags', () {
    test('estado inicial es TagsInicial', () {
      expect(build().state, isA<TagsInicial>());
    });

    blocTest<TagsCubit, TagsEstado>(
      'emite [Cargando, Cargados] con hayMas=false',
      build: build,
      setUp: () {
        when(() => repositorio.obtenerTags())
            .thenAnswer((_) async => (tags: _lista, hayMas: false));
      },
      act: (c) => c.cargarTags(),
      expect: () => [
        isA<TagsCargando>(),
        isA<TagsCargados>()
            .having((e) => e.tags.length,          'tags.length',          3)
            .having((e) => e.tagsFiltrados.length, 'tagsFiltrados.length', 3)
            .having((e) => e.hayMas,               'hayMas',               false),
      ],
    );

    blocTest<TagsCubit, TagsEstado>(
      'emite Cargados con hayMas=true cuando el repo indica más páginas',
      build: build,
      setUp: () {
        when(() => repositorio.obtenerTags())
            .thenAnswer((_) async => (tags: _lista, hayMas: true));
      },
      act: (c) => c.cargarTags(),
      expect: () => [
        isA<TagsCargando>(),
        isA<TagsCargados>()
            .having((e) => e.hayMas, 'hayMas', true),
      ],
    );

    blocTest<TagsCubit, TagsEstado>(
      'emite [Cargando, Error] cuando FallaServidor',
      build: build,
      setUp: () {
        when(() => repositorio.obtenerTags())
            .thenThrow(const FallaServidor('DB error'));
      },
      act: (c) => c.cargarTags(),
      expect: () => [
        isA<TagsCargando>(),
        isA<TagsError>().having((e) => e.mensaje, 'mensaje', 'DB error'),
      ],
    );

    blocTest<TagsCubit, TagsEstado>(
      'emite [Cargando, Error] cuando FallaRed',
      build: build,
      setUp: () {
        when(() => repositorio.obtenerTags())
            .thenThrow(const FallaRed('Sin internet'));
      },
      act: (c) => c.cargarTags(),
      expect: () => [
        isA<TagsCargando>(),
        isA<TagsError>().having((e) => e.mensaje, 'mensaje', 'Sin internet'),
      ],
    );
  });

  // ── cargarMas ──────────────────────────────────────────────────────────────

  group('TagsCubit.cargarMas', () {
    blocTest<TagsCubit, TagsEstado>(
      'no emite nada si hayMas es false',
      build: build,
      seed: _cargados,
      act: (c) => c.cargarMas(),
      expect: () => [],
    );

    blocTest<TagsCubit, TagsEstado>(
      'no emite nada si el estado no es Cargados',
      build: build,
      act: (c) => c.cargarMas(),
      expect: () => [],
    );

    blocTest<TagsCubit, TagsEstado>(
      'emite [CargandoMas, Cargados] acumulando la segunda página',
      build: build,
      setUp: () {
        when(() => repositorio.obtenerTags(offset: any(named: 'offset')))
            .thenAnswer((_) async => (tags: [_t3], hayMas: false));
      },
      seed: () => const TagsCargados(
        tags:          [_t1, _t2],
        tagsFiltrados: [_t1, _t2],
        hayMas:        true,
      ),
      act: (c) => c.cargarMas(),
      expect: () => [
        isA<TagsCargandoMas>(),
        isA<TagsCargados>()
            .having((e) => e.tags.length, 'tags.length', 3)
            .having((e) => e.hayMas,      'hayMas',      false),
      ],
    );

    blocTest<TagsCubit, TagsEstado>(
      'revierte al Cargados original si el repositorio falla',
      build: build,
      setUp: () {
        when(() => repositorio.obtenerTags(offset: any(named: 'offset')))
            .thenThrow(const FallaServidor('Error de red'));
      },
      seed: () => const TagsCargados(
        tags:          [_t1, _t2],
        tagsFiltrados: [_t1, _t2],
        hayMas:        true,
      ),
      act: (c) => c.cargarMas(),
      expect: () => [
        isA<TagsCargandoMas>(),
        isA<TagsCargados>()
            .having((e) => e.tags.length, 'tags.length', 2)
            .having((e) => e.hayMas,      'hayMas',      true),
      ],
    );
  });

  // ── filtrar ────────────────────────────────────────────────────────────────

  group('TagsCubit.filtrar', () {
    blocTest<TagsCubit, TagsEstado>(
      'no hace nada si el estado no es Cargados ni CargandoMas',
      build: build,
      act: (c) => c.filtrar('ing'),
      expect: () => [],
    );

    blocTest<TagsCubit, TagsEstado>(
      'filtra por nombre (case-insensitive)',
      build: build,
      seed: _cargados,
      act: (c) => c.filtrar('ingeniería'),
      expect: () => [
        isA<TagsCargados>().having(
          (e) => e.tagsFiltrados.map((t) => t.id).toList(),
          'ids',
          ['tag-1'],
        ),
      ],
    );

    blocTest<TagsCubit, TagsEstado>(
      'filtra por tipo',
      build: build,
      seed: _cargados,
      act: (c) => c.filtrar('secundario'),
      expect: () => [
        isA<TagsCargados>().having(
          (e) => e.tagsFiltrados.map((t) => t.id).toList(),
          'ids',
          ['tag-2'],
        ),
      ],
    );

    blocTest<TagsCubit, TagsEstado>(
      'filtra por descripción',
      build: build,
      seed: _cargados,
      act: (c) => c.filtrar('Carrera'),
      expect: () => [
        isA<TagsCargados>().having(
          (e) => e.tagsFiltrados.map((t) => t.id).toList(),
          'ids',
          ['tag-2'],
        ),
      ],
    );

    blocTest<TagsCubit, TagsEstado>(
      'texto vacío restaura todos los tags',
      build: build,
      seed: () => const TagsCargados(
        tags:          _lista,
        tagsFiltrados: [_t1],
        hayMas:        false,
      ),
      act: (c) => c.filtrar(''),
      expect: () => [
        isA<TagsCargados>()
            .having((e) => e.tagsFiltrados.length, 'length', 3),
      ],
    );

    blocTest<TagsCubit, TagsEstado>(
      'sin coincidencia devuelve lista vacía',
      build: build,
      seed: _cargados,
      act: (c) => c.filtrar('zzzzz'),
      expect: () => [
        isA<TagsCargados>()
            .having((e) => e.tagsFiltrados, 'tagsFiltrados', isEmpty),
      ],
    );
  });

  // ── activar / desactivar ───────────────────────────────────────────────────

  group('TagsCubit.activar', () {
    blocTest<TagsCubit, TagsEstado>(
      'no hace nada si el estado no es Cargados',
      build: build,
      act: (c) => c.activar('tag-3'),
      expect: () => [],
    );

    blocTest<TagsCubit, TagsEstado>(
      'llama al repo y recarga en éxito',
      build: build,
      setUp: () {
        when(() => repositorio.activarTag(any()))
            .thenAnswer((_) async {});
        when(() => repositorio.obtenerTags())
            .thenAnswer((_) async => (tags: _lista, hayMas: false));
      },
      seed: _cargados,
      act: (c) => c.activar('tag-3'),
      verify: (_) {
        verify(() => repositorio.activarTag('tag-3')).called(1);
        verify(() => repositorio.obtenerTags()).called(1);
      },
    );

    blocTest<TagsCubit, TagsEstado>(
      'emite TagsOperacionFallida cuando falla',
      build: build,
      setUp: () {
        when(() => repositorio.activarTag(any()))
            .thenThrow(const FallaServidor('Sin permiso'));
      },
      seed: _cargados,
      act: (c) => c.activar('tag-3'),
      expect: () => [
        isA<TagsOperacionFallida>()
            .having((e) => e.mensaje, 'mensaje', 'Sin permiso'),
      ],
    );
  });

  group('TagsCubit.desactivar', () {
    blocTest<TagsCubit, TagsEstado>(
      'no hace nada si el estado no es Cargados',
      build: build,
      act: (c) => c.desactivar('tag-1'),
      expect: () => [],
    );

    blocTest<TagsCubit, TagsEstado>(
      'llama al repo y recarga en éxito',
      build: build,
      setUp: () {
        when(() => repositorio.desactivarTag(any()))
            .thenAnswer((_) async {});
        when(() => repositorio.obtenerTags())
            .thenAnswer((_) async => (tags: _lista, hayMas: false));
      },
      seed: _cargados,
      act: (c) => c.desactivar('tag-1'),
      verify: (_) {
        verify(() => repositorio.desactivarTag('tag-1')).called(1);
        verify(() => repositorio.obtenerTags()).called(1);
      },
    );

    blocTest<TagsCubit, TagsEstado>(
      'emite TagsOperacionFallida cuando falla',
      build: build,
      setUp: () {
        when(() => repositorio.desactivarTag(any()))
            .thenThrow(const FallaServidor('Error al desactivar'));
      },
      seed: _cargados,
      act: (c) => c.desactivar('tag-1'),
      expect: () => [
        isA<TagsOperacionFallida>()
            .having((e) => e.mensaje, 'mensaje', 'Error al desactivar'),
      ],
    );
  });
}
