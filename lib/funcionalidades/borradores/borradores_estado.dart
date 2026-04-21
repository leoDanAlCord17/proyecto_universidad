import 'package:equatable/equatable.dart';

import 'borrador_evento.dart';

sealed class BorradoresEstado extends Equatable {
  const BorradoresEstado();
}

final class BorradoresInicial extends BorradoresEstado {
  const BorradoresInicial();
  @override
  List<Object?> get props => [];
}

final class BorradoresCargando extends BorradoresEstado {
  const BorradoresCargando();
  @override
  List<Object?> get props => [];
}

final class BorradoresCargados extends BorradoresEstado {
  const BorradoresCargados({
    required this.borradores,
    required this.borradoresFiltrados,
    this.publicandoId,
    this.errorPublicacion,
  });

  final List<BorradorEvento> borradores;
  final List<BorradorEvento> borradoresFiltrados;
  final String?              publicandoId;
  final String?              errorPublicacion;

  BorradoresCargados copiarCon({
    List<BorradorEvento>? borradores,
    List<BorradorEvento>? borradoresFiltrados,
    String?               publicandoId,
    bool                  limpiarPublicando = false,
    String?               errorPublicacion,
    bool                  limpiarError      = false,
  }) =>
      BorradoresCargados(
        borradores:          borradores          ?? this.borradores,
        borradoresFiltrados: borradoresFiltrados ?? this.borradoresFiltrados,
        publicandoId:        limpiarPublicando ? null : (publicandoId ?? this.publicandoId),
        errorPublicacion:    limpiarError ? null : (errorPublicacion ?? this.errorPublicacion),
      );

  @override
  List<Object?> get props => [
        borradores,
        borradoresFiltrados,
        publicandoId,
        errorPublicacion,
      ];
}

final class BorradoresError extends BorradoresEstado {
  const BorradoresError(this.mensaje);

  final String mensaje;

  @override
  List<Object?> get props => [mensaje];
}
