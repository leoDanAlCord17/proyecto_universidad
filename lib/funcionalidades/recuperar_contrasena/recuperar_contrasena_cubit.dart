import 'package:flutter_bloc/flutter_bloc.dart';

import '../../compartido/errores.dart';
import '../autenticacion/autenticacion_repositorio.dart';
import 'recuperar_contrasena_estado.dart';

class RecuperarContrasenaCubit extends Cubit<RecuperarContrasenaEstado> {
  RecuperarContrasenaCubit(this._repositorio)
      : super(const RecuperarContrasenaInicial());

  final AutenticacionRepositorio _repositorio;

  /// [cedula] es el número de identificación, no el correo — igual que en
  /// el login, se resuelve internamente al correo real registrado.
  Future<void> enviar(String cedula) async {
    final cedulaLimpia = cedula.trim();
    if (cedulaLimpia.isEmpty) {
      emit(const RecuperarContrasenaError(mensaje: 'Ingresa tu cédula.'));
      return;
    }
    emit(const RecuperarContrasenaEnviando());
    try {
      await _repositorio.enviarCorreoRecuperacion(cedulaLimpia);
      emit(const RecuperarContrasenaEnviado());
    } on FallaAutenticacion catch (e) {
      emit(RecuperarContrasenaError(mensaje: e.mensaje));
    } on FallaServidor catch (e) {
      emit(RecuperarContrasenaError(mensaje: e.mensaje));
    } on FallaInesperada catch (e) {
      emit(RecuperarContrasenaError(mensaje: e.mensaje));
    }
  }
}
