import 'package:flutter_bloc/flutter_bloc.dart';

import '../../compartido/errores.dart';
import '../../compartido/logger.dart';
import 'crear_tag_estado.dart';
import 'crear_tag_repositorio.dart';

class CrearTagCubit extends Cubit<CrearTagEstado> {
  CrearTagCubit(this._repositorio) : super(const CrearTagInicial());

  final CrearTagRepositorio _repositorio;

  void cargarFormulario() {
    emit(const CrearTagCargado());
  }

  Future<void> cargarTagParaEditar(String tagId) async {
    emit(const CrearTagCargando());
    try {
      final tag = await _repositorio.obtenerTag(tagId);
      emit(CrearTagCargado(
        tagId:              tagId,
        nombreInicial:      tag['nombre']      as String? ?? '',
        descripcionInicial: tag['descripcion'] as String? ?? '',
        tipoSeleccionado:   tag['tipo']        as String?,
      ),);
    } on FallaServidor catch (e) {
      reportarError(e);
      emit(CrearTagError(mensaje: e.mensaje));
    } on FallaInesperada catch (e) {
      reportarError(e);
      emit(CrearTagError(mensaje: e.mensaje));
    }
  }

  void seleccionarTipo(String tipo) {
    final e = state;
    if (e is! CrearTagCargado) return;
    emit(e.copiarCon(tipoSeleccionado: tipo, errorValidacion: ''));
  }

  Future<void> guardar({
    required String  nombre,
    required String  descripcion,
    required String? tipo,
    required String  creadorId,
  }) async {
    final e = state;
    if (e is! CrearTagCargado) return;

    if (nombre.isEmpty) {
      emit(e.copiarCon(errorValidacion: 'El nombre es obligatorio.'));
      return;
    }
    if (tipo == null) {
      emit(e.copiarCon(errorValidacion: 'Selecciona un tipo.'));
      return;
    }

    emit(e.copiarCon(estaGuardando: true, errorValidacion: ''));
    try {
      final duplicado = await _repositorio.existeDuplicado(
        nombre:    nombre,
        tipo:      tipo,
        excludeId: e.tagId,
      );
      if (duplicado) {
        final tipoDisplay = tipo == 'principal' ? 'Principal' : 'Secundario';
        emit(e.copiarCon(
          estaGuardando:   false,
          errorValidacion: 'Ya existe un tag "$nombre" de tipo $tipoDisplay.',
        ),);
        return;
      }
      await _persistirTag(estado: e, nombre: nombre, descripcion: descripcion, tipo: tipo, creadorId: creadorId);
      emit(const CrearTagGuardado());
    } on FallaServidor catch (err) {
      reportarError(err);
      emit(e.copiarCon(estaGuardando: false, errorValidacion: err.mensaje));
    } on FallaInesperada catch (err) {
      reportarError(err);
      emit(e.copiarCon(estaGuardando: false, errorValidacion: err.mensaje));
    }
  }

  Future<void> _persistirTag({
    required CrearTagCargado estado,
    required String          nombre,
    required String          descripcion,
    required String          tipo,
    required String          creadorId,
  }) async {
    final datos = {'nombre': nombre, 'descripcion': descripcion, 'tipo': tipo};
    if (estado.tagId != null) {
      await _repositorio.actualizarTag(id: estado.tagId!, datos: datos);
    } else {
      await _repositorio.crearTag({...datos, 'creado_por': creadorId});
    }
  }
}
