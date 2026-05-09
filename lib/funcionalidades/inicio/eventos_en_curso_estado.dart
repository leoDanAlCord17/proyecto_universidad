import 'package:equatable/equatable.dart';

import 'evento_en_curso.dart';

sealed class EventosEnCursoEstado extends Equatable {
  const EventosEnCursoEstado();
}

final class EventosEnCursoInicial extends EventosEnCursoEstado {
  const EventosEnCursoInicial();
  @override
  List<Object?> get props => [];
}

final class EventosEnCursoCargando extends EventosEnCursoEstado {
  const EventosEnCursoCargando();
  @override
  List<Object?> get props => [];
}

final class EventosEnCursoCargado extends EventosEnCursoEstado {
  const EventosEnCursoCargado({required this.eventos});

  final List<EventoEnCurso> eventos;

  @override
  List<Object?> get props => [eventos];
}

final class EventosEnCursoError extends EventosEnCursoEstado {
  const EventosEnCursoError(this.mensaje);

  final String mensaje;

  @override
  List<Object?> get props => [mensaje];
}
