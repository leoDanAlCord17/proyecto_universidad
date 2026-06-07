class BorradorEvento {
  factory BorradorEvento.desdeJson(Map<String, dynamic> json) {
    return BorradorEvento(
      id: json['id'] as String,
      titulo: json['titulo'] as String? ?? '',
      descripcion: json['descripcion'] as String? ?? '',
      fechaInicio: json['fecha_inicio'] != null
          ? DateTime.tryParse(json['fecha_inicio'] as String)
          : null,
      horaInicio: json['hora_inicio'] as String?,
      horaFin: json['hora_fin'] as String?,
    );
  }
  const BorradorEvento({
    required this.id,
    required this.titulo,
    required this.descripcion,
    this.fechaInicio,
    this.horaInicio,
    this.horaFin,
  });

  final String id;
  final String titulo;
  final String descripcion;
  final DateTime? fechaInicio;
  final String? horaInicio;
  final String? horaFin;
}
