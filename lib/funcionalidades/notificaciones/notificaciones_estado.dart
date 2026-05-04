import 'package:equatable/equatable.dart';

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
  const NotificacionesCargadas({this.cantidad = 0});
  final int cantidad;

  @override
  List<Object?> get props => [cantidad];
}

final class NotificacionesError extends NotificacionesEstado {
  const NotificacionesError(this.mensaje);
  final String mensaje;

  @override
  List<Object?> get props => [mensaje];
}
