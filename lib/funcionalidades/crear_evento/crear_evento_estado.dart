import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

import '../../compartido/constantes.dart';
import 'grupo_audiencia.dart';
import 'tag_opcion.dart';
import 'tipo_evento.dart';

sealed class CrearEventoEstado extends Equatable {
  const CrearEventoEstado();
}

final class CrearEventoInicial extends CrearEventoEstado {
  const CrearEventoInicial();
  @override
  List<Object?> get props => [];
}

final class CrearEventoCargando extends CrearEventoEstado {
  const CrearEventoCargando();
  @override
  List<Object?> get props => [];
}

final class CrearEventoCargado extends CrearEventoEstado {
  const CrearEventoCargado({
    required this.tiposEvento,
    required this.tagsPrincipales,
    required this.tagsSecundarios,
    this.eventoId,
    this.tipoEventoSeleccionado,
    this.alcance                 = AlcanceEvento.general,
    this.grupos                  = const [],
    this.maxTagsSecundarios      = 3,
    this.titulo                  = '',
    this.descripcion             = '',
    this.lugar                   = '',
    this.fechaInicio,
    this.horaInicio,
    this.tieneFechaFin           = true,
    this.fechaFin,
    this.horaFin,
    this.permiteManualAdmin      = true,
    this.permiteQrEvento         = true,
    this.permiteQrUsuario        = true,
    this.permiteForaneos         = false,
    this.requiereCicloCompleto   = false,
    this.permiteSalidaAnticipada = false,
    this.marcarAusentesAuto      = false,
    this.estaGuardando           = false,
    this.errorValidacion,
    this.pasoActual              = 0,
  });

  final String?            eventoId;
  final List<TipoEvento>   tiposEvento;
  final List<TagOpcion>    tagsPrincipales;
  final List<TagOpcion>    tagsSecundarios;
  final TipoEvento?        tipoEventoSeleccionado;
  final String             alcance;
  final List<GrupoAudiencia> grupos;
  final int                maxTagsSecundarios;
  final String             titulo;
  final String             descripcion;
  final String             lugar;
  final DateTime?          fechaInicio;
  final TimeOfDay?         horaInicio;
  final bool               tieneFechaFin;
  final DateTime?          fechaFin;
  final TimeOfDay?         horaFin;
  final bool               permiteManualAdmin;
  final bool               permiteQrEvento;
  final bool               permiteQrUsuario;
  final bool               permiteForaneos;
  final bool               requiereCicloCompleto;
  final bool               permiteSalidaAnticipada;
  final bool               marcarAusentesAuto;
  final bool               estaGuardando;
  final String?            errorValidacion;

  /// Paso actual del wizard (0 = info básica, 1 = fecha/lugar, 2 = configuración).
  final int                pasoActual;

  CrearEventoCargado copiarCon({
    String?              eventoId,
    List<TipoEvento>?    tiposEvento,
    List<TagOpcion>?     tagsPrincipales,
    List<TagOpcion>?     tagsSecundarios,
    TipoEvento?          tipoEventoSeleccionado,
    String?              alcance,
    List<GrupoAudiencia>? grupos,
    int?                 maxTagsSecundarios,
    String?              titulo,
    String?              descripcion,
    String?              lugar,
    DateTime?            fechaInicio,
    TimeOfDay?           horaInicio,
    bool?                tieneFechaFin,
    DateTime?            fechaFin,
    TimeOfDay?           horaFin,
    bool?                permiteManualAdmin,
    bool?                permiteQrEvento,
    bool?                permiteQrUsuario,
    bool?                permiteForaneos,
    bool?                requiereCicloCompleto,
    bool?                permiteSalidaAnticipada,
    bool?                marcarAusentesAuto,
    bool?                estaGuardando,
    String?              errorValidacion,
    bool                 limpiarErrorValidacion = false,
    int?                 pasoActual,
  }) =>
      CrearEventoCargado(
        eventoId:                eventoId                ?? this.eventoId,
        tiposEvento:             tiposEvento             ?? this.tiposEvento,
        tagsPrincipales:         tagsPrincipales         ?? this.tagsPrincipales,
        tagsSecundarios:         tagsSecundarios         ?? this.tagsSecundarios,
        tipoEventoSeleccionado:  tipoEventoSeleccionado  ?? this.tipoEventoSeleccionado,
        alcance:                 alcance                 ?? this.alcance,
        grupos:                  grupos                  ?? this.grupos,
        maxTagsSecundarios:      maxTagsSecundarios      ?? this.maxTagsSecundarios,
        titulo:                  titulo                  ?? this.titulo,
        descripcion:             descripcion             ?? this.descripcion,
        lugar:                   lugar                   ?? this.lugar,
        fechaInicio:             fechaInicio             ?? this.fechaInicio,
        horaInicio:              horaInicio              ?? this.horaInicio,
        tieneFechaFin:           tieneFechaFin           ?? this.tieneFechaFin,
        fechaFin:                fechaFin                ?? this.fechaFin,
        horaFin:                 horaFin                 ?? this.horaFin,
        permiteManualAdmin:      permiteManualAdmin      ?? this.permiteManualAdmin,
        permiteQrEvento:         permiteQrEvento         ?? this.permiteQrEvento,
        permiteQrUsuario:        permiteQrUsuario        ?? this.permiteQrUsuario,
        permiteForaneos:         permiteForaneos         ?? this.permiteForaneos,
        requiereCicloCompleto:   requiereCicloCompleto   ?? this.requiereCicloCompleto,
        permiteSalidaAnticipada: permiteSalidaAnticipada ?? this.permiteSalidaAnticipada,
        marcarAusentesAuto:      marcarAusentesAuto      ?? this.marcarAusentesAuto,
        estaGuardando:           estaGuardando           ?? this.estaGuardando,
        errorValidacion: limpiarErrorValidacion
            ? null
            : (errorValidacion ?? this.errorValidacion),
        pasoActual:              pasoActual              ?? this.pasoActual,
      );

  @override
  List<Object?> get props => [
        eventoId,
        tiposEvento,
        tagsPrincipales,
        tagsSecundarios,
        tipoEventoSeleccionado,
        alcance,
        grupos,
        maxTagsSecundarios,
        titulo,
        descripcion,
        lugar,
        fechaInicio,
        horaInicio,
        tieneFechaFin,
        fechaFin,
        horaFin,
        permiteManualAdmin,
        permiteQrEvento,
        permiteQrUsuario,
        permiteForaneos,
        requiereCicloCompleto,
        permiteSalidaAnticipada,
        marcarAusentesAuto,
        estaGuardando,
        errorValidacion,
        pasoActual,
      ];
}

final class CrearEventoGuardado extends CrearEventoEstado {
  const CrearEventoGuardado({
    required this.eventoId,
    this.esBorrador = false,
  });

  final String eventoId;

  /// `true` cuando se guardó como borrador (muestra snackbar de confirmación).
  final bool esBorrador;

  @override
  List<Object?> get props => [eventoId, esBorrador];
}

final class CrearEventoError extends CrearEventoEstado {
  const CrearEventoError({required this.mensaje});

  final String mensaje;

  @override
  List<Object?> get props => [mensaje];
}
