import 'package:flutter_bloc/flutter_bloc.dart';

import '../../compartido/errores.dart';
import '../../compartido/logger.dart';
import 'configuracion_general_estado.dart';
import 'configuracion_general_repositorio.dart';
import 'configuracion_item.dart';

class ConfiguracionGeneralCubit extends Cubit<ConfiguracionGeneralEstado> {
  ConfiguracionGeneralCubit(this._repositorio)
      : super(const ConfiguracionGeneralInicial());

  final ConfiguracionGeneralRepositorio _repositorio;

  Future<void> cargar() async {
    emit(const ConfiguracionGeneralCargando());
    try {
      final items = await _repositorio.obtenerTodas();
      if (isClosed) return;
      emit(ConfiguracionGeneralCargado(items: items));
    } on FallaServidor catch (e) {
      reportarError(e);
      if (!isClosed) emit(ConfiguracionGeneralError(e.mensaje));
    } on FallaInesperada catch (e) {
      reportarError(e);
      if (!isClosed) emit(ConfiguracionGeneralError(e.mensaje));
    }
  }

  /// Cambia el valor (1/0 para booleanos, o el número para enteros). Lo
  /// aplica de forma optimista para que el switch/stepper responda al
  /// instante, y si el guardado falla, revierte solo esa fila y expone el
  /// error puntual para que la pantalla lo muestre una vez.
  Future<void> actualizarValor(String id, int nuevoValor) async {
    final estado = state;
    if (estado is! ConfiguracionGeneralCargado) return;

    final anteriores = estado.items;
    final indice = anteriores.indexWhere((i) => i.id == id);
    if (indice == -1) return;

    final optimistas = [...anteriores];
    optimistas[indice] = anteriores[indice].copiarCon(valor: nuevoValor);

    emit(
      estado.copiarCon(
        items: optimistas,
        guardando: {...estado.guardando, id},
        limpiarError: true,
      ),
    );

    try {
      await _repositorio.actualizarValor(id, nuevoValor);
      final actual = state;
      if (actual is ConfiguracionGeneralCargado) {
        emit(actual.copiarCon(guardando: actual.guardando.difference({id})));
      }
    } on FallaServidor catch (e) {
      reportarError(e);
      _revertir(id: id, anteriores: anteriores, mensaje: e.mensaje);
    } on FallaInesperada catch (e) {
      reportarError(e);
      _revertir(id: id, anteriores: anteriores, mensaje: e.mensaje);
    }
  }

  void _revertir({
    required String id,
    required List<ConfiguracionItem> anteriores,
    required String mensaje,
  }) {
    if (isClosed) return;
    final actual = state;
    if (actual is! ConfiguracionGeneralCargado) return;
    emit(
      actual.copiarCon(
        items: anteriores,
        guardando: actual.guardando.difference({id}),
        errorPuntual: mensaje,
      ),
    );
  }
}
