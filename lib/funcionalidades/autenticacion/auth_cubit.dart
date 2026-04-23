import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

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

  @override
  Future<void> close() {
    _suscripcionRecuperacion.cancel();
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
      } else {
        emit(Autenticado(usuario));
      }
    } on FallaServidor {
      emit(NoAutenticado());
    } on FallaInesperada {
      emit(NoAutenticado());
    }
  }

  /// Actualiza el estado con el usuario autenticado.
  void actualizarUsuario(Usuario usuario) {
    emit(Autenticado(usuario));
  }

  /// Cierra la sesión del usuario y emite [NoAutenticado].
  Future<void> cerrarSesion() async {
    await _repositorio.cerrarSesion();
    emit(NoAutenticado());
  }
}
