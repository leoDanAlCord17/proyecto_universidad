import 'package:equatable/equatable.dart';

import '../../compartido/constantes.dart';

class Usuario extends Equatable {
  final String? id;
  final String? authId;
  final String primerNombre;
  final String? segundoNombre;
  final String primerApellido;
  final String? segundoApellido;
  final String? numeroIdentificacion;
  final String correo;
  final String? telefono;
  final String? urlAvatar;
  final bool   estatus;
  final String estatusAprobacion;
  final DateTime? creadoEn;
  final List<String> roles;
  final List<String> permisos;

  const Usuario({
    this.id,
    this.authId,
    required this.primerNombre,
    this.segundoNombre,
    required this.primerApellido,
    this.segundoApellido,
    this.numeroIdentificacion,
    required this.correo,
    this.telefono,
    this.urlAvatar,
    this.estatus           = true,
    this.estatusAprobacion = EstatusAprobacion.aprobado,
    this.creadoEn,
    this.roles    = const [],
    this.permisos = const [],
  });

  factory Usuario.desdeJson(Map<String, dynamic> json) {
    final usuariosRoles = json['usuarios_roles'] as List? ?? [];
    final activos       = _rolesActivos(usuariosRoles);

    return Usuario(
      id:                   json['id'],
      authId:               json['auth_id'],
      primerNombre:         json['primer_nombre'] ?? '',
      segundoNombre:        json['segundo_nombre'],
      primerApellido:       json['primer_apellido'] ?? '',
      segundoApellido:      json['segundo_apellido'],
      numeroIdentificacion: json['numero_identificacion'],
      correo:               json['correo'] ?? '',
      telefono:             json['telefono'],
      urlAvatar:            json['url_avatar'],
      estatus:              (json['estatus']            as bool?)   ?? true,
      estatusAprobacion:    (json['estatus_aprobacion'] as String?) ?? EstatusAprobacion.aprobado,
      creadoEn:             json['creado_en'] != null
                                ? DateTime.parse(json['creado_en'] as String)
                                : null,
      roles:                _extraerNombresRoles(activos),
      permisos:             _extraerNombresPermisos(activos),
    );
  }

  static List<Map<String, dynamic>> _rolesActivos(List usuariosRoles) =>
      usuariosRoles
          .where((ur) => ur['estatus'] == true)
          .map((ur) => ur['roles'])
          .whereType<Map<String, dynamic>>()
          .where((r) => r['estatus'] == true)
          .toList();

  static List<String> _extraerNombresRoles(List<Map<String, dynamic>> activos) =>
      activos
          .map((r) => r['nombre'] as String? ?? '')
          .where((n) => n.isNotEmpty)
          .toList();

  static List<String> _extraerNombresPermisos(List<Map<String, dynamic>> activos) =>
      activos
          .expand((r) => (r['roles_permisos'] as List? ?? []))
          .where((rp) => rp['estatus'] == true)
          .map((rp) => rp['permisos'])
          .whereType<Map<String, dynamic>>()
          .map((p) => p['nombre'] as String? ?? '')
          .where((n) => n.isNotEmpty)
          .toSet()
          .toList();

  Map<String, dynamic> aJson() => {
    if (authId != null) 'auth_id': authId,
    'primer_nombre':          primerNombre,
    'segundo_nombre':         segundoNombre,
    'primer_apellido':        primerApellido,
    'segundo_apellido':       segundoApellido,
    'numero_identificacion':  numeroIdentificacion,
    'correo':                 correo,
    'telefono':               telefono,
    'url_avatar':             urlAvatar,
    'estatus':                estatus,
    'estatus_aprobacion':     estatusAprobacion,
    // roles y permisos viven en usuarios_roles y roles_permisos, no en usuarios
  };

  bool tienePermiso(String permiso) => permisos.contains(permiso);
  bool tieneRol(String rol)         => roles.contains(rol);

  String get nombreCompleto => '$primerNombre $primerApellido';
  String get iniciales {
    final n = primerNombre.isNotEmpty ? primerNombre[0] : '';
    final a = primerApellido.isNotEmpty ? primerApellido[0] : '';
    return '$n$a'.toUpperCase();
  }

  @override
  List<Object?> get props => [
    id, authId, primerNombre, segundoNombre,
    primerApellido, segundoApellido, numeroIdentificacion,
    correo, telefono, urlAvatar, estatus, estatusAprobacion,
    creadoEn, roles, permisos,
  ];
}
