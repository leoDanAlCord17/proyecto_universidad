import 'package:equatable/equatable.dart';

import 'usuario.dart';

sealed class AuthEstado extends Equatable {}

final class AuthInicial extends AuthEstado {
  @override
  List<Object?> get props => [];
}

final class Autenticado extends AuthEstado {
  final Usuario usuario;
  Autenticado(this.usuario);

  @override
  List<Object?> get props => [usuario];
}

final class NoAutenticado extends AuthEstado {
  @override
  List<Object?> get props => [];
}

// El usuario existe en Auth pero aún no completó su perfil en la tabla usuarios.
// El router lo redirige a /completar_perfil para que termine el registro.
final class PerfilIncompleto extends AuthEstado {
  @override
  List<Object?> get props => [];
}

// Supabase detectó una sesión de recuperación de contraseña (enlace del correo).
// El router redirige a /nueva_contrasena para que el usuario establezca la nueva clave.
final class RecuperandoContrasena extends AuthEstado {
  @override
  List<Object?> get props => [];
}

// Otro dispositivo inició sesión con la misma cuenta y desplazó esta sesión.
// El router redirige a /login y se muestra un SnackBar informativo.
final class SesionDesplazada extends AuthEstado {
  @override
  List<Object?> get props => [];
}
