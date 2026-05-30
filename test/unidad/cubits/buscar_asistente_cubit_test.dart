import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:uniasist/compartido/constantes.dart';
import 'package:uniasist/compartido/errores.dart';
import 'package:uniasist/funcionalidades/buscar_asistente/buscar_asistente_cubit.dart';
import 'package:uniasist/funcionalidades/buscar_asistente/buscar_asistente_estado.dart';
import 'package:uniasist/funcionalidades/buscar_asistente/resultado_busqueda.dart';

import '../../helpers.dart';

// ─── Fixtures ─────────────────────────────────────────────────────────────────

const _usuarioFila = <String, dynamic>{
  'id':                   'u-1',
  'primer_nombre':        'Leo',
  'primer_apellido':      'Alvarez',
  'url_avatar':           null,
  'numero_identificacion': null,
};

const _usuarioFila2 = <String, dynamic>{
  'id':                   'u-2',
  'primer_nombre':        'Ana',
  'primer_apellido':      'Gomez',
  'url_avatar':           null,
  'numero_identificacion': null,
};

const _asistenciaPresente = <String, dynamic>{
  'id':                       'a-1',
  'usuario_id':               'u-1',
  'estatus':                  EstatusAsistencia.presente,
  'hora_entrada':             null,
  'hora_salida':              null,
  'entrada_registrada_por':   null,
};

const _asistenciaCompletado = <String, dynamic>{
  'id':                       'a-2',
  'usuario_id':               'u-2',
  'estatus':                  EstatusAsistencia.completado,
  'hora_entrada':             null,
  'hora_salida':              null,
  'entrada_registrada_por':   null,
};

// ─── Helpers ──────────────────────────────────────────────────────────────────

void _stubIniciar(MockBuscarAsistenteRepositorio repo) {
  when(() => repo.obtenerEvento(any()))
      .thenAnswer((_) async => eventoEjemplo);
  when(() => repo.streamAsistencia(any()))
      .thenAnswer((_) => const Stream.empty());
}

BuscarAsistenteCargado _estadoCargado() => BuscarAsistenteCargado(
  evento:            eventoEjemplo,
  resultados:        const [],
  busqueda:          '',
  cantidadPresentes: 0,
  cantidadTotal:     0,
);

// ─── Tests ────────────────────────────────────────────────────────────────────

