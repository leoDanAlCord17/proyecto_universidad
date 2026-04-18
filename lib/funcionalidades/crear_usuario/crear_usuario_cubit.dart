import 'package:flutter_bloc/flutter_bloc.dart';

import '../../compartido/constantes.dart';
import '../../compartido/errores.dart';
import '../autenticacion/autenticacion_repositorio.dart';
import '../autenticacion/usuario.dart';
import 'crear_usuario_estado.dart';

class CrearUsuarioCubit extends Cubit<CrearUsuarioEstado> {
  final AutenticacionRepositorio _repositorio;

  CrearUsuarioCubit(this._repositorio) : super(CrearUsuarioInicial());

  /// Retorna el correo de la sesión activa para pre-llenarlo en el formulario.
  String get correoSesion => _repositorio.obtenerSesionActual()?.user.email ?? '';

  /// Guarda el perfil del usuario recién registrado en la tabla 'usuarios'.
  ///
  /// Obtiene el [auth_id] y el [correo] de la sesión activa de Supabase,
  /// construye el [Usuario] con los datos del formulario y llama al repositorio.
  /// Lanza [FallaServidor] si hay un error al insertar en la base de datos.
  Future<void> guardarPerfil({
    required String primerNombre,
    required String primerApellido,
    String? segundoNombre,
    String? segundoApellido,
    String? numeroIdentificacion,
    String? telefono,
  }) async {
    if (primerNombre.trim().isEmpty || primerApellido.trim().isEmpty) {
      emit(CrearUsuarioError('El nombre y apellido son obligatorios.'));
      return;
    }

    // La sesión existe porque el usuario acaba de hacer signUp
    final sesion = _repositorio.obtenerSesionActual();

    if (sesion == null) {
      emit(CrearUsuarioError('No hay sesión activa. Vuelve a registrarte.'));
      return;
    }

    emit(CrearUsuarioCargando());

    try {
      final usuario = Usuario(
        authId: sesion.user.id,
        correo: sesion.user.email ?? '',
        primerNombre: primerNombre.trim(),
        segundoNombre: segundoNombre?.trim(),
        primerApellido: primerApellido.trim(),
        segundoApellido: segundoApellido?.trim(),
        numeroIdentificacion: numeroIdentificacion?.trim(),
        telefono: telefono?.trim(),
      );

      await _repositorio.crearPerfilUsuario(usuario);
      emit(CrearUsuarioExito());
    } on FallaServidor catch (e) {
      emit(CrearUsuarioError(e.mensaje));
    } on FallaInesperada {
      emit(CrearUsuarioError(MensajesError.inesperado));
    }
  }
}
