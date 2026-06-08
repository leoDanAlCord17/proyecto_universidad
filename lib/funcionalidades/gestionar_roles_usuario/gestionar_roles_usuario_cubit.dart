import 'dart:async' show unawaited;

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../compartido/errores.dart';
import '../../compartido/logger.dart';
import 'gestionar_roles_usuario_estado.dart';
import 'gestionar_roles_usuario_repositorio.dart';

class GestionarRolesUsuarioCubit extends Cubit<GestionarRolesUsuarioEstado> {
  GestionarRolesUsuarioCubit(this._repositorio)
      : super(const GestionarRolesUsuarioInicial());

  final GestionarRolesUsuarioRepositorio _repositorio;
  String? _usuarioId;
  String? _adminId;

  Future<void> cargar(String usuarioId, {String? adminId}) async {
    _usuarioId = usuarioId;
    _adminId = adminId;
    emit(const GestionarRolesUsuarioCargando());
    try {
      final info = await _repositorio.obtenerInfoUsuario(usuarioId);
      final rolesUsuario = await _repositorio.obtenerRolesUsuario(usuarioId);
      final todosLosRoles = await _repositorio.obtenerRolesActivos();

      final idsActivos = rolesUsuario.map((r) => r.id).toSet();

      emit(
        GestionarRolesUsuarioCargado(
          nombreUsuario: info.nombre,
          correoUsuario: info.correo,
          rolesActivos: rolesUsuario,
          rolesDisponibles:
              todosLosRoles.where((r) => !idsActivos.contains(r.id)).toList(),
        ),
      );
    } on FallaServidor catch (e) {
      reportarError(e);
      emit(GestionarRolesUsuarioError(mensaje: e.mensaje));
    } on FallaInesperada catch (e) {
      reportarError(e);
      emit(GestionarRolesUsuarioError(mensaje: e.mensaje));
    }
  }

  Future<void> asignarRol(String rolId) async {
    if (_usuarioId == null) return;
    final estadoActual = state;
    if (estadoActual is! GestionarRolesUsuarioCargado) return;
    try {
      await _repositorio.asignarRol(_usuarioId!, rolId, _adminId);
      await cargar(_usuarioId!, adminId: _adminId);
      try {
        unawaited(
          Supabase.instance.client.functions.invoke(
            'enviar-notificacion',
            body: {
              'usuario_ids': [_usuarioId!],
              'titulo': 'Nuevo rol asignado',
              'cuerpo': 'Se te asignó un nuevo rol en el sistema.',
            },
          ),
        );
      } catch (e) {
        log.w('No se pudo enviar notificación push', error: e);
      }
    } on FallaServidor catch (e) {
      reportarError(e);
      emit(GestionarRolesUsuarioOperacionFallida(
          anterior: estadoActual, mensaje: e.mensaje));
    } on FallaInesperada catch (e) {
      reportarError(e);
      emit(GestionarRolesUsuarioOperacionFallida(
          anterior: estadoActual, mensaje: e.mensaje));
    }
  }

  Future<void> quitarRol(String rolId) async {
    if (_usuarioId == null) return;
    final estadoActual = state;
    if (estadoActual is! GestionarRolesUsuarioCargado) return;
    try {
      await _repositorio.quitarRol(_usuarioId!, rolId, _adminId);
      await cargar(_usuarioId!, adminId: _adminId);
      try {
        unawaited(
          Supabase.instance.client.functions.invoke(
            'enviar-notificacion',
            body: {
              'usuario_ids': [_usuarioId!],
              'titulo': 'Rol removido',
              'cuerpo': 'Se te removió un rol del sistema.',
            },
          ),
        );
      } catch (e) {
        log.w('No se pudo enviar notificación push', error: e);
      }
    } on FallaServidor catch (e) {
      reportarError(e);
      emit(GestionarRolesUsuarioOperacionFallida(
          anterior: estadoActual, mensaje: e.mensaje));
    } on FallaInesperada catch (e) {
      reportarError(e);
      emit(GestionarRolesUsuarioOperacionFallida(
          anterior: estadoActual, mensaje: e.mensaje));
    }
  }
}
