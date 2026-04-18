import 'package:flutter_bloc/flutter_bloc.dart';

import '../../compartido/constantes.dart';
import '../../compartido/errores.dart';
import 'autenticacion_repositorio.dart';
import 'login_estado.dart';

class LoginCubit extends Cubit<LoginEstado> {
  final AutenticacionRepositorio _repositorio;

  LoginCubit(this._repositorio) : super(LoginInicial());

  /// Inicia sesión con correo y contraseña.
  /// Emite [LoginExito] si las credenciales son válidas.
  /// Emite [LoginError] si los campos están vacíos o las credenciales fallan.
  Future<void> ingresar(String correo, String clave) async {
    final correoLimpio = correo.trim();

    if (correoLimpio.isEmpty || clave.isEmpty) {
      emit(LoginError('Por favor, llena todos los campos.'));
      return;
    }

    emit(LoginCargando());

    try {
      await _repositorio.iniciarSesion(correoLimpio, clave);
      emit(LoginExito());
    } on FallaAutenticacion catch (e) {
      emit(LoginError(e.mensaje));
    } on FallaInesperada {
      emit(LoginError(MensajesError.inesperado));
    }
  }
}
