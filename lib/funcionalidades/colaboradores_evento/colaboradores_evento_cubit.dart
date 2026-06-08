import 'dart:async' show unawaited;

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../compartido/errores.dart';
import '../../compartido/logger.dart';
import 'colaborador_item.dart';
import 'colaboradores_evento_estado.dart';
import 'colaboradores_evento_repositorio.dart';

class ColaboradoresEventoCubit extends Cubit<ColaboradoresEventoEstado> {
  ColaboradoresEventoCubit(this._repositorio)
      : super(const ColaboradoresEventoInicial());

  final ColaboradoresEventoRepositorio _repositorio;

  String? _eventoId;
  String? _adminId;

  Future<void> iniciar(String eventoId, {String? adminId}) async {
    _eventoId = eventoId;
    _adminId = adminId;
    emit(const ColaboradoresEventoCargando());
    try {
      final colaboradores = await _repositorio.obtenerColaboradores(eventoId);
      emit(
        ColaboradoresEventoCargado(
          colaboradores: colaboradores,
          resultadosBusqueda: const [],
          busqueda: '',
        ),
      );
    } on FallaServidor catch (e) {
      reportarError(e);
      emit(ColaboradoresEventoError(mensaje: e.mensaje));
    } on FallaInesperada catch (e) {
      reportarError(e);
      emit(ColaboradoresEventoError(mensaje: e.mensaje));
    }
  }

  Future<void> buscar(String query) async {
    final cargado = _extraerCargado(state);
    if (cargado == null) return;
    if (query.trim().length < 2) {
      emit(cargado.copiarCon(resultadosBusqueda: const [], busqueda: query));
      return;
    }
    try {
      final todos = await _repositorio.buscarUsuarios(query);
      final idsAsignados =
          cargado.colaboradores.map((c) => c.usuarioId).toSet();
      final filtrados =
          todos.where((u) => !idsAsignados.contains(u.id)).toList();
      final actual = _extraerCargado(state) ?? cargado;
      emit(actual.copiarCon(resultadosBusqueda: filtrados, busqueda: query));
    } on FallaServidor catch (e) {
      reportarError(e);
      _emitirFallo(cargado, e.mensaje);
    } on FallaInesperada catch (e) {
      reportarError(e);
      _emitirFallo(cargado, e.mensaje);
    }
  }

  Future<void> asignar(UsuarioParaAsignar usuario) async {
    final cargado = _extraerCargado(state);
    if (cargado == null || _eventoId == null || _adminId == null) return;
    emit(cargado.copiarCon(idOperando: usuario.id));
    try {
      await _repositorio.asignarColaborador(
        eventoId: _eventoId!,
        usuarioId: usuario.id,
        asignadoPorId: _adminId!,
      );
      await _recargarColaboradores();
      final actual = _extraerCargado(state);
      if (actual == null) return;
      final filtrados = actual.resultadosBusqueda
          .where((u) => !actual.colaboradores.any((c) => c.usuarioId == u.id))
          .toList();
      emit(actual.copiarCon(resultadosBusqueda: filtrados, idOperando: null));
      try {
        unawaited(
          Supabase.instance.client.functions.invoke(
            'enviar-notificacion',
            body: {
              'usuario_ids': [usuario.id],
              'titulo': 'Nuevo rol en evento',
              'cuerpo': 'Fuiste asignado como colaborador en un evento.',
            },
          ),
        );
      } catch (e) {
        log.w('No se pudo enviar notificación push', error: e);
      }
    } on FallaServidor catch (e) {
      reportarError(e);
      _emitirFallo(cargado, e.mensaje);
    } on FallaInesperada catch (e) {
      reportarError(e);
      _emitirFallo(cargado, e.mensaje);
    }
  }

  Future<void> quitar(ColaboradorItem colaborador) async {
    final cargado = _extraerCargado(state);
    if (cargado == null) return;
    emit(cargado.copiarCon(idOperando: colaborador.asignacionId));
    try {
      await _repositorio.quitarColaborador(colaborador.asignacionId);
      await _recargarColaboradores();
      try {
        unawaited(
          Supabase.instance.client.functions.invoke(
            'enviar-notificacion',
            body: {
              'usuario_ids': [colaborador.usuarioId],
              'titulo': 'Removido de evento',
              'cuerpo': 'Ya no eres colaborador en el evento.',
            },
          ),
        );
      } catch (e) {
        log.w('No se pudo enviar notificación push', error: e);
      }
    } on FallaServidor catch (e) {
      reportarError(e);
      _emitirFallo(cargado, e.mensaje);
    } on FallaInesperada catch (e) {
      reportarError(e);
      _emitirFallo(cargado, e.mensaje);
    }
  }

  // ─── Helpers privados ────────────────────────────────────────────────────────

  Future<void> _recargarColaboradores() async {
    if (_eventoId == null) return;
    final colaboradores = await _repositorio.obtenerColaboradores(_eventoId!);
    final cargado = _extraerCargado(state);
    if (cargado == null) return;
    emit(cargado.copiarCon(colaboradores: colaboradores, idOperando: null));
  }

  void _emitirFallo(ColaboradoresEventoCargado base, String mensaje) {
    final actual = _extraerCargado(state) ?? base;
    emit(
      ColaboradoresEventoOperacionFallida(
        anterior: actual.copiarCon(idOperando: null),
        mensaje: mensaje,
      ),
    );
  }

  ColaboradoresEventoCargado? _extraerCargado(
          ColaboradoresEventoEstado estado) =>
      switch (estado) {
        ColaboradoresEventoCargado() => estado,
        ColaboradoresEventoOperacionFallida() => estado.anterior,
        _ => null,
      };
}
