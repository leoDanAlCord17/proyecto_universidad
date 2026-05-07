import 'package:equatable/equatable.dart';

sealed class CrearUsuarioEstado extends Equatable {
  const CrearUsuarioEstado();
}

final class CrearUsuarioInicial extends CrearUsuarioEstado {
  const CrearUsuarioInicial();
  @override
  List<Object?> get props => [];
}

final class CrearUsuarioCargando extends CrearUsuarioEstado {
  const CrearUsuarioCargando();
  @override
  List<Object?> get props => [];
}

final class CrearUsuarioExito extends CrearUsuarioEstado {
  const CrearUsuarioExito();
  @override
  List<Object?> get props => [];
}

final class CrearUsuarioError extends CrearUsuarioEstado {
  const CrearUsuarioError(this.mensaje);

  final String mensaje;

  @override
  List<Object?> get props => [mensaje];
}
