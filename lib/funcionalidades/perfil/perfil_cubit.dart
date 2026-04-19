import 'package:flutter_bloc/flutter_bloc.dart';

import '../../compartido/errores.dart';
import 'perfil_estado.dart';
import 'perfil_repositorio.dart';

class PerfilCubit extends Cubit<PerfilEstado> {
  PerfilCubit(this._repositorio) : super(const PerfilInicial());

  final PerfilRepositorio _repositorio;

  Future<void> cargarTags(String usuarioId) async {
    emit(const PerfilCargando());
    try {
      final resultado = await _repositorio.obtenerTags(usuarioId);
      emit(PerfilCargado(
        tagPrincipal:    resultado.tagPrincipal,
        tagsSecundarios: resultado.tagsSecundarios,
      ));
    } on FallaServidor catch (e) {
      emit(PerfilError(e.mensaje));
    } on FallaInesperada catch (e) {
      emit(PerfilError(e.mensaje));
    }
  }
}
