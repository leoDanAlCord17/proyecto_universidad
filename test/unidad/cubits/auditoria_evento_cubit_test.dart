import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:activiti/compartido/errores.dart';
import 'package:activiti/funcionalidades/auditoria_evento/auditoria_evento_cubit.dart';
import 'package:activiti/funcionalidades/auditoria_evento/auditoria_evento_estado.dart';
import 'package:activiti/funcionalidades/auditoria_evento/auditoria_evento_modelo.dart';

import '../../helpers.dart';

// ─── Fixtures ────────────────────────────────────────────────────────────────

const _evento1 = EventoParaAuditoria(
  id: 'ev-1',
  titulo: 'Congreso',
  estatus: 'en_curso',
);

const _evento2 = EventoParaAuditoria(
  id: 'ev-2',
  titulo: 'Taller',
  estatus: 'finalizado',
);

const _evento3 = EventoParaAuditoria(
  id: 'ev-3',
  titulo: 'Seminario',
  estatus: 'finalizado',
);

RegistroAuditoria _reg(String id, String estatus) => RegistroAuditoria(
      id: id,
      nombre: 'Test $id',
      iniciales: 'T',
      estatus: estatus,
      esForaneo: false,
      horaEntrada: '',
      horaSalida: '',
    );

void main() {
  late MockAuditoriaEventoRepositorio repositorio;

  setUp(() {
    registrarFallbacks();
    repositorio = MockAuditoriaEventoRepositorio();
  });

  group('AuditoriaEventoCubit.iniciar', () {
    test('estado inicial es AuditoriaEventoInicial', () {
      final cubit = AuditoriaEventoCubit(repositorio);
      expect(cubit.state, isA<AuditoriaEventoInicial>());
      cubit.close();
    });

    blocTest<AuditoriaEventoCubit, AuditoriaEventoEstado>(
      'emite [CargandoLista, ListaCargada] cuando el repositorio devuelve datos',
      build: () {
        when(() => repositorio.obtenerEventos()).thenAnswer(
            (_) async => (eventos: [_evento1, _evento2], hayMas: false));
        return AuditoriaEventoCubit(repositorio);
      },
      act: (c) => c.iniciar(),
      expect: () => [
        isA<AuditoriaEventoCargandoLista>(),
        isA<AuditoriaEventoListaCargada>(),
      ],
    );

    blocTest<AuditoriaEventoCubit, AuditoriaEventoEstado>(
      'todosEventos se llena después de iniciar con éxito',
      build: () {
        when(() => repositorio.obtenerEventos()).thenAnswer(
            (_) async => (eventos: [_evento1, _evento2], hayMas: false));
        return AuditoriaEventoCubit(repositorio);
      },
      act: (c) => c.iniciar(),
      verify: (c) {
        expect(c.todosEventos.length, 2);
        expect(c.todosEventos.first.id, 'ev-1');
        expect(c.hayMasEventos, false);
      },
    );

    blocTest<AuditoriaEventoCubit, AuditoriaEventoEstado>(
      'hayMasEventos=true cuando el repo indica más páginas',
      build: () {
        when(() => repositorio.obtenerEventos()).thenAnswer(
            (_) async => (eventos: [_evento1, _evento2], hayMas: true));
        return AuditoriaEventoCubit(repositorio);
      },
      act: (c) => c.iniciar(),
      verify: (c) => expect(c.hayMasEventos, true),
    );

    blocTest<AuditoriaEventoCubit, AuditoriaEventoEstado>(
      'emite [CargandoLista, AuditoriaEventoError] al recibir FallaServidor',
      build: () {
        when(() => repositorio.obtenerEventos())
            .thenThrow(const FallaServidor('Error de base de datos.'));
        return AuditoriaEventoCubit(repositorio);
      },
      act: (c) => c.iniciar(),
      expect: () => [
        isA<AuditoriaEventoCargandoLista>(),
        isA<AuditoriaEventoError>().having(
          (e) => e.mensaje,
          'mensaje',
          'Error de base de datos.',
        ),
      ],
    );

    blocTest<AuditoriaEventoCubit, AuditoriaEventoEstado>(
      'emite [CargandoLista, AuditoriaEventoError] al recibir FallaInesperada',
      build: () {
        when(() => repositorio.obtenerEventos())
            .thenThrow(const FallaInesperada('Sin conexión.'));
        return AuditoriaEventoCubit(repositorio);
      },
      act: (c) => c.iniciar(),
      expect: () => [
        isA<AuditoriaEventoCargandoLista>(),
        isA<AuditoriaEventoError>(),
      ],
    );
  });

  // ── cargarMasEventos ───────────────────────────────────────────────────────

  group('AuditoriaEventoCubit.cargarMasEventos', () {
    test('no hace nada si hayMasEventos es false', () async {
      when(() => repositorio.obtenerEventos())
          .thenAnswer((_) async => (eventos: [_evento1], hayMas: false));
      final cubit = AuditoriaEventoCubit(repositorio);
      await cubit.iniciar();
      final estadoAntes = cubit.state;

      await cubit.cargarMasEventos();

      expect(cubit.todosEventos.length, 1);
      expect(cubit.state, estadoAntes);
      await cubit.close();
    });

    test('acumula eventos sin emitir nuevo estado cubit', () async {
      var llamadas = 0;
      when(() => repositorio.obtenerEventos(offset: any(named: 'offset')))
          .thenAnswer((_) async {
        llamadas++;
        return llamadas == 1
            ? (eventos: [_evento1, _evento2], hayMas: true)
            : (eventos: [_evento3], hayMas: false);
      });
      final cubit = AuditoriaEventoCubit(repositorio);
      await cubit.iniciar();
      expect(cubit.hayMasEventos, true);
      final estadoTrasIniciar = cubit.state;

      await cubit.cargarMasEventos();

      expect(cubit.todosEventos.length, 3);
      expect(cubit.hayMasEventos, false);
      // El estado cubit no cambia — la modal reactúa vía setState propio.
      expect(cubit.state, estadoTrasIniciar);
      await cubit.close();
    });

    test('no modifica todosEventos si el repositorio lanza excepción',
        () async {
      var llamadas = 0;
      when(() => repositorio.obtenerEventos(offset: any(named: 'offset')))
          .thenAnswer((_) async {
        llamadas++;
        if (llamadas == 1) return (eventos: [_evento1], hayMas: true);
        throw const FallaServidor('Fallo de red');
      });
      final cubit = AuditoriaEventoCubit(repositorio);
      await cubit.iniciar();

      await cubit.cargarMasEventos();

      expect(cubit.todosEventos.length, 1);
      // hayMasEventos sigue true para permitir reintentar.
      expect(cubit.hayMasEventos, true);
      await cubit.close();
    });
  });

  group('AuditoriaEventoCubit.seleccionarEvento', () {
    blocTest<AuditoriaEventoCubit, AuditoriaEventoEstado>(
      'emite [CargandoAuditoria, Cargada] con registros y resumen',
      build: () {
        when(() => repositorio.obtenerRegistros('ev-1')).thenAnswer(
          (_) async => [
            _reg('r1', 'presente'),
            _reg('r2', 'ausente'),
          ],
        );
        return AuditoriaEventoCubit(repositorio);
      },
      act: (c) => c.seleccionarEvento(_evento1),
      expect: () => [
        isA<AuditoriaEventoCargandoAuditoria>().having(
          (s) => s.eventoSeleccionado.id,
          'eventoId',
          'ev-1',
        ),
        isA<AuditoriaEventoCargada>().having(
          (s) => s.registros.length,
          'registros.length',
          2,
        ),
      ],
    );

    blocTest<AuditoriaEventoCubit, AuditoriaEventoEstado>(
      'Cargada tiene resumen con totalRegistros correcto',
      build: () {
        when(() => repositorio.obtenerRegistros(any())).thenAnswer(
          (_) async => [
            _reg('r1', 'presente'),
            _reg('r2', 'ausente'),
            _reg('r3', 'esperado'),
          ],
        );
        return AuditoriaEventoCubit(repositorio);
      },
      act: (c) => c.seleccionarEvento(_evento1),
      expect: () => [
        isA<AuditoriaEventoCargandoAuditoria>(),
        isA<AuditoriaEventoCargada>().having(
          (s) => s.resumen.totalRegistros,
          'totalRegistros',
          3,
        ),
      ],
    );

    blocTest<AuditoriaEventoCubit, AuditoriaEventoEstado>(
      'emite [CargandoAuditoria, Error] al recibir FallaServidor',
      build: () {
        when(() => repositorio.obtenerRegistros(any()))
            .thenThrow(const FallaServidor('Fallo DB.'));
        return AuditoriaEventoCubit(repositorio);
      },
      act: (c) => c.seleccionarEvento(_evento1),
      expect: () => [
        isA<AuditoriaEventoCargandoAuditoria>(),
        isA<AuditoriaEventoError>().having(
          (e) => e.mensaje,
          'mensaje',
          'Fallo DB.',
        ),
      ],
    );
  });

  group('AuditoriaEventoCubit.cambiarFiltro', () {
    blocTest<AuditoriaEventoCubit, AuditoriaEventoEstado>(
      'actualiza el filtro cuando el estado es Cargada',
      build: () {
        when(() => repositorio.obtenerRegistros(any()))
            .thenAnswer((_) async => [_reg('r1', 'ausente')]);
        return AuditoriaEventoCubit(repositorio);
      },
      act: (c) async {
        await c.seleccionarEvento(_evento1);
        c.cambiarFiltro(FiltroParticipantes.ausentes);
      },
      expect: () => [
        isA<AuditoriaEventoCargandoAuditoria>(),
        isA<AuditoriaEventoCargada>().having(
          (s) => s.filtro,
          'filtro',
          FiltroParticipantes.todos,
        ),
        isA<AuditoriaEventoCargada>().having(
          (s) => s.filtro,
          'filtro',
          FiltroParticipantes.ausentes,
        ),
      ],
    );

    blocTest<AuditoriaEventoCubit, AuditoriaEventoEstado>(
      'no emite nada cuando el estado no es Cargada',
      build: () => AuditoriaEventoCubit(repositorio),
      act: (c) => c.cambiarFiltro(FiltroParticipantes.foraneos),
      expect: () => [],
    );
  });

  group('AuditoriaEventoCubit.buscarParticipante', () {
    blocTest<AuditoriaEventoCubit, AuditoriaEventoEstado>(
      'actualiza busquedaParticipante cuando el estado es Cargada',
      build: () {
        when(() => repositorio.obtenerRegistros(any()))
            .thenAnswer((_) async => [_reg('r1', 'presente')]);
        return AuditoriaEventoCubit(repositorio);
      },
      act: (c) async {
        await c.seleccionarEvento(_evento1);
        c.buscarParticipante('Leo');
      },
      expect: () => [
        isA<AuditoriaEventoCargandoAuditoria>(),
        isA<AuditoriaEventoCargada>().having(
          (s) => s.busquedaParticipante,
          'busqueda',
          '',
        ),
        isA<AuditoriaEventoCargada>().having(
          (s) => s.busquedaParticipante,
          'busqueda',
          'Leo',
        ),
      ],
    );

    blocTest<AuditoriaEventoCubit, AuditoriaEventoEstado>(
      'no emite nada cuando el estado no es Cargada',
      build: () => AuditoriaEventoCubit(repositorio),
      act: (c) => c.buscarParticipante('Leo'),
      expect: () => [],
    );
  });

  group('AuditoriaEventoCargada.registrosFiltrados', () {
    final registros = [
      _reg('r1', 'presente'),
      _reg('r2', 'ausente'),
      _reg('r3', 'salio_anticipado'),
      const RegistroAuditoria(
        id: 'r4',
        nombre: 'Carlos Foraneo',
        iniciales: 'CF',
        estatus: 'esperado',
        esForaneo: true,
        horaEntrada: '',
        horaSalida: '',
      ),
    ];
    final resumen = ResumenAuditoria.calcular(registros);

    AuditoriaEventoCargada estado(FiltroParticipantes f, [String q = '']) =>
        AuditoriaEventoCargada(
          eventoSeleccionado: _evento1,
          registros: registros,
          resumen: resumen,
          filtro: f,
          busquedaParticipante: q,
        );

    test('todos devuelve todos los registros', () {
      expect(estado(FiltroParticipantes.todos).registrosFiltrados.length, 4);
    });

    test('entraron devuelve solo los que haEntrado', () {
      final r = estado(FiltroParticipantes.entraron).registrosFiltrados;
      expect(r.every((r) => r.haEntrado), isTrue);
      expect(r.length, 2); // presente + salio_anticipado
    });

    test('ausentes devuelve solo estatus ausente', () {
      final r = estado(FiltroParticipantes.ausentes).registrosFiltrados;
      expect(r.every((r) => r.estatus == 'ausente'), isTrue);
      expect(r.length, 1);
    });

    test('salioAnticipado devuelve solo salio_anticipado', () {
      final r = estado(FiltroParticipantes.salioAnticipado).registrosFiltrados;
      expect(r.every((r) => r.estatus == 'salio_anticipado'), isTrue);
      expect(r.length, 1);
    });

    test('foraneos devuelve solo esForaneo true', () {
      final r = estado(FiltroParticipantes.foraneos).registrosFiltrados;
      expect(r.every((r) => r.esForaneo), isTrue);
      expect(r.length, 1);
    });

    test('búsqueda por nombre filtra correctamente', () {
      final r = estado(FiltroParticipantes.todos, 'Carlos').registrosFiltrados;
      expect(r.length, 1);
      expect(r.first.nombre, 'Carlos Foraneo');
    });

    test('búsqueda vacía no filtra nada', () {
      expect(estado(FiltroParticipantes.todos, '   ').registrosFiltrados.length,
          4);
    });
  });
}
