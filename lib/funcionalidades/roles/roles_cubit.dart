import 'package:flutter_bloc/flutter_bloc.dart';

import '../../compartido/errores.dart';
import 'roles_estado.dart';
import 'roles_repositorio.dart';

class RolesCubit extends Cubit<RolesEstado> {
  RolesCubit(this._repositorio) : super(const RolesInicial());

  final RolesRepositorio _repositorio;

  Future<void> cargarRoles() async {
    emit(const RolesCargando());
    try {
      final roles = await _repositorio.obtenerRoles();
      emit(RolesCargados(roles: roles, rolesFiltrados: roles));
    } on FallaServidor catch (e) {
      emit(RolesError(mensaje: e.mensaje));
    } on FallaInesperada catch (e) {
      emit(RolesError(mensaje: e.mensaje));
    }
  }

  void filtrar(String texto) {
    final estadoActual = state;
    if (estadoActual is! RolesCargados) return;
    if (texto.trim().isEmpty) {
      emit(estadoActual.copiarCon(rolesFiltrados: estadoActual.roles));
      return;
    }
    final q = texto.toLowerCase();
    emit(estadoActual.copiarCon(
      rolesFiltrados: estadoActual.roles
          .where((r) =>
              r.nombre.toLowerCase().contains(q) ||
              r.descripcion.toLowerCase().contains(q),)
          .toList(),
    ),);
  }
}
