import 'package:equatable/equatable.dart';

sealed class RegistroEstado extends Equatable {}

final class RegistroInicial extends RegistroEstado {
  @override
  List<Object?> get props => [];
}

final class RegistroCargando extends RegistroEstado {
  @override
  List<Object?> get props => [];
}

final class RegistroExito extends RegistroEstado {
  @override
  List<Object?> get props => [];
}

final class RegistroError extends RegistroEstado {
  final String mensaje;
  RegistroError(this.mensaje);

  @override
  List<Object?> get props => [mensaje];
}
