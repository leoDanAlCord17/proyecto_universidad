import 'package:flutter_bloc/flutter_bloc.dart';

import '../../compartido/errores.dart';
import 'usuario_item.dart';
import 'usuarios_estado.dart';
import 'usuarios_repositorio.dart';

class UsuariosCubit extends Cubit<UsuariosEstado> {
  UsuariosCubit(this._repositorio) : super(const UsuariosInicial());

  final UsuariosRepositorio _repositorio;
  String _busqueda = '';

  Future<void> cargar() async {
    emit(const UsuariosCargando());
    try {
      final usuarios = await _repositorio.obtenerUsuarios();
      emit(UsuariosCargados(
        usuarios:          usuarios,
        usuariosFiltrados: _aplicarFiltro(usuarios, _busqueda),
      ));
    } on FallaServidor catch (e) {
      emit(UsuariosError(mensaje: e.mensaje));
    } on FallaInesperada catch (e) {
      emit(UsuariosError(mensaje: e.mensaje));
    }
  }

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
    ));
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
