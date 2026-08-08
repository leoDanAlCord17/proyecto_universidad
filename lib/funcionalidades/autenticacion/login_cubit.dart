import 'package:flutter_bloc/flutter_bloc.dart';

import '../../compartido/constantes.dart';
import '../../compartido/errores.dart';
import '../../compartido/logger.dart';
import 'autenticacion_repositorio.dart';
import 'login_estado.dart';

class LoginCubit extends Cubit<LoginEstado> {
  LoginCubit(this._repositorio) : super(LoginInicial());
  final AutenticacionRepositorio _repositorio;

  /// [cedula] es el número de identificación (DNI/Cédula/Pasaporte) del
  /// usuario, no su correo — AutenticacionRepositorio.iniciarSesion lo
  /// resuelve internamente al correo real registrado en Supabase Auth.
  Future<void> ingresar(String cedula, String clave) async {
    final cedulaLimpia = cedula.trim();

    if (cedulaLimpia.isEmpty || clave.isEmpty) {
      emit(LoginError('Por favor, llena todos los campos.'));
      return;
    }

    emit(LoginCargando());

    try {
      await _repositorio.iniciarSesion(cedulaLimpia, clave);
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
