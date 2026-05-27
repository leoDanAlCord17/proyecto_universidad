import 'package:equatable/equatable.dart';

sealed class LoginEstado extends Equatable {}

final class LoginInicial extends LoginEstado {
  @override
  List<Object?> get props => [];
}

final class LoginCargando extends LoginEstado {
  @override
  List<Object?> get props => [];
}

final class LoginExito extends LoginEstado {
  @override
  List<Object?> get props => [];
}

final class LoginError extends LoginEstado {
  LoginError(this.mensaje);
  final String mensaje;

  @override
  List<Object?> get props => [mensaje];
}
