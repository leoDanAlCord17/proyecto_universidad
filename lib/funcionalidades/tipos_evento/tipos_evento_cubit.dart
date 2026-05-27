import 'package:flutter_bloc/flutter_bloc.dart';

import '../../compartido/errores.dart';
import 'tipos_evento_estado.dart';
import 'tipos_evento_repositorio.dart';

class TiposEventoCubit extends Cubit<TiposEventoEstado> {
  TiposEventoCubit(this._repositorio) : super(const TiposEventoInicial());

  final TiposEventoRepositorio _repositorio;

  Future<void> cargar() async {
    emit(const TiposEventoCargando());
    try {
      final items = await _repositorio.obtenerTiposEvento();
      emit(TiposEventoCargados(items: items, filtrados: items));
    } on FallaServidor catch (falla) {
      emit(TiposEventoError(mensaje: falla.mensaje));
    } on FallaInesperada catch (falla) {
      emit(TiposEventoError(mensaje: falla.mensaje));
    }
  }

  void filtrar(String texto) {
    final estadoActual = state;
    if (estadoActual is! TiposEventoCargados) return;
    if (texto.trim().isEmpty) {
      emit(estadoActual.copiarCon(filtrados: estadoActual.items));
      return;
    }
    final busqueda = texto.toLowerCase();
    emit(estadoActual.copiarCon(
      filtrados: estadoActual.items
          .where((tipo) =>
              tipo.nombre.toLowerCase().contains(busqueda) ||
              tipo.descripcion.toLowerCase().contains(busqueda),)
          .toList(),
    ),);
  }

  Future<void> desactivar(String id) async {
    final estadoActual = state;
    if (estadoActual is! TiposEventoCargados) return;
    emit(estadoActual.copiarCon(estaDesactivando: true));
    try {
      await _repositorio.desactivarTipoEvento(id);
      await cargar();
    } on FallaServidor catch (falla) {
      emit(TiposEventoCargados(
        items:            estadoActual.items,
        filtrados:        estadoActual.filtrados,
        estaDesactivando: false,
        errorOperacion:   falla.mensaje,
      ),);
    } on FallaInesperada catch (falla) {
      emit(TiposEventoCargados(
        items:            estadoActual.items,
        filtrados:        estadoActual.filtrados,
        estaDesactivando: false,
        errorOperacion:   falla.mensaje,
      ),);
    }
  }
}
