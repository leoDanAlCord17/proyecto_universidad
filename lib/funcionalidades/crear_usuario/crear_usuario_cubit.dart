import 'dart:async' show unawaited;

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../compartido/constantes.dart';
import '../../compartido/errores.dart';
import '../../compartido/logger.dart';
import '../../compartido/notificaciones_push_servicio.dart';
import '../autenticacion/autenticacion_repositorio.dart';
import '../autenticacion/usuario.dart';
import 'crear_usuario_estado.dart';

class CrearUsuarioCubit extends Cubit<CrearUsuarioEstado> {
  CrearUsuarioCubit(this._repositorio) : super(const CrearUsuarioInicial());
  final AutenticacionRepositorio _repositorio;

  /// Retorna el correo de la sesión activa para pre-llenarlo en el formulario.
  String get correoSesion =>
      _repositorio.obtenerSesionActual()?.user.email ?? '';

  /// Retorna el auth_id de la sesión activa — usado como nombre de archivo
  /// estable para la foto de perfil, ya que el id de `usuarios` todavía no
  /// existe en este punto del flujo (se crea recién al guardar el perfil).
  String get authIdSesion => _repositorio.obtenerSesionActual()?.user.id ?? '';

  /// Guarda el perfil del usuario recién registrado en la tabla 'usuarios'.
  ///
  /// [numeroIdentificacion] es obligatorio — es el identificador con el que
  /// el usuario inicia sesión de aquí en adelante (ver LoginCubit.ingresar),
  /// así que sin él la cuenta quedaría sin forma de entrar.
  Future<void> guardarPerfil({
    required String primerNombre,
    required String primerApellido,
    required String numeroIdentificacion,
    String? segundoNombre,
    String? segundoApellido,
    String? telefono,
    String? urlAvatar,
  }) async {
    if (primerNombre.trim().isEmpty || primerApellido.trim().isEmpty) {
      emit(const CrearUsuarioError('El nombre y apellido son obligatorios.'));
      return;
    }
    if (numeroIdentificacion.trim().isEmpty) {
      emit(const CrearUsuarioError(
          'La cédula es obligatoria — la usarás para iniciar sesión.'));
      return;
    }
    final sesion = _repositorio.obtenerSesionActual();
    if (sesion == null) {
      emit(const CrearUsuarioError(
          'No hay sesión activa. Vuelve a registrarte.'));
      return;
    }
    emit(const CrearUsuarioCargando());
    try {
      final requiereRevision =
          await _repositorio.verificarRevisionCreacionHabilitada();
      await _repositorio.crearPerfilUsuario(
        _construirUsuario(
          sesion.user.id,
          sesion.user.email ?? '',
          requiereRevision,
          primerNombre,
          primerApellido,
          segundoNombre,
          segundoApellido,
          numeroIdentificacion,
          telefono,
          urlAvatar,
        ),
      );
      if (requiereRevision) {
        unawaited(_notificarRevisores());
      }
      emit(const CrearUsuarioExito());
    } on FallaServidor catch (e) {
      reportarError(e);
      emit(CrearUsuarioError(e.mensaje));
    } on FallaInesperada catch (e) {
      reportarError(e);
      emit(const CrearUsuarioError(MensajesError.inesperado));
    }
  }

  /// Avisa a todos los usuarios con permiso de revisión que hay una cuenta
  /// nueva esperando aprobación. Ni la búsqueda de destinatarios ni el envío
  /// lanzan excepción — un fallo aquí no debe afectar el registro, que ya
  /// se completó con éxito en este punto.
  Future<void> _notificarRevisores() async {
    final ids =
        await _repositorio.obtenerIdsConPermiso(Permisos.ajustesRevision);
    await NotificacionesPushServicio.enviar(
      usuarioIds: ids,
      titulo: 'Nuevo usuario pendiente',
      cuerpo: 'Hay una cuenta nueva esperando aprobación.',
      tipo: TiposNotificacion.aprobacion,
    );
  }

  Usuario _construirUsuario(
    String authId,
    String correo,
    bool requiereRevision,
    String primerNombre,
    String primerApellido,
    String? segundoNombre,
    String? segundoApellido,
    String numeroIdentificacion,
    String? telefono,
    String? urlAvatar,
  ) =>
      Usuario(
        authId: authId,
        correo: correo,
        primerNombre: primerNombre.trim(),
        segundoNombre: segundoNombre?.trim(),
        primerApellido: primerApellido.trim(),
        segundoApellido: segundoApellido?.trim(),
        numeroIdentificacion: numeroIdentificacion.trim(),
        telefono: telefono?.trim(),
        urlAvatar: urlAvatar,
        estatusAprobacion: requiereRevision
            ? EstatusAprobacion.pendiente
            : EstatusAprobacion.aprobado,
      );
}
