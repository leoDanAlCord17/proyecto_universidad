import 'dart:async' show unawaited;

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../compartido/errores.dart';
import '../../compartido/logger.dart';
import 'revision_usuario_item.dart';
import 'revision_usuarios_estado.dart';
import 'revision_usuarios_repositorio.dart';

class RevisionUsuariosCubit extends Cubit<RevisionUsuariosEstado> {
  RevisionUsuariosCubit(this._repositorio)
      : super(const RevisionUsuariosInicial());

  final RevisionUsuariosRepositorio _repositorio;

  List<RevisionUsuarioItem> _todos = [];
  int _offset = 0;

  Future<void> cargar() async {
    _offset = 0;
    _todos = [];
    emit(const RevisionUsuariosCargando());
    try {
      final resultado = await _repositorio.obtenerPendientes(offset: _offset);
      if (isClosed) return;
      _todos = resultado.usuarios;
      _offset += resultado.usuarios.length;
      emit(
        RevisionUsuariosCargados(
          usuarios: _todos,
          hayMas: resultado.hayMas,
        ),
      );
    } on FallaServidor catch (falla) {
      if (isClosed) return;
      reportarError(falla);
      emit(RevisionUsuariosError(falla.mensaje));
    } on FallaRed catch (falla) {
      if (isClosed) return;
      reportarError(falla);
      emit(RevisionUsuariosError(falla.mensaje));
    } on FallaInesperada catch (falla) {
      if (isClosed) return;
      reportarError(falla);
      emit(RevisionUsuariosError(falla.mensaje));
    }
  }

  Future<void> cargarMas() async {
    final estado = state;
    if (estado is! RevisionUsuariosCargados || !estado.hayMas) return;

    emit(RevisionUsuariosCargandoMas(usuarios: estado.usuarios));
    try {
      final resultado = await _repositorio.obtenerPendientes(offset: _offset);
      if (isClosed) return;
      _todos = [...estado.usuarios, ...resultado.usuarios];
      _offset += resultado.usuarios.length;
      emit(
        RevisionUsuariosCargados(
          usuarios: _todos,
          hayMas: resultado.hayMas,
        ),
      );
    } catch (_) {
      if (isClosed) return;
      emit(
        RevisionUsuariosCargados(
          usuarios: estado.usuarios,
          hayMas: estado.hayMas,
        ),
      );
    }
  }

  Future<void> aprobar(String usuarioId) async {
    final estadoActual = state;
    if (estadoActual is! RevisionUsuariosCargados) return;
    emit(
      estadoActual.copiarCon(
        usuarioIdProcessando: usuarioId,
        limpiarError: true,
      ),
    );
    try {
      await _repositorio.aprobar(usuarioId);
      await cargar();
      try {
        unawaited(
          Supabase.instance.client.functions.invoke(
            'enviar-notificacion',
            body: {
              'usuario_ids': [usuarioId],
              'titulo': 'Cuenta aprobada',
              'cuerpo': 'Tu cuenta fue aprobada. Ya puedes acceder a UniAsist.',
            },
          ),
        );
      } catch (e) {
        log.w('No se pudo enviar notificación push', error: e);
      }
    } on FallaServidor catch (falla) {
      reportarError(falla);
      emit(
        estadoActual.copiarCon(
          limpiarProcessando: true,
          errorOperacion: falla.mensaje,
        ),
      );
    } on FallaInesperada catch (falla) {
      reportarError(falla);
      emit(
        estadoActual.copiarCon(
          limpiarProcessando: true,
          errorOperacion: falla.mensaje,
        ),
      );
    }
  }

  Future<void> rechazar(String usuarioId) async {
    final estadoActual = state;
    if (estadoActual is! RevisionUsuariosCargados) return;
    emit(
      estadoActual.copiarCon(
        usuarioIdProcessando: usuarioId,
        limpiarError: true,
      ),
    );
    try {
      await _repositorio.rechazar(usuarioId);
      await cargar();
      try {
        unawaited(
          Supabase.instance.client.functions.invoke(
            'enviar-notificacion',
            body: {
              'usuario_ids': [usuarioId],
              'titulo': 'Solicitud rechazada',
              'cuerpo': 'Tu solicitud de cuenta fue rechazada.',
            },
          ),
        );
      } catch (e) {
        log.w('No se pudo enviar notificación push', error: e);
      }
    } on FallaServidor catch (falla) {
      reportarError(falla);
      emit(
        estadoActual.copiarCon(
          limpiarProcessando: true,
          errorOperacion: falla.mensaje,
        ),
      );
    } on FallaInesperada catch (falla) {
      reportarError(falla);
      emit(
        estadoActual.copiarCon(
          limpiarProcessando: true,
          errorOperacion: falla.mensaje,
        ),
      );
    }
  }
}
