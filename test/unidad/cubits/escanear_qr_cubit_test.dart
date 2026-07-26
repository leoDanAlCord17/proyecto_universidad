import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:activiti/compartido/errores.dart';
import 'package:activiti/funcionalidades/escanear_qr/escanear_qr_cubit.dart';
import 'package:activiti/funcionalidades/escanear_qr/escanear_qr_estado.dart';
import 'package:activiti/funcionalidades/eventos/evento.dart';

import '../../helpers.dart';

Evento _eventoConQr(bool permiteQrEvento) => Evento(
      id: eventoEjemplo.id,
      titulo: eventoEjemplo.titulo,
      modoRegistro: eventoEjemplo.modoRegistro,
      estatus: eventoEjemplo.estatus,
      creadoEn: eventoEjemplo.creadoEn,
      actualizadoEn: eventoEjemplo.actualizadoEn,
      permiteQrEvento: permiteQrEvento,
      permiteQrUsuario: eventoEjemplo.permiteQrUsuario,
      permiteManualAdmin: eventoEjemplo.permiteManualAdmin,
      requiereCicloCompleto: eventoEjemplo.requiereCicloCompleto,
      permiteSalidaAnticipada: eventoEjemplo.permiteSalidaAnticipada,
      marcarAusentesAuto: eventoEjemplo.marcarAusentesAuto,
      permiteForaneos: eventoEjemplo.permiteForaneos,
    );

