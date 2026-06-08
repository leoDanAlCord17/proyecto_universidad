import 'dart:async' show unawaited;

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../compartido/errores.dart';
import '../../compartido/logger.dart';
import 'usuario_item.dart';
import 'usuarios_estado.dart';
import 'usuarios_repositorio.dart';

class UsuariosCubit extends Cubit<UsuariosEstado> {
  UsuariosCubit(this._repositorio) : super(const UsuariosInicial());

  final UsuariosRepositorio _repositorio;

  String _busqueda = '';
  List<UsuarioItem> _todos = [];
  int _offset = 0;

  // ── Carga inicial ──────────────────────────────────────────────────────────

  Future<void> cargar() async {
    _offset = 0;
    _todos = [];
    emit(const UsuariosCargando());
    try {
      final resultado = await _repositorio.obtenerUsuarios(offset: 0);
      if (isClosed) return;
      _todos = resultado.usuarios;
      _offset = resultado.usuarios.length;
      emit(
        UsuariosCargados(
          usuarios: _todos,
          usuariosFiltrados: _aplicarFiltro(_todos, _busqueda),
          hayMas: resultado.hayMas,
        ),
      );
    } on FallaServidor catch (e) {
      if (isClosed) return;
      reportarError(e);
      emit(UsuariosError(mensaje: e.mensaje));
    } on FallaRed catch (e) {
      if (isClosed) return;
      reportarError(e);
      emit(UsuariosError(mensaje: e.mensaje));
    } on FallaInesperada catch (e) {
      if (isClosed) return;
      reportarError(e);
      emit(UsuariosError(mensaje: e.mensaje));
    }
  }

  Future<void> cargarMas() async {
    final estado = state;
    if (estado is! UsuariosCargados || !estado.hayMas) return;

    emit(
      UsuariosCargandoMas(
        usuarios: estado.usuarios,
        usuariosFiltrados: estado.usuariosFiltrados,
        seleccionados: estado.seleccionados,
        modoSeleccion: estado.modoSeleccion,
      ),
    );
    try {
      final resultado = await _repositorio.obtenerUsuarios(offset: _offset);
      if (isClosed) return;
      _todos = [...estado.usuarios, ...resultado.usuarios];
      _offset += resultado.usuarios.length;
      emit(
        UsuariosCargados(
          usuarios: _todos,
          usuariosFiltrados: _busqueda.trim().isEmpty
              ? _todos
              : _aplicarFiltro(_todos, _busqueda),
          hayMas: resultado.hayMas,
          seleccionados: estado.seleccionados,
          modoSeleccion: estado.modoSeleccion,
        ),
      );
    } catch (_) {
      if (isClosed) return;
      emit(estado);
    }
  }

  // ── Suspender usuario individual ───────────────────────────────────────────

  Future<void> suspender(String usuarioId) async {
    final cargados = _extraerCargados(state);
    if (cargados == null) return;
    try {
      await _repositorio.suspenderUsuario(usuarioId);
      await cargar();
      try {
        unawaited(
          Supabase.instance.client.functions.invoke(
            'enviar-notificacion',
            body: {
              'usuario_ids': [usuarioId],
              'titulo': 'Cuenta suspendida',
              'cuerpo': 'Tu cuenta ha sido suspendida.',
            },
          ),
        );
      } catch (e) {
        log.w('No se pudo enviar notificación push', error: e);
      }
    } on FallaServidor catch (e) {
      reportarError(e);
      emit(UsuariosOperacionFallida(anterior: cargados, mensaje: e.mensaje));
    } on FallaInesperada catch (e) {
      reportarError(e);
      emit(UsuariosOperacionFallida(anterior: cargados, mensaje: e.mensaje));
    }
  }

  // ── Filtrado ───────────────────────────────────────────────────────────────

