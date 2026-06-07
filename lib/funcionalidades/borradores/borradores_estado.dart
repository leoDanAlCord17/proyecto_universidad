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
    required this.hayMas,
    this.publicandoId,
    this.errorPublicacion,
  });

  final List<BorradorEvento> borradores;
  final List<BorradorEvento> borradoresFiltrados;
  final bool hayMas;
  final String? publicandoId;
  final String? errorPublicacion;

  BorradoresCargados copiarCon({
    List<BorradorEvento>? borradores,
    List<BorradorEvento>? borradoresFiltrados,
    bool? hayMas,
    String? publicandoId,
    bool limpiarPublicando = false,
    String? errorPublicacion,
    bool limpiarError = false,
  }) =>
      BorradoresCargados(
        borradores: borradores ?? this.borradores,
        borradoresFiltrados: borradoresFiltrados ?? this.borradoresFiltrados,
        hayMas: hayMas ?? this.hayMas,
        publicandoId:
            limpiarPublicando ? null : (publicandoId ?? this.publicandoId),
        errorPublicacion:
            limpiarError ? null : (errorPublicacion ?? this.errorPublicacion),
      );

  @override
  List<Object?> get props => [
        borradores,
        borradoresFiltrados,
        hayMas,
        publicandoId,
        errorPublicacion,
      ];
}

/// La lista ya muestra resultados y se está cargando la siguiente página.
final class BorradoresCargandoMas extends BorradoresEstado {
  const BorradoresCargandoMas({
    required this.borradores,
    required this.borradoresFiltrados,
  });

  final List<BorradorEvento> borradores;
  final List<BorradorEvento> borradoresFiltrados;

  @override
  List<Object?> get props => [borradores, borradoresFiltrados];
}

final class BorradoresError extends BorradoresEstado {
  const BorradoresError(this.mensaje);

  final String mensaje;

  @override
  List<Object?> get props => [mensaje];
}
