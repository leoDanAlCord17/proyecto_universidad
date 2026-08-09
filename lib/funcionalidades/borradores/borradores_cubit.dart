import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../compartido/errores.dart';
import '../../compartido/logger.dart';
import 'borrador_evento.dart';
import 'borradores_estado.dart';
import 'borradores_repositorio.dart';

class BorradoresCubit extends Cubit<BorradoresEstado> {
  BorradoresCubit(this._repositorio) : super(const BorradoresInicial());

  final BorradoresRepositorio _repositorio;

  List<BorradorEvento> _todos = [];
  String? _usuarioId;
  int _offset = 0;

  Future<void> cargarBorradores(String usuarioId) async {
    _usuarioId = usuarioId;
    _offset = 0;
    _todos = [];
    emit(const BorradoresCargando());
    try {
      final resultado =
          await _repositorio.obtenerBorradores(usuarioId, offset: _offset);
      if (isClosed) return;
      _todos = resultado.borradores;
      _offset += resultado.borradores.length;
      emit(
        BorradoresCargados(
          borradores: _todos,
          borradoresFiltrados: _todos,
          hayMas: resultado.hayMas,
        ),
      );
    } on FallaServidor catch (e) {
      if (isClosed) return;
      reportarError(e);
      emit(BorradoresError(e.mensaje));
    } on FallaRed catch (e) {
      if (isClosed) return;
      reportarError(e);
      emit(BorradoresError(e.mensaje));
    } on FallaInesperada catch (e) {
      if (isClosed) return;
      reportarError(e);
      emit(BorradoresError(e.mensaje));
    }
  }

  Future<void> cargarMas() async {
    final estado = state;
    final usuarioId = _usuarioId;
    if (estado is! BorradoresCargados || !estado.hayMas || usuarioId == null)
      return;

    emit(
      BorradoresCargandoMas(
        borradores: estado.borradores,
        borradoresFiltrados: estado.borradoresFiltrados,
      ),
    );
    try {
      final resultado =
          await _repositorio.obtenerBorradores(usuarioId, offset: _offset);
      if (isClosed) return;
      _todos = [...estado.borradores, ...resultado.borradores];
      _offset += resultado.borradores.length;
      emit(
        BorradoresCargados(
          borradores: _todos,
          borradoresFiltrados: _todos,
          hayMas: resultado.hayMas,
        ),
      );
    } catch (_) {
      if (isClosed) return;
      emit(
        BorradoresCargados(
          borradores: estado.borradores,
          borradoresFiltrados: estado.borradoresFiltrados,
          hayMas: estado.hayMas,
        ),
      );
    }
  }

  void filtrar(String texto, DateTimeRange? rango) {
    final estadoActual = state;
    final base = switch (estadoActual) {
      BorradoresCargados() => estadoActual.borradores,
      BorradoresCargandoMas() => estadoActual.borradores,
      _ => null,
    };
    if (base == null) return;

    var filtrados = base;
    if (texto.isNotEmpty) {
      final q = texto.toLowerCase();
      filtrados = filtrados
          .where(
            (e) =>
                e.titulo.toLowerCase().contains(q) ||
                e.descripcion.toLowerCase().contains(q),
          )
          .toList();
    }
    if (rango != null) {
      final inicio =
          DateTime(rango.start.year, rango.start.month, rango.start.day);
      final fin =
          DateTime(rango.end.year, rango.end.month, rango.end.day, 23, 59, 59);
      filtrados = filtrados
          .where(
            (e) =>
                e.fechaInicio != null &&
                !e.fechaInicio!.isBefore(inicio) &&
                !e.fechaInicio!.isAfter(fin),
          )
          .toList();
    }

    if (estadoActual is BorradoresCargados) {
      emit(estadoActual.copiarCon(borradoresFiltrados: filtrados));
    } else if (estadoActual is BorradoresCargandoMas) {
      emit(
        BorradoresCargandoMas(
          borradores: estadoActual.borradores,
          borradoresFiltrados: filtrados,
        ),
      );
    }
  }

