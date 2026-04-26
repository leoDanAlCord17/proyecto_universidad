import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../compartido/constantes.dart';
import '../../compartido/errores.dart';
import 'evento.dart';
import 'eventos_estado.dart';
import 'eventos_repositorio.dart';

class EventosCubit extends Cubit<EventosEstado> {
  EventosCubit(this._repositorio) : super(const EventosInicial());

  final EventosRepositorio _repositorio;

  List<EventoConGrupos> _enCurso  = [];
  List<EventoConGrupos> _proximos = [];
  Timer? _timer;

  static const _intervaloRefresh = Duration(seconds: 60);

  Future<void> cargar(String usuarioId) async {
    _timer?.cancel();
    emit(const EventosCargando());
    try {
      final eventos     = await _repositorio.obtenerEventosConGrupos();
      final tagsUsuario = await _repositorio.obtenerTagsUsuario(usuarioId);
      final visibles    = eventos.where((e) => _esVisible(e, tagsUsuario)).toList();

      _enCurso  = visibles.where((e) => e.evento.estatus == EstatusEvento.enCurso).toList();
      _proximos = visibles.where((e) => e.evento.estatus == EstatusEvento.programado).toList();

      emit(EventosCargado(enCurso: _enCurso, proximos: _proximos));
      _timer = Timer.periodic(_intervaloRefresh, (_) => _refrescarSilencioso(usuarioId));
    } on FallaServidor catch (e) {
      emit(EventosError(e.mensaje));
    } on FallaInesperada catch (e) {
      emit(EventosError(e.mensaje));
    }
  }

  void filtrar(String texto, DateTimeRange? rango) {
    final estadoActual = state;
    if (estadoActual is! EventosCargado) return;

    emit(estadoActual.copiarCon(
      enCurso:       _aplicarFiltros(_enCurso,  texto, rango),
      proximos:      _aplicarFiltros(_proximos, texto, rango),
      textoBusqueda: texto,
      rangoFechas:   rango,
      limpiarRango:  rango == null,
    ));
  }

  Future<void> _refrescarSilencioso(String usuarioId) async {
    try {
      final eventos     = await _repositorio.obtenerEventosConGrupos();
      final tagsUsuario = await _repositorio.obtenerTagsUsuario(usuarioId);
      final visibles    = eventos.where((e) => _esVisible(e, tagsUsuario)).toList();

      _enCurso  = visibles.where((e) => e.evento.estatus == EstatusEvento.enCurso).toList();
      _proximos = visibles.where((e) => e.evento.estatus == EstatusEvento.programado).toList();

      final estadoActual = state;
      if (estadoActual is! EventosCargado) return;

      emit(estadoActual.copiarCon(
        enCurso:  _aplicarFiltros(_enCurso,  estadoActual.textoBusqueda, estadoActual.rangoFechas),
        proximos: _aplicarFiltros(_proximos, estadoActual.textoBusqueda, estadoActual.rangoFechas),
      ));
    } catch (_) {
      // Fallo silencioso — no interrumpe al usuario
    }
  }

  List<EventoConGrupos> _aplicarFiltros(
    List<EventoConGrupos> lista,
    String                texto,
    DateTimeRange?        rango,
  ) {
    var resultado = lista;

    if (texto.trim().isNotEmpty) {
      final q = texto.trim().toLowerCase();
      resultado = resultado.where((e) {
        final ev = e.evento;
        return ev.titulo.toLowerCase().contains(q)               ||
            (ev.descripcion?.toLowerCase().contains(q) ?? false) ||
            (ev.lugar?.toLowerCase().contains(q)       ?? false) ||
            e.nombresParaBusqueda.any((t) => t.toLowerCase().contains(q));
      }).toList();
    }

    if (rango != null) {
      final inicio = DateTime(rango.start.year, rango.start.month, rango.start.day);
      final fin    = DateTime(rango.end.year,   rango.end.month,   rango.end.day, 23, 59, 59);
      resultado = resultado.where((e) {
        final fecha = e.evento.fechaInicio;
        return fecha != null && !fecha.isBefore(inicio) && !fecha.isAfter(fin);
      }).toList();
    }

    return resultado;
  }

  static bool _esVisible(
    EventoConGrupos evento,
    ({String? tagPrincipalId, List<String> tagsSecundariosIds}) tagsUsuario,
  ) {
    if (evento.esGeneral) return true;
    if (evento.grupos.isEmpty) return false;
    return evento.grupos.any((g) => _coincideGrupo(g, tagsUsuario));
  }

  static bool _coincideGrupo(
    GrupoEvento grupo,
    ({String? tagPrincipalId, List<String> tagsSecundariosIds}) tagsUsuario,
  ) {
    if (tagsUsuario.tagPrincipalId != grupo.tagPrincipalId) return false;
    return grupo.tagsSecundariosIds.every(tagsUsuario.tagsSecundariosIds.contains);
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}
