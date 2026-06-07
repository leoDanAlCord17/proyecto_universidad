import 'package:flutter_bloc/flutter_bloc.dart';

import '../../compartido/constantes.dart';
import '../../compartido/errores.dart';
import '../../compartido/logger.dart';
import '../autenticacion/autenticacion_repositorio.dart';
import '../autenticacion/usuario.dart';
import 'crear_usuario_estado.dart';

class CrearUsuarioCubit extends Cubit<CrearUsuarioEstado> {

  CrearUsuarioCubit(this._repositorio) : super(const CrearUsuarioInicial());
  final AutenticacionRepositorio _repositorio;

  /// Retorna el correo de la sesión activa para pre-llenarlo en el formulario.
  String get correoSesion => _repositorio.obtenerSesionActual()?.user.email ?? '';

  /// Guarda el perfil del usuario recién registrado en la tabla 'usuarios'.
  Future<void> guardarPerfil({
    required String primerNombre,
    required String primerApellido,
    String? segundoNombre,
    String? segundoApellido,
    String? numeroIdentificacion,
    String? telefono,
  }) async {
    if (primerNombre.trim().isEmpty || primerApellido.trim().isEmpty) {
      emit(const CrearUsuarioError('El nombre y apellido son obligatorios.'));
      return;
    }
    final sesion = _repositorio.obtenerSesionActual();
    if (sesion == null) {
      emit(const CrearUsuarioError('No hay sesión activa. Vuelve a registrarte.'));
      return;
    }
    emit(const CrearUsuarioCargando());
    try {
      final requiereRevision =
          await _repositorio.verificarRevisionCreacionHabilitada();
      await _repositorio.crearPerfilUsuario(_construirUsuario(
        sesion.user.id, sesion.user.email ?? '', requiereRevision,
        primerNombre, primerApellido,
        segundoNombre, segundoApellido, numeroIdentificacion, telefono,
      ),);
      emit(const CrearUsuarioExito());
    } on FallaServidor catch (e) {
      reportarError(e);
      emit(CrearUsuarioError(e.mensaje));
    } on FallaInesperada catch (e) {
      reportarError(e);
      emit(const CrearUsuarioError(MensajesError.inesperado));
    }
  }

  Usuario _construirUsuario(
    String  authId,
    String  correo,
    bool    requiereRevision,
    String  primerNombre,
    String  primerApellido,
    String? segundoNombre,
    String? segundoApellido,
    String? numeroIdentificacion,
    String? telefono,
  ) =>
      Usuario(
        authId:               authId,
        correo:               correo,
        primerNombre:         primerNombre.trim(),
        segundoNombre:        segundoNombre?.trim(),
        primerApellido:       primerApellido.trim(),
        segundoApellido:      segundoApellido?.trim(),
        numeroIdentificacion: numeroIdentificacion?.trim(),
        telefono:             telefono?.trim(),
        estatusAprobacion:    requiereRevision
            ? EstatusAprobacion.pendiente
            : EstatusAprobacion.aprobado,
      );
}
