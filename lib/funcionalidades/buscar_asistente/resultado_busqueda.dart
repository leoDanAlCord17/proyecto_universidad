import 'package:equatable/equatable.dart';

import '../../compartido/constantes.dart';

class ResultadoBusqueda extends Equatable {

  factory ResultadoBusqueda.desdeUsuario(
    Map<String, dynamic> fila, {
    Map<String, dynamic>? asistencia,
    String?               registradoPorNombre,
  }) {
    final pN    = fila['primer_nombre']  as String? ?? '';
    final pA    = fila['primer_apellido'] as String? ?? '';
    final nombre = '$pN $pA'.trim();
    return ResultadoBusqueda(
      usuarioId:            fila['id']                    as String,
      nombre:               nombre.isNotEmpty ? nombre    : 'Sin nombre',
      iniciales:            _iniciales(nombre),
      urlFoto:              fila['url_avatar']             as String?,
      numeroIdentificacion: fila['numero_identificacion']  as String?,
      asistenciaId:         asistencia?['id']              as String?,
      estatus:              asistencia?['estatus']          as String?,
      horaEntrada:          _parsearHora(asistencia?['hora_entrada'] as String?),
      horaSalida:           _parsearHora(asistencia?['hora_salida']  as String?),
      registradoPorNombre:  registradoPorNombre,
    );
  }

  factory ResultadoBusqueda.desdeForaneo(Map<String, dynamic> fila) {
    final pN    = fila['visitante_primer_nombre']   as String? ?? '';
    final pA    = fila['visitante_primer_apellido'] as String? ?? '';
    final nombre = '$pN $pA'.trim();
    return ResultadoBusqueda(
      usuarioId:    fila['id']       as String,
      nombre:       nombre.isNotEmpty ? nombre : 'Visitante',
      iniciales:    _iniciales(nombre.isNotEmpty ? nombre : 'Visitante'),
      asistenciaId: fila['id']       as String?,
      estatus:      fila['estatus']  as String?,
      horaEntrada:  _parsearHora(fila['hora_entrada'] as String?),
      esForaneo:    true,
    );
  }
  const ResultadoBusqueda({
    required this.usuarioId,
    required this.nombre,
    required this.iniciales,
    this.urlFoto,
    this.numeroIdentificacion,
    this.asistenciaId,
    this.estatus,
    this.horaEntrada,
    this.horaSalida,
    this.registradoPorNombre,
    this.esForaneo = false,
  });

  /// ID del usuario (sistema) o ID del registro asistencia (foráneo).
  final String  usuarioId;
  final String  nombre;
  final String  iniciales;
  final String? urlFoto;
  final String? numeroIdentificacion;

  /// ID del registro en la tabla asistencia, null si no tiene registro aún.
  final String? asistenciaId;

  /// null = usuario sin registro en el evento (no esperado).
  final String? estatus;
  final String? horaEntrada;
  final String? horaSalida;
  final String? registradoPorNombre;
  final bool    esForaneo;

  bool get estaActivo =>
      estatus == EstatusAsistencia.presente ||
      estatus == EstatusAsistencia.completado ||
      estatus == EstatusAsistencia.salioAnticipado;

  bool get esEsperado  => estatus == EstatusAsistencia.esperado;
  bool get esNoEsperado => !esForaneo && estatus == null;

  static String _iniciales(String nombre) {
    final partes = nombre.split(' ').where((p) => p.isNotEmpty).toList();
    if (partes.length >= 2) return '${partes[0][0]}${partes[1][0]}'.toUpperCase();
    return nombre.isNotEmpty ? nombre[0].toUpperCase() : '?';
  }

  static String? _parsearHora(String? isoString) {
    if (isoString == null) return null;
    final dt = DateTime.tryParse(isoString)?.toLocal();
    if (dt == null) return null;
    final h12  = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final min  = dt.minute.toString().padLeft(2, '0');
    final ampm = dt.hour < 12 ? 'AM' : 'PM';
    return '$h12:$min $ampm';
  }

  @override
  List<Object?> get props =>
      [usuarioId, estatus, horaEntrada, horaSalida, registradoPorNombre, esForaneo];
}
