import 'package:flutter_bloc/flutter_bloc.dart';

import '../../compartido/errores.dart';
import '../autenticacion/autenticacion_repositorio.dart';
import 'nueva_contrasena_estado.dart';

class NuevaContrasenaCubit extends Cubit<NuevaContrasenaEstado> {
  NuevaContrasenaCubit(this._repositorio)
      : super(const NuevaContrasenaInicial());

  final AutenticacionRepositorio _repositorio;

  Future<void> cambiar({
    required String nuevaClave,
    required String confirmacion,
  }) async {
    if (nuevaClave.length < 6) {
      emit(const NuevaContrasenaError(
          mensaje: 'La contraseña debe tener al menos 6 caracteres.'));
      return;
    }
    if (nuevaClave != confirmacion) {
      emit(
          const NuevaContrasenaError(mensaje: 'Las contraseñas no coinciden.'));
      return;
    }
    emit(const NuevaContrasenaGuardando());
    try {
      await _repositorio.actualizarContrasena(nuevaClave);
      emit(const NuevaContrasenaGuardada());
    } on FallaAutenticacion catch (e) {
      emit(NuevaContrasenaError(mensaje: e.mensaje));
    } on FallaInesperada catch (e) {
      emit(NuevaContrasenaError(mensaje: e.mensaje));
    }
  }
}
