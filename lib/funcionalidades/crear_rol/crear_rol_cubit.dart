import 'package:flutter_bloc/flutter_bloc.dart';

import '../../compartido/errores.dart';
import '../../compartido/logger.dart';
import 'crear_rol_estado.dart';
import 'crear_rol_repositorio.dart';
import 'permiso_opcion.dart';

class CrearRolCubit extends Cubit<CrearRolEstado> {
  CrearRolCubit(this._repositorio) : super(const CrearRolInicial());

  final CrearRolRepositorio _repositorio;
  String _busqueda = '';

  Future<void> cargarPermisos() async {
    emit(const CrearRolCargando());
    try {
      final permisos = await _repositorio.obtenerPermisos();
      emit(CrearRolCargado(permisos: permisos, permisosVisibles: permisos));
    } on FallaServidor catch (e) {
      reportarError(e);
      emit(CrearRolError(mensaje: e.mensaje));
    } on FallaInesperada catch (e) {
      reportarError(e);
      emit(CrearRolError(mensaje: e.mensaje));
    }
  }

  void togglePermiso(String id) {
    final e = state;
    if (e is! CrearRolCargado) return;
    final actuales = List<String>.from(e.permisosSeleccionadosIds);
    if (actuales.contains(id)) {
      actuales.remove(id);
    } else {
      actuales.add(id);
    }
    emit(
      e.copiarCon(
        permisosSeleccionadosIds: actuales,
        permisosVisibles: _computarVisibles(e.permisos, actuales, _busqueda),
      ),
    );
  }

  void filtrarPermisos(String texto) {
    final e = state;
    if (e is! CrearRolCargado) return;
    _busqueda = texto;
    emit(
      e.copiarCon(
        permisosVisibles:
            _computarVisibles(e.permisos, e.permisosSeleccionadosIds, texto),
      ),
    );
  }

  Future<void> cargarRolParaEditar(String rolId) async {
    emit(const CrearRolCargando());
    try {
      final permisos = await _repositorio.obtenerPermisos();
      final resultado = await _repositorio.obtenerRol(rolId);
      final sel = resultado.permisosIds;
      emit(
        CrearRolCargado(
          rolId: rolId,
          permisos: permisos,
          permisosVisibles: _computarVisibles(permisos, sel, ''),
          permisosSeleccionadosIds: sel,
          permisosIniciales: sel,
          nombreInicial: resultado.rol['nombre'] as String? ?? '',
          descripcionInicial: resultado.rol['descripcion'] as String? ?? '',
        ),
      );
    } on FallaServidor catch (e) {
      reportarError(e);
      emit(CrearRolError(mensaje: e.mensaje));
    } on FallaInesperada catch (e) {
      reportarError(e);
      emit(CrearRolError(mensaje: e.mensaje));
    }
  }

  Future<void> guardar(
      {required String nombre, required String descripcion}) async {
    final e = state;
    if (e is! CrearRolCargado) return;
    emit(e.copiarCon(estaGuardando: true));
    try {
      final editando = e.rolId != null;
      final datos = {
        'nombre': nombre,
        'descripcion': descripcion,
        'estatus': true
      };
      final rolId =
          editando ? e.rolId! : await _repositorio.crearRol(datos: datos);
      if (editando) await _repositorio.actualizarRol(id: rolId, datos: datos);
      await _persistirPermisos(
        rolId: rolId,
        editando: editando,
        nuevosIds: e.permisosSeleccionadosIds,
        anterioresIds: e.permisosIniciales,
      );
      emit(const CrearRolGuardado());
    } on FallaServidor catch (e) {
      reportarError(e);
      emit(CrearRolError(mensaje: e.mensaje));
    } on FallaInesperada catch (e) {
      reportarError(e);
      emit(CrearRolError(mensaje: e.mensaje));
    }
  }

  Future<void> _persistirPermisos({
    required String rolId,
    required bool editando,
    required List<String> nuevosIds,
    required List<String> anterioresIds,
  }) async {
    if (editando) {
      await _repositorio.sincronizarPermisos(
        rolId: rolId,
        nuevosIds: nuevosIds,
        anterioresIds: anterioresIds,
      );
    } else if (nuevosIds.isNotEmpty) {
      await _repositorio.asignarPermisos(rolId: rolId, permisosIds: nuevosIds);
    }
  }

  List<PermisoOpcion> _computarVisibles(
    List<PermisoOpcion> todos,
    List<String> seleccionados,
    String busqueda,
  ) {
    if (busqueda.trim().isNotEmpty) {
      final q = busqueda.toLowerCase();
      return todos
          .where(
            (p) =>
                p.nombre.toLowerCase().contains(q) ||
                p.descripcion.toLowerCase().contains(q),
          )
          .toList();
    }
    final sel = todos.where((p) => seleccionados.contains(p.id)).toList();
    final noSel = todos.where((p) => !seleccionados.contains(p.id)).toList();
    return [...sel, ...noSel];
  }
}
