import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:uniasist/compartido/constantes.dart';
import 'package:uniasist/compartido/errores.dart';
import 'package:uniasist/funcionalidades/eventos/evento.dart';
import 'package:uniasist/funcionalidades/panel_control_evento/asistente_item.dart';
import 'package:uniasist/funcionalidades/panel_control_evento/panel_control_cubit.dart';
import 'package:uniasist/funcionalidades/panel_control_evento/panel_control_estado.dart';

import '../../helpers.dart';

// ─── Fixtures ─────────────────────────────────────────────────────────────────

Evento _crearEvento({
  String id = 'evento-1',
  String alcance = AlcanceEvento.general,
  bool marcarAusentesAuto = false,
}) =>
    Evento(
      id: id,
      titulo: 'Charla',
      modoRegistro: ModoRegistro.auto,
      estatus: EstatusEvento.enCurso,
      alcance: alcance,
      creadoEn: DateTime.utc(2025),
      actualizadoEn: DateTime.utc(2025),
      permiteQrEvento: true,
      permiteQrUsuario: true,
      permiteManualAdmin: true,
      requiereCicloCompleto: false,
      permiteSalidaAnticipada: false,
      marcarAusentesAuto: marcarAusentesAuto,
      permiteForaneos: false,
    );

const _asistentePresenteEsperado = AsistenteItem(
  id: 'a-1',
  usuarioId: 'u-1',
  nombre: 'Leo Alvarez',
  iniciales: 'LA',
  estatus: EstatusAsistencia.presente,
  esForaneo: false,
  eraEsperado: true,
);

const _asistenteForaneo = AsistenteItem(
  id: 'a-2',
  usuarioId: null,
  nombre: 'Visitante',
  iniciales: 'V',
  estatus: EstatusAsistencia.presente,
  esForaneo: true,
  eraEsperado: false,
);

const _asistenteEsperadoPendiente = AsistenteItem(
  id: 'a-3',
  usuarioId: 'u-3',
  nombre: 'Carlos Ruiz',
  iniciales: 'CR',
  estatus: EstatusAsistencia.esperado,
  esForaneo: false,
  eraEsperado: true,
);

