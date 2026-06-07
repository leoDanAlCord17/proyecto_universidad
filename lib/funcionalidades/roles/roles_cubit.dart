import 'package:flutter_bloc/flutter_bloc.dart';

import '../../compartido/errores.dart';
import '../../compartido/logger.dart';
import 'roles_estado.dart';
import 'roles_repositorio.dart';

class RolesCubit extends Cubit<RolesEstado> {
  RolesCubit(this._repositorio) : super(const RolesInicial());

  final RolesRepositorio _repositorio;

  int _offset = 0;

  Future<void> cargarRoles() async {
    _offset = 0;
    emit(const RolesCargando());
    try {
      final resultado = await _repositorio.obtenerRoles(offset: _offset);
      final conteos   = await _repositorio.contarUsuariosPorRol();
      if (isClosed) return;
      _offset += resultado.roles.length;
      emit(RolesCargados(
        roles:          resultado.roles,
        rolesFiltrados: resultado.roles,
        hayMas:         resultado.hayMas,
        conteoUsuarios: conteos,
      ),);
    } on FallaServidor catch (e) {
      if (isClosed) return;
      reportarError(e);
      emit(RolesError(mensaje: e.mensaje));
    } on FallaRed catch (e) {
      if (isClosed) return;
      reportarError(e);
      emit(RolesError(mensaje: e.mensaje));
    } on FallaInesperada catch (e) {
      if (isClosed) return;
      reportarError(e);
      emit(RolesError(mensaje: e.mensaje));
    }
  }

  Future<void> cargarMas() async {
    final estado = state;
    if (estado is! RolesCargados || !estado.hayMas) return;

    emit(RolesCargandoMas(
      roles:          estado.roles,
      rolesFiltrados: estado.rolesFiltrados,
      conteoUsuarios: estado.conteoUsuarios,
    ),);
    try {
      final resultado = await _repositorio.obtenerRoles(offset: _offset);
      if (isClosed) return;
      _offset += resultado.roles.length;
      final todos = [...estado.roles, ...resultado.roles];
      emit(RolesCargados(
        roles:          todos,
        rolesFiltrados: todos,
        hayMas:         resultado.hayMas,
        conteoUsuarios: estado.conteoUsuarios,
      ),);
    } catch (_) {
      if (isClosed) return;
      emit(RolesCargados(
        roles:          estado.roles,
        rolesFiltrados: estado.rolesFiltrados,
        hayMas:         estado.hayMas,
        conteoUsuarios: estado.conteoUsuarios,
      ),);
    }
  }

  void filtrar(String texto) {
    final estadoActual = state;
    final base = switch (estadoActual) {
      RolesCargados()    => estadoActual.roles,
      RolesCargandoMas() => estadoActual.roles,
      _                  => null,
    };
    if (base == null) return;

    final filtrados = texto.trim().isEmpty
        ? base
        : base.where((r) {
            final q = texto.toLowerCase();
            return r.nombre.toLowerCase().contains(q) ||
                r.descripcion.toLowerCase().contains(q);
          }).toList();

    if (estadoActual is RolesCargados) {
      emit(estadoActual.copiarCon(rolesFiltrados: filtrados));
    } else if (estadoActual is RolesCargandoMas) {
      emit(RolesCargandoMas(
        roles:          estadoActual.roles,
        rolesFiltrados: filtrados,
        conteoUsuarios: estadoActual.conteoUsuarios,
      ),);
    }
  }
}
