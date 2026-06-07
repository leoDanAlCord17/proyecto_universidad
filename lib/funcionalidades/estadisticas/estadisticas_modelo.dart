class ResumenEstadisticas {
  factory ResumenEstadisticas.desdeJson(Map<String, dynamic> json) =>
      ResumenEstadisticas(
        totalEventos: (json['total_eventos'] as num?)?.toInt() ?? 0,
        totalAsistencias: (json['total_asistencias'] as num?)?.toInt() ?? 0,
        tasaAsistencia: (json['tasa_asistencia'] as num?)?.toDouble() ?? 0.0,
        usuariosActivos: (json['usuarios_activos'] as num?)?.toInt() ?? 0,
      );
  const ResumenEstadisticas({
    required this.totalEventos,
    required this.totalAsistencias,
    required this.tasaAsistencia,
    required this.usuariosActivos,
  });

  final int totalEventos;
  final int totalAsistencias;
  final double tasaAsistencia;
  final int usuariosActivos;

  static ResumenEstadisticas vacio() => const ResumenEstadisticas(
        totalEventos: 0,
        totalAsistencias: 0,
        tasaAsistencia: 0.0,
        usuariosActivos: 0,
      );
}

/// Punto de dato genérico para gráficas simples.
/// [valorSql] es el valor interno en BD cuando [etiqueta] está traducida.
class DatoGrafica {
  const DatoGrafica({
    required this.etiqueta,
    required this.valor,
    this.valorSql,
  });

  final String etiqueta;
  final double valor;
  final String? valorSql;
}

class EventoTopStat {
  factory EventoTopStat.desdeJson(Map<String, dynamic> json) => EventoTopStat(
        titulo: (json['titulo'] as String?) ?? '',
        totalEsperados: (json['total'] as num?)?.toInt() ?? 0,
        totalPresentes: (json['presentes'] as num?)?.toInt() ?? 0,
      );
  const EventoTopStat({
    required this.titulo,
    required this.totalEsperados,
    required this.totalPresentes,
  });

  final String titulo;
  final int totalEsperados;
  final int totalPresentes;

  double get porcentajeAsistencia =>
      totalEsperados == 0 ? 0 : totalPresentes / totalEsperados;
}

/// Opción para los selectores de filtros avanzados.
class OpcionFiltro {
  factory OpcionFiltro.desdeJson(Map<String, dynamic> json) => OpcionFiltro(
        id: (json['id'] as String?) ?? '',
        nombre: (json['nombre'] as String?) ?? '',
      );
  const OpcionFiltro({required this.id, required this.nombre});

  final String id;
  final String nombre;

  @override
  bool operator ==(Object other) => other is OpcionFiltro && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

/// Opciones disponibles para los filtros avanzados.
class OpcionesFiltros {
  factory OpcionesFiltros.desdeJson(Map<String, dynamic> json) {
    List<OpcionFiltro> parsarLista(String clave) {
      final raw = json[clave];
      if (raw == null) return [];
      return (raw as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .map(OpcionFiltro.desdeJson)
          .toList();
    }

    return OpcionesFiltros(
      tipos: parsarLista('tipos'),
      creadores: parsarLista('creadores'),
      tags: parsarLista('tags'),
    );
  }
  const OpcionesFiltros({
    this.tipos = const [],
    this.creadores = const [],
    this.tags = const [],
  });

  final List<OpcionFiltro> tipos;
  final List<OpcionFiltro> creadores;
  final List<OpcionFiltro> tags;

  static OpcionesFiltros vacio() => const OpcionesFiltros();
}

/// Registro mínimo de un evento para el panel de detalle (drill-down).
class EventoResumido {
  factory EventoResumido.desdeJson(Map<String, dynamic> json) => EventoResumido(
        id: (json['id'] as String?) ?? '',
        titulo: (json['titulo'] as String?) ?? '',
        fechaInicio: json['fecha_inicio'] != null
            ? DateTime.tryParse(json['fecha_inicio'] as String)
            : null,
        tipoNombre: (json['tipo_nombre'] as String?) ?? 'Sin tipo',
        creadorNombre: (json['creador_nombre'] as String?) ?? '',
        total: (json['total'] as num?)?.toInt() ?? 0,
        presentes: (json['presentes'] as num?)?.toInt() ?? 0,
      );
  const EventoResumido({
    required this.id,
    required this.titulo,
    required this.fechaInicio,
    required this.tipoNombre,
    required this.creadorNombre,
    required this.total,
    required this.presentes,
  });

  final String id;
  final String titulo;
  final DateTime? fechaInicio;
  final String tipoNombre;
  final String creadorNombre;
  final int total;
  final int presentes;

  double get tasa => total == 0 ? 0 : presentes / total;
}

/// Métricas calculadas del embudo de asistencia a partir de [porEstatus].
class MetricasEmbudo {
  factory MetricasEmbudo.desdeEstatus(List<DatoGrafica> porEstatus) {
    double v(String etiqueta) => porEstatus
        .firstWhere(
          (d) => d.etiqueta == etiqueta,
          orElse: () => const DatoGrafica(etiqueta: '', valor: 0),
        )
        .valor;

    final total = porEstatus.fold(0.0, (s, d) => s + d.valor);
    final llegaron = v('Presente') + v('Completado') + v('Salió antes');
    final completaron = v('Completado');
    final ausentes = v('Ausente');

    return MetricasEmbudo(
      total: total,
      llegaron: llegaron,
      completaron: completaron,
      ausentes: ausentes,
    );
  }
  const MetricasEmbudo({
    required this.total,
    required this.llegaron,
    required this.completaron,
    required this.ausentes,
  });

