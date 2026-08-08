import 'package:equatable/equatable.dart';

/// Una fila de la tabla `configuracion` — un interruptor o número ajustable
/// que controla el comportamiento de la app en tiempo real, sin necesidad
/// de publicar una nueva versión.
class ConfiguracionItem extends Equatable {
  factory ConfiguracionItem.desdeJson(Map<String, dynamic> json) =>
      ConfiguracionItem(
        id: json['id'] as String,
        clave: json['clave'] as String,
        valor: json['valor'] as int,
        tipo: json['tipo'] as String,
        descripcion: json['descripcion'] as String,
        modulo: json['modulo'] as String,
        estatus: json['estatus'] as bool,
      );

  const ConfiguracionItem({
    required this.id,
    required this.clave,
    required this.valor,
    required this.tipo,
    required this.descripcion,
    required this.modulo,
    required this.estatus,
  });

  final String id;
  final String clave;
  final int valor;
  final String tipo;
  final String descripcion;
  final String modulo;

  /// Si esta configuración está activa. Con estatus=false, el resto de la
  /// app la trata como si no existiera (ver ej. obtenerPuedeEditarPerfil en
  /// perfil_repositorio.dart), sin importar el valor que tenga.
  final bool estatus;

  bool get esBooleano => tipo == 'boolean';
  bool get valorBooleano => valor == 1;

  /// clave en snake_case → texto legible para mostrar en pantalla.
  /// La descripción (escrita por un humano) explica el qué; esto solo
  /// presenta el nombre técnico de forma más amigable como encabezado.
  String get tituloLegible => clave
      .split('_')
      .map((p) => p.isEmpty ? p : '${p[0].toUpperCase()}${p.substring(1)}')
      .join(' ');

  ConfiguracionItem copiarCon({int? valor, bool? estatus}) => ConfiguracionItem(
        id: id,
        clave: clave,
        valor: valor ?? this.valor,
        tipo: tipo,
        descripcion: descripcion,
        modulo: modulo,
        estatus: estatus ?? this.estatus,
      );

  @override
  List<Object?> get props =>
      [id, clave, valor, tipo, descripcion, modulo, estatus];
}
