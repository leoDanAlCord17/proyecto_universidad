import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

/// Singleton que expone el estado de conectividad de red.
/// Funciona en web (navigator.onLine), Android e iOS sin cambios.
class ConectividadServicio {
  ConectividadServicio._();
  static final ConectividadServicio instancia = ConectividadServicio._();

  final _connectivity = Connectivity();

  Stream<bool> get enLinea => _connectivity.onConnectivityChanged.map(
        (resultados) => resultados.any((r) => r != ConnectivityResult.none),
      );

  Future<bool> get estaEnLinea async {
    final resultados = await _connectivity.checkConnectivity();
    return resultados.any((r) => r != ConnectivityResult.none);
  }
}
