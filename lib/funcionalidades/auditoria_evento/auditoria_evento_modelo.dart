class EventoParaAuditoria {

  factory EventoParaAuditoria.desdeJson(Map<String, dynamic> json) {
    DateTime? fecha;
    final fechaStr = json['fecha_inicio'] as String?;
    if (fechaStr != null) {
      try {
        fecha = DateTime.parse(fechaStr);
      } catch (_) {}
    }
    return EventoParaAuditoria(
      id:          (json['id']         as String?) ?? '',
      titulo:      (json['titulo']     as String?) ?? '',
      estatus:     (json['estatus']    as String?) ?? '',
      fechaInicio: fecha,
      horaInicio:  json['hora_inicio'] as String?,
    );
  }
  const EventoParaAuditoria({
    required this.id,
    required this.titulo,
    required this.estatus,
    this.fechaInicio,
    this.horaInicio,
  });

  final String    id;
  final String    titulo;
  final String    estatus;
  final DateTime? fechaInicio;
  final String?   horaInicio;

  String get etiquetaEstatus => switch (estatus) {
        'en_curso'   => 'En curso',
        'programado' => 'Programado',
        'finalizado' => 'Finalizado',
        'cancelado'  => 'Cancelado',
        'borrador'   => 'Borrador',
        _            => estatus,
      };

  static const _meses = [
    '', 'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
    'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre',
  ];

  String get fechaFormateada {
    if (fechaInicio == null) return 'Sin fecha';
    final d = fechaInicio!;
    return '${d.day} de ${_meses[d.month]}, ${d.year}';
  }
}

class RegistroAuditoria {

  factory RegistroAuditoria.desdeJson(Map<String, dynamic> json) {
    final asistente  = json['asistente']   as Map<String, dynamic>?;
    final regEntrada = json['reg_entrada'] as Map<String, dynamic>?;
    final regSalida  = json['reg_salida']  as Map<String, dynamic>?;

    final esForaneo  = json['usuario_id'] == null;

    String nombre;
    String iniciales;
    String? urlFoto;
    String? numeroIdentificacion;
    String? contactoForaneo;

    if (esForaneo) {
      final pNombre   = (json['visitante_primer_nombre']   as String?) ?? '';
      final pApellido = (json['visitante_primer_apellido'] as String?) ?? '';
      nombre              = '$pNombre $pApellido'.trim();
      iniciales           = _calcularIniciales(pNombre, pApellido);
      numeroIdentificacion = json['visitante_numero_identificacion'] as String?;
      contactoForaneo     = json['visitante_contacto']               as String?;
    } else {
      final pNombre   = (asistente?['primer_nombre']   as String?) ?? '';
      final pApellido = (asistente?['primer_apellido'] as String?) ?? '';
      nombre              = '$pNombre $pApellido'.trim();
      iniciales           = _calcularIniciales(pNombre, pApellido);
      urlFoto             = asistente?['url_avatar']            as String?;
      numeroIdentificacion = asistente?['numero_identificacion'] as String?;
    }

    if (nombre.isEmpty) nombre = 'Sin nombre';

    String? regPorNombre;
    if (regEntrada != null) {
      final rn = (regEntrada['primer_nombre']   as String?) ?? '';
      final ra = (regEntrada['primer_apellido'] as String?) ?? '';
      regPorNombre = '$rn $ra'.trim();
      if (regPorNombre.isEmpty) regPorNombre = null;
    }

    String? salidaRegPorNombre;
    if (regSalida != null) {
      final sn = (regSalida['primer_nombre']   as String?) ?? '';
      final sa = (regSalida['primer_apellido'] as String?) ?? '';
      salidaRegPorNombre = '$sn $sa'.trim();
      if (salidaRegPorNombre.isEmpty) salidaRegPorNombre = null;
    }

    final horaEntradaIso = json['hora_entrada'] as String?;
    final horaSalidaIso  = json['hora_salida']  as String?;

    return RegistroAuditoria(
      id:                        (json['id']     as String?) ?? '',
      usuarioId:                 json['usuario_id'] as String?,
      nombre:                    nombre,
      iniciales:                 iniciales,
      urlFoto:                   urlFoto,
      numeroIdentificacion:      numeroIdentificacion,
      estatus:                   (json['estatus'] as String?) ?? 'esperado',
      esForaneo:                 esForaneo,
      horaEntrada:               _formatearHora(horaEntradaIso),
      horaEntradaHora:           _extraerHora(horaEntradaIso),
      horaSalida:                _formatearHora(horaSalidaIso),
      registradoPorNombre:       regPorNombre,
      salidaRegistradaPorNombre: salidaRegPorNombre,
      motivoSalidaAnticipada:    json['motivo_salida_anticipada'] as String?,
      contactoForaneo:           contactoForaneo,
    );
  }
  const RegistroAuditoria({
    required this.id,
    required this.nombre,
    required this.iniciales,
    required this.estatus,
    required this.esForaneo,
    required this.horaEntrada,
    required this.horaSalida,
    this.usuarioId,
    this.urlFoto,
    this.numeroIdentificacion,
    this.horaEntradaHora,
    this.registradoPorNombre,
    this.salidaRegistradaPorNombre,
    this.motivoSalidaAnticipada,
    this.contactoForaneo,
  });

