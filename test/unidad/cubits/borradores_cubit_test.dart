import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:uniasist/compartido/errores.dart';
import 'package:uniasist/funcionalidades/borradores/borrador_evento.dart';
import 'package:uniasist/funcionalidades/borradores/borradores_cubit.dart';
import 'package:uniasist/funcionalidades/borradores/borradores_estado.dart';

import '../../helpers.dart';

// ─── Fixtures ─────────────────────────────────────────────────────────────────

final _b1 = BorradorEvento(
  id:          'b-1',
  titulo:      'Congreso Flutter',
  descripcion: 'Desc 1',
  fechaInicio: DateTime(2026, 3, 10),
);
final _b2 = BorradorEvento(
  id:          'b-2',
  titulo:      'Taller Dart',
  descripcion: 'Desc 2',
  fechaInicio: DateTime(2026, 4, 20),
);
const _b3 = BorradorEvento(
  id:          'b-3',
  titulo:      'Seminario UX',
  descripcion: 'Desc 3',
);

const _uid = 'user-1';

BorradoresCargados _cargados() => BorradoresCargados(
  borradores:          [_b1, _b2, _b3],
  borradoresFiltrados: [_b1, _b2, _b3],
  hayMas:              false,
);

// ─── Tests ────────────────────────────────────────────────────────────────────

