import 'package:flutter_bloc/flutter_bloc.dart';

import '../../compartido/errores.dart';
import 'tag.dart';
import 'tags_estado.dart';
import 'tags_repositorio.dart';

class TagsCubit extends Cubit<TagsEstado> {
  TagsCubit(this._repositorio) : super(const TagsInicial());

  final TagsRepositorio _repositorio;
  String _busqueda = '';

  Future<void> cargarTags() async {
    emit(const TagsCargando());
    try {
      final tags = await _repositorio.obtenerTags();
      emit(TagsCargados(
        tags:          tags,
        tagsFiltrados: _aplicarFiltro(tags, _busqueda),
      ),);
    } on FallaServidor catch (e) {
      emit(TagsError(mensaje: e.mensaje));
    } on FallaInesperada catch (e) {
      emit(TagsError(mensaje: e.mensaje));
    }
  }

  void filtrar(String texto) {
    final estadoActual = state;
    if (estadoActual is! TagsCargados) return;
    _busqueda = texto;
    if (texto.trim().isEmpty) {
      emit(estadoActual.copiarCon(tagsFiltrados: estadoActual.tags));
      return;
    }
    emit(estadoActual.copiarCon(tagsFiltrados: _aplicarFiltro(estadoActual.tags, texto)));
  }

  Future<void> activar(String id) async {
    final e = state;
    if (e is! TagsCargados) return;
    try {
      await _repositorio.activarTag(id);
    } on FallaServidor catch (err) {
      emit(TagsOperacionFallida(anterior: e, mensaje: err.mensaje));
      return;
    } on FallaInesperada catch (err) {
      emit(TagsOperacionFallida(anterior: e, mensaje: err.mensaje));
      return;
    }
    await cargarTags();
  }

  Future<void> desactivar(String id) async {
    final e = state;
    if (e is! TagsCargados) return;
    try {
      await _repositorio.desactivarTag(id);
    } on FallaServidor catch (err) {
      emit(TagsOperacionFallida(anterior: e, mensaje: err.mensaje));
      return;
    } on FallaInesperada catch (err) {
      emit(TagsOperacionFallida(anterior: e, mensaje: err.mensaje));
      return;
    }
    await cargarTags();
  }

  List<Tag> _aplicarFiltro(List<Tag> tags, String busqueda) {
    if (busqueda.trim().isEmpty) return tags;
    final q = busqueda.toLowerCase();
    return tags.where((t) =>
        t.nombre.toLowerCase().contains(q) ||
        t.descripcion.toLowerCase().contains(q) ||
        t.tipo.toLowerCase().contains(q),).toList();
  }
}
