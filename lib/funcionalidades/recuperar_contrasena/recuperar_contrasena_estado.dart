import 'package:equatable/equatable.dart';

sealed class RecuperarContrasenaEstado extends Equatable {
  const RecuperarContrasenaEstado();
}

final class RecuperarContrasenaInicial extends RecuperarContrasenaEstado {
  const RecuperarContrasenaInicial();
  @override
  List<Object?> get props => [];
}

final class RecuperarContrasenaEnviando extends RecuperarContrasenaEstado {
  const RecuperarContrasenaEnviando();
  @override
  List<Object?> get props => [];
}

// No lleva el correo/cédula como dato — por seguridad no revelamos si la
// cédula ingresada estaba registrada o no, así que la confirmación es
// siempre el mismo mensaje genérico, sin importar el resultado real.
final class RecuperarContrasenaEnviado extends RecuperarContrasenaEstado {
  const RecuperarContrasenaEnviado();
  @override
  List<Object?> get props => [];
}

final class RecuperarContrasenaError extends RecuperarContrasenaEstado {
  const RecuperarContrasenaError({required this.mensaje});
  final String mensaje;
  @override
  List<Object?> get props => [mensaje];
}