  final String    id;
  final String?   usuarioId;
  final String    nombre;
  final String    iniciales;
  final String?   urlFoto;
  final String?   numeroIdentificacion;
  final String    estatus;
  final bool      esForaneo;
  final String    horaEntrada;
  final int?      horaEntradaHora;
  final String    horaSalida;
  final String?   registradoPorNombre;
  final String?   salidaRegistradaPorNombre;
  final String?   motivoSalidaAnticipada;
  final String?   contactoForaneo;

  bool get haEntrado =>
      estatus == 'presente' ||
      estatus == 'completado' ||
      estatus == 'salio_anticipado';

  String get etiquetaEstatus => switch (estatus) {
        'presente'         => 'Presente',
        'completado'       => 'Completado',
        'ausente'          => 'Ausente',
        'esperado'         => 'Esperado',
        'salio_anticipado' => 'Anticipado',
        'anulado'          => 'Anulado',
        _                  => estatus,
      };

  static String _formatearHora(String? iso) {
    if (iso == null) return '';
    try {
      final dt = DateTime.parse(iso).toLocal();
      final hora = dt.hour;
      final min  = dt.minute.toString().padLeft(2, '0');
      final ampm = hora >= 12 ? 'PM' : 'AM';
      final h    = hora % 12 == 0 ? 12 : hora % 12;
      return '$h:$min $ampm';
    } catch (_) {
      return iso;
    }
  }

  static int? _extraerHora(String? iso) {
    if (iso == null) return null;
    try {
      return DateTime.parse(iso).toLocal().hour;
    } catch (_) {
      return null;
    }
  }

  static String _calcularIniciales(String nombre, String apellido) {
    final n = nombre.isNotEmpty   ? nombre[0].toUpperCase()   : '';
    final a = apellido.isNotEmpty ? apellido[0].toUpperCase() : '';
    return '$n$a'.trim().isNotEmpty ? '$n$a' : '?';
  }
}

class DatoTimeline {
  const DatoTimeline({
    required this.hora,
    required this.label,
    required this.cantidad,
  });

  final int    hora;
  final String label;
  final int    cantidad;
}

class DatoRegistrador {
  const DatoRegistrador({
    required this.nombre,
    required this.entradas,
  });

  final String nombre;
  final int    entradas;

  double porcentaje(int total) =>
      total == 0 ? 0 : (entradas / total * 100);
}

class ResumenAuditoria {

  factory ResumenAuditoria.calcular(List<RegistroAuditoria> registros) {
    int haEntradoC       = 0;
    int completadosC     = 0;
    int presentesC       = 0;
    int ausentesC        = 0;
    int salioAnticipadoC = 0;
    int foraneosC        = 0;
    int esperadosC       = 0;

    final conteoPorHora    = <int, int>{};
    final conteoRegEntrada = <String, int>{};

    for (final r in registros) {
      if (r.haEntrado) haEntradoC++;
      switch (r.estatus) {
        case 'completado':
          completadosC++;
        case 'presente':
          presentesC++;
        case 'ausente':
          ausentesC++;
        case 'salio_anticipado':
          salioAnticipadoC++;
        case 'esperado':
          esperadosC++;
      }
      if (r.esForaneo) foraneosC++;

      if (r.horaEntradaHora != null) {
        conteoPorHora[r.horaEntradaHora!] =
            (conteoPorHora[r.horaEntradaHora!] ?? 0) + 1;
      }

      if (r.registradoPorNombre != null) {
        conteoRegEntrada[r.registradoPorNombre!] =
            (conteoRegEntrada[r.registradoPorNombre!] ?? 0) + 1;
      }
    }

    final horasOrdenadas = conteoPorHora.keys.toList()..sort();
    final timeline = horasOrdenadas.map((h) {
      final ampm = h >= 12 ? 'PM' : 'AM';
      final hDisplay = h % 12 == 0 ? 12 : h % 12;
      return DatoTimeline(hora: h, label: '$hDisplay$ampm', cantidad: conteoPorHora[h]!);
    }).toList();

    final registradoresList = conteoRegEntrada.entries
        .map((e) => DatoRegistrador(nombre: e.key, entradas: e.value))
        .toList()
      ..sort((a, b) => b.entradas.compareTo(a.entradas));

    return ResumenAuditoria(
      totalRegistros:  registros.length,
      haEntrado:       haEntradoC,
      completados:     completadosC,
      presentes:       presentesC,
      ausentes:        ausentesC,
      salioAnticipado: salioAnticipadoC,
      foraneos:        foraneosC,
      esperados:       esperadosC,
      timelineEntradas: timeline,
      registradores:   registradoresList,
    );
  }
  const ResumenAuditoria({
    required this.totalRegistros,
    required this.haEntrado,
    required this.completados,
    required this.presentes,
    required this.ausentes,
    required this.salioAnticipado,
    required this.foraneos,
    required this.esperados,
    required this.timelineEntradas,
    required this.registradores,
  });

  final int                  totalRegistros;
  final int                  haEntrado;
  final int                  completados;
  final int                  presentes;
  final int                  ausentes;
  final int                  salioAnticipado;
  final int                  foraneos;
  final int                  esperados;
  final List<DatoTimeline>   timelineEntradas;
  final List<DatoRegistrador> registradores;

  double get tasaAsistencia =>
      totalRegistros == 0 ? 0 : (haEntrado / totalRegistros * 100);
}

enum FiltroParticipantes {
  todos,
  entraron,
  ausentes,
  salioAnticipado,
  foraneos,
}
