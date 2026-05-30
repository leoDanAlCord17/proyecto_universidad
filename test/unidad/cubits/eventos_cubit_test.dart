import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:uniasist/compartido/errores.dart';
import 'package:uniasist/funcionalidades/eventos/evento.dart';
import 'package:uniasist/funcionalidades/eventos/eventos_cubit.dart';
import 'package:uniasist/funcionalidades/eventos/eventos_estado.dart';

import '../../helpers.dart';

// ─── Fixtures locales ─────────────────────────────────────────────────────────

const _tagsVacios = (tagPrincipalId: null, tagsSecundariosIds: <String>[]);

EventoConGrupos _eventoGeneral({
  String id = 'ev-general',
  String estatus = 'programado',
  DateTime? fechaInicio,
}) =>
    EventoConGrupos.desdeJson(<String, dynamic>{
      'id':                        id,
      'titulo':                    'Evento General',
      'modo_registro':             'auto',
      'estatus':                   estatus,
      'alcance':                   'general',
      'creado_en':                 '2025-01-01T00:00:00Z',
      'actualizado_en':            '2025-01-01T00:00:00Z',
      'permite_qr_evento':         true,
      'permite_qr_usuario':        true,
      'permite_manual_admin':      true,
      'requiere_ciclo_completo':   false,
      'permite_salida_anticipada': false,
      'marcar_ausentes_auto':      false,
      'permite_foraneos':          false,
      if (fechaInicio != null) 'fecha_inicio': fechaInicio.toIso8601String(),
      'evento_grupos_tags': const <Map<String, dynamic>>[],
    });

EventoConGrupos _eventoDirigido({
  String id = 'ev-dirigido',
  String estatus = 'programado',
  String tagPrincipalId = 'tp-1',
  String tagSecundarioId = 'ts-1',
  DateTime? fechaInicio,
}) =>
    EventoConGrupos.desdeJson(<String, dynamic>{
      'id':                        id,
      'titulo':                    'Evento Dirigido',
      'modo_registro':             'auto',
      'estatus':                   estatus,
      'alcance':                   'dirigido',
      'creado_en':                 '2025-01-01T00:00:00Z',
      'actualizado_en':            '2025-01-01T00:00:00Z',
      'permite_qr_evento':         true,
      'permite_qr_usuario':        true,
      'permite_manual_admin':      true,
      'requiere_ciclo_completo':   false,
      'permite_salida_anticipada': false,
      'marcar_ausentes_auto':      false,
      'permite_foraneos':          false,
      if (fechaInicio != null) 'fecha_inicio': fechaInicio.toIso8601String(),
      'evento_grupos_tags': <Map<String, dynamic>>[
        <String, dynamic>{
          'grupo_index': 0,
          'tag_id':      tagPrincipalId,
          'tags': const <String, dynamic>{'tipo': 'principal', 'nombre': 'Ing'},
        },
        <String, dynamic>{
          'grupo_index': 0,
          'tag_id':      tagSecundarioId,
          'tags': const <String, dynamic>{'tipo': 'secundario', 'nombre': 'Sis'},
        },
      ],
    });

EventoConGrupos _eventoDirigidoSinGrupos({String id = 'ev-sin-grupos'}) =>
    EventoConGrupos.desdeJson(<String, dynamic>{
      'id':                        id,
      'titulo':                    'Sin Grupos',
      'modo_registro':             'auto',
      'estatus':                   'programado',
      'alcance':                   'dirigido',
      'creado_en':                 '2025-01-01T00:00:00Z',
      'actualizado_en':            '2025-01-01T00:00:00Z',
      'permite_qr_evento':         true,
      'permite_qr_usuario':        true,
      'permite_manual_admin':      true,
      'requiere_ciclo_completo':   false,
      'permite_salida_anticipada': false,
      'marcar_ausentes_auto':      false,
      'permite_foraneos':          false,
      'evento_grupos_tags':        const <Map<String, dynamic>>[],
    });

// ─── Helpers de stub ──────────────────────────────────────────────────────────

