import 'dart:async';
import 'dart:math';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../compartido/constantes.dart';
import '../../compartido/errores.dart';
import '../../compartido/logger.dart';
import 'auth_estado.dart';
import 'autenticacion_repositorio.dart';
import 'usuario.dart';

class AuthCubit extends Cubit<AuthEstado> {
  AuthCubit(this._repositorio) : super(AuthInicial()) {
    _suscripcionRecuperacion = _repositorio
        .flujoRecuperacionContrasena()
        .listen((_) => emit(RecuperandoContrasena()));
  }

  final AutenticacionRepositorio _repositorio;
  late final StreamSubscription<bool> _suscripcionRecuperacion;
  StreamSubscription<String?>? _suscripcionSesion;
  String? _tokenSesionActual;

  @override
  Future<void> close() {
    _suscripcionRecuperacion.cancel();
    _suscripcionSesion?.cancel();
    return super.close();
  }

  /// Revisa si hay sesión activa al arrancar. Aplica timeout de [kTimeoutSolicitud]
  /// para evitar que el splash quede congelado si Supabase no responde.
  Future<void> verificarSesion() async {
    final sesion = _repositorio.obtenerSesionActual();

    if (sesion == null) {
      emit(NoAutenticado());
      return;
    }

    try {
      final usuario = await _repositorio
          .obtenerPerfil(sesion.user.id)
          .timeout(kTimeoutSolicitud);

      if (usuario == null) {
        emit(PerfilIncompleto());
      } else if (usuario.estatusAprobacion == EstatusAprobacion.pendiente) {
        emit(PendienteAprobacion());
      } else if (usuario.estatusAprobacion == EstatusAprobacion.rechazado) {
        emit(UsuarioRechazado());
      } else {
        emit(Autenticado(usuario));
        await _iniciarControlSesionUnica(usuario.id);
      }
    } on TimeoutException {
      log.w('verificarSesion: timeout — redirigiendo a login');
      emit(NoAutenticado());
    } on FallaServidor catch (e) {
      reportarError(e);
      emit(NoAutenticado());
    } on FallaInesperada catch (e) {
      reportarError(e);
      emit(NoAutenticado());
    }
  }

  void reiniciarParaReintento() => emit(PerfilIncompleto());

  void actualizarUsuario(Usuario usuario) => emit(Autenticado(usuario));

  Future<void> cerrarSesion() async {
    await _repositorio.cerrarSesion();
    emit(NoAutenticado());
  }

  Future<void> _iniciarControlSesionUnica(String? usuarioId) async {
    if (usuarioId == null) return;
    try {
      final nuevoToken = _generarToken();
      _tokenSesionActual = nuevoToken;
      await _repositorio.actualizarTokenSesion(usuarioId, nuevoToken);
      await _suscripcionSesion?.cancel();
      _suscripcionSesion =
          _repositorio.flujoTokenSesion(usuarioId).listen(_procesarCambioToken);
    } on FallaServidor catch (e) {
      // El fallo en el token no bloquea la sesión principal, pero sí debe
      // quedar visible: es la señal de fallos en el control de sesión única.
      reportarError(e);
    } on FallaInesperada catch (e) {
      reportarError(e);
    }
  }

  // Async para awaitar cerrarSesion() antes de emitir SesionDesplazada.
  // Sin await, verificarSesion() podría releer la sesión aún abierta.
  Future<void> _procesarCambioToken(String? tokenRemoto) async {
    if (tokenRemoto == null || tokenRemoto == _tokenSesionActual) return;
    await _suscripcionSesion?.cancel();
    await _repositorio.cerrarSesion();
    emit(SesionDesplazada());
  }

  static String _generarToken() {
    final r = Random.secure();
    return List.generate(
      32,
      (_) => r.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ).join();
  }
}
