import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:activiti/funcionalidades/inicio/eventos_en_curso_cubit.dart';
import 'package:activiti/funcionalidades/inicio/eventos_en_curso_estado.dart';
import 'package:activiti/funcionalidades/inicio/evento_en_curso.dart';

import '../../helpers.dart';

const _eventoEjemplo = EventoEnCurso(
  id: 'evento-1',
  titulo: 'Charla de Flutter',
  permiteQrEvento: true,
  permiteQrUsuario: true,
  permiteForaneos: false,
  modoRegistro: 'auto',
  alcance: 'general',
  totalPresentes: 0,
  totalRegistrados: 0,
);

void main() {
  late MockEventosEnCursoRepositorio repositorio;

  setUp(() {
    repositorio = MockEventosEnCursoRepositorio();
  });

  group('EventosEnCursoCubit.cargar', () {
    test(
        'emite [Cargando, Cargado] y se suscribe a la asistencia de cada evento',
        () {
      fakeAsync((async) {
        when(() => repositorio.obtenerEventosEnCurso('u-1'))
            .thenAnswer((_) async => [_eventoEjemplo]);
        when(() => repositorio.streamAsistencia('evento-1'))
            .thenAnswer((_) => const Stream.empty());

        final cubit = EventosEnCursoCubit(repositorio);
        final estados = <EventosEnCursoEstado>[];
        cubit.stream.listen(estados.add);

        cubit.cargar('u-1');
        async.flushMicrotasks();

        expect(estados, [
          isA<EventosEnCursoCargando>(),
          isA<EventosEnCursoCargado>()
              .having((e) => e.eventos.length, 'eventos.length', 1),
        ]);
        verify(() => repositorio.streamAsistencia('evento-1')).called(1);

        cubit.close();
      });
    });
  });

  group('EventosEnCursoCubit — resiliencia del stream de asistencia', () {
    // Sentry reportó RealtimeSubscribeException (WebSocket caído/cerrado)
    // repetidas veces en esta pantalla — sin manejo de error, el contador de
    // asistentes en vivo dejaba de actualizarse en silencio hasta recargar
    // la app entera. Cada llamada a streamAsistencia devuelve un Stream
    // nuevo (como haría el cliente real de Supabase), en vez de reutilizar
    // un StreamController de una sola suscripción entre reintentos.
    test(
        'vuelve a suscribirse 5s después de un error, si el evento sigue en curso',
        () {
      fakeAsync((async) {
        when(() => repositorio.obtenerEventosEnCurso('u-1'))
            .thenAnswer((_) async => [_eventoEjemplo]);
        var llamadas = 0;
        when(() => repositorio.streamAsistencia('evento-1')).thenAnswer((_) {
          llamadas++;
          return llamadas == 1
              ? Stream<List<Map<String, dynamic>>>.error(
                  Exception('WebSocket cerrado'))
              : const Stream.empty();
        });

        final cubit = EventosEnCursoCubit(repositorio);
        cubit.cargar('u-1');
        async.flushMicrotasks();
        expect(llamadas, 1); // suscripción inicial, ya recibió el error

        async.elapse(const Duration(seconds: 4));
        async.flushMicrotasks();
        expect(llamadas, 1); // el reintento espera 5s, todavía no ocurre

        async.elapse(const Duration(seconds: 1));
        async.flushMicrotasks();
        expect(llamadas, 2); // se volvió a suscribir desde cero

        cubit.close();
      });
    });

    // Nota: la reconexión también verifica que el evento siga en la lista
    // actual antes de resuscribirse (ver el `if (sigueEnCurso)` en
    // _suscribir) — no se agregó un test aislado para ese caso puntual
    // porque requiere hacer coincidir el reintento de 5s con el refresco
    // periódico de 5 min dentro de la misma zona fakeAsync, y no logré un
    // montaje confiable para eso sin acoplar el test a detalles internos de
    // implementación.
  });
}
