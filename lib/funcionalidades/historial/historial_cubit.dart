import 'package:flutter_bloc/flutter_bloc.dart';

import '../../compartido/errores.dart';
import '../../compartido/logger.dart';
import 'historial_estado.dart';
import 'historial_repositorio.dart';

class HistorialCubit extends Cubit<HistorialEstado> {
  HistorialCubit(this._repositorio) : super(const HistorialInicial());

  final HistorialRepositorio _repositorio;

  String? _usuarioId;
  int     _offset = 0;

  /// Carga la primera página del historial (reinicia el offset).
  Future<void> cargar(String usuarioId) async {
    _usuarioId = usuarioId;
    _offset    = 0;
    emit(const HistorialCargando());
    try {
      final resultado = await _repositorio.obtenerHistorial(usuarioId, offset: _offset);
      if (isClosed) return;
      _offset += resultado.items.length;
      emit(HistorialCargado(items: resultado.items, hayMas: resultado.hayMas));
    } on FallaServidor catch (falla) {
      if (isClosed) return;
      reportarError(falla);
      emit(HistorialError(falla.mensaje));
    } on FallaRed catch (falla) {
      if (isClosed) return;
      reportarError(falla);
      emit(HistorialError(falla.mensaje));
    } on FallaInesperada catch (falla) {
      if (isClosed) return;
      reportarError(falla);
      emit(HistorialError(falla.mensaje));
    }
  }

  /// Carga la siguiente página y la acumula a los items ya visibles.
  /// Si falla, restaura el estado [HistorialCargado] anterior sin perder datos.
  Future<void> cargarMas() async {
    final estado    = state;
    final usuarioId = _usuarioId;
    if (estado is! HistorialCargado || !estado.hayMas || usuarioId == null) return;

    emit(HistorialCargandoMas(items: estado.items));
    try {
      final resultado = await _repositorio.obtenerHistorial(usuarioId, offset: _offset);
      if (isClosed) return;
      _offset += resultado.items.length;
      emit(HistorialCargado(
        items:  [...estado.items, ...resultado.items],
        hayMas: resultado.hayMas,
      ),);
    } catch (_) {
      if (isClosed) return;
      emit(HistorialCargado(items: estado.items, hayMas: estado.hayMas));
    }
  }
}
