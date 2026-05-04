import 'package:flutter_bloc/flutter_bloc.dart';

import '../../compartido/errores.dart';
import 'crear_tipo_evento_estado.dart';
import 'tipos_evento_repositorio.dart';

class CrearTipoEventoCubit extends Cubit<CrearTipoEventoEstado> {
  CrearTipoEventoCubit(this._repositorio) : super(const CrearTipoEventoInicial());

  final TiposEventoRepositorio _repositorio;

  void iniciarCreacion() {
    emit(const CrearTipoEventoCargado());
  }

  Future<void> cargarParaEditar(String id) async {
    emit(const CrearTipoEventoCargando());
    try {
      final datos = await _repositorio.obtenerTipoEvento(id);
      emit(CrearTipoEventoCargado(
        tipoEventoId:       id,
        nombreInicial:      (datos['nombre']      as String?) ?? '',
        descripcionInicial: (datos['descripcion'] as String?) ?? '',
      ));
    } on FallaServidor catch (falla) {
      emit(CrearTipoEventoError(mensaje: falla.mensaje));
    } on FallaInesperada catch (falla) {
      emit(CrearTipoEventoError(mensaje: falla.mensaje));
    }
  }

  Future<void> guardar({
    required String nombre,
    required String descripcion,
  }) async {
    final estadoActual = state;
    if (estadoActual is! CrearTipoEventoCargado) return;
    emit(estadoActual.copiarCon(estaGuardando: true));
    try {
      if (estadoActual.tipoEventoId != null) {
        await _repositorio.actualizarTipoEvento(
          id:          estadoActual.tipoEventoId!,
          nombre:      nombre,
          descripcion: descripcion,
        );
      } else {
        await _repositorio.crearTipoEvento(
          nombre:      nombre,
          descripcion: descripcion,
        );
      }
      emit(const CrearTipoEventoGuardado());
    } on FallaServidor catch (falla) {
      emit(CrearTipoEventoError(mensaje: falla.mensaje));
    } on FallaInesperada catch (falla) {
      emit(CrearTipoEventoError(mensaje: falla.mensaje));
    }
  }
}
