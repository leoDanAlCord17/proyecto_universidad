import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../compartido/errores.dart';
import 'borrador_evento.dart';
import 'borradores_estado.dart';
import 'borradores_repositorio.dart';

class BorradoresCubit extends Cubit<BorradoresEstado> {
  BorradoresCubit(this._repositorio) : super(const BorradoresInicial());

  final BorradoresRepositorio _repositorio;
  List<BorradorEvento> _todos = [];

  Future<void> cargarBorradores(String usuarioId) async {
    emit(const BorradoresCargando());
    try {
      _todos = await _repositorio.obtenerBorradores(usuarioId);
      emit(BorradoresCargados(borradores: _todos, borradoresFiltrados: _todos));
    } on FallaServidor catch (e) {
      emit(BorradoresError(e.mensaje));
    } on FallaInesperada catch (e) {
      emit(BorradoresError(e.mensaje));
    }
  }

  void filtrar(String texto, DateTimeRange? rango) {
    final estadoActual = state;
    if (estadoActual is! BorradoresCargados) return;
    var filtrados = _todos;
    if (texto.isNotEmpty) {
      final q = texto.toLowerCase();
      filtrados = filtrados
          .where((e) =>
              e.titulo.toLowerCase().contains(q) ||
              e.descripcion.toLowerCase().contains(q),)
          .toList();
    }
    if (rango != null) {
      final inicio = DateTime(rango.start.year, rango.start.month, rango.start.day);
      final fin    = DateTime(rango.end.year, rango.end.month, rango.end.day, 23, 59, 59);
      filtrados = filtrados
          .where((e) =>
              e.fechaInicio != null &&
              !e.fechaInicio!.isBefore(inicio) &&
              !e.fechaInicio!.isAfter(fin),)
          .toList();
    }
    emit(estadoActual.copiarCon(borradoresFiltrados: filtrados));
  }

  Future<void> publicarEvento(String eventoId) async {
    final estadoActual = state;
    if (estadoActual is! BorradoresCargados) return;
    emit(estadoActual.copiarCon(publicandoId: eventoId));
    try {
      await _repositorio.publicarEvento(eventoId);
      _todos = _todos.where((e) => e.id != eventoId).toList();
      final filtrados = estadoActual.borradoresFiltrados
          .where((e) => e.id != eventoId)
          .toList();
      emit(BorradoresCargados(borradores: _todos, borradoresFiltrados: filtrados));
    } on FallaServidor catch (e) {
      emit(BorradoresCargados(
        borradores:          estadoActual.borradores,
        borradoresFiltrados: estadoActual.borradoresFiltrados,
        errorPublicacion:    e.mensaje,
      ),);
    } on FallaInesperada catch (e) {
      emit(BorradoresCargados(
        borradores:          estadoActual.borradores,
        borradoresFiltrados: estadoActual.borradoresFiltrados,
        errorPublicacion:    e.mensaje,
      ),);
    }
  }

  void limpiarError() {
    final estadoActual = state;
    if (estadoActual is! BorradoresCargados) return;
    emit(estadoActual.copiarCon(limpiarError: true));
  }
}
