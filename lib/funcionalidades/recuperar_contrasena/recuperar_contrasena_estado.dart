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

final class RecuperarContrasenaEnviado extends RecuperarContrasenaEstado {
  const RecuperarContrasenaEnviado({required this.correo});
  final String correo;
  @override
  List<Object?> get props => [correo];
}

final class RecuperarContrasenaError extends RecuperarContrasenaEstado {
  const RecuperarContrasenaError({required this.mensaje});
  final String mensaje;
  @override
  List<Object?> get props => [mensaje];
}
