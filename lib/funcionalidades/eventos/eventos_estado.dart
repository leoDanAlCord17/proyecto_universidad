import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

import 'evento.dart';

sealed class EventosEstado extends Equatable {
  const EventosEstado();
}

final class EventosInicial extends EventosEstado {
  const EventosInicial();
  @override
  List<Object?> get props => [];
}

final class EventosCargando extends EventosEstado {
  const EventosCargando();
  @override
  List<Object?> get props => [];
}

final class EventosCargado extends EventosEstado {
  const EventosCargado({
    required this.enCurso,
    required this.proximos,
    this.textoBusqueda = '',
    this.rangoFechas,
  });

  final List<EventoConGrupos> enCurso;
  final List<EventoConGrupos> proximos;
  final String              textoBusqueda;
  final DateTimeRange?      rangoFechas;

  EventosCargado copiarCon({
    List<EventoConGrupos>? enCurso,
    List<EventoConGrupos>? proximos,
    String?              textoBusqueda,
    DateTimeRange?       rangoFechas,
    bool                 limpiarRango = false,
  }) =>
      EventosCargado(
        enCurso:       enCurso       ?? this.enCurso,
        proximos:      proximos      ?? this.proximos,
        textoBusqueda: textoBusqueda ?? this.textoBusqueda,
        rangoFechas:   limpiarRango ? null : (rangoFechas ?? this.rangoFechas),
      );

  @override
  List<Object?> get props => [enCurso, proximos, textoBusqueda, rangoFechas];
}

final class EventosError extends EventosEstado {
  const EventosError(this.mensaje);

  final String mensaje;

  @override
  List<Object?> get props => [mensaje];
}
