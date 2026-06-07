import 'package:equatable/equatable.dart';

import '../../compartido/constantes.dart';

class AsistenteItem extends Equatable {
  factory AsistenteItem.desdeJson(
    Map<String, dynamic> json, {
    bool eraEsperado = false,
  }) {
    final usuarioId = json['usuario_id'] as String?;
    final esForaneo = usuarioId == null;

    final String nombre;
    final String? detalle;
    final String? urlFoto;

    if (!esForaneo) {
      final u = json['usuarios'] as Map<String, dynamic>?;
      final pNombre = u?['primer_nombre'] as String? ?? '';
      final pApellido = u?['primer_apellido'] as String? ?? '';
      nombre = '$pNombre $pApellido'.trim();
      detalle = u?['numero_identificacion'] as String?;
      urlFoto = u?['url_avatar'] as String?;
    } else {
      final vPN = json['visitante_primer_nombre'] as String? ?? '';
      final vPA = json['visitante_primer_apellido'] as String? ?? '';
      final nombreVisit = '$vPN $vPA'.trim();
      nombre = nombreVisit.isNotEmpty ? nombreVisit : 'Visitante';
      detalle = json['visitante_contacto'] as String?;
      urlFoto = null;
    }

    final partes = nombre.split(' ').where((p) => p.isNotEmpty).toList();
    final iniciales = partes.length >= 2
        ? '${partes[0][0]}${partes[1][0]}'.toUpperCase()
        : nombre.isNotEmpty
            ? nombre[0].toUpperCase()
            : '?';

    final reg = json['registrador'] as Map<String, dynamic>?;
    final regN = reg?['primer_nombre'] as String? ?? '';
    final regA = reg?['primer_apellido'] as String? ?? '';
    final regNombre = reg != null
        ? '$regN $regA'.trim().isNotEmpty
            ? '$regN $regA'.trim()
            : null
        : null;

    return AsistenteItem(
      id: json['id'] as String,
      usuarioId: usuarioId,
      nombre: nombre,
      detalle: detalle,
      urlFoto: urlFoto,
      iniciales: iniciales,
      estatus: json['estatus'] as String? ?? EstatusAsistencia.esperado,
      esForaneo: esForaneo,
      eraEsperado: eraEsperado,
      horaEntrada: _parsearHora(json['hora_entrada'] as String?),
      horaSalida: _parsearHora(json['hora_salida'] as String?),
      registradoPorNombre: regNombre,
    );
  }
  const AsistenteItem({
    required this.id,
    required this.nombre,
    required this.iniciales,
    required this.estatus,
    required this.esForaneo,
    required this.eraEsperado,
    this.usuarioId,
    this.detalle,
    this.urlFoto,
    this.horaEntrada,
    this.horaSalida,
    this.registradoPorNombre,
  });

  final String id;
  final String? usuarioId;
  final String nombre;

  /// Número de identificación (sistema) o contacto (foráneo).
  final String? detalle;
  final String? urlFoto;
  final String iniciales;
  final String estatus;
  final bool esForaneo;

  /// true si el usuario estaba en la audiencia definida del evento.
  final bool eraEsperado;

  final String? horaEntrada;
  final String? horaSalida;
  final String? registradoPorNombre;

  bool get esRegistrado =>
      estatus == EstatusAsistencia.presente ||
      estatus == EstatusAsistencia.completado;

  bool get esAbandono => estatus == EstatusAsistencia.salioAnticipado;

  String get etiquetaDetalle {
    switch (estatus) {
      case EstatusAsistencia.presente:
        return horaEntrada != null ? 'Entrada $horaEntrada' : 'Presente';
      case EstatusAsistencia.completado:
        return horaEntrada != null ? 'Entrada $horaEntrada' : 'Completado';
      case EstatusAsistencia.salioAnticipado:
        return horaSalida != null ? 'Salió $horaSalida' : 'Salida anticipada';
      case EstatusAsistencia.ausente:
        return 'Ausente';
      case EstatusAsistencia.anulado:
        return 'Anulado';
      default:
        return detalle ?? 'Sin registro aún';
    }
  }

  AsistenteItem copiarCon({bool? eraEsperado}) => AsistenteItem(
        id: id,
        usuarioId: usuarioId,
        nombre: nombre,
        detalle: detalle,
        urlFoto: urlFoto,
        iniciales: iniciales,
        estatus: estatus,
        esForaneo: esForaneo,
        eraEsperado: eraEsperado ?? this.eraEsperado,
        horaEntrada: horaEntrada,
        horaSalida: horaSalida,
        registradoPorNombre: registradoPorNombre,
      );

  static String? _parsearHora(String? isoString) {
    if (isoString == null) return null;
    final dt = DateTime.tryParse(isoString)?.toLocal();
    if (dt == null) return null;
    final h12 = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final min = dt.minute.toString().padLeft(2, '0');
    final ampm = dt.hour < 12 ? 'AM' : 'PM';
    return '$h12:$min $ampm';
  }

  @override
  List<Object?> get props =>
      [id, usuarioId, nombre, estatus, esForaneo, eraEsperado, horaSalida];
}