  final double total;
  final double llegaron;
  final double completaron;
  final double ausentes;

  bool get hayDatos => total > 0;
}

// ─── Modelos v3 ───────────────────────────────────────────────────────────────

/// Tasa de asistencia por tipo de evento.
class DatoTasaTipo {
  // 0-100

  factory DatoTasaTipo.desdeJson(Map<String, dynamic> json) => DatoTasaTipo(
        tipoNombre: (json['tipo_nombre'] as String?) ?? '',
        totalEventos: (json['total_eventos'] as num?)?.toInt() ?? 0,
        totalRegistros: (json['total_registros'] as num?)?.toInt() ?? 0,
        presentes: (json['presentes'] as num?)?.toInt() ?? 0,
        tasa: (json['tasa'] as num?)?.toDouble() ?? 0.0,
      );
  const DatoTasaTipo({
    required this.tipoNombre,
    required this.totalEventos,
    required this.totalRegistros,
    required this.presentes,
    required this.tasa,
  });

  final String tipoNombre;
  final int totalEventos;
  final int totalRegistros;
  final int presentes;
  final double tasa;
}

/// Tendencia mensual con volumen y tasa de asistencia.
class DatoTendenciaDual {
  // 0-100

  factory DatoTendenciaDual.desdeJson(Map<String, dynamic> json) =>
      DatoTendenciaDual(
        mes: (json['mes'] as String?) ?? '',
        cantidad: (json['cantidad'] as num?)?.toDouble() ?? 0,
        tasa: (json['tasa'] as num?)?.toDouble() ?? 0,
      );
  const DatoTendenciaDual({
    required this.mes,
    required this.cantidad,
    required this.tasa,
  });

  final String mes;
  final double cantidad;
  final double tasa;
}

/// Tag con cantidad de eventos y tasa de asistencia.
class DatoTag {
  // 0-100

  factory DatoTag.desdeJson(Map<String, dynamic> json) => DatoTag(
        nombre: (json['nombre'] as String?) ?? '',
        tagId: (json['tag_id'] as String?) ?? '',
        cantidad: (json['cantidad'] as num?)?.toInt() ?? 0,
        presentes: (json['presentes'] as num?)?.toInt() ?? 0,
        tasa: (json['tasa'] as num?)?.toDouble() ?? 0.0,
      );
  const DatoTag({
    required this.nombre,
    required this.tagId,
    required this.cantidad,
    required this.presentes,
    required this.tasa,
  });

  final String nombre;
  final String tagId;
  final int cantidad;
  final int presentes;
  final double tasa;
}

/// Asistente frecuente (top usuarios por presencia).
class AsistenteFrecuente {
  // 0-100

  factory AsistenteFrecuente.desdeJson(Map<String, dynamic> json) =>
      AsistenteFrecuente(
        nombre: (json['nombre'] as String?) ?? '',
        usuarioId: (json['usuario_id'] as String?) ?? '',
        totalAsistencias: (json['total_asistencias'] as num?)?.toInt() ?? 0,
        totalEventos: (json['total_eventos'] as num?)?.toInt() ?? 0,
        tasa: (json['tasa'] as num?)?.toDouble() ?? 0.0,
      );
  const AsistenteFrecuente({
    required this.nombre,
    required this.usuarioId,
    required this.totalAsistencias,
    required this.totalEventos,
    required this.tasa,
  });

  final String nombre;
  final String usuarioId;
  final int totalAsistencias;
  final int totalEventos;
  final double tasa;
}

/// Un mes con su distribución de eventos por tipo (para barras apiladas).
class ComposicionMes {
  const ComposicionMes({required this.mes, required this.porTipo});

  final String mes;
  final Map<String, double> porTipo; // tipo_nombre → cantidad

  double get total => porTipo.values.fold(0, (s, v) => s + v);
}

/// Creador con cantidad de eventos y asistentes presentes.
class DatoCreador {
  factory DatoCreador.desdeJson(Map<String, dynamic> json) => DatoCreador(
        nombre: (json['nombre'] as String?) ?? '',
        creadorId: (json['creador_id'] as String?) ?? '',
        cantidad: (json['cantidad'] as num?)?.toInt() ?? 0,
        presentes: (json['presentes'] as num?)?.toInt() ?? 0,
      );
  const DatoCreador({
    required this.nombre,
    required this.creadorId,
    required this.cantidad,
    required this.presentes,
  });

  final String nombre;
  final String creadorId;
  final int cantidad;
  final int presentes;

  DatoGrafica toDatoGrafica() => DatoGrafica(
        etiqueta: nombre,
        valor: cantidad.toDouble(),
        valorSql: nombre,
      );
}

/// Celda del mapa de calor (hora de entrada vs día de semana).
class DatoHeatmap {
  factory DatoHeatmap.desdeJson(Map<String, dynamic> json) => DatoHeatmap(
        dia: (json['dia'] as String?) ?? '',
        diaOrden: (json['dia_orden'] as num?)?.toInt() ?? 0,
        hora: (json['hora'] as num?)?.toInt() ?? 0,
        cantidad: (json['cantidad'] as num?)?.toInt() ?? 0,
      );
  const DatoHeatmap({
    required this.dia,
    required this.diaOrden,
    required this.hora,
    required this.cantidad,
  });

  final String dia;
  final int diaOrden;
  final int hora;
  final int cantidad;
}