void main() {
  late MockEscanearQrRepositorio repositorio;

  // UUID válido para tests
  const uuidValido = '550e8400-e29b-41d4-a716-446655440000';

  setUp(() {
    repositorio = MockEscanearQrRepositorio();
  });

  EscanearQrCubit build() => EscanearQrCubit(repositorio);

  void stubIniciar({bool permiteQr = true, int presentes = 0}) {
    when(() => repositorio.obtenerEvento(any()))
        .thenAnswer((_) async => _eventoConQr(permiteQr));
    when(() => repositorio.contarPresentes(any()))
        .thenAnswer((_) async => presentes);
  }

  group('EscanearQrCubit.iniciar', () {
    test('estado inicial es EscanearQrInicial', () {
      expect(build().state, isA<EscanearQrInicial>());
    });

    blocTest<EscanearQrCubit, EscanearQrEstado>(
      'emite [Cargando, Listo] cuando el evento permite QR',
      build: build,
      setUp: () => stubIniciar(presentes: 3),
      act: (c) => c.iniciar('evento-1'),
      expect: () => [
        isA<EscanearQrCargando>(),
        isA<EscanearQrListo>().having((e) => e.presentes, 'presentes', 3),
      ],
    );

    blocTest<EscanearQrCubit, EscanearQrEstado>(
      'emite [Cargando, ErrorCarga] cuando el evento NO permite QR',
      build: build,
      setUp: () => stubIniciar(permiteQr: false),
      act: (c) => c.iniciar('evento-1'),
      expect: () => [
        isA<EscanearQrCargando>(),
        isA<EscanearQrErrorCarga>().having(
          (e) => e.mensaje,
          'mensaje',
          contains('no permite'),
        ),
      ],
    );

    blocTest<EscanearQrCubit, EscanearQrEstado>(
      'emite [Cargando, ErrorCarga] cuando FallaServidor en obtenerEvento',
      build: build,
      setUp: () {
        when(() => repositorio.obtenerEvento(any()))
            .thenThrow(const FallaServidor('Sin conexión'));
        when(() => repositorio.contarPresentes(any()))
            .thenAnswer((_) async => 0);
      },
      act: (c) => c.iniciar('evento-1'),
      expect: () => [
        isA<EscanearQrCargando>(),
        isA<EscanearQrErrorCarga>().having(
          (e) => e.mensaje,
          'mensaje',
          'Sin conexión',
        ),
      ],
    );
  });

  group('EscanearQrCubit.procesarQr', () {
    blocTest<EscanearQrCubit, EscanearQrEstado>(
      'emite [Procesando, Confirmado] cuando el usuario es nuevo',
      build: build,
      setUp: () {
        stubIniciar();
        when(() => repositorio.buscarUsuario(any())).thenAnswer(
          (_) async => {
            'primer_nombre': 'Leo',
            'primer_apellido': 'Alvarez',
            'numero_identificacion': '12345',
            'usuarios_roles': [],
          },
        );
        when(
          () => repositorio.registrarEntrada(
            eventoId: any(named: 'eventoId'),
            usuarioId: any(named: 'usuarioId'),
            registradoPorId: any(named: 'registradoPorId'),
          ),
        ).thenAnswer((_) async => true);
      },
      act: (c) async {
        await c.iniciar('evento-1');
        await c.procesarQr(uuidValido);
      },
      expect: () => [
        isA<EscanearQrCargando>(),
        isA<EscanearQrListo>(),
        isA<EscanearQrProcesando>(),
        isA<EscanearQrConfirmado>()
            .having((e) => e.nombre, 'nombre', 'Leo Alvarez')
            .having((e) => e.presentes, 'presentes', 1),
      ],
    );

    blocTest<EscanearQrCubit, EscanearQrEstado>(
      'emite [Procesando, YaRegistrado] cuando registrarEntrada retorna false',
      build: build,
      setUp: () {
        stubIniciar(presentes: 2);
        when(() => repositorio.buscarUsuario(any())).thenAnswer(
          (_) async => {
            'primer_nombre': 'Ana',
            'primer_apellido': 'Gomez',
            'numero_identificacion': null,
            'usuarios_roles': [],
          },
        );
        when(
          () => repositorio.registrarEntrada(
            eventoId: any(named: 'eventoId'),
            usuarioId: any(named: 'usuarioId'),
            registradoPorId: any(named: 'registradoPorId'),
          ),
        ).thenAnswer((_) async => false);
      },
      act: (c) async {
        await c.iniciar('evento-1');
        await c.procesarQr(uuidValido);
      },
      expect: () => [
        isA<EscanearQrCargando>(),
        isA<EscanearQrListo>(),
        isA<EscanearQrProcesando>(),
        isA<EscanearQrYaRegistrado>()
            .having((e) => e.nombre, 'nombre', 'Ana Gomez')
            .having((e) => e.presentes, 'presentes', 2),
      ],
    );

    blocTest<EscanearQrCubit, EscanearQrEstado>(
      'emite [Procesando, NoValido] cuando buscarUsuario retorna null',
      build: build,
      setUp: () {
        stubIniciar();
        when(() => repositorio.buscarUsuario(any()))
            .thenAnswer((_) async => null);
      },
      act: (c) async {
        await c.iniciar('evento-1');
        await c.procesarQr(uuidValido);
      },
      expect: () => [
        isA<EscanearQrCargando>(),
        isA<EscanearQrListo>(),
        isA<EscanearQrProcesando>(),
        isA<EscanearQrNoValido>(),
      ],
    );

    blocTest<EscanearQrCubit, EscanearQrEstado>(
      'no procesa si el estado no es Listo',
      build: build,
      act: (c) => c.procesarQr(uuidValido),
      expect: () => [],
    );

    blocTest<EscanearQrCubit, EscanearQrEstado>(
      'segunda llamada procesarQr es ignorada mientras está procesando',
      build: build,
      setUp: () {
        stubIniciar();
        when(() => repositorio.buscarUsuario(any()))
            .thenAnswer((_) async => null);
      },
      act: (c) async {
        await c.iniciar('evento-1');
        // Las dos llamadas se hacen sin await para que la segunda llegue
        // mientras la primera aún está procesando
        final f1 = c.procesarQr(uuidValido);
        final f2 = c.procesarQr(uuidValido);
        await Future.wait([f1, f2]);
      },
      verify: (_) {
        // buscarUsuario solo llamado una vez aunque procesarQr se llamó dos veces
        verify(() => repositorio.buscarUsuario(any())).called(1);
      },
    );
  });
}
