import 'package:flutter_bloc/flutter_bloc.dart';

import '../../compartido/errores.dart';
import '../../compartido/logger.dart';
import 'ver_perfil_usuario_estado.dart';
import 'ver_perfil_usuario_repositorio.dart';

class VerPerfilUsuarioCubit extends Cubit<VerPerfilUsuarioEstado> {
  VerPerfilUsuarioCubit(this._repositorio)
      : super(const VerPerfilUsuarioInicial());

  final VerPerfilUsuarioRepositorio _repositorio;

  Future<void> cargar(String usuarioId) async {
    emit(const VerPerfilUsuarioCargando());
    try {
      final perfil = await _repositorio.obtenerPerfilCompleto(usuarioId);
      emit(VerPerfilUsuarioCargado(perfil: perfil));
    } on FallaServidor catch (e) {
      reportarError(e);
      emit(VerPerfilUsuarioError(mensaje: e.mensaje));
    } on FallaInesperada catch (e) {
      reportarError(e);
      emit(VerPerfilUsuarioError(mensaje: e.mensaje));
    }
  }
}
