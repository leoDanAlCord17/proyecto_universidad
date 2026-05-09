import 'package:equatable/equatable.dart';

import 'notificacion.dart';

sealed class NotificacionesEstado extends Equatable {
  const NotificacionesEstado();
}

final class NotificacionesInicial extends NotificacionesEstado {
  @override
  List<Object?> get props => [];
}

final class NotificacionesCargando extends NotificacionesEstado {
  @override
  List<Object?> get props => [];
}

final class NotificacionesCargadas extends NotificacionesEstado {
  const NotificacionesCargadas({
    this.cantidad      = 0,
    this.notificaciones = const [],
  });

  final int                  cantidad;
  final List<Notificacion>   notificaciones;

  NotificacionesCargadas copyWith({
    int?                 cantidad,
    List<Notificacion>?  notificaciones,
  }) => NotificacionesCargadas(
    cantidad:       cantidad       ?? this.cantidad,
    notificaciones: notificaciones ?? this.notificaciones,
  );

  @override
  List<Object?> get props => [cantidad, notificaciones];
}

final class NotificacionesError extends NotificacionesEstado {
  const NotificacionesError(this.mensaje);
  final String mensaje;

  @override
  List<Object?> get props => [mensaje];
}
