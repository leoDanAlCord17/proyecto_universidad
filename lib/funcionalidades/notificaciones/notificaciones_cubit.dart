import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../compartido/errores.dart';
import 'notificacion.dart';
import 'notificaciones_estado.dart';
import 'notificaciones_repositorio.dart';

class NotificacionesCubit extends Cubit<NotificacionesEstado> {
  NotificacionesCubit(this._repositorio) : super(NotificacionesInicial());

  final NotificacionesRepositorio _repositorio;

  StreamSubscription<int>? _subContador;
  String? _usuarioId;

  /// Inicia el stream del contador de no leídas (para el badge).
  /// Se llama una vez al autenticarse.
  void iniciarStream(String usuarioId) {
    if (_usuarioId == usuarioId) return;
    _usuarioId = usuarioId;

    _subContador?.cancel();
    _subContador = _repositorio
        .streamCantidadNoLeidas(usuarioId)
        .listen(
          (cantidad) {
            final anterior = state is NotificacionesCargadas
                ? (state as NotificacionesCargadas).notificaciones
                : <Notificacion>[];
            emit(NotificacionesCargadas(
              cantidad:       cantidad,
              notificaciones: anterior,
            ));
          },
          onError: (_) {},
        );
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
      emit(NotificacionesCargadas(
        cantidad:       cantidadActual,
        notificaciones: lista,
      ));
    } on FallaServidor catch (e) {
      emit(NotificacionesError(e.mensaje));
    } on FallaInesperada catch (e) {
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
    } catch (_) {
      // Si falla, el stream del contador corregirá el badge automáticamente
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
    } catch (_) {}
  }

  @override
  Future<void> close() {
    _subContador?.cancel();
    return super.close();
  }
}