// ─── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  late MockPanelControlRepositorio repositorio;

  setUp(() {
    repositorio = MockPanelControlRepositorio();
    when(() => repositorio.streamCambiosAsistencia(any()))
        .thenAnswer((_) => const Stream.empty());
  });

  PanelControlCubit build() => PanelControlCubit(repositorio);

  group('PanelControlCubit.cargar', () {
    test('estado inicial es PanelControlInicial', () {
      expect(build().state, isA<PanelControlInicial>());
    });

    blocTest<PanelControlCubit, PanelControlEstado>(
      'emite [Cargando, Cargado] para evento dirigido con audiencia',
      build: build,
      setUp: () {
        when(() => repositorio.obtenerEvento(any())).thenAnswer(
            (_) async => _crearEvento(alcance: AlcanceEvento.dirigido));
        when(() => repositorio.obtenerAsistentes(any()))
            .thenAnswer((_) async => [_asistentePresenteEsperado]);
        when(() => repositorio.obtenerMiembrosGrupo(any()))
            .thenAnswer((_) async => [_asistenteEsperadoPendiente]);
      },
      act: (c) => c.cargar('evento-1'),
      expect: () => [
        isA<PanelControlCargando>(),
        isA<PanelControlCargado>()
            .having((e) => e.evento.alcance, 'alcance', AlcanceEvento.dirigido)
            .having((e) => e.asistentes.length, 'asistentes', 1)
            .having((e) => e.listaEsperados.length, 'esperados', 1),
      ],
    );

    blocTest<PanelControlCubit, PanelControlEstado>(
      'emite [Cargando, Cargado] para evento general sin audiencia',
      build: build,
      setUp: () {
        when(() => repositorio.obtenerEvento(any()))
            .thenAnswer((_) async => _crearEvento());
        when(() => repositorio.obtenerAsistentes(any()))
            .thenAnswer((_) async => []);
      },
      act: (c) => c.cargar('evento-1'),
      expect: () => [
        isA<PanelControlCargando>(),
        isA<PanelControlCargado>()
            .having((e) => e.listaEsperados, 'esperados', isEmpty),
      ],
      verify: (_) {
        verifyNever(() => repositorio.obtenerMiembrosGrupo(any()));
      },
    );

    blocTest<PanelControlCubit, PanelControlEstado>(
      'emite [Cargando, Error] cuando FallaServidor',
      build: build,
      setUp: () {
        when(() => repositorio.obtenerEvento(any()))
            .thenThrow(const FallaServidor('Sin red'));
        when(() => repositorio.obtenerAsistentes(any()))
            .thenAnswer((_) async => []);
      },
      act: (c) => c.cargar('evento-1'),
      expect: () => [
        isA<PanelControlCargando>(),
        isA<PanelControlError>().having((e) => e.mensaje, 'mensaje', 'Sin red'),
      ],
    );

    blocTest<PanelControlCubit, PanelControlEstado>(
      'emite [Cargando, Error] cuando FallaInesperada',
      build: build,
      setUp: () {
        when(() => repositorio.obtenerEvento(any()))
            .thenThrow(const FallaInesperada('Falla rara'));
        when(() => repositorio.obtenerAsistentes(any()))
            .thenAnswer((_) async => []);
      },
      act: (c) => c.cargar('evento-1'),
      expect: () => [
        isA<PanelControlCargando>(),
        isA<PanelControlError>()
            .having((e) => e.mensaje, 'mensaje', 'Falla rara'),
      ],
    );
  });

  group('PanelControlCubit.cambiarFiltro', () {
    blocTest<PanelControlCubit, PanelControlEstado>(
      'actualiza filtroActivo en estado Cargado',
      build: build,
      setUp: () {
        when(() => repositorio.obtenerEvento(any()))
            .thenAnswer((_) async => _crearEvento());
        when(() => repositorio.obtenerAsistentes(any()))
            .thenAnswer((_) async => []);
      },
      act: (c) async {
        await c.cargar('evento-1');
        c.cambiarFiltro(FiltroAsistentes.foraneos);
      },
      expect: () => [
        isA<PanelControlCargando>(),
        isA<PanelControlCargado>()
            .having((e) => e.filtroActivo, 'filtro', FiltroAsistentes.todos),
        isA<PanelControlCargado>()
            .having((e) => e.filtroActivo, 'filtro', FiltroAsistentes.foraneos),
      ],
    );

    blocTest<PanelControlCubit, PanelControlEstado>(
      'no emite si el estado no es Cargado',
      build: build,
      act: (c) => c.cambiarFiltro(FiltroAsistentes.foraneos),
      expect: () => [],
    );
  });

  group('PanelControlCubit.cerrarEvento', () {
    blocTest<PanelControlCubit, PanelControlEstado>(
      'emite [Cargado(cerrando:true), EventoCerrado]',
      build: build,
      setUp: () {
        when(() => repositorio.obtenerEvento(any()))
            .thenAnswer((_) async => _crearEvento());
        when(() => repositorio.obtenerAsistentes(any()))
            .thenAnswer((_) async => []);
        when(() => repositorio.cerrarEvento(any())).thenAnswer((_) async {});
      },
      act: (c) async {
        await c.cargar('evento-1');
        await c.cerrarEvento();
      },
      expect: () => [
        isA<PanelControlCargando>(),
        isA<PanelControlCargado>(),
        isA<PanelControlCargado>()
            .having((e) => e.estaCerrando, 'cerrando', true),
        isA<PanelControlEventoCerrado>(),
      ],
      verify: (_) {
        verify(() => repositorio.cerrarEvento('evento-1')).called(1);
      },
    );

    blocTest<PanelControlCubit, PanelControlEstado>(
      'llama marcarAusentesAuto cuando marcarAusentesAuto=true',
      build: build,
      setUp: () {
        when(() => repositorio.obtenerEvento(any()))
            .thenAnswer((_) async => _crearEvento(marcarAusentesAuto: true));
        when(() => repositorio.obtenerAsistentes(any()))
            .thenAnswer((_) async => []);
        when(() => repositorio.cerrarEvento(any())).thenAnswer((_) async {});
        when(() => repositorio.marcarAusentesAuto(any()))
            .thenAnswer((_) async {});
      },
      act: (c) async {
        await c.cargar('evento-1');
        await c.cerrarEvento();
      },
      verify: (_) {
        verify(() => repositorio.marcarAusentesAuto('evento-1')).called(1);
      },
    );

    blocTest<PanelControlCubit, PanelControlEstado>(
      'emite OperacionFallida cuando cerrarEvento lanza FallaServidor',
      build: build,
      setUp: () {
        when(() => repositorio.obtenerEvento(any()))
            .thenAnswer((_) async => _crearEvento());
        when(() => repositorio.obtenerAsistentes(any()))
            .thenAnswer((_) async => []);
        when(() => repositorio.cerrarEvento(any()))
            .thenThrow(const FallaServidor('Error al cerrar'));
      },
      act: (c) async {
        await c.cargar('evento-1');
        await c.cerrarEvento();
      },
      expect: () => [
        isA<PanelControlCargando>(),
        isA<PanelControlCargado>(),
        isA<PanelControlCargado>()
            .having((e) => e.estaCerrando, 'cerrando', true),
        isA<PanelControlOperacionFallida>()
            .having((e) => e.mensaje, 'mensaje', 'Error al cerrar'),
      ],
    );
  });

  group('PanelControlCubit.asistentesFiltrados', () {
    late PanelControlCargado estado;

    setUp(() {
      estado = PanelControlCargado(
        evento: _crearEvento(alcance: AlcanceEvento.dirigido),
        asistentes: const [
          _asistentePresenteEsperado,
          _asistenteForaneo,
          _asistenteEsperadoPendiente,
        ],
        listaEsperados: const [
          _asistentePresenteEsperado,
          _asistenteEsperadoPendiente,
        ],
      );
    });

    test('filtro todos devuelve todos los asistentes', () {
      expect(estado.asistentesFiltrados.length, 3);
    });

    test('filtro esperados devuelve listaEsperados', () {
      final filtrado = estado
          .copiarCon(filtroActivo: FiltroAsistentes.esperados)
          .asistentesFiltrados;
      expect(filtrado.length, 2);
    });

    test('filtro foraneos devuelve solo foráneos', () {
      final filtrado = estado
          .copiarCon(filtroActivo: FiltroAsistentes.foraneos)
          .asistentesFiltrados;
      expect(filtrado, [_asistenteForaneo]);
    });

    test('filtro noEsperados excluye foráneos y esperados de la audiencia', () {
      final filtrado = estado
          .copiarCon(filtroActivo: FiltroAsistentes.noEsperados)
          .asistentesFiltrados;
      expect(filtrado, isEmpty);
    });

    test('filtro registrados incluye presente y completado', () {
      final filtrado = estado
          .copiarCon(filtroActivo: FiltroAsistentes.registrados)
          .asistentesFiltrados;
      expect(filtrado, contains(_asistentePresenteEsperado));
    });
  });

  group('PanelControlCubit contadores', () {
    test('totalPresentes cuenta presente, completado y salioAnticipado', () {
      final e = PanelControlCargado(
        evento: _crearEvento(),
        asistentes: const [
          _asistentePresenteEsperado,
          _asistenteForaneo,
          _asistenteEsperadoPendiente,
        ],
        listaEsperados: const [],
      );
      expect(e.totalPresentes, 2);
    });

    test('pendientes cuenta esperados sin registrar en listaEsperados', () {
      final e = PanelControlCargado(
        evento: _crearEvento(alcance: AlcanceEvento.dirigido),
        asistentes: const [],
        listaEsperados: const [_asistenteEsperadoPendiente],
      );
      expect(e.pendientes, 1);
    });

    test('tasaConvocatoria es null para evento general', () {
      final e = PanelControlCargado(
        evento: _crearEvento(),
        asistentes: const [],
        listaEsperados: const [],
      );
      expect(e.tasaConvocatoria, isNull);
    });

    test('tasaConvocatoria calcula correctamente para evento dirigido', () {
      final e = PanelControlCargado(
        evento: _crearEvento(alcance: AlcanceEvento.dirigido),
        asistentes: const [_asistentePresenteEsperado],
        listaEsperados: const [
          _asistentePresenteEsperado,
          _asistenteEsperadoPendiente,
        ],
      );
      expect(e.tasaConvocatoria, 0.5);
    });
  });
}
