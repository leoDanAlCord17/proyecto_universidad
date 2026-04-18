import 'package:equatable/equatable.dart';

sealed class CrearUsuarioEstado extends Equatable {}

final class CrearUsuarioInicial extends CrearUsuarioEstado {
  @override
  List<Object?> get props => [];
}

final class CrearUsuarioCargando extends CrearUsuarioEstado {
  @override
  List<Object?> get props => [];
}

final class CrearUsuarioExito extends CrearUsuarioEstado {
  @override
  List<Object?> get props => [];
}

final class CrearUsuarioError extends CrearUsuarioEstado {
  final String mensaje;
  CrearUsuarioError(this.mensaje);

  @override
  List<Object?> get props => [mensaje];
}
