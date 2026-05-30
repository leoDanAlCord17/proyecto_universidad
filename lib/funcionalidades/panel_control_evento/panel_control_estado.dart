import 'package:equatable/equatable.dart';

import '../../compartido/constantes.dart';
import '../eventos/evento.dart';
import 'asistente_item.dart';

enum FiltroAsistentes { todos, esperados, pendientes, noEsperados, registrados, abandono, foraneos }

sealed class PanelControlEstado extends Equatable {
  const PanelControlEstado();
}

final class PanelControlInicial extends PanelControlEstado {
  const PanelControlInicial();
  @override List<Object?> get props => [];
}

final class PanelControlCargando extends PanelControlEstado {
  const PanelControlCargando();
  @override List<Object?> get props => [];
}

final class PanelControlCargado extends PanelControlEstado {
  const PanelControlCargado({
    required this.evento,
    required this.asistentes,
    required this.listaEsperados,
    this.filtroActivo    = FiltroAsistentes.todos,
    this.estaCerrando    = false,
    this.estaRegistrando = false,
  });

  final Evento              evento;

  /// Registros reales de la tabla asistencia (con flag eraEsperado aplicado).
  final List<AsistenteItem> asistentes;

  /// Audiencia definida del evento fusionada con sus registros reales.
  /// Vacío para eventos de alcance 'general'.
  final List<AsistenteItem> listaEsperados;

  final FiltroAsistentes filtroActivo;
  final bool             estaCerrando;
  final bool             estaRegistrando;

  // ─── Tipo de evento ──────────────────────────────────────────────────────────

  bool get esEventoDirigido => evento.alcance == AlcanceEvento.dirigido;

  // ─── Audiencia definida ──────────────────────────────────────────────────────

  /// Tamaño de la audiencia pre-definida. 0 para eventos generales.
  int get totalAudiencia => listaEsperados.length;

  // ─── Contadores por población ────────────────────────────────────────────────

  /// Población A: usuarios esperados que llegaron (cualquier estado activo).
  int get presentesEsperados =>
      asistentes.where((a) => a.eraEsperado && _estaActivo(a)).length;

  /// Población B: usuarios del sistema que llegaron sin estar en la audiencia.
  int get presentesNoEsperados =>
      asistentes.where((a) => !a.esForaneo && !a.eraEsperado && _estaActivo(a)).length;

  /// Población C: visitantes sin cuenta en el sistema.
  int get presentesForaneos =>
      asistentes.where((a) => a.esForaneo && _estaActivo(a)).length;

  /// Total de personas actualmente en el recinto (las 3 poblaciones).
  int get totalPresentes => asistentes.where(_estaActivo).length;

  /// Esperados de la audiencia que aún no han llegado.
  int get pendientes =>
      listaEsperados.where((a) => a.estatus == EstatusAsistencia.esperado).length;

  /// Esperados de la audiencia marcados como ausentes al cerrar.
  int get ausentes =>
      asistentes.where((a) => a.eraEsperado && a.estatus == EstatusAsistencia.ausente).length;

  int get cantidadAnticipados =>
      asistentes.where((a) => a.estatus == EstatusAsistencia.salioAnticipado).length;

  // ─── Tasas ───────────────────────────────────────────────────────────────────

  /// Porcentaje de la audiencia definida que llegó.
  /// null si el evento es general o no tiene audiencia definida.
  double? get tasaConvocatoria {
    if (!esEventoDirigido || totalAudiencia == 0) return null;
    return presentesEsperados / totalAudiencia;
  }

  /// Porcentaje de ocupación real (todas las poblaciones / audiencia definida).
  /// null si el evento es general o no tiene audiencia definida.
  double? get tasaOcupacion {
    if (!esEventoDirigido || totalAudiencia == 0) return null;
    return totalPresentes / totalAudiencia;
  }

  // ─── Modos de registro ───────────────────────────────────────────────────────

  int get cantidadModos => [
    evento.permiteQrEvento,
    evento.permiteQrUsuario,
    evento.permiteManualAdmin,
  ].where((b) => b).length;

  // ─── Lista filtrada ──────────────────────────────────────────────────────────

  List<AsistenteItem> get asistentesFiltrados => switch (filtroActivo) {
    FiltroAsistentes.todos        => asistentes,
    FiltroAsistentes.esperados    => listaEsperados,
    FiltroAsistentes.pendientes   => listaEsperados
        .where((a) => a.estatus == EstatusAsistencia.esperado)
        .toList(),
    FiltroAsistentes.noEsperados  => asistentes
        .where((a) => !a.esForaneo && !a.eraEsperado)
        .toList(),
    FiltroAsistentes.registrados  => asistentes
        .where((a) => a.esRegistrado)
        .toList(),
    FiltroAsistentes.abandono     => asistentes
        .where((a) => a.esAbandono)
        .toList(),
    FiltroAsistentes.foraneos     => asistentes
        .where((a) => a.esForaneo)
        .toList(),
  };

  // ─── Helper interno ──────────────────────────────────────────────────────────

  bool _estaActivo(AsistenteItem a) =>
      a.estatus == EstatusAsistencia.presente      ||
      a.estatus == EstatusAsistencia.completado    ||
      a.estatus == EstatusAsistencia.salioAnticipado;

  // ─── Copia ───────────────────────────────────────────────────────────────────

  PanelControlCargado copiarCon({
    Evento?              evento,
    List<AsistenteItem>? asistentes,
    List<AsistenteItem>? listaEsperados,
    FiltroAsistentes?    filtroActivo,
    bool?                estaCerrando,
    bool?                estaRegistrando,
  }) =>
      PanelControlCargado(
        evento:          evento          ?? this.evento,
        asistentes:      asistentes      ?? this.asistentes,
        listaEsperados:  listaEsperados  ?? this.listaEsperados,
        filtroActivo:    filtroActivo    ?? this.filtroActivo,
        estaCerrando:    estaCerrando    ?? this.estaCerrando,
        estaRegistrando: estaRegistrando ?? this.estaRegistrando,
      );

  @override
  List<Object?> get props =>
      [evento, asistentes, listaEsperados, filtroActivo, estaCerrando, estaRegistrando];
}

final class PanelControlOperacionFallida extends PanelControlEstado {
  const PanelControlOperacionFallida({
    required this.anterior,
    required this.mensaje,
  });

  final PanelControlCargado anterior;
  final String              mensaje;

  @override List<Object?> get props => [anterior, mensaje];
}

final class PanelControlError extends PanelControlEstado {
  const PanelControlError({required this.mensaje});
  final String mensaje;
  @override List<Object?> get props => [mensaje];
}

final class PanelControlEventoCerrado extends PanelControlEstado {
  const PanelControlEventoCerrado();
  @override List<Object?> get props => [];
}