  Future<void> publicarEvento(String eventoId) async {
    final estadoActual = state;
    if (estadoActual is! BorradoresCargados) return;

    final borrador = _todos.where((e) => e.id == eventoId).firstOrNull;
    if (borrador != null && _fechaHoraYaPaso(borrador)) {
      emit(
        estadoActual.copiarCon(
          errorPublicacion:
              'Este evento ya pasó su fecha y hora de inicio. Debes editarlo antes de poder publicarlo.',
        ),
      );
      return;
    }

    emit(estadoActual.copiarCon(publicandoId: eventoId));
    try {
      await _repositorio.publicarEvento(eventoId);
      _todos = _todos.where((e) => e.id != eventoId).toList();
      final filtrados = estadoActual.borradoresFiltrados
          .where((e) => e.id != eventoId)
          .toList();
      emit(
        BorradoresCargados(
          borradores: _todos,
          borradoresFiltrados: filtrados,
          hayMas: estadoActual.hayMas,
        ),
      );
    } on FallaServidor catch (e) {
      reportarError(e);
      emit(
        BorradoresCargados(
          borradores: estadoActual.borradores,
          borradoresFiltrados: estadoActual.borradoresFiltrados,
          hayMas: estadoActual.hayMas,
          errorPublicacion: e.mensaje,
        ),
      );
    } on FallaInesperada catch (e) {
      reportarError(e);
      emit(
        BorradoresCargados(
          borradores: estadoActual.borradores,
          borradoresFiltrados: estadoActual.borradoresFiltrados,
          hayMas: estadoActual.hayMas,
          errorPublicacion: e.mensaje,
        ),
      );
    }
  }

  /// "Olvida" el borrador (no lo borra, lo pasa a cancelado) para que deje
  /// de aparecer en la lista.
  Future<void> olvidarEvento(String eventoId) async {
    final estadoActual = state;
    if (estadoActual is! BorradoresCargados) return;
    emit(estadoActual.copiarCon(publicandoId: eventoId));
    try {
      await _repositorio.olvidarEvento(eventoId);
      _todos = _todos.where((e) => e.id != eventoId).toList();
      final filtrados = estadoActual.borradoresFiltrados
          .where((e) => e.id != eventoId)
          .toList();
      emit(
        BorradoresCargados(
          borradores: _todos,
          borradoresFiltrados: filtrados,
          hayMas: estadoActual.hayMas,
        ),
      );
    } on FallaServidor catch (e) {
      reportarError(e);
      emit(
        BorradoresCargados(
          borradores: estadoActual.borradores,
          borradoresFiltrados: estadoActual.borradoresFiltrados,
          hayMas: estadoActual.hayMas,
          errorPublicacion: e.mensaje,
        ),
      );
    } on FallaInesperada catch (e) {
      reportarError(e);
      emit(
        BorradoresCargados(
          borradores: estadoActual.borradores,
          borradoresFiltrados: estadoActual.borradoresFiltrados,
          hayMas: estadoActual.hayMas,
          errorPublicacion: e.mensaje,
        ),
      );
    }
  }

  void limpiarError() {
    final estadoActual = state;
    if (estadoActual is! BorradoresCargados) return;
    emit(estadoActual.copiarCon(limpiarError: true));
  }
}

/// Combina fecha (solo día) y hora de inicio del borrador para saber si el
/// evento ya pasó. Sin hora definida, se da el beneficio de la duda: solo se
/// considera "pasado" si la fecha ya no es hoy.
bool _fechaHoraYaPaso(BorradorEvento borrador) {
  final fecha = borrador.fechaInicio;
  if (fecha == null) return false;
  final hora = borrador.horaInicio;
  DateTime inicio;
  if (hora != null && hora.length >= 5) {
    final partes = hora.substring(0, 5).split(':');
    final h = int.tryParse(partes[0]) ?? 0;
    final m = int.tryParse(partes[1]) ?? 0;
    inicio = DateTime(fecha.year, fecha.month, fecha.day, h, m);
  } else {
    inicio = DateTime(fecha.year, fecha.month, fecha.day, 23, 59, 59);
  }
  return inicio.isBefore(DateTime.now());
}
