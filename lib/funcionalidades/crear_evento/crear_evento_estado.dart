import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

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
    this.tagsPrincipalesIds      = const [],
    this.tagsSecundariosIds      = const [],
    this.titulo                  = '',
    this.descripcion             = '',
    this.lugar                   = '',
    this.fechaInicio,
    this.horaInicio,
    this.tieneFechaFin           = false,
    this.fechaFin,
    this.horaFin,
    this.usarTags                = false,
    this.permiteManualAdmin      = true,
    this.permiteQrEvento         = true,
    this.permiteQrUsuario        = true,
    this.permiteForaneos         = false,
    this.requiereCicloCompleto   = false,
    this.permiteSalidaAnticipada = false,
    this.marcarAusentesAuto      = false,
    this.estaGuardando           = false,
  });

  final String?          eventoId;
  final List<TipoEvento> tiposEvento;
  final List<TagOpcion>  tagsPrincipales;
  final List<TagOpcion>  tagsSecundarios;
  final TipoEvento?      tipoEventoSeleccionado;
  final List<String>     tagsPrincipalesIds;
  final List<String>     tagsSecundariosIds;
  final String           titulo;
  final String           descripcion;
  final String           lugar;
  final DateTime?        fechaInicio;
  final TimeOfDay?       horaInicio;
  final bool             tieneFechaFin;
  final DateTime?        fechaFin;
  final TimeOfDay?       horaFin;
  final bool             usarTags;
  final bool             permiteManualAdmin;
  final bool             permiteQrEvento;
  final bool             permiteQrUsuario;
  final bool             permiteForaneos;
  final bool             requiereCicloCompleto;
  final bool             permiteSalidaAnticipada;
  final bool             marcarAusentesAuto;
  final bool             estaGuardando;

  CrearEventoCargado copiarCon({
    String?           eventoId,
    List<TipoEvento>? tiposEvento,
    List<TagOpcion>?  tagsPrincipales,
    List<TagOpcion>?  tagsSecundarios,
    TipoEvento?       tipoEventoSeleccionado,
    List<String>?     tagsPrincipalesIds,
    List<String>?     tagsSecundariosIds,
    String?           titulo,
    String?           descripcion,
    String?           lugar,
    DateTime?         fechaInicio,
    TimeOfDay?        horaInicio,
    bool?             tieneFechaFin,
    DateTime?         fechaFin,
    TimeOfDay?        horaFin,
    bool?             usarTags,
    bool?             permiteManualAdmin,
    bool?             permiteQrEvento,
    bool?             permiteQrUsuario,
    bool?             permiteForaneos,
    bool?             requiereCicloCompleto,
    bool?             permiteSalidaAnticipada,
    bool?             marcarAusentesAuto,
    bool?             estaGuardando,
  }) =>
      CrearEventoCargado(
        eventoId:                eventoId                ?? this.eventoId,
        tiposEvento:             tiposEvento             ?? this.tiposEvento,
        tagsPrincipales:         tagsPrincipales         ?? this.tagsPrincipales,
        tagsSecundarios:         tagsSecundarios         ?? this.tagsSecundarios,
        tipoEventoSeleccionado:  tipoEventoSeleccionado  ?? this.tipoEventoSeleccionado,
        tagsPrincipalesIds:      tagsPrincipalesIds      ?? this.tagsPrincipalesIds,
        tagsSecundariosIds:      tagsSecundariosIds      ?? this.tagsSecundariosIds,
        titulo:                  titulo                  ?? this.titulo,
        descripcion:             descripcion             ?? this.descripcion,
        lugar:                   lugar                   ?? this.lugar,
        fechaInicio:             fechaInicio             ?? this.fechaInicio,
        horaInicio:              horaInicio              ?? this.horaInicio,
        tieneFechaFin:           tieneFechaFin           ?? this.tieneFechaFin,
        fechaFin:                fechaFin                ?? this.fechaFin,
        horaFin:                 horaFin                 ?? this.horaFin,
        usarTags:                usarTags                ?? this.usarTags,
        permiteManualAdmin:      permiteManualAdmin      ?? this.permiteManualAdmin,
        permiteQrEvento:         permiteQrEvento         ?? this.permiteQrEvento,
        permiteQrUsuario:        permiteQrUsuario        ?? this.permiteQrUsuario,
        permiteForaneos:         permiteForaneos         ?? this.permiteForaneos,
        requiereCicloCompleto:   requiereCicloCompleto   ?? this.requiereCicloCompleto,
        permiteSalidaAnticipada: permiteSalidaAnticipada ?? this.permiteSalidaAnticipada,
        marcarAusentesAuto:      marcarAusentesAuto      ?? this.marcarAusentesAuto,
        estaGuardando:           estaGuardando           ?? this.estaGuardando,
      );

  @override
  List<Object?> get props => [
        eventoId,
        tiposEvento,
        tagsPrincipales,
        tagsSecundarios,
        tipoEventoSeleccionado,
        tagsPrincipalesIds,
        tagsSecundariosIds,
        titulo,
        descripcion,
        lugar,
        fechaInicio,
        horaInicio,
        tieneFechaFin,
        fechaFin,
        horaFin,
        usarTags,
        permiteManualAdmin,
        permiteQrEvento,
        permiteQrUsuario,
        permiteForaneos,
        requiereCicloCompleto,
        permiteSalidaAnticipada,
        marcarAusentesAuto,
        estaGuardando,
      ];
}

final class CrearEventoGuardado extends CrearEventoEstado {
  const CrearEventoGuardado({required this.eventoId});

  final String eventoId;

  @override
  List<Object?> get props => [eventoId];
}

final class CrearEventoError extends CrearEventoEstado {
  const CrearEventoError({required this.mensaje});

  final String mensaje;

  @override
  List<Object?> get props => [mensaje];
}
