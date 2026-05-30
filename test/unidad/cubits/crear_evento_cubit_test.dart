import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:uniasist/compartido/constantes.dart';
import 'package:uniasist/compartido/errores.dart';
import 'package:uniasist/funcionalidades/crear_evento/crear_evento_cubit.dart';
import 'package:uniasist/funcionalidades/crear_evento/crear_evento_estado.dart';
import 'package:uniasist/funcionalidades/crear_evento/grupo_audiencia.dart';

import '../../helpers.dart';

// ─── Fixtures ─────────────────────────────────────────────────────────────────

CrearEventoCargado _estadoBase() => const CrearEventoCargado(
  tiposEvento:     [tipoEventoEjemplo],
  tagsPrincipales: [tagPrincipalEjemplo],
  tagsSecundarios: [tagSecundarioEjemplo],
);

CrearEventoCargado _estadoConTitulo({String titulo = 'Mi evento'}) =>
    _estadoBase().copiarCon(titulo: titulo);

CrearEventoCargado _estadoConHoraFin() => _estadoConTitulo().copiarCon(
  horaFin: const TimeOfDay(hour: 18, minute: 0),
);

// ─── Tests ────────────────────────────────────────────────────────────────────

void main() {
  late MockCrearEventoRepositorio repositorio;

  setUp(() {
    repositorio = MockCrearEventoRepositorio();
  });

  CrearEventoCubit build() => CrearEventoCubit(repositorio);

  void stubOpciones() {
    when(() => repositorio.obtenerTiposEvento())
        .thenAnswer((_) async => [tipoEventoEjemplo]);
    when(() => repositorio.obtenerTags())
        .thenAnswer((_) async => [tagPrincipalEjemplo, tagSecundarioEjemplo]);
    when(() => repositorio.obtenerMaxTagsSecundarios())
        .thenAnswer((_) async => 3);
  }

  // ── cargarOpciones ─────────────────────────────────────────────────────────

  group('CrearEventoCubit.cargarOpciones', () {
    test('estado inicial es CrearEventoInicial', () {
      expect(build().state, isA<CrearEventoInicial>());
    });

    blocTest<CrearEventoCubit, CrearEventoEstado>(
      'emite [Cargando, Cargado] con tipos y tags del repositorio',
      build: build,
      setUp: stubOpciones,
      act: (c) => c.cargarOpciones(),
      expect: () => [
        isA<CrearEventoCargando>(),
        isA<CrearEventoCargado>()
            .having((e) => e.tiposEvento.length,     'tiposEvento.length',     1)
            .having((e) => e.tagsPrincipales.length, 'tagsPrincipales.length', 1)
            .having((e) => e.tagsSecundarios.length, 'tagsSecundarios.length', 1)
            .having((e) => e.maxTagsSecundarios,     'maxTagsSecundarios',     3),
      ],
    );

    blocTest<CrearEventoCubit, CrearEventoEstado>(
      'emite [Cargando, Error] cuando FallaServidor',
      build: build,
      setUp: () {
        when(() => repositorio.obtenerTiposEvento())
            .thenThrow(const FallaServidor('Sin red'));
        when(() => repositorio.obtenerTags())
            .thenAnswer((_) async => []);
        when(() => repositorio.obtenerMaxTagsSecundarios())
            .thenAnswer((_) async => 3);
      },
      act: (c) => c.cargarOpciones(),
      expect: () => [
        isA<CrearEventoCargando>(),
        isA<CrearEventoError>()
            .having((e) => e.mensaje, 'mensaje', 'Sin red'),
      ],
    );

    blocTest<CrearEventoCubit, CrearEventoEstado>(
      'emite [Cargando, Error] cuando FallaInesperada',
      build: build,
      setUp: () {
        when(() => repositorio.obtenerTiposEvento())
            .thenThrow(const FallaInesperada('Error raro'));
        when(() => repositorio.obtenerTags())
            .thenAnswer((_) async => []);
        when(() => repositorio.obtenerMaxTagsSecundarios())
            .thenAnswer((_) async => 3);
      },
      act: (c) => c.cargarOpciones(),
      expect: () => [
        isA<CrearEventoCargando>(),
        isA<CrearEventoError>(),
      ],
    );
  });

  // ── irAPaso ────────────────────────────────────────────────────────────────

  group('CrearEventoCubit.irAPaso', () {
    blocTest<CrearEventoCubit, CrearEventoEstado>(
      'no hace nada si el estado no es Cargado',
      build: build,
      act: (c) => c.irAPaso(1),
      expect: () => [],
    );

    blocTest<CrearEventoCubit, CrearEventoEstado>(
      'avanza normalmente cuando el título no está vacío',
      build: build,
      seed: _estadoConTitulo,
      act: (c) => c.irAPaso(1),
      expect: () => [
        isA<CrearEventoCargado>()
            .having((e) => e.pasoActual, 'pasoActual', 1),
      ],
    );

    blocTest<CrearEventoCubit, CrearEventoEstado>(
      'bloquea avance desde paso 0 cuando el título está vacío',
      build: build,
      seed: _estadoBase,
      // Nota: la primera emit (null error) se suprime porque el estado ya tiene error=null.
      // Solo se emite el estado con error.
      act: (c) => c.irAPaso(1),
      expect: () => [
        isA<CrearEventoCargado>()
            .having((e) => e.errorValidacion, 'errorValidacion', isNotNull)
            .having((e) => e.pasoActual, 'pasoActual', 0),
      ],
    );

    blocTest<CrearEventoCubit, CrearEventoEstado>(
      'retroceder desde paso 1 a paso 0 es libre sin validación',
      build: build,
      seed: () => _estadoBase().copiarCon(pasoActual: 1),
      act: (c) => c.irAPaso(0),
      expect: () => [
        isA<CrearEventoCargado>()
            .having((e) => e.pasoActual, 'pasoActual', 0),
      ],
    );

    blocTest<CrearEventoCubit, CrearEventoEstado>(
      'avance desde paso 1 en adelante no requiere validación de título',
      build: build,
      seed: () => _estadoBase().copiarCon(pasoActual: 1),
      act: (c) => c.irAPaso(2),
      expect: () => [
        isA<CrearEventoCargado>()
            .having((e) => e.pasoActual, 'pasoActual', 2),
      ],
    );
  });

  // ── _emitirErrorValidacion ─────────────────────────────────────────────────

  group('CrearEventoCubit._emitirErrorValidacion (doble emit)', () {
    blocTest<CrearEventoCubit, CrearEventoEstado>(
      'segunda llamada con mismo mensaje dispara el listener — doble emit funciona',
      build: build,
      // Seed con error ya presente: el primer emit (null) SÍ es diferente al actual
      seed: () => _estadoBase().copiarCon(
        errorValidacion: 'El título del evento es obligatorio.',
      ),
      act: (c) => c.irAPaso(1),
      expect: () => [
        // Primer emit: limpia error (null) — distinto del seed con error → se emite
        isA<CrearEventoCargado>()
            .having((e) => e.errorValidacion, 'error', isNull),
        // Segundo emit: pone el mensaje — distinto del null anterior → se emite
        isA<CrearEventoCargado>()
            .having((e) => e.errorValidacion, 'error', isNotNull),
      ],
    );
  });

  // ── publicarEvento ─────────────────────────────────────────────────────────

  group('CrearEventoCubit.publicarEvento', () {
    blocTest<CrearEventoCubit, CrearEventoEstado>(
      'emite error de validación si horaFin es null',
      build: build,
      seed: _estadoConTitulo,
      // El primer emit (null) se suprime porque el estado ya tiene error=null.
      act: (c) => c.publicarEvento(),
      expect: () => [
        isA<CrearEventoCargado>()
            .having((e) => e.errorValidacion, 'error', contains('hora de cierre')),
      ],
    );

    blocTest<CrearEventoCubit, CrearEventoEstado>(
      'emite [estaGuardando=true, Guardado] con esBorrador=false cuando horaFin está presente',
      build: build,
      setUp: () {
        when(() => repositorio.crearEvento(datos: any(named: 'datos')))
            .thenAnswer((_) async => 'nuevo-evento-id');
        when(() => repositorio.guardarGruposEvento(
              eventoId: any(named: 'eventoId'),
              grupos:   any(named: 'grupos'),
            ),).thenAnswer((_) async {});
      },
      seed: _estadoConHoraFin,
      act: (c) => c.publicarEvento(),
      expect: () => [
        isA<CrearEventoCargado>()
            .having((e) => e.estaGuardando, 'estaGuardando', true),
        isA<CrearEventoGuardado>()
            .having((e) => e.esBorrador, 'esBorrador', false)
            .having((e) => e.eventoId,  'eventoId',  'nuevo-evento-id'),
      ],
    );

    blocTest<CrearEventoCubit, CrearEventoEstado>(
      'no hace nada si el estado no es Cargado',
      build: build,
      act: (c) => c.publicarEvento(),
      expect: () => [],
    );
  });

  // ── guardarBorrador ────────────────────────────────────────────────────────

  group('CrearEventoCubit.guardarBorrador', () {
    blocTest<CrearEventoCubit, CrearEventoEstado>(
      'emite [estaGuardando=true, Guardado] con esBorrador=true sin importar horaFin',
      build: build,
      setUp: () {
        when(() => repositorio.crearEvento(datos: any(named: 'datos')))
            .thenAnswer((_) async => 'borrador-id');
        when(() => repositorio.guardarGruposEvento(
              eventoId: any(named: 'eventoId'),
              grupos:   any(named: 'grupos'),
            ),).thenAnswer((_) async {});
      },
      seed: _estadoConTitulo,
      act: (c) => c.guardarBorrador(),
      expect: () => [
        isA<CrearEventoCargado>()
            .having((e) => e.estaGuardando, 'estaGuardando', true),
        isA<CrearEventoGuardado>()
            .having((e) => e.esBorrador, 'esBorrador', true)
            .having((e) => e.eventoId,  'eventoId',  'borrador-id'),
      ],
    );

    blocTest<CrearEventoCubit, CrearEventoEstado>(
      'llama crearEvento con estatus borrador',
      build: build,
      setUp: () {
        when(() => repositorio.crearEvento(datos: any(named: 'datos')))
            .thenAnswer((_) async => 'ev-1');
        when(() => repositorio.guardarGruposEvento(
              eventoId: any(named: 'eventoId'),
              grupos:   any(named: 'grupos'),
            ),).thenAnswer((_) async {});
      },
      seed: _estadoConTitulo,
      act: (c) => c.guardarBorrador(),
      verify: (_) {
        verify(() => repositorio.crearEvento(
          datos: any(named: 'datos', that: predicate<Map<String, dynamic>>(
            (m) => m['estatus'] == EstatusEvento.borrador,
          ),),
        ),).called(1);
      },
    );

    blocTest<CrearEventoCubit, CrearEventoEstado>(
      'emite [estaGuardando=true, Error] cuando el repositorio falla',
      build: build,
      setUp: () {
        when(() => repositorio.crearEvento(datos: any(named: 'datos')))
            .thenThrow(const FallaServidor('Sin permiso'));
      },
      seed: _estadoConTitulo,
      act: (c) => c.guardarBorrador(),
      expect: () => [
        isA<CrearEventoCargado>()
            .having((e) => e.estaGuardando, 'estaGuardando', true),
        isA<CrearEventoError>()
            .having((e) => e.mensaje, 'mensaje', 'Sin permiso'),
      ],
    );
  });

  // ── agregarGrupo / eliminarGrupo ──────────────────────────────────────────

  group('CrearEventoCubit.agregarGrupo / eliminarGrupo', () {
    const grupo = GrupoAudiencia(
      grupoIndex:   0,
      tagPrincipal: tagPrincipalEjemplo,
    );

    blocTest<CrearEventoCubit, CrearEventoEstado>(
      'agregarGrupo añade un grupo al estado',
      build: build,
      seed: _estadoConTitulo,
      act: (c) => c.agregarGrupo(grupo),
      expect: () => [
        isA<CrearEventoCargado>().having(
          (e) => e.grupos.length, 'grupos.length', 1,
        ),
      ],
    );

    blocTest<CrearEventoCubit, CrearEventoEstado>(
      'eliminarGrupo quita el grupo por grupoIndex',
      build: build,
      seed: () => _estadoConTitulo().copiarCon(grupos: [grupo]),
      act: (c) => c.eliminarGrupo(0),
      expect: () => [
        isA<CrearEventoCargado>()
            .having((e) => e.grupos, 'grupos', isEmpty),
      ],
    );

    blocTest<CrearEventoCubit, CrearEventoEstado>(
      'agregarGrupo no hace nada si el estado no es Cargado',
      build: build,
      act: (c) => c.agregarGrupo(grupo),
      expect: () => [],
    );
  });
}
