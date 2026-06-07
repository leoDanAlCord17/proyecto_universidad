import 'package:flutter_bloc/flutter_bloc.dart';

import '../../compartido/errores.dart';
import '../../compartido/logger.dart';
import 'permisos_estado.dart';
import 'permisos_repositorio.dart';

class PermisosCubit extends Cubit<PermisosEstado> {
  PermisosCubit(this._repositorio) : super(const PermisosInicial());

  final PermisosRepositorio _repositorio;

  Future<void> cargarPermisos() async {
    emit(const PermisosCargando());
    try {
      final permisos = await _repositorio.obtenerPermisos();
      emit(PermisosCargados(permisos: permisos, permisosFiltrados: permisos));
    } on FallaServidor catch (e) {
      reportarError(e);
      emit(PermisosError(mensaje: e.mensaje));
    } on FallaInesperada catch (e) {
      reportarError(e);
      emit(PermisosError(mensaje: e.mensaje));
    }
  }

  void filtrar(String texto) {
    final estadoActual = state;
    if (estadoActual is! PermisosCargados) return;
    if (texto.trim().isEmpty) {
      emit(estadoActual.copiarCon(permisosFiltrados: estadoActual.permisos));
      return;
    }
    final q = texto.toLowerCase();
    emit(estadoActual.copiarCon(
      permisosFiltrados: estadoActual.permisos
          .where((p) =>
              p.nombre.toLowerCase().contains(q) ||
              p.descripcion.toLowerCase().contains(q),)
          .toList(),
    ),);
  }
}
