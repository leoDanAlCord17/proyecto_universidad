import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../compartido/constantes.dart';
import '../../compartido/errores.dart';
import '../../compartido/logger.dart';
import 'evento.dart';
import 'eventos_estado.dart';
import 'eventos_repositorio.dart';

class EventosCubit extends Cubit<EventosEstado> {
  EventosCubit(this._repositorio) : super(const EventosInicial());

  final EventosRepositorio _repositorio;

  List<EventoConGrupos> _enCurso = [];
  List<EventoConGrupos> _proximos = [];
  Timer? _timer;

  static const _intervaloRefresh = Duration(seconds: 60);

  Future<void> cargar(String usuarioId) async {
    _timer?.cancel();
    emit(const EventosCargando());
    try {
      final eventos =
          await _repositorio.obtenerEventosConGrupos(usuarioId: usuarioId);
      final tagsUsuario = await _repositorio.obtenerTagsUsuario(usuarioId);
      if (isClosed) return;
      final visibles =
          eventos.where((e) => _esVisible(e, tagsUsuario)).toList();

      _enCurso = visibles
          .where((e) => e.evento.estatus == EstatusEvento.enCurso)
          .toList();
      _proximos = visibles
          .where((e) => e.evento.estatus == EstatusEvento.programado)
          .toList();

      _enCurso = await _enriquecerConPresentes(_enCurso);
      if (isClosed) return;

      // Conteos auxiliares — fallo silencioso para no bloquear la carga principal
      int cantidadBorradores = 0;
      try {
        cantidadBorradores = await _repositorio.contarBorradores(usuarioId);
      } catch (e) {
        log.w('No se pudo obtener cantidad de borradores', error: e);
      }

      if (isClosed) return;
      emit(
        EventosCargado(
          enCurso: _enCurso,
          proximos: _proximos,
          cantidadBorradores: cantidadBorradores,
        ),
      );
      _timer = Timer.periodic(
          _intervaloRefresh, (_) => _refrescarSilencioso(usuarioId));
    } on FallaServidor catch (e) {
      if (isClosed) return;
      reportarError(e);
      _emitirDesdeCache(usuarioId, e.mensaje);
    } on FallaInesperada catch (e) {
      if (isClosed) return;
      reportarError(e);
      _emitirDesdeCache(usuarioId, e.mensaje);
    }
  }

  /// Si hay datos en caché emite [EventosSinConexion]; si no, emite [EventosError].
  void _emitirDesdeCache(String usuarioId, String mensajeError) {
    final desdeCache =
        _repositorio.obtenerEventosConGruposDesdeCache(usuarioId);
    if (desdeCache == null) {
      emit(EventosError(mensajeError));
      return;
    }
    _enCurso = desdeCache
        .where((e) => e.evento.estatus == EstatusEvento.enCurso)
        .toList();
    _proximos = desdeCache
        .where((e) => e.evento.estatus == EstatusEvento.programado)
        .toList();
    emit(EventosSinConexion(enCurso: _enCurso, proximos: _proximos));
  }

  /// Enriquece los eventos en curso con el contador de asistentes presentes.
  Future<List<EventoConGrupos>> _enriquecerConPresentes(
    List<EventoConGrupos> enCurso,
  ) async {
    if (enCurso.isEmpty) return enCurso;
    try {
      final ids = enCurso.map((e) => e.evento.id).toList();
      final conteos = await _repositorio.obtenerConteoPresentesPorEvento(ids);
      return enCurso.map((e) {
        final total = conteos[e.evento.id];
        return total != null ? e.copiarConPresentes(total) : e;
      }).toList();
    } catch (e) {
      log.w('No se pudo obtener conteo de presentes', error: e);
      return enCurso; // fallo silencioso — tarjetas sin contador
    }
  }

  void filtrar(String texto, DateTimeRange? rango) {
    final estadoActual = state;

    if (estadoActual is EventosCargado) {
      emit(
        estadoActual.copiarCon(
          enCurso: _aplicarFiltros(_enCurso, texto, rango),
          proximos: _aplicarFiltros(_proximos, texto, rango),
          textoBusqueda: texto,
          rangoFechas: rango,
          limpiarRango: rango == null,
        ),
      );
    } else if (estadoActual is EventosSinConexion) {
      emit(
        estadoActual.copiarCon(
          enCurso: _aplicarFiltros(_enCurso, texto, rango),
          proximos: _aplicarFiltros(_proximos, texto, rango),
          textoBusqueda: texto,
          rangoFechas: rango,
          limpiarRango: rango == null,
        ),
      );
    }
  }

  Future<void> _refrescarSilencioso(String usuarioId) async {
    try {
      final eventos =
          await _repositorio.obtenerEventosConGrupos(usuarioId: usuarioId);
      final tagsUsuario = await _repositorio.obtenerTagsUsuario(usuarioId);
      final visibles =
          eventos.where((e) => _esVisible(e, tagsUsuario)).toList();

      _enCurso = visibles
          .where((e) => e.evento.estatus == EstatusEvento.enCurso)
          .toList();
      _proximos = visibles
          .where((e) => e.evento.estatus == EstatusEvento.programado)
          .toList();
      _enCurso = await _enriquecerConPresentes(_enCurso);

      final estadoActual = state;
      if (isClosed || estadoActual is! EventosCargado) return;

      int cantidadBorradores = estadoActual.cantidadBorradores;
      try {
        cantidadBorradores = await _repositorio.contarBorradores(usuarioId);
      } catch (e) {
        log.w('No se pudo refrescar cantidad de borradores', error: e);
      }

      if (isClosed) return;
      emit(
        estadoActual.copiarCon(
          enCurso: _aplicarFiltros(
              _enCurso, estadoActual.textoBusqueda, estadoActual.rangoFechas),
          proximos: _aplicarFiltros(
              _proximos, estadoActual.textoBusqueda, estadoActual.rangoFechas),
          cantidadBorradores: cantidadBorradores,
        ),
      );
    } catch (e) {
      // Fallo silencioso — no interrumpe al usuario, es un refresco en
      // segundo plano; la próxima recarga o el refresh periódico reintenta.
      log.w('Falló el refresco silencioso de eventos', error: e);
    }
  }

  List<EventoConGrupos> _aplicarFiltros(
    List<EventoConGrupos> lista,
    String texto,
    DateTimeRange? rango,
  ) {
    var resultado = lista;

    if (texto.trim().isNotEmpty) {
      final q = texto.trim().toLowerCase();
      resultado = resultado.where((e) {
        final ev = e.evento;
        return ev.titulo.toLowerCase().contains(q) ||
            (ev.descripcion?.toLowerCase().contains(q) ?? false) ||
            (ev.lugar?.toLowerCase().contains(q) ?? false) ||
            e.nombresParaBusqueda.any((t) => t.toLowerCase().contains(q));
      }).toList();
    }

    if (rango != null) {
      final inicio =
          DateTime(rango.start.year, rango.start.month, rango.start.day);
      final fin =
          DateTime(rango.end.year, rango.end.month, rango.end.day, 23, 59, 59);
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
    return grupo.tagsSecundariosIds
        .every(tagsUsuario.tagsSecundariosIds.contains);
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}
