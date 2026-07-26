import 'package:flutter_bloc/flutter_bloc.dart';

import '../../compartido/errores.dart';
import '../../compartido/validadores.dart';
import '../autenticacion/autenticacion_repositorio.dart';
import 'recuperar_contrasena_estado.dart';

class RecuperarContrasenaCubit extends Cubit<RecuperarContrasenaEstado> {
  RecuperarContrasenaCubit(this._repositorio)
      : super(const RecuperarContrasenaInicial());

  final AutenticacionRepositorio _repositorio;

  Future<void> enviar(String correo) async {
    final correoLimpio = correo.trim();
    if (correoLimpio.isEmpty) {
      emit(const RecuperarContrasenaError(
          mensaje: 'Ingresa tu correo institucional.'));
      return;
    }
    if (!Validadores.esCorreoValido(correoLimpio)) {
      emit(
          const RecuperarContrasenaError(mensaje: 'Ingresa un correo válido.'));
      return;
    }
    emit(const RecuperarContrasenaEnviando());
    try {
      await _repositorio.enviarCorreoRecuperacion(correoLimpio);
      emit(RecuperarContrasenaEnviado(correo: correoLimpio));
    } on FallaAutenticacion catch (e) {
      emit(RecuperarContrasenaError(mensaje: e.mensaje));
    } on FallaInesperada catch (e) {
      emit(RecuperarContrasenaError(mensaje: e.mensaje));
    }
  }
}
