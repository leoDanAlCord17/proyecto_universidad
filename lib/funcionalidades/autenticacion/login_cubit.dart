import 'package:flutter_bloc/flutter_bloc.dart';

import '../../compartido/constantes.dart';
import '../../compartido/errores.dart';
import '../../compartido/logger.dart';
import 'autenticacion_repositorio.dart';
import 'login_estado.dart';

class LoginCubit extends Cubit<LoginEstado> {

  LoginCubit(this._repositorio) : super(LoginInicial());
  final AutenticacionRepositorio _repositorio;

  static final _regexEmail = RegExp(r'^[\w.+\-]+@[\w\-]+\.[a-zA-Z]{2,}$');

  Future<void> ingresar(String correo, String clave) async {
    final correoLimpio = correo.trim();

    if (correoLimpio.isEmpty || clave.isEmpty) {
      emit(LoginError('Por favor, llena todos los campos.'));
      return;
    }

    if (!_regexEmail.hasMatch(correoLimpio)) {
      emit(LoginError('Ingresa un correo con formato válido.'));
      return;
    }

    emit(LoginCargando());

    try {
      await _repositorio.iniciarSesion(correoLimpio, clave);
      emit(LoginExito());
    } on FallaAutenticacion catch (e) {
      emit(LoginError(e.mensaje));
    } on FallaRed catch (e) {
      reportarError(e);
      emit(LoginError(e.mensaje));
    } on FallaInesperada catch (e) {
      reportarError(e);
      emit(LoginError(MensajesError.inesperado));
    }
  }
}
