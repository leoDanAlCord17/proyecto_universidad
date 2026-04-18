import 'package:flutter_bloc/flutter_bloc.dart';

import '../../compartido/constantes.dart';
import '../../compartido/errores.dart';
import 'autenticacion_repositorio.dart';
import 'registro_estado.dart';

class RegistroCubit extends Cubit<RegistroEstado> {
  final AutenticacionRepositorio _repositorio;

  RegistroCubit(this._repositorio) : super(RegistroInicial());

  /// Crea un nuevo usuario en Supabase Auth con correo y contraseña.
  ///
  /// Valida campos, coincidencia de contraseñas y longitud mínima antes
  /// de llamar al repositorio.
  /// Emite [RegistroExito] si el usuario fue creado correctamente.
  /// Emite [RegistroError] si hay un error de validación o de autenticación.
  Future<void> registrarse(
    String correo,
    String clave,
    String confirmarClave,
  ) async {
    if (correo.isEmpty || clave.isEmpty || confirmarClave.isEmpty) {
      emit(RegistroError('Por favor, llena todos los campos.'));
      return;
    }

    if (clave != confirmarClave) {
      emit(RegistroError('Las contraseñas no coinciden.'));
      return;
    }

    if (clave.length < 6) {
      emit(RegistroError('La contraseña debe tener al menos 6 caracteres.'));
      return;
    }

    emit(RegistroCargando());

    try {
      await _repositorio.registrarse(correo, clave);
      emit(RegistroExito());
    } on FallaAutenticacion catch (e) {
      emit(RegistroError(e.mensaje));
    } on FallaInesperada {
      emit(RegistroError(MensajesError.inesperado));
    }
  }
}
