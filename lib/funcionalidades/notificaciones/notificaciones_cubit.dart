import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../compartido/errores.dart';
import '../../compartido/logger.dart';
import '../../compartido/notificaciones_push_servicio.dart';
import 'notificacion.dart';
import 'notificaciones_estado.dart';
import 'notificaciones_repositorio.dart';

class NotificacionesCubit extends Cubit<NotificacionesEstado> {
  NotificacionesCubit(this._repositorio) : super(NotificacionesInicial());

  final NotificacionesRepositorio _repositorio;

  StreamSubscription<int>? _subContador;
  StreamSubscription<MensajePushRecibido>? _subPush;
  String? _usuarioId;

  /// Inicia el stream del contador de no leídas (para el badge) y la
  /// escucha de push en primer plano para refrescar la lista si la pantalla
  /// de notificaciones ya está abierta. Se llama una vez al autenticarse.
  void iniciarStream(String usuarioId) {
    if (_usuarioId == usuarioId) return;
    _usuarioId = usuarioId;

    _subContador?.cancel();
    _subContador = _repositorio.streamCantidadNoLeidas(usuarioId).listen(
      (cantidad) {
        final anterior = state is NotificacionesCargadas
            ? (state as NotificacionesCargadas).notificaciones
            : <Notificacion>[];
        emit(
          NotificacionesCargadas(
            cantidad: cantidad,
            notificaciones: anterior,
          ),
        );
      },
      onError: (_) =>
          emit(const NotificacionesCargadas(cantidad: 0, notificaciones: [])),
    );

    _subPush?.cancel();
    _subPush = NotificacionesPushServicio.alRecibirPush.listen(
      (_) => _refrescarSilencioso(),
    );
  }

  /// Refresca la lista completa cuando llega un push en primer plano — sin
  /// esto, si el usuario ya tenía la pantalla de notificaciones abierta, la
  /// notificación recién insertada en el servidor (y ya visible como push
  /// del sistema) no aparecía en la lista hasta salir y volver a entrar. El
  /// contador (badge) ya se actualizaba solo porque viene de un stream en
  /// tiempo real; esto extiende lo mismo a la lista completa.
  ///
  /// Si la lista nunca se cargó en esta sesión (pantalla no abierta), no
  /// hace nada — cargarLista() la traerá completa cuando se abra.
  Future<void> _refrescarSilencioso() async {
    final usuarioId = _usuarioId;
    if (usuarioId == null) return;
    if (state is! NotificacionesCargadas) return;
    try {
      final lista = await _repositorio.obtenerTodas(usuarioId);
      if (isClosed) return;
      final cantidadActual = (state as NotificacionesCargadas).cantidad;
      emit(
        NotificacionesCargadas(cantidad: cantidadActual, notificaciones: lista),
      );
    } catch (e) {
      log.w('No se pudo refrescar la lista de notificaciones', error: e);
    }
  }

  /// Carga la lista completa de notificaciones (al abrir la pantalla).
  Future<void> cargarLista() async {
    if (_usuarioId == null) return;

    final cantidadActual = state is NotificacionesCargadas
        ? (state as NotificacionesCargadas).cantidad
        : 0;

    emit(NotificacionesCargando());
    try {
      final lista = await _repositorio.obtenerTodas(_usuarioId!);
      emit(
        NotificacionesCargadas(
          cantidad: cantidadActual,
          notificaciones: lista,
        ),
      );
    } on FallaServidor catch (e) {
      reportarError(e);
      emit(NotificacionesError(e.mensaje));
    } on FallaInesperada catch (e) {
      reportarError(e);
      emit(NotificacionesError(e.mensaje));
    }
  }

  /// Marca una notificación individual como leída.
  Future<void> marcarLeida(String notificacionId) async {
    if (state is! NotificacionesCargadas) return;
    final actual = state as NotificacionesCargadas;

    // Actualiza la UI de forma optimista
    final nuevaLista = actual.notificaciones
        .map((n) => n.id == notificacionId ? n.comoLeida() : n)
        .toList();
    emit(actual.copyWith(notificaciones: nuevaLista));

    try {
      await _repositorio.marcarLeida(notificacionId);
    } catch (e) {
      // Si falla, el stream del contador corregirá el badge automáticamente
      log.w('No se pudo marcar notificación como leída', error: e);
    }
  }

  /// Marca todas como leídas de una vez.
  Future<void> marcarTodasLeidas() async {
    if (_usuarioId == null) return;
    if (state is! NotificacionesCargadas) return;
    final actual = state as NotificacionesCargadas;

    final nuevaLista = actual.notificaciones.map((n) => n.comoLeida()).toList();
    emit(actual.copyWith(notificaciones: nuevaLista));

    try {
      await _repositorio.marcarTodasLeidas(_usuarioId!);
    } catch (e) {
      log.w(
        'No se pudo marcar todas las notificaciones como leídas',
        error: e,
      );
    }
  }

  /// true si el usuario tiene al menos un token push registrado. Ante
  /// cualquier error asume que sí — es preferible no mostrar el banner de
  /// activación a insistir por un fallo transitorio de red.
  Future<bool> tieneTokenRegistrado(String usuarioId) async {
    try {
      return await _repositorio.tieneTokenRegistrado(usuarioId);
    } catch (e) {
      log.w('No se pudo verificar el token de notificaciones', error: e);
      return true;
    }
  }

  @override
  Future<void> close() {
    _subContador?.cancel();
    _subPush?.cancel();
    return super.close();
  }
}