  void filtrar(String texto) {
    _busqueda = texto;
    final estado = state;
    final filtrados = switch (estado) {
      UsuariosCargados() => texto.trim().isEmpty
          ? estado.usuarios
          : _aplicarFiltro(estado.usuarios, texto),
      UsuariosCargandoMas() => texto.trim().isEmpty
          ? estado.usuarios
          : _aplicarFiltro(estado.usuarios, texto),
      _ => null,
    };
    if (filtrados == null) return;
    switch (estado) {
      case UsuariosCargados():
        emit(estado.copiarCon(usuariosFiltrados: filtrados));
      case UsuariosCargandoMas():
        emit(
          UsuariosCargandoMas(
            usuarios: estado.usuarios,
            usuariosFiltrados: filtrados,
            seleccionados: estado.seleccionados,
            modoSeleccion: estado.modoSeleccion,
          ),
        );
      default:
        break;
    }
  }

  // ── Selección múltiple ─────────────────────────────────────────────────────

  /// Activa el modo selección con el primer usuario seleccionado (long press).
  void activarSeleccion(String usuarioId) {
    final cargados = _extraerCargados(state);
    if (cargados == null) return;
    emit(
      cargados.copiarCon(
        modoSeleccion: true,
        seleccionados: {usuarioId},
      ),
    );
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
    emit(
      cargados.copiarCon(
        seleccionados: nuevos,
        modoSeleccion: nuevos.isNotEmpty,
      ),
    );
  }

  /// Sale del modo selección limpiando toda selección.
  void salirModoSeleccion() {
    final cargados = _extraerCargados(state);
    if (cargados == null) return;
    emit(
      cargados.copiarCon(
        modoSeleccion: false,
        seleccionados: {},
        limpiarError: true,
      ),
    );
  }

  // ── Selectores para modales ────────────────────────────────────────────────

  Future<List<({String id, String nombre})>> cargarRolesParaSelector() =>
      _repositorio.obtenerRolesActivos();

  Future<List<({String id, String nombre, String tipo})>>
      cargarTagsParaSelector() => _repositorio.obtenerTagsActivos();

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
      try {
        unawaited(
          Supabase.instance.client.functions.invoke(
            'enviar-notificacion',
            body: {
              'usuario_ids': ids,
              'titulo': 'Nuevo rol asignado',
              'cuerpo': 'Se te asignó un nuevo rol en el sistema.',
            },
          ),
        );
      } catch (e) {
        log.w('No se pudo enviar notificación push', error: e);
      }
    } on FallaServidor catch (e) {
      if (isClosed) return;
      reportarError(e);
      _emitirErrorLote(e.mensaje);
    } on FallaInesperada catch (e) {
      if (isClosed) return;
      reportarError(e);
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
      reportarError(e);
      _emitirErrorLote(e.mensaje);
    } on FallaInesperada catch (e) {
      if (isClosed) return;
      reportarError(e);
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
      try {
        unawaited(
          Supabase.instance.client.functions.invoke(
            'enviar-notificacion',
            body: {
              'usuario_ids': ids,
              'titulo': 'Cuenta suspendida',
              'cuerpo': 'Tu cuenta ha sido suspendida.',
            },
          ),
        );
      } catch (e) {
        log.w('No se pudo enviar notificación push', error: e);
      }
    } on FallaServidor catch (e) {
      if (isClosed) return;
      reportarError(e);
      _emitirErrorLote(e.mensaje);
    } on FallaInesperada catch (e) {
      if (isClosed) return;
      reportarError(e);
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
        UsuariosCargados() => estado,
        UsuariosOperacionFallida() => estado.anterior,
        UsuariosCargandoMas() => UsuariosCargados(
            usuarios: estado.usuarios,
            usuariosFiltrados: estado.usuariosFiltrados,
            seleccionados: estado.seleccionados,
            modoSeleccion: estado.modoSeleccion,
            hayMas: true,
          ),
        _ => null,
      };

  List<UsuarioItem> _aplicarFiltro(
      List<UsuarioItem> usuarios, String busqueda) {
    if (busqueda.trim().isEmpty) return usuarios;
    final q = busqueda.toLowerCase();
    return usuarios
        .where(
          (u) =>
              u.nombreCompleto.toLowerCase().contains(q) ||
              u.correo.toLowerCase().contains(q) ||
              (u.numeroIdentificacion?.toLowerCase().contains(q) ?? false),
        )
        .toList();
  }
}
