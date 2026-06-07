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

/// Página cargada correctamente. [hayMas] indica si existen más registros.
final class HistorialCargado extends HistorialEstado {
  const HistorialCargado({required this.items, required this.hayMas});

  final List<HistorialItem> items;
  final bool hayMas;

  @override
  List<Object?> get props => [items, hayMas];
}

/// La lista ya muestra resultados y se está cargando la siguiente página.
/// [items] contiene los registros ya cargados para no perder la vista actual.
final class HistorialCargandoMas extends HistorialEstado {
  const HistorialCargandoMas({required this.items});

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
