import 'package:equatable/equatable.dart';

import 'tipo_evento_item.dart';

sealed class TiposEventoEstado extends Equatable {
  const TiposEventoEstado();
}

final class TiposEventoInicial extends TiposEventoEstado {
  const TiposEventoInicial();
  @override
  List<Object?> get props => [];
}

final class TiposEventoCargando extends TiposEventoEstado {
  const TiposEventoCargando();
  @override
  List<Object?> get props => [];
}

final class TiposEventoCargados extends TiposEventoEstado {
  const TiposEventoCargados({
    required this.items,
    required this.filtrados,
    this.estaDesactivando = false,
    this.errorOperacion,
  });

  final List<TipoEventoItem> items;
  final List<TipoEventoItem> filtrados;
  final bool estaDesactivando;
  final String? errorOperacion;

  TiposEventoCargados copiarCon({
    List<TipoEventoItem>? filtrados,
    bool? estaDesactivando,
  }) =>
      TiposEventoCargados(
        items: items,
        filtrados: filtrados ?? this.filtrados,
        estaDesactivando: estaDesactivando ?? this.estaDesactivando,
      );

  @override
  List<Object?> get props =>
      [items, filtrados, estaDesactivando, errorOperacion];
}

final class TiposEventoError extends TiposEventoEstado {
  const TiposEventoError({required this.mensaje});

  final String mensaje;

  @override
  List<Object?> get props => [mensaje];
}
