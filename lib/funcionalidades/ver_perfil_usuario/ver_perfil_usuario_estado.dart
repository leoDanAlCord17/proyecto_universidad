import 'package:equatable/equatable.dart';

import 'perfil_completo_usuario.dart';

sealed class VerPerfilUsuarioEstado extends Equatable {
  const VerPerfilUsuarioEstado();
}

final class VerPerfilUsuarioInicial extends VerPerfilUsuarioEstado {
  const VerPerfilUsuarioInicial();
  @override List<Object?> get props => [];
}

final class VerPerfilUsuarioCargando extends VerPerfilUsuarioEstado {
  const VerPerfilUsuarioCargando();
  @override List<Object?> get props => [];
}

final class VerPerfilUsuarioCargado extends VerPerfilUsuarioEstado {
  const VerPerfilUsuarioCargado({required this.perfil});
  final PerfilCompletoUsuario perfil;
  @override List<Object?> get props => [perfil];
}

final class VerPerfilUsuarioError extends VerPerfilUsuarioEstado {
  const VerPerfilUsuarioError({required this.mensaje});
  final String mensaje;
  @override List<Object?> get props => [mensaje];
}
