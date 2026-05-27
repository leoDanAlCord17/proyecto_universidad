import 'package:flutter_bloc/flutter_bloc.dart';

import '../../compartido/constantes.dart';
import '../../compartido/errores.dart';
import 'autenticacion_repositorio.dart';
import 'registro_estado.dart';

class RegistroCubit extends Cubit<RegistroEstado> {

  RegistroCubit(this._repositorio) : super(RegistroInicial());
  final AutenticacionRepositorio _repositorio;

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
    final correoLimpio = correo.trim();
    if (correoLimpio.isEmpty || clave.isEmpty || confirmarClave.isEmpty) {
      emit(RegistroError('Por favor, llena todos los campos.'));
      return;
    }

    if (clave != confirmarClave) {
      emit(RegistroError('Las contraseñas no coinciden.'));
      return;
    }

    if (clave.length < 8) {
      emit(RegistroError('La contraseña debe tener al menos 8 caracteres.'));
      return;
    }

    if (!RegExp(r'\d').hasMatch(clave)) {
      emit(RegistroError('La contraseña debe incluir al menos un número.'));
      return;
    }

    emit(RegistroCargando());

    try {
      await _repositorio.registrarse(correoLimpio, clave);
      emit(RegistroExito());
    } on FallaAutenticacion catch (e) {
      emit(RegistroError(e.mensaje));
    } on FallaInesperada {
      emit(RegistroError(MensajesError.inesperado));
    }
  }
}
