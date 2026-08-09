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

// [correo] es el mismo hint censurado que ya se mostró mientras el usuario
// escribía la cédula (ver RecuperarContrasenaCubit.correoPrevio) — repetirlo
// aquí no revela nada que la pantalla anterior no haya revelado ya. Queda
// en null si la cédula no existía (no había hint que mostrar), y en ese
// caso la pantalla de confirmación cae a un mensaje genérico.
final class RecuperarContrasenaEnviado extends RecuperarContrasenaEstado {
  const RecuperarContrasenaEnviado({this.correo});
  final String? correo;
  @override
  List<Object?> get props => [correo];
}

final class RecuperarContrasenaError extends RecuperarContrasenaEstado {
  const RecuperarContrasenaError({required this.mensaje});
  final String mensaje;
  @override
  List<Object?> get props => [mensaje];
}
