import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../compartido/constantes.dart';
import '../../compartido/errores.dart';
import '../../compartido/logger.dart';
import '../../compartido/notificaciones_push_servicio.dart';
import 'evento_en_curso.dart';
import 'eventos_en_curso_estado.dart';
import 'eventos_en_curso_repositorio.dart';

class EventosEnCursoCubit extends Cubit<EventosEnCursoEstado> {
  EventosEnCursoCubit(this._repositorio) : super(const EventosEnCursoInicial());

  final EventosEnCursoRepositorio _repositorio;
  final Map<String, StreamSubscription<List<Map<String, dynamic>>>> _subs = {};

  String? _usuarioId;
  Timer? _timer;
  StreamSubscription<MensajePushRecibido>? _subPush;

  // Esta pantalla (Inicio) vive en el IndexedStack de NavegacionPrincipal y
  // solo se construye una vez por sesión — sin refresco, un evento que pasa
  // a "en curso" mientras la app sigue abierta nunca aparecía hasta recargar
  // la app entera. El refresco principal ahora es reactivo: se dispara al
  // recibir el push que el propio ciclo_eventos() envía al iniciar el
  // evento (ver NotificacionesPushServicio.alRecibirPush). Este timer queda
  // solo como red de seguridad para el caso en que el push no llegue
  // (permiso denegado, token no registrado, red intermitente) — por eso el
  // intervalo es mucho más espaciado que antes (era cada 30s, un polling
  // constante e innecesario la mayor parte del tiempo).
  static const _intervaloRefresh = Duration(minutes: 5);

  Future<void> registrarForaneo({
    required String eventoId,
    required String primerNombre,
    required String primerApellido,
    required String cedula,
    String? contacto,
  }) =>
      _repositorio.registrarForaneo(
        eventoId: eventoId,
        primerNombre: primerNombre,
        primerApellido: primerApellido,
        cedula: cedula,
        contacto: contacto,
      );

  /// Carga los eventos en curso del usuario, activa un stream por cada uno
  /// y arranca el refresco periódico silencioso.
  Future<void> cargar(String usuarioId) async {
    _usuarioId = usuarioId;
    emit(const EventosEnCursoCargando());
    try {
      final eventos = await _repositorio.obtenerEventosEnCurso(usuarioId);
      if (isClosed) return;
      emit(EventosEnCursoCargado(eventos: eventos));
      for (final e in eventos) {
        _suscribir(e.id);
      }
      _timer?.cancel();
      _timer = Timer.periodic(
        _intervaloRefresh,
        (_) => _refrescarSilencioso(usuarioId),
      );

      await _subPush?.cancel();
      _subPush = NotificacionesPushServicio.alRecibirPush.listen(
        (_) => _refrescarSilencioso(usuarioId),
      );
    } on FallaServidor catch (f) {
      reportarError(f);
      if (!isClosed) emit(EventosEnCursoError(f.mensaje));
    } on FallaInesperada catch (f) {
      reportarError(f);
      if (!isClosed) emit(EventosEnCursoError(f.mensaje));
    }
  }

  /// Fuerza un refresco inmediato — se llama cuando la app vuelve a primer
  /// plano, para no esperar hasta el próximo tick del timer.
  Future<void> refrescarAlReanudar() async {
    final usuarioId = _usuarioId;
    if (usuarioId == null) return;
    await _refrescarSilencioso(usuarioId);
  }

  /// Igual que [cargar] pero sin pasar por el estado "Cargando" (evita el
  /// parpadeo del spinner cada 30s) y preservando los contadores en vivo de
  /// los eventos que ya estaban en la lista — [obtenerEventosEnCurso] no
  /// trae asistencia, así que sobreescribir sin fusionar los resetearía a
  /// cero hasta el próximo evento del stream de asistencia.
  Future<void> _refrescarSilencioso(String usuarioId) async {
    try {
      final frescos = await _repositorio.obtenerEventosEnCurso(usuarioId);
      if (isClosed) return;

      final anteriores = {
        for (final e in _extraerEventos(state)) e.id: e,
      };
      final eventos = frescos.map((fresco) {
        final anterior = anteriores[fresco.id];
        return anterior == null
            ? fresco
            : fresco.copyWith(
                totalPresentes: anterior.totalPresentes,
                totalRegistrados: anterior.totalRegistrados,
              );
      }).toList();

      // Cancela las suscripciones de eventos que ya no están en curso
      // (ej. el mismo job los cerró por llegar a su hora de fin).
      final idsNuevos = eventos.map((e) => e.id).toSet();
      final idsObsoletos =
          _subs.keys.where((id) => !idsNuevos.contains(id)).toList();
      for (final id in idsObsoletos) {
        await _subs.remove(id)?.cancel();
      }

      emit(EventosEnCursoCargado(eventos: eventos));
      for (final e in eventos) {
        if (!_subs.containsKey(e.id)) _suscribir(e.id);
      }
    } catch (_) {
      // Silencioso: la próxima pasada del timer (o el próximo resumen de
      // la app) reintenta — no tiene sentido interrumpir al usuario por
      // un refresco de fondo que falló.
    }
  }

  List<EventoEnCurso> _extraerEventos(EventosEnCursoEstado estado) =>
      estado is EventosEnCursoCargado ? estado.eventos : const [];

  // Sentry muestra RealtimeSubscribeException (WebSocket cerrado/caído) con
  // cierta frecuencia en esta pantalla — el cliente de Supabase reintenta la
  // conexión del socket por su cuenta, pero sin `onError` acá, si el
  // listener de este stream específico quedaba en mal estado tras el error,
  // el contador de asistentes en vivo dejaba de actualizarse en silencio
  // hasta recargar la app entera. Reintentar la suscripción desde cero tras
  // un respiro es la red de seguridad.
  void _suscribir(String eventoId) {
    _subs[eventoId]?.cancel();
    _subs[eventoId] = _repositorio.streamAsistencia(eventoId).listen(
      (rows) => _actualizarContador(eventoId, rows),
      onError: (Object error, StackTrace stackTrace) {
        reportarError(error, stack: stackTrace);
        Future.delayed(const Duration(seconds: 5), () {
          if (isClosed) return;
          final sigueEnCurso =
              _extraerEventos(state).any((e) => e.id == eventoId);
          if (sigueEnCurso) _suscribir(eventoId);
        });
      },
    );
  }

  void _actualizarContador(
    String eventoId,
    List<Map<String, dynamic>> rows,
  ) {
    final estado = state;
    if (estado is! EventosEnCursoCargado) return;
    final indice = estado.eventos.indexWhere((e) => e.id == eventoId);
    if (indice == -1) return;
    final presentes = rows.where((r) {
      final s = r['estatus'] as String? ?? '';
      return s == EstatusAsistencia.presente ||
          s == EstatusAsistencia.completado;
    }).length;
    final esGeneral = estado.eventos[indice].esGeneral;
    final total = esGeneral
        ? 0
        : rows.where((r) => r['estatus'] != EstatusAsistencia.anulado).length;
    final actualizados = estado.eventos.map((e) {
      if (e.id != eventoId) return e;
      return e.copyWith(totalPresentes: presentes, totalRegistrados: total);
    }).toList();
    emit(EventosEnCursoCargado(eventos: actualizados));
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    _subPush?.cancel();
    for (final sub in _subs.values) {
      sub.cancel();
    }
    _subs.clear();
    return super.close();
  }
}