void _stubVacio(MockEventosRepositorio repo) {
  when(() => repo.obtenerEventosConGrupos()).thenAnswer((_) async => []);
  when(() => repo.obtenerTagsUsuario(any())).thenAnswer((_) async => _tagsVacios);
  when(() => repo.contarBorradores(any())).thenAnswer((_) async => 0);
  when(() => repo.obtenerConteoPresentesPorEvento(any()))
      .thenAnswer((_) async => {});
}

// ─── Tests ────────────────────────────────────────────────────────────────────

void main() {
  late MockEventosRepositorio repositorio;

  setUp(() {
    repositorio = MockEventosRepositorio();
  });

  EventosCubit build() => EventosCubit(repositorio);

  group('EventosCubit.cargar', () {
    test('estado inicial es EventosInicial', () {
      expect(build().state, isA<EventosInicial>());
    });

    blocTest<EventosCubit, EventosEstado>(
      'emite [Cargando, Cargado] con listas vacías cuando el repo no devuelve eventos',
      build: build,
      setUp: () => _stubVacio(repositorio),
      act: (c) => c.cargar('user-1'),
      expect: () => [
        isA<EventosCargando>(),
        isA<EventosCargado>()
            .having((e) => e.enCurso,  'enCurso',  isEmpty)
            .having((e) => e.proximos, 'proximos', isEmpty),
      ],
    );

    blocTest<EventosCubit, EventosEstado>(
      'emite [Cargando, Error] con mensaje cuando FallaServidor en obtenerEventosConGrupos',
      build: build,
      setUp: () {
        when(() => repositorio.obtenerEventosConGrupos())
            .thenThrow(const FallaServidor('Sin red'));
        when(() => repositorio.obtenerTagsUsuario(any()))
            .thenAnswer((_) async => _tagsVacios);
      },
      act: (c) => c.cargar('user-1'),
      expect: () => [
        isA<EventosCargando>(),
        isA<EventosError>().having((e) => e.mensaje, 'mensaje', 'Sin red'),
      ],
    );

    blocTest<EventosCubit, EventosEstado>(
      'emite [Cargando, Error] cuando FallaInesperada',
      build: build,
      setUp: () {
        when(() => repositorio.obtenerEventosConGrupos())
            .thenThrow(const FallaInesperada('Error raro'));
        when(() => repositorio.obtenerTagsUsuario(any()))
            .thenAnswer((_) async => _tagsVacios);
      },
      act: (c) => c.cargar('user-1'),
      expect: () => [
        isA<EventosCargando>(),
        isA<EventosError>().having((e) => e.mensaje, 'mensaje', 'Error raro'),
      ],
    );

    blocTest<EventosCubit, EventosEstado>(
      'fallo en contarBorradores no impide emitir Cargado',
      build: build,
      setUp: () {
        when(() => repositorio.obtenerEventosConGrupos())
            .thenAnswer((_) async => []);
        when(() => repositorio.obtenerTagsUsuario(any()))
            .thenAnswer((_) async => _tagsVacios);
        when(() => repositorio.contarBorradores(any()))
            .thenThrow(const FallaServidor('fallo borradores'));
        when(() => repositorio.obtenerConteoPresentesPorEvento(any()))
            .thenAnswer((_) async => {});
      },
      act: (c) => c.cargar('user-1'),
      expect: () => [
        isA<EventosCargando>(),
        isA<EventosCargado>(),
      ],
    );

    blocTest<EventosCubit, EventosEstado>(
      'llama obtenerConteoPresentesPorEvento para enriquecer eventos en curso',
      build: build,
      setUp: () {
        final enCurso = _eventoGeneral(id: 'ev-1', estatus: 'en_curso');
        when(() => repositorio.obtenerEventosConGrupos())
            .thenAnswer((_) async => [enCurso]);
        when(() => repositorio.obtenerTagsUsuario(any()))
            .thenAnswer((_) async => _tagsVacios);
        when(() => repositorio.contarBorradores(any()))
            .thenAnswer((_) async => 0);
        when(() => repositorio.obtenerConteoPresentesPorEvento(any()))
            .thenAnswer((_) async => {'ev-1': 5});
      },
      act: (c) => c.cargar('user-1'),
      expect: () => [
        isA<EventosCargando>(),
        isA<EventosCargado>().having(
          (e) => e.enCurso.first.totalPresentes,
          'totalPresentes',
          5,
        ),
      ],
      verify: (_) {
        verify(() => repositorio.obtenerConteoPresentesPorEvento(['ev-1']))
            .called(1);
      },
    );
  });

  group('EventosCubit._esVisible — visibilidad', () {
    blocTest<EventosCubit, EventosEstado>(
      'evento general siempre aparece independientemente de los tags del usuario',
      build: build,
      setUp: () {
        when(() => repositorio.obtenerEventosConGrupos())
            .thenAnswer((_) async => [_eventoGeneral()]);
        when(() => repositorio.obtenerTagsUsuario(any()))
            .thenAnswer((_) async => _tagsVacios);
        when(() => repositorio.contarBorradores(any()))
            .thenAnswer((_) async => 0);
        when(() => repositorio.obtenerConteoPresentesPorEvento(any()))
            .thenAnswer((_) async => {});
      },
      act: (c) => c.cargar('user-1'),
      expect: () => [
        isA<EventosCargando>(),
        isA<EventosCargado>()
            .having((e) => e.proximos.length, 'proximos.length', 1),
      ],
    );

    blocTest<EventosCubit, EventosEstado>(
      'evento dirigido sin grupos nunca aparece',
      build: build,
      setUp: () {
        when(() => repositorio.obtenerEventosConGrupos())
            .thenAnswer((_) async => [_eventoDirigidoSinGrupos()]);
        when(() => repositorio.obtenerTagsUsuario(any()))
            .thenAnswer((_) async => _tagsVacios);
        when(() => repositorio.contarBorradores(any()))
            .thenAnswer((_) async => 0);
        when(() => repositorio.obtenerConteoPresentesPorEvento(any()))
            .thenAnswer((_) async => {});
      },
      act: (c) => c.cargar('user-1'),
      expect: () => [
        isA<EventosCargando>(),
        isA<EventosCargado>()
            .having((e) => e.proximos, 'proximos', isEmpty)
            .having((e) => e.enCurso,  'enCurso',  isEmpty),
      ],
    );

    blocTest<EventosCubit, EventosEstado>(
      'evento dirigido cuyos grupos coinciden con los tags del usuario aparece',
      build: build,
      setUp: () {
        when(() => repositorio.obtenerEventosConGrupos()).thenAnswer(
          (_) async => [
            _eventoDirigido(tagPrincipalId: 'tp-1', tagSecundarioId: 'ts-1'),
          ],
        );
        when(() => repositorio.obtenerTagsUsuario(any())).thenAnswer(
          (_) async => (
            tagPrincipalId:     'tp-1',
            tagsSecundariosIds: ['ts-1'],
          ),
        );
        when(() => repositorio.contarBorradores(any()))
            .thenAnswer((_) async => 0);
        when(() => repositorio.obtenerConteoPresentesPorEvento(any()))
            .thenAnswer((_) async => {});
      },
      act: (c) => c.cargar('user-1'),
      expect: () => [
        isA<EventosCargando>(),
        isA<EventosCargado>()
            .having((e) => e.proximos.length, 'proximos.length', 1),
      ],
    );

    blocTest<EventosCubit, EventosEstado>(
      'evento dirigido cuyo tag principal no coincide no aparece',
      build: build,
      setUp: () {
        when(() => repositorio.obtenerEventosConGrupos()).thenAnswer(
          (_) async => [
            _eventoDirigido(tagPrincipalId: 'tp-1', tagSecundarioId: 'ts-1'),
          ],
        );
        when(() => repositorio.obtenerTagsUsuario(any())).thenAnswer(
          (_) async => (
            tagPrincipalId:     'tp-OTRO',
            tagsSecundariosIds: ['ts-1'],
          ),
        );
        when(() => repositorio.contarBorradores(any()))
            .thenAnswer((_) async => 0);
        when(() => repositorio.obtenerConteoPresentesPorEvento(any()))
            .thenAnswer((_) async => {});
      },
      act: (c) => c.cargar('user-1'),
      expect: () => [
        isA<EventosCargando>(),
        isA<EventosCargado>()
            .having((e) => e.proximos, 'proximos', isEmpty),
      ],
    );

    blocTest<EventosCubit, EventosEstado>(
      'evento dirigido con tag principal correcto pero falta tag secundario requerido no aparece',
      build: build,
      setUp: () {
        when(() => repositorio.obtenerEventosConGrupos()).thenAnswer(
          (_) async => [
            _eventoDirigido(tagPrincipalId: 'tp-1', tagSecundarioId: 'ts-1'),
          ],
        );
        when(() => repositorio.obtenerTagsUsuario(any())).thenAnswer(
          (_) async => (
            tagPrincipalId:     'tp-1',
            tagsSecundariosIds: <String>[],
          ),
        );
        when(() => repositorio.contarBorradores(any()))
            .thenAnswer((_) async => 0);
        when(() => repositorio.obtenerConteoPresentesPorEvento(any()))
            .thenAnswer((_) async => {});
      },
      act: (c) => c.cargar('user-1'),
      expect: () => [
        isA<EventosCargando>(),
        isA<EventosCargado>()
            .having((e) => e.proximos, 'proximos', isEmpty),
      ],
    );
  });

  // filtrar() opera sobre _proximos/_enCurso (listas internas del cubit),
  // no sobre el estado. Por eso hay que llamar cargar() primero para
  // popularllas y usar skip: 2 para ignorar [Cargando, Cargado].
  group('EventosCubit.filtrar', () {
    final evGeneral = _eventoGeneral(id: 'ev-g');
    final evDescripcion = EventoConGrupos.desdeJson(const <String, dynamic>{
      'id': 'ev-d', 'titulo': 'Sin nombre relevante',
      'descripcion': 'Taller de robótica avanzada',
      'modo_registro': 'auto', 'estatus': 'programado', 'alcance': 'general',
      'creado_en': '2025-01-01T00:00:00Z', 'actualizado_en': '2025-01-01T00:00:00Z',
      'permite_qr_evento': true, 'permite_qr_usuario': true,
      'permite_manual_admin': true, 'requiere_ciclo_completo': false,
      'permite_salida_anticipada': false, 'marcar_ausentes_auto': false,
      'permite_foraneos': false, 'evento_grupos_tags': <Map<String, dynamic>>[],
    });
    final evLugar = EventoConGrupos.desdeJson(const <String, dynamic>{
      'id': 'ev-l', 'titulo': 'Otro titulo', 'lugar': 'Auditorio Central',
      'modo_registro': 'auto', 'estatus': 'programado', 'alcance': 'general',
      'creado_en': '2025-01-01T00:00:00Z', 'actualizado_en': '2025-01-01T00:00:00Z',
      'permite_qr_evento': true, 'permite_qr_usuario': true,
      'permite_manual_admin': true, 'requiere_ciclo_completo': false,
      'permite_salida_anticipada': false, 'marcar_ausentes_auto': false,
      'permite_foraneos': false, 'evento_grupos_tags': <Map<String, dynamic>>[],
    });
    final evEnero = _eventoGeneral(id: 'ev-enero', fechaInicio: DateTime.utc(2025, 1, 15));
    final evMarzo = _eventoGeneral(id: 'ev-marzo', fechaInicio: DateTime.utc(2025, 3, 10));

    void stubConEventos(List<EventoConGrupos> eventos) {
      when(() => repositorio.obtenerEventosConGrupos())
          .thenAnswer((_) async => eventos);
      when(() => repositorio.obtenerTagsUsuario(any()))
          .thenAnswer((_) async => _tagsVacios);
      when(() => repositorio.contarBorradores(any()))
          .thenAnswer((_) async => 0);
      when(() => repositorio.obtenerConteoPresentesPorEvento(any()))
          .thenAnswer((_) async => {});
    }

    blocTest<EventosCubit, EventosEstado>(
      'no hace nada si el estado no es Cargado',
      build: build,
      act: (c) => c.filtrar('texto', null),
      expect: () => [],
    );

    blocTest<EventosCubit, EventosEstado>(
      'texto vacío después de filtrar restaura todos los eventos',
      build: build,
      setUp: () => stubConEventos([evGeneral, evDescripcion, evLugar]),
      // Cargar → filtrar con texto (reduce lista) → filtrar vacío (restaura)
      act: (c) async {
        await c.cargar('user-1');
        c.filtrar('Evento General', null);
        c.filtrar('', null);
      },
      skip: 3, // skip [Cargando, Cargado, Cargado(filtrado)]
      expect: () => [
        isA<EventosCargado>()
            .having((e) => e.proximos.length, 'proximos.length', 3),
      ],
    );

    blocTest<EventosCubit, EventosEstado>(
      'filtra por título',
      build: build,
      setUp: () => stubConEventos([evGeneral, evDescripcion, evLugar]),
      act: (c) async { await c.cargar('user-1'); c.filtrar('Evento General', null); },
      skip: 2,
      expect: () => [
        isA<EventosCargado>().having(
          (e) => e.proximos.map((x) => x.evento.id).toList(),
          'ids', ['ev-g'],
        ),
      ],
    );

    blocTest<EventosCubit, EventosEstado>(
      'filtra por descripción',
      build: build,
      setUp: () => stubConEventos([evGeneral, evDescripcion, evLugar]),
      act: (c) async { await c.cargar('user-1'); c.filtrar('robótica', null); },
      skip: 2,
      expect: () => [
        isA<EventosCargado>().having(
          (e) => e.proximos.map((x) => x.evento.id).toList(),
          'ids', ['ev-d'],
        ),
      ],
    );

    blocTest<EventosCubit, EventosEstado>(
      'filtra por lugar',
      build: build,
      setUp: () => stubConEventos([evGeneral, evDescripcion, evLugar]),
      act: (c) async { await c.cargar('user-1'); c.filtrar('auditorio', null); },
      skip: 2,
      expect: () => [
        isA<EventosCargado>().having(
          (e) => e.proximos.map((x) => x.evento.id).toList(),
          'ids', ['ev-l'],
        ),
      ],
    );

    blocTest<EventosCubit, EventosEstado>(
      'DateTimeRange filtra eventos por fechaInicio',
      build: build,
      setUp: () => stubConEventos([evEnero, evMarzo]),
      act: (c) async {
        await c.cargar('user-1');
        c.filtrar('', DateTimeRange(start: DateTime.utc(2025, 1, 1), end: DateTime.utc(2025, 2, 1)));
      },
      skip: 2,
      expect: () => [
        isA<EventosCargado>().having(
          (e) => e.proximos.map((x) => x.evento.id).toList(),
          'ids', ['ev-enero'],
        ),
      ],
    );

    blocTest<EventosCubit, EventosEstado>(
      'texto + rango se aplican juntos (AND)',
      build: build,
      setUp: () => stubConEventos([evEnero, evMarzo]),
      act: (c) async {
        await c.cargar('user-1');
        c.filtrar('Evento General', DateTimeRange(
          start: DateTime.utc(2025, 3, 1), end: DateTime.utc(2025, 3, 31),
        ),);
      },
      skip: 2,
      expect: () => [
        isA<EventosCargado>().having(
          (e) => e.proximos.map((x) => x.evento.id).toList(),
          'ids', ['ev-marzo'],
        ),
      ],
    );

    blocTest<EventosCubit, EventosEstado>(
      'texto sin coincidencia devuelve listas vacías',
      build: build,
      setUp: () => stubConEventos([evGeneral]),
      act: (c) async { await c.cargar('user-1'); c.filtrar('zzzzz', null); },
      skip: 2,
      expect: () => [
        isA<EventosCargado>()
            .having((e) => e.proximos, 'proximos', isEmpty),
      ],
    );
  });

  group('EventosCubit.close', () {
    test('close no lanza excepción', () async {
      _stubVacio(repositorio);
      final cubit = build();
      await cubit.cargar('user-1');
      await expectLater(cubit.close(), completes);
    });
  });
}
