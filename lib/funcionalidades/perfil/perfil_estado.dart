import 'package:equatable/equatable.dart';

sealed class PerfilEstado extends Equatable {
  const PerfilEstado();
}

final class PerfilInicial extends PerfilEstado {
  const PerfilInicial();
  @override
  List<Object?> get props => [];
}

final class PerfilCargando extends PerfilEstado {
  const PerfilCargando();
  @override
  List<Object?> get props => [];
}

final class PerfilCargado extends PerfilEstado {
  const PerfilCargado({
    this.tagPrincipal,
    this.tagsSecundarios = const [],
  });

  final String?      tagPrincipal;
  final List<String> tagsSecundarios;

  @override
  List<Object?> get props => [tagPrincipal, tagsSecundarios];
}

final class PerfilError extends PerfilEstado {
  const PerfilError(this.mensaje);

  final String mensaje;

  @override
  List<Object?> get props => [mensaje];
}