void main() {
  late MockBuscarAsistenteRepositorio repositorio;

  setUp(() {
    repositorio = MockBuscarAsistenteRepositorio();
    registrarFallbacks();
  });

  BuscarAsistenteCubit build() => BuscarAsistenteCubit(repositorio);

  // ── iniciar ────────────────────────────────────────────────────────────────

  group('BuscarAsistenteCubit.iniciar', () {
    test('estado inicial es BuscarAsistenteInicial', () {
      expect(build().state, isA<BuscarAsistenteInicial>());
    });

    blocTest<BuscarAsistenteCubit, BuscarAsistenteEstado>(
      'emite [Cargando, Cargado] cuando el evento carga correctamente',
      build: build,
      setUp: () => _stubIniciar(repositorio),
      act: (c) => c.iniciar('ev-1'),
      expect: () => [
        isA<BuscarAsistenteCargando>(),
        isA<BuscarAsistenteCargado>()
            .having((e) => e.evento.id,  'evento.id',  eventoEjemplo.id)
            .having((e) => e.resultados, 'resultados', isEmpty),
      ],
    );

    blocTest<BuscarAsistenteCubit, BuscarAsistenteEstado>(
      'emite [Cargando, Error] cuando FallaServidor en obtenerEvento',
      build: build,
      setUp: () {
        when(() => repositorio.obtenerEvento(any()))
            .thenThrow(const FallaServidor('No encontrado'));
        when(() => repositorio.streamAsistencia(any()))
            .thenAnswer((_) => const Stream.empty());
      },
      act: (c) => c.iniciar('ev-1'),
      expect: () => [
        isA<BuscarAsistenteCargando>(),
        isA<BuscarAsistenteError>()
            .having((e) => e.mensaje, 'mensaje', 'No encontrado'),
      ],
    );
  });

  // ── buscar ─────────────────────────────────────────────────────────────────

  group('BuscarAsistenteCubit.buscar', () {
    blocTest<BuscarAsistenteCubit, BuscarAsistenteEstado>(
      'no hace nada si el estado no es Cargado',
      build: build,
      act: (c) => c.buscar('leo'),
      expect: () => [],
    );

    // buscar() requiere que _eventoId esté seteado (via iniciar).
    // Usamos act con iniciar() primero y skip:2 para ignorar [Cargando, Cargado].
    blocTest<BuscarAsistenteCubit, BuscarAsistenteEstado>(
      'query con menos de 2 caracteres limpia resultados sin llamar al repo',
      build: build,
      setUp: () => _stubIniciar(repositorio),
      act: (c) async {
        await c.iniciar('ev-1');
        await c.buscar('a');
      },
      skip: 2,
      expect: () => [
        isA<BuscarAsistenteCargado>()
            .having((e) => e.resultados, 'resultados', isEmpty)
            .having((e) => e.busqueda,   'busqueda',   'a'),
      ],
      verify: (_) {
        verifyNever(() => repositorio.buscarUsuarios(any()));
      },
    );

    blocTest<BuscarAsistenteCubit, BuscarAsistenteEstado>(
      'query vacío limpia resultados sin llamar al repo',
      build: build,
      setUp: () => _stubIniciar(repositorio),
      act: (c) async {
        await c.iniciar('ev-1');
        // Primero buscar algo para que el estado sea diferente, luego vaciar
        when(() => repositorio.buscarUsuarios(any()))
            .thenAnswer((_) async => [_usuarioFila]);
        when(() => repositorio.resolverNombresUsuarios(any()))
            .thenAnswer((_) async => {});
        await c.buscar('le');
        await c.buscar('');
      },
      skip: 3, // skip [Cargando, Cargado, búsqueda-con-resultados]
      expect: () => [
        isA<BuscarAsistenteCargado>()
            .having((e) => e.resultados, 'resultados', isEmpty),
      ],
    );

    blocTest<BuscarAsistenteCubit, BuscarAsistenteEstado>(
      'query con 2+ caracteres llama al repositorio y emite resultados',
      build: build,
      setUp: () {
        _stubIniciar(repositorio);
        when(() => repositorio.buscarUsuarios(any()))
            .thenAnswer((_) async => [_usuarioFila]);
        when(() => repositorio.resolverNombresUsuarios(any()))
            .thenAnswer((_) async => {});
      },
      act: (c) async {
        await c.iniciar('ev-1');
        await c.buscar('le');
      },
      skip: 2,
      expect: () => [
        isA<BuscarAsistenteCargado>()
            .having((e) => e.resultados.length, 'resultados.length', 1)
            .having((e) => e.busqueda,          'busqueda',          'le'),
      ],
      verify: (_) {
        verify(() => repositorio.buscarUsuarios('le')).called(1);
      },
    );

    blocTest<BuscarAsistenteCubit, BuscarAsistenteEstado>(
      'emite OperacionFallida cuando FallaServidor en buscarUsuarios',
      build: build,
      setUp: () {
        _stubIniciar(repositorio);
        when(() => repositorio.buscarUsuarios(any()))
            .thenThrow(const FallaServidor('Sin red'));
      },
      act: (c) async {
        await c.iniciar('ev-1');
        await c.buscar('le');
      },
      skip: 2,
      expect: () => [
        isA<BuscarAsistenteOperacionFallida>()
            .having((e) => e.mensaje, 'mensaje', 'Sin red'),
      ],
    );
  });

  // ── registrarEntrada ───────────────────────────────────────────────────────

  group('BuscarAsistenteCubit.registrarEntrada', () {
    final resultado = ResultadoBusqueda.desdeUsuario(_usuarioFila);

    blocTest<BuscarAsistenteCubit, BuscarAsistenteEstado>(
      'no hace nada si el estado no es Cargado',
      build: build,
      act: (c) => c.registrarEntrada(resultado),
      expect: () => [],
    );

    blocTest<BuscarAsistenteCubit, BuscarAsistenteEstado>(
      'emite [estaRegistrando=true, estaRegistrando=false] al registrar con éxito',
      build: build,
      setUp: () {
        _stubIniciar(repositorio);
        when(() => repositorio.registrarEntrada(
              eventoId:        any(named: 'eventoId'),
              usuarioId:       any(named: 'usuarioId'),
              asistenciaId:    any(named: 'asistenciaId'),
              registradoPorId: any(named: 'registradoPorId'),
            ),).thenAnswer((_) async {});
      },
      act: (c) async {
        await c.iniciar('ev-1');
        await c.registrarEntrada(resultado);
      },
      skip: 2,
      expect: () => [
        isA<BuscarAsistenteCargado>()
            .having((e) => e.estaRegistrando,      'estaRegistrando',      true)
            .having((e) => e.usuarioIdRegistrando, 'usuarioIdRegistrando', 'u-1'),
        isA<BuscarAsistenteCargado>()
            .having((e) => e.estaRegistrando,      'estaRegistrando',      false)
            .having((e) => e.usuarioIdRegistrando, 'usuarioIdRegistrando', isNull),
      ],
    );

    blocTest<BuscarAsistenteCubit, BuscarAsistenteEstado>(
      'segunda llamada con mismo usuarioId se ignora mientras está en curso',
      build: build,
      setUp: () {
        _stubIniciar(repositorio);
        when(() => repositorio.registrarEntrada(
              eventoId:        any(named: 'eventoId'),
              usuarioId:       any(named: 'usuarioId'),
              asistenciaId:    any(named: 'asistenciaId'),
              registradoPorId: any(named: 'registradoPorId'),
            ),).thenAnswer((_) async {});
      },
      act: (c) async {
        await c.iniciar('ev-1');
        final f1 = c.registrarEntrada(resultado);
        final f2 = c.registrarEntrada(resultado);
        await Future.wait([f1, f2]);
      },
      verify: (_) {
        verify(() => repositorio.registrarEntrada(
              eventoId:        any(named: 'eventoId'),
              usuarioId:       any(named: 'usuarioId'),
              asistenciaId:    any(named: 'asistenciaId'),
              registradoPorId: any(named: 'registradoPorId'),
            ),).called(1);
      },
    );

    blocTest<BuscarAsistenteCubit, BuscarAsistenteEstado>(
      'emite OperacionFallida cuando FallaServidor en registrarEntrada',
      build: build,
      setUp: () {
        _stubIniciar(repositorio);
        when(() => repositorio.registrarEntrada(
              eventoId:        any(named: 'eventoId'),
              usuarioId:       any(named: 'usuarioId'),
              asistenciaId:    any(named: 'asistenciaId'),
              registradoPorId: any(named: 'registradoPorId'),
            ),).thenThrow(const FallaServidor('DB error'));
      },
      act: (c) async {
        await c.iniciar('ev-1');
        await c.registrarEntrada(resultado);
      },
      skip: 2,
      expect: () => [
        isA<BuscarAsistenteCargado>()
            .having((e) => e.estaRegistrando, 'estaRegistrando', true),
        isA<BuscarAsistenteOperacionFallida>()
            .having((e) => e.mensaje, 'mensaje', 'DB error'),
      ],
    );
  });

  // ── marcarSalida ───────────────────────────────────────────────────────────

  group('BuscarAsistenteCubit.marcarSalida', () {
    blocTest<BuscarAsistenteCubit, BuscarAsistenteEstado>(
      'no hace nada si el estado no es Cargado',
      build: build,
      act: (c) => c.marcarSalida(asistenciaId: 'a-1', esAnticipada: false),
      expect: () => [],
    );

    blocTest<BuscarAsistenteCubit, BuscarAsistenteEstado>(
      'emite [marcandoSalida=true, marcandoSalida=false] al registrar salida normal',
      build: build,
      setUp: () {
        when(() => repositorio.marcarSalida(
              asistenciaId:    any(named: 'asistenciaId'),
              esAnticipada:    any(named: 'esAnticipada'),
              motivo:          any(named: 'motivo'),
              registradoPorId: any(named: 'registradoPorId'),
            ),).thenAnswer((_) async {});
      },
      seed: _estadoCargado,
      act: (c) => c.marcarSalida(asistenciaId: 'a-1', esAnticipada: false),
      expect: () => [
        isA<BuscarAsistenteCargado>()
            .having((e) => e.estaMarcandoSalida, 'estaMarcandoSalida', true),
        isA<BuscarAsistenteCargado>()
            .having((e) => e.estaMarcandoSalida, 'estaMarcandoSalida', false),
      ],
    );

    blocTest<BuscarAsistenteCubit, BuscarAsistenteEstado>(
      'emite OperacionFallida cuando FallaServidor en marcarSalida',
      build: build,
      setUp: () {
        when(() => repositorio.marcarSalida(
              asistenciaId:    any(named: 'asistenciaId'),
              esAnticipada:    any(named: 'esAnticipada'),
              motivo:          any(named: 'motivo'),
              registradoPorId: any(named: 'registradoPorId'),
            ),).thenThrow(const FallaServidor('Sin permiso'));
      },
      seed: _estadoCargado,
      act: (c) => c.marcarSalida(asistenciaId: 'a-1', esAnticipada: true),
      expect: () => [
        isA<BuscarAsistenteCargado>()
            .having((e) => e.estaMarcandoSalida, 'estaMarcandoSalida', true),
        isA<BuscarAsistenteOperacionFallida>()
            .having((e) => e.mensaje, 'mensaje', 'Sin permiso'),
      ],
    );
  });

  // ── _contarPresentes (indirecto via stream) ────────────────────────────────

  group('BuscarAsistenteCubit._contarPresentes', () {
    blocTest<BuscarAsistenteCubit, BuscarAsistenteEstado>(
      'cuenta presente, completado y salioAnticipado como presentes',
      build: build,
      setUp: () {
        when(() => repositorio.obtenerEvento(any()))
            .thenAnswer((_) async => eventoEjemplo);
        // Stream con dos registros activos (presente + completado)
        final controller = StreamController<List<Map<String, dynamic>>>();
        when(() => repositorio.streamAsistencia(any()))
            .thenAnswer((_) => controller.stream);
        when(() => repositorio.buscarUsuarios(any()))
            .thenAnswer((_) async => [_usuarioFila, _usuarioFila2]);
        when(() => repositorio.resolverNombresUsuarios(any()))
            .thenAnswer((_) async => {});
        // Emitir los dos registros activos después de iniciar y cerrar el sink
        Future.microtask(() {
          controller.add([_asistenciaPresente, _asistenciaCompletado]);
          controller.close();
        });
      },
      act: (c) async {
        await c.iniciar('ev-1');
        await Future.delayed(Duration.zero);
        await c.buscar('le');
      },
      expect: () => [
        isA<BuscarAsistenteCargando>(),
        isA<BuscarAsistenteCargado>(),
        isA<BuscarAsistenteCargado>()
            .having((e) => e.cantidadPresentes, 'cantidadPresentes', 2),
      ],
    );
  });

  // ── close ──────────────────────────────────────────────────────────────────

  group('BuscarAsistenteCubit.close', () {
    test('close cancela la suscripción sin lanzar excepción', () async {
      _stubIniciar(repositorio);
      final cubit = build();
      await cubit.iniciar('ev-1');
      await expectLater(cubit.close(), completes);
    });
  });
}
