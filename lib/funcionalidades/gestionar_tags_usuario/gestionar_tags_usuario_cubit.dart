import 'package:flutter_bloc/flutter_bloc.dart';

import '../../compartido/errores.dart';
import 'gestionar_tags_usuario_estado.dart';
import 'gestionar_tags_usuario_repositorio.dart';

class GestionarTagsUsuarioCubit extends Cubit<GestionarTagsUsuarioEstado> {
  GestionarTagsUsuarioCubit(this._repositorio)
      : super(const GestionarTagsUsuarioInicial());

  final GestionarTagsUsuarioRepositorio _repositorio;
  String? _usuarioId;
  String? _adminId;

  Future<void> cargar(String usuarioId, {String? adminId}) async {
    _usuarioId = usuarioId;
    _adminId   = adminId;
    emit(const GestionarTagsUsuarioCargando());
    try {
      final info           = await _repositorio.obtenerInfoUsuario(usuarioId);
      final tagsUsuario    = await _repositorio.obtenerTagsUsuario(usuarioId);
      final todosLosTags   = await _repositorio.obtenerTagsActivos();
      final maxSecundarios = await _repositorio.obtenerMaxTagsSecundarios();

      final idsAsignados = {
        if (tagsUsuario.tagPrincipal != null) tagsUsuario.tagPrincipal!.id,
        ...tagsUsuario.tagsSecundarios.map((t) => t.id),
      };

      emit(GestionarTagsUsuarioCargado(
        nombreUsuario:          info.nombre,
        correoUsuario:          info.correo,
        tagPrincipal:           tagsUsuario.tagPrincipal,
        tagsSecundarios:        tagsUsuario.tagsSecundarios,
        principalesDisponibles: todosLosTags.where((t) =>  t.esPrincipal).toList(),
        secundariosDisponibles: todosLosTags.where((t) => !t.esPrincipal && !idsAsignados.contains(t.id)).toList(),
        maxSecundarios:         maxSecundarios,
      ),);
    } on FallaServidor catch (e) {
      emit(GestionarTagsUsuarioError(mensaje: e.mensaje));
    } on FallaInesperada catch (e) {
      emit(GestionarTagsUsuarioError(mensaje: e.mensaje));
    }
  }

  Future<void> asignarPrincipal(String tagId) async {
    final e = state;
    if (e is! GestionarTagsUsuarioCargado) return;
    await _ejecutar(() async {
      if (e.tagPrincipal != null) {
        await _repositorio.quitarTag(_usuarioId!, e.tagPrincipal!.id, _adminId);
      }
      await _repositorio.asignarTag(_usuarioId!, tagId, _adminId);
    });
  }

  Future<void> quitarPrincipal() async {
    final e = state;
    if (e is! GestionarTagsUsuarioCargado || e.tagPrincipal == null) return;
    await _ejecutar(
      () => _repositorio.quitarTag(_usuarioId!, e.tagPrincipal!.id, _adminId),
    );
  }

  Future<void> agregarSecundario(String tagId) =>
      _ejecutar(() => _repositorio.asignarTag(_usuarioId!, tagId, _adminId));

  Future<void> quitarSecundario(String tagId) =>
      _ejecutar(() => _repositorio.quitarTag(_usuarioId!, tagId, _adminId));

  Future<void> _ejecutar(Future<void> Function() operacion) async {
    if (_usuarioId == null) return;
    final estadoActual = state;
    if (estadoActual is! GestionarTagsUsuarioCargado) return;
    try {
      await operacion();
      await cargar(_usuarioId!, adminId: _adminId);
    } on FallaServidor catch (e) {
      emit(GestionarTagsUsuarioOperacionFallida(anterior: estadoActual, mensaje: e.mensaje));
    } on FallaInesperada catch (e) {
      emit(GestionarTagsUsuarioOperacionFallida(anterior: estadoActual, mensaje: e.mensaje));
    }
  }
}
