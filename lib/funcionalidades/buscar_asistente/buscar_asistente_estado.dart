import 'package:equatable/equatable.dart';

import '../eventos/evento.dart';
import 'resultado_busqueda.dart';

sealed class BuscarAsistenteEstado extends Equatable {
  const BuscarAsistenteEstado();
}

final class BuscarAsistenteInicial extends BuscarAsistenteEstado {
  const BuscarAsistenteInicial();
  @override List<Object?> get props => [];
}

final class BuscarAsistenteCargando extends BuscarAsistenteEstado {
  const BuscarAsistenteCargando();
  @override List<Object?> get props => [];
}

// Sentinel que distingue "no se pasó el argumento" de "se pasó null explícitamente".
const _kMantener = Object();

final class BuscarAsistenteCargado extends BuscarAsistenteEstado {
  const BuscarAsistenteCargado({
    required this.evento,
    required this.resultados,
    required this.busqueda,
    required this.cantidadPresentes,
    required this.cantidadTotal,
    this.estaRegistrando     = false,
    this.estaMarcandoSalida  = false,
    this.usuarioIdRegistrando,
  });

  final Evento                  evento;
  final List<ResultadoBusqueda> resultados;
  final String                  busqueda;
  final int                     cantidadPresentes;
  final int                     cantidadTotal;
  final bool                    estaRegistrando;
  final bool                    estaMarcandoSalida;

  /// ID del usuario cuyo botón "Registrar entrada" está en curso.
  /// null = ninguna operación de entrada activa.
  final String?                 usuarioIdRegistrando;

  BuscarAsistenteCargado copiarCon({
    List<ResultadoBusqueda>? resultados,
    String?                  busqueda,
    int?                     cantidadPresentes,
    int?                     cantidadTotal,
    bool?                    estaRegistrando,
    bool?                    estaMarcandoSalida,
    Object?                  usuarioIdRegistrando = _kMantener,
  }) =>
      BuscarAsistenteCargado(
        evento:               evento,
        resultados:           resultados         ?? this.resultados,
        busqueda:             busqueda           ?? this.busqueda,
        cantidadPresentes:    cantidadPresentes  ?? this.cantidadPresentes,
        cantidadTotal:        cantidadTotal      ?? this.cantidadTotal,
        estaRegistrando:      estaRegistrando    ?? this.estaRegistrando,
        estaMarcandoSalida:   estaMarcandoSalida ?? this.estaMarcandoSalida,
        usuarioIdRegistrando: identical(usuarioIdRegistrando, _kMantener)
            ? this.usuarioIdRegistrando
            : usuarioIdRegistrando as String?,
      );

  @override
  List<Object?> get props => [
    evento, resultados, busqueda, cantidadPresentes, cantidadTotal,
    estaRegistrando, estaMarcandoSalida, usuarioIdRegistrando,
  ];
}

final class BuscarAsistenteOperacionFallida extends BuscarAsistenteEstado {
  const BuscarAsistenteOperacionFallida({
    required this.anterior,
    required this.mensaje,
  });

  final BuscarAsistenteCargado anterior;
  final String                 mensaje;

  @override List<Object?> get props => [anterior, mensaje];
}

final class BuscarAsistenteError extends BuscarAsistenteEstado {
  const BuscarAsistenteError({required this.mensaje});
  final String mensaje;
  @override List<Object?> get props => [mensaje];
}