void main() {
  late MockBorradoresRepositorio repositorio;

  setUp(() {
    repositorio = MockBorradoresRepositorio();
  });

  BorradoresCubit build() => BorradoresCubit(repositorio);

  // ── cargarBorradores ───────────────────────────────────────────────────────

  group('BorradoresCubit.cargarBorradores', () {
    test('estado inicial es BorradoresInicial', () {
      expect(build().state, isA<BorradoresInicial>());
    });

    blocTest<BorradoresCubit, BorradoresEstado>(
      'emite [Cargando, Cargados] con hayMas=false',
      build: build,
      setUp: () {
        when(() => repositorio.obtenerBorradores(_uid))
            .thenAnswer((_) async => (borradores: [_b1, _b2], hayMas: false));
      },
      act: (c) => c.cargarBorradores(_uid),
      expect: () => [
        isA<BorradoresCargando>(),
        isA<BorradoresCargados>()
            .having((e) => e.borradores.length,          'borradores.length',          2)
            .having((e) => e.borradoresFiltrados.length, 'borradoresFiltrados.length', 2)
            .having((e) => e.hayMas,                     'hayMas',                     false),
      ],
    );

    blocTest<BorradoresCubit, BorradoresEstado>(
      'emite Cargados con hayMas=true cuando el repo indica más páginas',
      build: build,
      setUp: () {
        when(() => repositorio.obtenerBorradores(_uid))
            .thenAnswer((_) async => (borradores: [_b1, _b2], hayMas: true));
      },
      act: (c) => c.cargarBorradores(_uid),
      expect: () => [
        isA<BorradoresCargando>(),
        isA<BorradoresCargados>()
            .having((e) => e.hayMas, 'hayMas', true),
      ],
    );

    blocTest<BorradoresCubit, BorradoresEstado>(
      'emite [Cargando, Error] cuando FallaServidor',
      build: build,
      setUp: () {
        when(() => repositorio.obtenerBorradores(_uid))
            .thenThrow(const FallaServidor('DB error'));
      },
      act: (c) => c.cargarBorradores(_uid),
      expect: () => [
        isA<BorradoresCargando>(),
        isA<BorradoresError>().having((e) => e.mensaje, 'mensaje', 'DB error'),
      ],
    );

    blocTest<BorradoresCubit, BorradoresEstado>(
      'emite [Cargando, Error] cuando FallaInesperada',
      build: build,
      setUp: () {
        when(() => repositorio.obtenerBorradores(_uid))
            .thenThrow(const FallaInesperada('Error inesperado'));
      },
      act: (c) => c.cargarBorradores(_uid),
      expect: () => [
        isA<BorradoresCargando>(),
        isA<BorradoresError>(),
      ],
    );
  });

  // ── cargarMas ──────────────────────────────────────────────────────────────

  group('BorradoresCubit.cargarMas', () {
    blocTest<BorradoresCubit, BorradoresEstado>(
      'no emite nada si hayMas es false',
      build: build,
      setUp: () {
        when(() => repositorio.obtenerBorradores(_uid))
            .thenAnswer((_) async => (borradores: [_b1], hayMas: false));
      },
      act: (c) async {
        await c.cargarBorradores(_uid);
        await c.cargarMas();
      },
      expect: () => [
        isA<BorradoresCargando>(),
        isA<BorradoresCargados>().having((e) => e.hayMas, 'hayMas', false),
        // cargarMas no emite nada extra
      ],
    );

    blocTest<BorradoresCubit, BorradoresEstado>(
      'no emite nada si el cubit no tiene usuarioId (estado inicial)',
      build: build,
      act: (c) => c.cargarMas(),
      expect: () => [],
    );

    blocTest<BorradoresCubit, BorradoresEstado>(
      'emite [CargandoMas, Cargados] acumulando la segunda página',
      build: build,
      setUp: () {
        var llamadas = 0;
        when(() => repositorio.obtenerBorradores(_uid, offset: any(named: 'offset')))
            .thenAnswer((_) async {
          llamadas++;
          return llamadas == 1
              ? (borradores: [_b1, _b2], hayMas: true)
              : (borradores: [_b3],      hayMas: false);
        });
      },
      act: (c) async {
        await c.cargarBorradores(_uid);
        await c.cargarMas();
      },
      expect: () => [
        isA<BorradoresCargando>(),
        isA<BorradoresCargados>()
            .having((e) => e.borradores.length, 'tras cargar', 2)
            .having((e) => e.hayMas, 'hayMas', true),
        isA<BorradoresCargandoMas>(),
        isA<BorradoresCargados>()
            .having((e) => e.borradores.length, 'tras cargarMas', 3)
            .having((e) => e.hayMas, 'hayMas', false),
      ],
    );

    blocTest<BorradoresCubit, BorradoresEstado>(
      'revierte al Cargados original si el repositorio falla en la segunda página',
      build: build,
      setUp: () {
        var llamadas = 0;
        when(() => repositorio.obtenerBorradores(_uid, offset: any(named: 'offset')))
            .thenAnswer((_) async {
          llamadas++;
          if (llamadas == 1) return (borradores: [_b1, _b2], hayMas: true);
          throw const FallaServidor('Sin conexión');
        });
      },
      act: (c) async {
        await c.cargarBorradores(_uid);
        await c.cargarMas();
      },
      expect: () => [
        isA<BorradoresCargando>(),
        isA<BorradoresCargados>()
            .having((e) => e.borradores.length, 'tras cargar', 2),
        isA<BorradoresCargandoMas>(),
        isA<BorradoresCargados>()
            .having((e) => e.borradores.length, 'tras error', 2)
            .having((e) => e.hayMas, 'hayMas', true),
      ],
    );
  });

  // ── filtrar ────────────────────────────────────────────────────────────────

  group('BorradoresCubit.filtrar', () {
    blocTest<BorradoresCubit, BorradoresEstado>(
      'no hace nada si el estado no es Cargados ni CargandoMas',
      build: build,
      act: (c) => c.filtrar('flutter', null),
      expect: () => [],
    );

    blocTest<BorradoresCubit, BorradoresEstado>(
      'filtra por título (case-insensitive)',
      build: build,
      seed: _cargados,
      act: (c) => c.filtrar('flutter', null),
      expect: () => [
        isA<BorradoresCargados>().having(
          (e) => e.borradoresFiltrados.map((b) => b.id).toList(),
          'ids',
          ['b-1'],
        ),
      ],
    );

    blocTest<BorradoresCubit, BorradoresEstado>(
      'filtra por descripción',
      build: build,
      seed: _cargados,
      act: (c) => c.filtrar('Desc 2', null),
      expect: () => [
        isA<BorradoresCargados>().having(
          (e) => e.borradoresFiltrados.map((b) => b.id).toList(),
          'ids',
          ['b-2'],
        ),
      ],
    );

    blocTest<BorradoresCubit, BorradoresEstado>(
      'texto vacío restaura todos los borradores',
      build: build,
      seed: () => BorradoresCargados(
        borradores:          [_b1, _b2, _b3],
        borradoresFiltrados: [_b1],
        hayMas:              false,
      ),
      act: (c) => c.filtrar('', null),
      expect: () => [
        isA<BorradoresCargados>()
            .having((e) => e.borradoresFiltrados.length, 'length', 3),
      ],
    );

    blocTest<BorradoresCubit, BorradoresEstado>(
      'filtra por rango de fecha',
      build: build,
      seed: _cargados,
      act: (c) => c.filtrar(
        '',
        DateTimeRange(
          start: DateTime(2026, 4, 1),
          end:   DateTime(2026, 4, 30),
        ),
      ),
      expect: () => [
        isA<BorradoresCargados>().having(
          (e) => e.borradoresFiltrados.map((b) => b.id).toList(),
          'ids',
          ['b-2'],
        ),
      ],
    );
  });

  // ── publicarEvento ─────────────────────────────────────────────────────────

  group('BorradoresCubit.publicarEvento', () {
    blocTest<BorradoresCubit, BorradoresEstado>(
      'no hace nada si el estado no es Cargados',
      build: build,
      act: (c) => c.publicarEvento('b-1'),
      expect: () => [],
    );

    blocTest<BorradoresCubit, BorradoresEstado>(
      'emite publicandoId y luego elimina el evento de la lista',
      build: build,
      setUp: () {
        when(() => repositorio.obtenerBorradores(_uid, offset: any(named: 'offset')))
            .thenAnswer((_) async => (borradores: [_b1, _b2], hayMas: false));
        when(() => repositorio.publicarEvento(any()))
            .thenAnswer((_) async {});
      },
      act: (c) async {
        await c.cargarBorradores(_uid);
        await c.publicarEvento('b-1');
      },
      expect: () => [
        isA<BorradoresCargando>(),
        isA<BorradoresCargados>()
            .having((e) => e.borradores.length, 'tras cargar', 2),
        isA<BorradoresCargados>()
            .having((e) => e.publicandoId, 'publicandoId', 'b-1'),
        isA<BorradoresCargados>()
            .having((e) => e.borradores.length,          'borradores.length',          1)
            .having((e) => e.borradoresFiltrados.length, 'borradoresFiltrados.length', 1)
            .having((e) => e.publicandoId,               'publicandoId',               null),
      ],
    );

    blocTest<BorradoresCubit, BorradoresEstado>(
      'emite errorPublicacion cuando publicarEvento falla',
      build: build,
      setUp: () {
        when(() => repositorio.obtenerBorradores(_uid, offset: any(named: 'offset')))
            .thenAnswer((_) async => (borradores: [_b1, _b2], hayMas: false));
        when(() => repositorio.publicarEvento(any()))
            .thenThrow(const FallaServidor('Sin permiso'));
      },
      act: (c) async {
        await c.cargarBorradores(_uid);
        await c.publicarEvento('b-1');
      },
      expect: () => [
        isA<BorradoresCargando>(),
        isA<BorradoresCargados>()
            .having((e) => e.borradores.length, 'tras cargar', 2),
        isA<BorradoresCargados>()
            .having((e) => e.publicandoId, 'publicandoId', 'b-1'),
        isA<BorradoresCargados>()
            .having((e) => e.errorPublicacion, 'errorPublicacion', 'Sin permiso')
            .having((e) => e.borradores.length, 'borradores.length', 2),
      ],
    );
  });
}
