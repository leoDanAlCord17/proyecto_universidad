import 'package:flutter_bloc/flutter_bloc.dart';

import '../../compartido/errores.dart';
import '../../compartido/logger.dart';
import 'tag.dart';
import 'tags_estado.dart';
import 'tags_repositorio.dart';

class TagsCubit extends Cubit<TagsEstado> {
  TagsCubit(this._repositorio) : super(const TagsInicial());

  final TagsRepositorio _repositorio;

  String _busqueda = '';
  int _offset = 0;

  Future<void> cargarTags() async {
    _offset = 0;
    emit(const TagsCargando());
    try {
      final resultado = await _repositorio.obtenerTags(offset: _offset);
      if (isClosed) return;
      _offset += resultado.tags.length;
      emit(
        TagsCargados(
          tags: resultado.tags,
          tagsFiltrados: _aplicarFiltro(resultado.tags, _busqueda),
          hayMas: resultado.hayMas,
        ),
      );
    } on FallaServidor catch (e) {
      if (isClosed) return;
      reportarError(e);
      emit(TagsError(mensaje: e.mensaje));
    } on FallaRed catch (e) {
      if (isClosed) return;
      reportarError(e);
      emit(TagsError(mensaje: e.mensaje));
    } on FallaInesperada catch (e) {
      if (isClosed) return;
      reportarError(e);
      emit(TagsError(mensaje: e.mensaje));
    }
  }

  Future<void> cargarMas() async {
    final estado = state;
    if (estado is! TagsCargados || !estado.hayMas) return;

    emit(
      TagsCargandoMas(
        tags: estado.tags,
        tagsFiltrados: estado.tagsFiltrados,
      ),
    );
    try {
      final resultado = await _repositorio.obtenerTags(offset: _offset);
      if (isClosed) return;
      _offset += resultado.tags.length;
      final todos = [...estado.tags, ...resultado.tags];
      emit(
        TagsCargados(
          tags: todos,
          tagsFiltrados: _aplicarFiltro(todos, _busqueda),
          hayMas: resultado.hayMas,
        ),
      );
    } catch (_) {
      if (isClosed) return;
      emit(
        TagsCargados(
          tags: estado.tags,
          tagsFiltrados: estado.tagsFiltrados,
          hayMas: estado.hayMas,
        ),
      );
    }
  }

  void filtrar(String texto) {
    _busqueda = texto;
    final estadoActual = state;
    final base = switch (estadoActual) {
      TagsCargados() => estadoActual.tags,
      TagsCargandoMas() => estadoActual.tags,
      _ => null,
    };
    if (base == null) return;

    final filtrados = _aplicarFiltro(base, texto);

    if (estadoActual is TagsCargados) {
      emit(estadoActual.copiarCon(tagsFiltrados: filtrados));
    } else if (estadoActual is TagsCargandoMas) {
      emit(TagsCargandoMas(tags: estadoActual.tags, tagsFiltrados: filtrados));
    }
  }

  Future<void> activar(String id) async {
    final e = state;
    if (e is! TagsCargados) return;
    try {
      await _repositorio.activarTag(id);
    } on FallaServidor catch (err) {
      reportarError(err);
      emit(TagsOperacionFallida(anterior: e, mensaje: err.mensaje));
      return;
    } on FallaInesperada catch (err) {
      reportarError(err);
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
      reportarError(err);
      emit(TagsOperacionFallida(anterior: e, mensaje: err.mensaje));
      return;
    } on FallaInesperada catch (err) {
      reportarError(err);
      emit(TagsOperacionFallida(anterior: e, mensaje: err.mensaje));
      return;
    }
    await cargarTags();
  }

  List<Tag> _aplicarFiltro(List<Tag> tags, String busqueda) {
    if (busqueda.trim().isEmpty) return tags;
    final q = busqueda.toLowerCase();
    return tags
        .where(
          (t) =>
              t.nombre.toLowerCase().contains(q) ||
              t.descripcion.toLowerCase().contains(q) ||
              t.tipo.toLowerCase().contains(q),
        )
        .toList();
  }
}
