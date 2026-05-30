import 'package:flutter_bloc/flutter_bloc.dart';

import '../../compartido/errores.dart';
import 'usuario_item.dart';
import 'usuarios_estado.dart';
import 'usuarios_repositorio.dart';

class UsuariosCubit extends Cubit<UsuariosEstado> {
  UsuariosCubit(this._repositorio) : super(const UsuariosInicial());

  final UsuariosRepositorio _repositorio;
  String _busqueda = '';

  // ── Carga inicial ──────────────────────────────────────────────────────────

  Future<void> cargar() async {
    emit(const UsuariosCargando());
    try {
      final usuarios = await _repositorio.obtenerUsuarios();
      if (isClosed) return;
      emit(UsuariosCargados(
        usuarios:          usuarios,
        usuariosFiltrados: _aplicarFiltro(usuarios, _busqueda),
      ),);
    } on FallaServidor catch (e) {
      if (isClosed) return;
      emit(UsuariosError(mensaje: e.mensaje));
    } on FallaInesperada catch (e) {
      if (isClosed) return;
      emit(UsuariosError(mensaje: e.mensaje));
    }
  }

  // ── Suspender usuario individual ───────────────────────────────────────────

  Future<void> suspender(String usuarioId) async {
    final cargados = _extraerCargados(state);
    if (cargados == null) return;
    try {
      await _repositorio.suspenderUsuario(usuarioId);
      await cargar();
    } on FallaServidor catch (e) {
      emit(UsuariosOperacionFallida(anterior: cargados, mensaje: e.mensaje));
    } on FallaInesperada catch (e) {
      emit(UsuariosOperacionFallida(anterior: cargados, mensaje: e.mensaje));
    }
  }

  // ── Filtrado ───────────────────────────────────────────────────────────────

  void filtrar(String texto) {
    final estadoActual = _extraerCargados(state);
    if (estadoActual == null) return;
    _busqueda = texto;
    if (texto.trim().isEmpty) {
      emit(estadoActual.copiarCon(usuariosFiltrados: estadoActual.usuarios));
      return;
    }
    emit(estadoActual.copiarCon(
      usuariosFiltrados: _aplicarFiltro(estadoActual.usuarios, texto),
    ),);
  }

  // ── Selección múltiple ─────────────────────────────────────────────────────

  /// Activa el modo selección con el primer usuario seleccionado (long press).
  void activarSeleccion(String usuarioId) {
    final cargados = _extraerCargados(state);
    if (cargados == null) return;
    emit(cargados.copiarCon(
      modoSeleccion: true,
      seleccionados: {usuarioId},
    ),);
  }

  /// Alterna la selección de un usuario. Sale del modo selección si quedan 0.
  void toggleSeleccion(String usuarioId) {
    final cargados = _extraerCargados(state);
    if (cargados == null) return;
    final nuevos = Set<String>.from(cargados.seleccionados);
    if (nuevos.contains(usuarioId)) {
      nuevos.remove(usuarioId);
    } else {
      nuevos.add(usuarioId);
    }
    emit(cargados.copiarCon(
      seleccionados: nuevos,
      modoSeleccion: nuevos.isNotEmpty,
    ),);
  }

  /// Sale del modo selección limpiando toda selección.
  void salirModoSeleccion() {
    final cargados = _extraerCargados(state);
    if (cargados == null) return;
    emit(cargados.copiarCon(
      modoSeleccion: false,
      seleccionados: {},
      limpiarError:  true,
    ),);
  }

  // ── Selectores para modales ────────────────────────────────────────────────

  Future<List<({String id, String nombre})>> cargarRolesParaSelector() =>
      _repositorio.obtenerRolesActivos();

  Future<List<({String id, String nombre, String tipo})>> cargarTagsParaSelector() =>
      _repositorio.obtenerTagsActivos();

  // ── Acciones en lote ───────────────────────────────────────────────────────

  Future<void> asignarRolLote(String rolId, String adminId) async {
    final cargados = _extraerCargados(state);
    if (cargados == null || cargados.seleccionados.isEmpty) return;
    final ids = cargados.seleccionados.toList();

    emit(cargados.copiarCon(estaEjecutandoLote: true, limpiarError: true));
    try {
      await _repositorio.asignarRolLote(ids, rolId, adminId);
      if (isClosed) return;
      await cargar();
    } on FallaServidor catch (e) {
      if (isClosed) return;
      _emitirErrorLote(e.mensaje);
    } on FallaInesperada catch (e) {
      if (isClosed) return;
      _emitirErrorLote(e.mensaje);
    }
  }

  Future<void> asignarTagLote(String tagId, String adminId) async {
    final cargados = _extraerCargados(state);
    if (cargados == null || cargados.seleccionados.isEmpty) return;
    final ids = cargados.seleccionados.toList();

    emit(cargados.copiarCon(estaEjecutandoLote: true, limpiarError: true));
    try {
      await _repositorio.asignarTagLote(ids, tagId, adminId);
      if (isClosed) return;
      await cargar();
    } on FallaServidor catch (e) {
      if (isClosed) return;
      _emitirErrorLote(e.mensaje);
    } on FallaInesperada catch (e) {
      if (isClosed) return;
      _emitirErrorLote(e.mensaje);
    }
  }

  Future<void> suspenderLote() async {
    final cargados = _extraerCargados(state);
    if (cargados == null || cargados.seleccionados.isEmpty) return;
    final ids = cargados.seleccionados.toList();

    emit(cargados.copiarCon(estaEjecutandoLote: true, limpiarError: true));
    try {
      await _repositorio.suspenderLote(ids);
      if (isClosed) return;
      await cargar();
    } on FallaServidor catch (e) {
      if (isClosed) return;
      _emitirErrorLote(e.mensaje);
    } on FallaInesperada catch (e) {
      if (isClosed) return;
      _emitirErrorLote(e.mensaje);
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  void _emitirErrorLote(String mensaje) {
    final actual = _extraerCargados(state);
    if (actual == null) return;
    emit(actual.copiarCon(estaEjecutandoLote: false, errorLote: mensaje));
  }

  UsuariosCargados? _extraerCargados(UsuariosEstado estado) => switch (estado) {
    UsuariosCargados()         => estado,
    UsuariosOperacionFallida() => estado.anterior,
    _                          => null,
  };

  List<UsuarioItem> _aplicarFiltro(List<UsuarioItem> usuarios, String busqueda) {
    if (busqueda.trim().isEmpty) return usuarios;
    final q = busqueda.toLowerCase();
    return usuarios.where((u) =>
        u.nombreCompleto.toLowerCase().contains(q)                        ||
        u.correo.toLowerCase().contains(q)                                ||
        (u.numeroIdentificacion?.toLowerCase().contains(q) ?? false),
    ).toList();
  }
}
