import 'package:flutter_bloc/flutter_bloc.dart';

import '../../compartido/errores.dart';
import 'revision_usuarios_estado.dart';
import 'revision_usuarios_repositorio.dart';

class RevisionUsuariosCubit extends Cubit<RevisionUsuariosEstado> {
  RevisionUsuariosCubit(this._repositorio)
      : super(const RevisionUsuariosInicial());

  final RevisionUsuariosRepositorio _repositorio;

  /// Carga los usuarios pendientes de aprobación.
  Future<void> cargar() async {
    emit(const RevisionUsuariosCargando());
    try {
      final usuarios = await _repositorio.obtenerPendientes();
      emit(RevisionUsuariosCargados(usuarios: usuarios));
    } on FallaServidor catch (falla) {
      emit(RevisionUsuariosError(falla.mensaje));
    } on FallaInesperada catch (falla) {
      emit(RevisionUsuariosError(falla.mensaje));
    }
  }

  /// Aprueba al usuario cambiando su estatus a aprobado.
  Future<void> aprobar(String usuarioId) async {
    final estadoActual = state;
    if (estadoActual is! RevisionUsuariosCargados) return;
    emit(estadoActual.copiarCon(
      usuarioIdProcessando: usuarioId,
      limpiarError:         true,
    ),);
    try {
      await _repositorio.aprobar(usuarioId);
      await cargar();
    } on FallaServidor catch (falla) {
      emit(estadoActual.copiarCon(
        limpiarProcessando: true,
        errorOperacion:     falla.mensaje,
      ),);
    } on FallaInesperada catch (falla) {
      emit(estadoActual.copiarCon(
        limpiarProcessando: true,
        errorOperacion:     falla.mensaje,
      ),);
    }
  }

  /// Rechaza la solicitud de un usuario pendiente.
  Future<void> rechazar(String usuarioId) async {
    final estadoActual = state;
    if (estadoActual is! RevisionUsuariosCargados) return;
    emit(estadoActual.copiarCon(
      usuarioIdProcessando: usuarioId,
      limpiarError:         true,
    ),);
    try {
      await _repositorio.rechazar(usuarioId);
      await cargar();
    } on FallaServidor catch (falla) {
      emit(estadoActual.copiarCon(
        limpiarProcessando: true,
        errorOperacion:     falla.mensaje,
      ),);
    } on FallaInesperada catch (falla) {
      emit(estadoActual.copiarCon(
        limpiarProcessando: true,
        errorOperacion:     falla.mensaje,
      ),);
    }
  }
}
