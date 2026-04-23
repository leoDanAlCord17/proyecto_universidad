import 'package:equatable/equatable.dart';

sealed class NuevaContrasenaEstado extends Equatable {
  const NuevaContrasenaEstado();
}

final class NuevaContrasenaInicial extends NuevaContrasenaEstado {
  const NuevaContrasenaInicial();
  @override
  List<Object?> get props => [];
}

final class NuevaContrasenaGuardando extends NuevaContrasenaEstado {
  const NuevaContrasenaGuardando();
  @override
  List<Object?> get props => [];
}

final class NuevaContrasenaGuardada extends NuevaContrasenaEstado {
  const NuevaContrasenaGuardada();
  @override
  List<Object?> get props => [];
}

final class NuevaContrasenaError extends NuevaContrasenaEstado {
  const NuevaContrasenaError({required this.mensaje});
  final String mensaje;
  @override
  List<Object?> get props => [mensaje];
}
