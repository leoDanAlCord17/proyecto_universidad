import 'package:equatable/equatable.dart';

sealed class InicioEstado extends Equatable {
  const InicioEstado();
}

final class InicioInicial extends InicioEstado {
  const InicioInicial();
  @override
  List<Object?> get props => [];
}

final class InicioTagsCargando extends InicioEstado {
  const InicioTagsCargando();
  @override
  List<Object?> get props => [];
}

final class InicioTagsCargados extends InicioEstado {
  const InicioTagsCargados({
    this.tagPrincipal,
    this.tagsSecundarios = const [],
  });

  final String?       tagPrincipal;
  final List<String>  tagsSecundarios;

  @override
  List<Object?> get props => [tagPrincipal, tagsSecundarios];
}

final class InicioError extends InicioEstado {
  const InicioError(this.mensaje);

  final String mensaje;

  @override
  List<Object?> get props => [mensaje];
}
