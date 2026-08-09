import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../compartido/errores.dart';
import '../autenticacion/autenticacion_repositorio.dart';
import 'recuperar_contrasena_estado.dart';

class RecuperarContrasenaCubit extends Cubit<RecuperarContrasenaEstado> {
  RecuperarContrasenaCubit(this._repositorio)
      : super(const RecuperarContrasenaInicial());

  final AutenticacionRepositorio _repositorio;

  /// Correo (censurado) que recibiría el enlace, mientras el usuario escribe
  /// su cédula — vive aparte del estado de envío para no tener que
  /// propagarlo a través de todos sus estados (Inicial/Enviando/Error).
  final correoPrevio = ValueNotifier<String?>(null);

  int _peticion = 0;

  /// Busca el correo censurado asociado a [cedula] para mostrarlo como
  /// vista previa. Se espera que la UI llame esto con debounce, no en cada
  /// tecla. Cualquier falla (red, cédula inexistente) simplemente deja de
  /// mostrar la vista previa — es un hint secundario, no crítico.
  Future<void> verificarCedula(String cedula) async {
    final cedulaLimpia = cedula.trim();
    final miPeticion = ++_peticion;
    if (cedulaLimpia.length < 6) {
      correoPrevio.value = null;
      return;
    }
    try {
      final correo = await _repositorio.obtenerCorreoEnmascarado(cedulaLimpia);
      if (miPeticion != _peticion) return; // ya hay una búsqueda más nueva
      correoPrevio.value = correo;
    } catch (_) {
      if (miPeticion != _peticion) return;
      correoPrevio.value = null;
    }
  }

  @override
  Future<void> close() {
    correoPrevio.dispose();
    return super.close();
  }

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
      emit(RecuperarContrasenaEnviado(correo: correoPrevio.value));
    } on FallaAutenticacion catch (e) {
      emit(RecuperarContrasenaError(mensaje: e.mensaje));
    } on FallaServidor catch (e) {
      emit(RecuperarContrasenaError(mensaje: e.mensaje));
    } on FallaInesperada catch (e) {
      emit(RecuperarContrasenaError(mensaje: e.mensaje));
    }
  }
}
