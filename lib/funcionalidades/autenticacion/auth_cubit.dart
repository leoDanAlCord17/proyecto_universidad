import 'dart:async';
import 'dart:math';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../compartido/constantes.dart';
import '../../compartido/errores.dart';
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

  /// Revisa si hay una sesión activa al abrir la app.
  /// Si hay sesión y perfil completo → emite [Autenticado].
  /// Si hay sesión pero sin perfil → emite [PerfilIncompleto].
  /// Si no hay sesión o hay un error real de DB → emite [NoAutenticado].
  Future<void> verificarSesion() async {
    final sesion = _repositorio.obtenerSesionActual();

    if (sesion == null) {
      emit(NoAutenticado());
      return;
    }

    try {
      final usuario = await _repositorio.obtenerPerfil(sesion.user.id);
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
    } on FallaServidor {
      emit(NoAutenticado());
    } on FallaInesperada {
      emit(NoAutenticado());
    }
  }

  /// Permite a un usuario rechazado volver a la pantalla de completar perfil.
  void reiniciarParaReintento() => emit(PerfilIncompleto());

  /// Actualiza el estado con el usuario autenticado.
  void actualizarUsuario(Usuario usuario) {
    emit(Autenticado(usuario));
  }

  /// Cierra la sesión del usuario y emite [NoAutenticado].
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
      _suscripcionSesion = _repositorio
          .flujoTokenSesion(usuarioId)
          .listen(_procesarCambioToken);
    } on FallaServidor catch (_) {
      // El fallo en el token no bloquea la sesión
    } on FallaInesperada catch (_) {
      // El fallo en el token no bloquea la sesión
    }
  }

  void _procesarCambioToken(String? tokenRemoto) {
    if (tokenRemoto == null || tokenRemoto == _tokenSesionActual) return;
    _suscripcionSesion?.cancel();
    _repositorio.cerrarSesion();
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
