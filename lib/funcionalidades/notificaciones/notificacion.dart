class Notificacion {

  factory Notificacion.desdeJson(Map<String, dynamic> json) => Notificacion(
    id:          json['id']           as String,
    titulo:      json['titulo']       as String,
    cuerpo:      json['cuerpo']       as String,
    tipo:        json['tipo']         as String,
    leida:       json['leida']        as bool,
    creadoEn:    DateTime.parse(json['creado_en'] as String).toLocal(),
    entidadId:   json['entidad_id']   as String?,
    entidadTipo: json['entidad_tipo'] as String?,
  );
  const Notificacion({
    required this.id,
    required this.titulo,
    required this.cuerpo,
    required this.tipo,
    required this.leida,
    required this.creadoEn,
    this.entidadId,
    this.entidadTipo,
  });

  final String   id;
  final String   titulo;
  final String   cuerpo;
  final String   tipo;
  final bool     leida;
  final DateTime creadoEn;
  final String?  entidadId;
  final String?  entidadTipo;

  Notificacion comoLeida() => Notificacion(
    id:          id,
    titulo:      titulo,
    cuerpo:      cuerpo,
    tipo:        tipo,
    leida:       true,
    creadoEn:    creadoEn,
    entidadId:   entidadId,
    entidadTipo: entidadTipo,
  );
}
