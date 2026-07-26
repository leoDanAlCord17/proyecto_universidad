import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:activiti/compartido/errores.dart';
import 'package:activiti/funcionalidades/notificaciones/notificacion.dart';
import 'package:activiti/funcionalidades/notificaciones/notificaciones_cubit.dart';
import 'package:activiti/funcionalidades/notificaciones/notificaciones_estado.dart';

import '../../helpers.dart';

// ─── Fixtures ────────────────────────────────────────────────────────────────

Notificacion _notificacion(String id, {bool leida = false}) => Notificacion(
      id: id,
      titulo: 'Titulo $id',
      cuerpo: 'Cuerpo $id',
      tipo: 'evento',
      leida: leida,
      creadoEn: DateTime(2024, 5, 10, 10),
    );

void main() {
  late MockNotificacionesRepositorio repositorio;

  setUp(() {
    registrarFallbacks();
    repositorio = MockNotificacionesRepositorio();
  });

  group('NotificacionesCubit — estado inicial', () {
    test('estado inicial es NotificacionesInicial', () {
      final cubit = NotificacionesCubit(repositorio);
      expect(cubit.state, isA<NotificacionesInicial>());
      cubit.close();
    });
  });

  group('NotificacionesCubit.iniciarStream', () {
    blocTest<NotificacionesCubit, NotificacionesEstado>(
      'emite NotificacionesCargadas con la cantidad del stream',
      build: () {
        when(() => repositorio.streamCantidadNoLeidas('u1'))
            .thenAnswer((_) => Stream.fromIterable([3]));
        return NotificacionesCubit(repositorio);
      },
      act: (c) => c.iniciarStream('u1'),
      expect: () => [
        isA<NotificacionesCargadas>().having(
          (s) => s.cantidad,
          'cantidad',
          3,
        ),
      ],
    );

    blocTest<NotificacionesCubit, NotificacionesEstado>(
      'emite múltiples estados cuando el stream emite varios valores',
      build: () {
        when(() => repositorio.streamCantidadNoLeidas('u1'))
            .thenAnswer((_) => Stream.fromIterable([2, 1, 0]));
        return NotificacionesCubit(repositorio);
      },
      act: (c) => c.iniciarStream('u1'),
      expect: () => [
        isA<NotificacionesCargadas>().having((s) => s.cantidad, 'cantidad', 2),
        isA<NotificacionesCargadas>().having((s) => s.cantidad, 'cantidad', 1),
        isA<NotificacionesCargadas>().having((s) => s.cantidad, 'cantidad', 0),
      ],
    );

    blocTest<NotificacionesCubit, NotificacionesEstado>(
      'emite cantidad 0 cuando el stream falla',
      build: () {
        when(() => repositorio.streamCantidadNoLeidas('u1'))
            .thenAnswer((_) => Stream.error(Exception('fallo')));
        return NotificacionesCubit(repositorio);
      },
      act: (c) => c.iniciarStream('u1'),
      expect: () => [
        isA<NotificacionesCargadas>().having((s) => s.cantidad, 'cantidad', 0),
      ],
    );

    blocTest<NotificacionesCubit, NotificacionesEstado>(
      'no llama al repositorio si se llama dos veces con el mismo usuarioId',
      build: () {
        when(() => repositorio.streamCantidadNoLeidas('u1'))
            .thenAnswer((_) => const Stream.empty());
        return NotificacionesCubit(repositorio);
      },
      act: (c) async {
        c.iniciarStream('u1');
        c.iniciarStream('u1');
      },
      verify: (_) {
        verify(() => repositorio.streamCantidadNoLeidas('u1')).called(1);
      },
    );

    blocTest<NotificacionesCubit, NotificacionesEstado>(
      'preserva la lista de notificaciones existente al actualizar el badge',
      build: () {
        when(() => repositorio.streamCantidadNoLeidas('u1'))
            .thenAnswer((_) => Stream.fromIterable([5]));
        return NotificacionesCubit(repositorio);
      },
      seed: () => NotificacionesCargadas(
        cantidad: 2,
        notificaciones: [_notificacion('n1')],
      ),
      act: (c) => c.iniciarStream('u1'),
      expect: () => [
        isA<NotificacionesCargadas>()
            .having((s) => s.cantidad, 'cantidad', 5)
            .having((s) => s.notificaciones.length, 'lista.length', 1),
      ],
    );
  });

  group('NotificacionesCubit.cargarLista', () {
    blocTest<NotificacionesCubit, NotificacionesEstado>(
      'no hace nada si usuarioId es null',
      build: () => NotificacionesCubit(repositorio),
      act: (c) => c.cargarLista(),
      expect: () => [],
    );

    blocTest<NotificacionesCubit, NotificacionesEstado>(
      'emite [Cargando, Cargadas] con la lista del repositorio',
      build: () {
        // Stream vacío: solo establece _usuarioId, no emite estados
        when(() => repositorio.streamCantidadNoLeidas('u1'))
            .thenAnswer((_) => const Stream.empty());
        when(() => repositorio.obtenerTodas('u1')).thenAnswer(
            (_) async => [_notificacion('n1'), _notificacion('n2')]);
        return NotificacionesCubit(repositorio);
      },
      act: (c) async {
        c.iniciarStream('u1');
        await c.cargarLista();
      },
      expect: () => [
        isA<NotificacionesCargando>(),
        isA<NotificacionesCargadas>().having(
          (s) => s.notificaciones.length,
          'lista.length',
          2,
        ),
      ],
    );

    blocTest<NotificacionesCubit, NotificacionesEstado>(
      'preserva la cantidad del badge al cargar la lista',
      build: () {
        // Stream vacío para no interferir con el timing de cargarLista
        when(() => repositorio.streamCantidadNoLeidas('u1'))
            .thenAnswer((_) => const Stream.empty());
        when(() => repositorio.obtenerTodas('u1'))
            .thenAnswer((_) async => [_notificacion('n1')]);
        return NotificacionesCubit(repositorio);
      },
      // Seed con cantidad=4 para que cargarLista lo preserve
      seed: () => const NotificacionesCargadas(cantidad: 4, notificaciones: []),
      act: (c) async {
        c.iniciarStream('u1');
        await c.cargarLista();
      },
      expect: () => [
        isA<NotificacionesCargando>(),
        isA<NotificacionesCargadas>()
            .having((s) => s.cantidad, 'cantidad', 4)
            .having((s) => s.notificaciones.length, 'lista.length', 1),
      ],
    );

    blocTest<NotificacionesCubit, NotificacionesEstado>(
      'emite [Cargando, NotificacionesError] al recibir FallaServidor',
      build: () {
        when(() => repositorio.streamCantidadNoLeidas('u1'))
            .thenAnswer((_) => const Stream.empty());
        when(() => repositorio.obtenerTodas('u1'))
            .thenThrow(const FallaServidor('Error en servidor.'));
        return NotificacionesCubit(repositorio);
      },
      act: (c) async {
        c.iniciarStream('u1');
        await c.cargarLista();
      },
      expect: () => [
        isA<NotificacionesCargando>(),
        isA<NotificacionesError>().having(
          (e) => e.mensaje,
          'mensaje',
          'Error en servidor.',
        ),
      ],
    );
  });

  group('NotificacionesCubit.marcarLeida', () {
    blocTest<NotificacionesCubit, NotificacionesEstado>(
      'actualiza la notificación de forma optimista',
      build: () {
        when(() => repositorio.marcarLeida('n1')).thenAnswer((_) async {});
        return NotificacionesCubit(repositorio);
      },
      seed: () => NotificacionesCargadas(
        cantidad: 1,
        notificaciones: [_notificacion('n1', leida: false)],
      ),
      act: (c) => c.marcarLeida('n1'),
      expect: () => [
        isA<NotificacionesCargadas>().having(
          (s) => s.notificaciones.first.leida,
          'leida',
          true,
        ),
      ],
    );

    blocTest<NotificacionesCubit, NotificacionesEstado>(
      'no emite nada si el estado no es Cargadas',
      build: () => NotificacionesCubit(repositorio),
      act: (c) => c.marcarLeida('n1'),
      expect: () => [],
    );

    blocTest<NotificacionesCubit, NotificacionesEstado>(
      'llama al repositorio exactamente una vez',
      build: () {
        when(() => repositorio.marcarLeida('n1')).thenAnswer((_) async {});
        return NotificacionesCubit(repositorio);
      },
      seed: () => NotificacionesCargadas(
        cantidad: 1,
        notificaciones: [_notificacion('n1', leida: false)],
      ),
      act: (c) => c.marcarLeida('n1'),
      verify: (_) {
        verify(() => repositorio.marcarLeida('n1')).called(1);
      },
    );

    blocTest<NotificacionesCubit, NotificacionesEstado>(
      'no revierte la UI si el repositorio falla (el stream corregirá el badge)',
      build: () {
        when(() => repositorio.marcarLeida('n1')).thenThrow(Exception('fallo'));
        return NotificacionesCubit(repositorio);
      },
      seed: () => NotificacionesCargadas(
        cantidad: 1,
        notificaciones: [_notificacion('n1', leida: false)],
      ),
      act: (c) => c.marcarLeida('n1'),
      errors: () => [],
    );
  });

  group('NotificacionesCubit.marcarTodasLeidas', () {
    blocTest<NotificacionesCubit, NotificacionesEstado>(
      'marca todas las notificaciones como leídas en la UI de forma optimista',
      build: () {
        // Stub en build para que iniciarStream no falle al suscribirse
        when(() => repositorio.streamCantidadNoLeidas('u1'))
            .thenAnswer((_) => const Stream.empty());
        when(() => repositorio.marcarTodasLeidas('u1'))
            .thenAnswer((_) async {});
        return NotificacionesCubit(repositorio);
      },
      seed: () => NotificacionesCargadas(
        cantidad: 3,
        notificaciones: [
          _notificacion('n1', leida: false),
          _notificacion('n2', leida: false),
          _notificacion('n3', leida: true),
        ],
      ),
      act: (c) async {
        c.iniciarStream('u1');
        await c.marcarTodasLeidas();
      },
      expect: () => [
        isA<NotificacionesCargadas>().having(
          (s) => s.notificaciones.every((n) => n.leida),
          'todas leídas',
          isTrue,
        ),
      ],
    );

    blocTest<NotificacionesCubit, NotificacionesEstado>(
      'no hace nada si usuarioId es null',
      build: () => NotificacionesCubit(repositorio),
      act: (c) => c.marcarTodasLeidas(),
      expect: () => [],
    );

    blocTest<NotificacionesCubit, NotificacionesEstado>(
      'no emite si el estado no es Cargadas (stream recién iniciado, sin lista)',
      build: () {
        when(() => repositorio.streamCantidadNoLeidas('u1'))
            .thenAnswer((_) => const Stream.empty());
        return NotificacionesCubit(repositorio);
      },
      act: (c) async {
        c.iniciarStream('u1');
        await c.marcarTodasLeidas();
      },
      expect: () => [],
    );
  });
}
