import 'package:flutter_bloc/flutter_bloc.dart';

import '../../compartido/errores.dart';
import 'historial_estado.dart';
import 'historial_repositorio.dart';

class HistorialCubit extends Cubit<HistorialEstado> {
  HistorialCubit(this._repositorio) : super(const HistorialInicial());

  final HistorialRepositorio _repositorio;

  /// Carga el historial de asistencia del usuario.
  Future<void> cargar(String usuarioId) async {
    emit(const HistorialCargando());
    try {
      final items = await _repositorio.obtenerHistorial(usuarioId);
      if (isClosed) return;
      emit(HistorialCargado(items: items));
    } on FallaServidor catch (falla) {
      if (isClosed) return;
      emit(HistorialError(falla.mensaje));
    } on FallaInesperada catch (falla) {
      if (isClosed) return;
      emit(HistorialError(falla.mensaje));
    }
  }
}
