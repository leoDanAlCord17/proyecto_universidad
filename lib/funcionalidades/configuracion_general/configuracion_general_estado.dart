import 'package:equatable/equatable.dart';

import 'configuracion_item.dart';

sealed class ConfiguracionGeneralEstado extends Equatable {
  const ConfiguracionGeneralEstado();
}

final class ConfiguracionGeneralInicial extends ConfiguracionGeneralEstado {
  const ConfiguracionGeneralInicial();
  @override
  List<Object?> get props => [];
}

final class ConfiguracionGeneralCargando extends ConfiguracionGeneralEstado {
  const ConfiguracionGeneralCargando();
  @override
  List<Object?> get props => [];
}

final class ConfiguracionGeneralCargado extends ConfiguracionGeneralEstado {
  const ConfiguracionGeneralCargado({
    required this.items,
    this.guardando = const {},
    this.errorPuntual,
  });

  final List<ConfiguracionItem> items;

  /// IDs de las filas con un guardado en curso — deshabilita sus controles
  /// y muestra un indicador pequeño mientras dura la llamada al servidor.
  final Set<String> guardando;

  /// Mensaje de error de la última operación fallida, si la hay. Es
  /// transitorio: la pantalla lo muestra una vez (AvisoApp) y lo limpia.
  final String? errorPuntual;

  ConfiguracionGeneralCargado copiarCon({
    List<ConfiguracionItem>? items,
    Set<String>? guardando,
    String? errorPuntual,
    bool limpiarError = false,
  }) =>
      ConfiguracionGeneralCargado(
        items: items ?? this.items,
        guardando: guardando ?? this.guardando,
        errorPuntual: limpiarError ? null : (errorPuntual ?? this.errorPuntual),
      );

  @override
  List<Object?> get props => [items, guardando, errorPuntual];
}

final class ConfiguracionGeneralError extends ConfiguracionGeneralEstado {
  const ConfiguracionGeneralError(this.mensaje);
  final String mensaje;

  @override
  List<Object?> get props => [mensaje];
}
