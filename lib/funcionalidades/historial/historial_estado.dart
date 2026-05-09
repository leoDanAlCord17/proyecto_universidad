import 'package:equatable/equatable.dart';

import 'historial_item.dart';

sealed class HistorialEstado extends Equatable {
  const HistorialEstado();
}

final class HistorialInicial extends HistorialEstado {
  const HistorialInicial();
  @override
  List<Object?> get props => [];
}

final class HistorialCargando extends HistorialEstado {
  const HistorialCargando();
  @override
  List<Object?> get props => [];
}

final class HistorialCargado extends HistorialEstado {
  const HistorialCargado({required this.items});

  final List<HistorialItem> items;

  @override
  List<Object?> get props => [items];
}

final class HistorialError extends HistorialEstado {
  const HistorialError(this.mensaje);

  final String mensaje;

  @override
  List<Object?> get props => [mensaje];
}
