import 'package:equatable/equatable.dart';

import 'colaborador_item.dart';

sealed class ColaboradoresEventoEstado extends Equatable {
  const ColaboradoresEventoEstado();
}

final class ColaboradoresEventoInicial extends ColaboradoresEventoEstado {
  const ColaboradoresEventoInicial();
  @override
  List<Object?> get props => [];
}

final class ColaboradoresEventoCargando extends ColaboradoresEventoEstado {
  const ColaboradoresEventoCargando();
  @override
  List<Object?> get props => [];
}

// Sentinel para distinguir "no se pasó" de "se pasó null explícito".
const _kMantener = Object();

final class ColaboradoresEventoCargado extends ColaboradoresEventoEstado {
  const ColaboradoresEventoCargado({
    required this.colaboradores,
    required this.resultadosBusqueda,
    required this.busqueda,
    this.idOperando,
  });

  final List<ColaboradorItem> colaboradores;
  final List<UsuarioParaAsignar> resultadosBusqueda;
  final String busqueda;
  final String? idOperando;

  ColaboradoresEventoCargado copiarCon({
    List<ColaboradorItem>? colaboradores,
    List<UsuarioParaAsignar>? resultadosBusqueda,
    String? busqueda,
    Object? idOperando = _kMantener,
  }) =>
      ColaboradoresEventoCargado(
        colaboradores: colaboradores ?? this.colaboradores,
        resultadosBusqueda: resultadosBusqueda ?? this.resultadosBusqueda,
        busqueda: busqueda ?? this.busqueda,
        idOperando: identical(idOperando, _kMantener)
            ? this.idOperando
            : idOperando as String?,
      );

  @override
  List<Object?> get props =>
      [colaboradores, resultadosBusqueda, busqueda, idOperando];
}

final class ColaboradoresEventoOperacionFallida
    extends ColaboradoresEventoEstado {
  const ColaboradoresEventoOperacionFallida({
    required this.anterior,
    required this.mensaje,
  });

  final ColaboradoresEventoCargado anterior;
  final String mensaje;

  @override
  List<Object?> get props => [anterior, mensaje];
}

final class ColaboradoresEventoError extends ColaboradoresEventoEstado {
  const ColaboradoresEventoError({required this.mensaje});
  final String mensaje;
  @override
  List<Object?> get props => [mensaje];
}
