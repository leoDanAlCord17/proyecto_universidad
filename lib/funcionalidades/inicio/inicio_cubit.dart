import 'package:flutter_bloc/flutter_bloc.dart';

import '../../compartido/errores.dart';
import 'inicio_estado.dart';
import 'inicio_repositorio.dart';

class InicioCubit extends Cubit<InicioEstado> {
  InicioCubit(this._repositorio) : super(const InicioInicial());

  final InicioRepositorio _repositorio;

  /// Carga el tag principal y los tags secundarios del usuario autenticado.
  Future<void> cargarTags(String usuarioId) async {
    emit(const InicioTagsCargando());
    try {
      final resultado = await _repositorio.obtenerTags(usuarioId);
      emit(InicioTagsCargados(
        tagPrincipal:    resultado.tagPrincipal,
        tagsSecundarios: resultado.tagsSecundarios,
      ));
    } on FallaServidor catch (e) {
      emit(InicioError(e.mensaje));
    } on FallaInesperada catch (e) {
      emit(InicioError(e.mensaje));
    }
  }
}
