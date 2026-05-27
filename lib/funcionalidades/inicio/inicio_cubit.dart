import 'package:flutter_bloc/flutter_bloc.dart';

import '../../compartido/errores.dart';
import 'inicio_estado.dart';
import 'inicio_repositorio.dart';

class InicioCubit extends Cubit<InicioEstado> {
  InicioCubit(this._repositorio) : super(const InicioInicial());

  final InicioRepositorio _repositorio;

  /// Carga los tags del usuario y el flag de revisión de usuarios.
  Future<void> cargarTags(String usuarioId) async {
    emit(const InicioTagsCargando());
    try {
      final tagsF     = _repositorio.obtenerTags(usuarioId);
      final revisionF = _repositorio.obtenerRevisionHabilitada();
      final tags      = await tagsF;
      final revision  = await revisionF;
      if (isClosed) return;
      emit(InicioTagsCargados(
        tagPrincipal:       tags.tagPrincipal,
        tagsSecundarios:    tags.tagsSecundarios,
        revisionHabilitada: revision,
      ),);
    } on FallaServidor catch (falla) {
      if (!isClosed) emit(InicioError(falla.mensaje));
    } on FallaInesperada catch (falla) {
      if (!isClosed) emit(InicioError(falla.mensaje));
    }
  }
}
