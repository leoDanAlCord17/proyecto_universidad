import 'package:supabase_flutter/supabase_flutter.dart';

import '../../compartido/constantes.dart';
import '../../compartido/errores.dart';
import '../../compartido/reintento.dart';
import '../../compartido/traductor_errores.dart';
import 'estadisticas_modelo.dart';
import 'filtros_estadisticas.dart';

class EstadisticasRepositorio {
  const EstadisticasRepositorio(this._supabase);

  final SupabaseClient _supabase;

  // ─── Métodos v2 ──────────────────────────────────────────────────────────────

  /// Retorna los 4 KPIs principales (total eventos, asistencias, tasa, usuarios activos).
  Future<ResumenEstadisticas> obtenerResumen(FiltrosEstadisticas f) =>
      conReintentos(() async {
        try {
          final datos = await _supabase
              .rpc(
                'estadisticas_resumen',
                params: _params(f),
              )
              .timeout(kTimeoutSolicitud) as Map<String, dynamic>;
          return ResumenEstadisticas.desdeJson(datos);
        } on PostgrestException catch (e) {
          throw FallaServidor(TraductorErrores.dePostgres(e));
        } catch (e) {
          TraductorErrores.lanzarInesperado(e);
        }
      });

  /// Cantidad de eventos agrupados por tipo de evento.
  Future<List<DatoGrafica>> obtenerEventosPorTipo(FiltrosEstadisticas f) =>
      conReintentos(() async {
        try {
          final filas = await _supabase
              .rpc(
                'estadisticas_eventos_por_tipo',
                params: _params(f),
              )
              .timeout(kTimeoutSolicitud) as List<dynamic>;
          return filas
              .cast<Map<String, dynamic>>()
              .map(
                (r) => DatoGrafica(
                  etiqueta: (r['nombre'] as String?) ?? '',
                  valor: (r['cantidad'] as num?)?.toDouble() ?? 0,
                ),
              )
              .toList();
        } on PostgrestException catch (e) {
          throw FallaServidor(TraductorErrores.dePostgres(e));
        } catch (e) {
          TraductorErrores.lanzarInesperado(e);
        }
      });

  /// Cantidad de eventos por mes dentro del rango seleccionado.
  Future<List<DatoGrafica>> obtenerEventosPorMes(FiltrosEstadisticas f) =>
      conReintentos(() async {
        try {
          final filas = await _supabase
              .rpc(
                'estadisticas_eventos_por_mes',
                params: _params(f),
              )
              .timeout(kTimeoutSolicitud) as List<dynamic>;
          return filas
              .cast<Map<String, dynamic>>()
              .map(
                (r) => DatoGrafica(
                  etiqueta: (r['mes'] as String?) ?? '',
                  valor: (r['cantidad'] as num?)?.toDouble() ?? 0,
                  valorSql: (r['mes'] as String?) ?? '',
                ),
              )
              .toList();
        } on PostgrestException catch (e) {
          throw FallaServidor(TraductorErrores.dePostgres(e));
        } catch (e) {
          TraductorErrores.lanzarInesperado(e);
        }
      });

  /// Conteo de registros de asistencia agrupados por estatus (presente, ausente, etc.).
  Future<List<DatoGrafica>> obtenerAsistenciaPorEstatus(
          FiltrosEstadisticas f) =>
      conReintentos(() async {
        try {
          final filas = await _supabase
              .rpc(
                'estadisticas_asistencia_por_estatus',
                params: _params(f),
              )
              .timeout(kTimeoutSolicitud) as List<dynamic>;
          return filas.cast<Map<String, dynamic>>().map((r) {
            final estatusSql = (r['estatus'] as String?) ?? '';
            return DatoGrafica(
              etiqueta: _traducirEstatus(estatusSql),
              valor: (r['cantidad'] as num?)?.toDouble() ?? 0,
              valorSql: estatusSql,
            );
          }).toList();
        } on PostgrestException catch (e) {
          throw FallaServidor(TraductorErrores.dePostgres(e));
        } catch (e) {
          TraductorErrores.lanzarInesperado(e);
        }
      });

  /// Top 5 eventos con mayor tasa de asistencia (presentes / esperados).
  Future<List<EventoTopStat>> obtenerTopEventos(FiltrosEstadisticas f) =>
      conReintentos(() async {
        try {
          final filas = await _supabase.rpc(
            'estadisticas_top_eventos',
            params: {..._params(f), 'p_limite': 5},
          ).timeout(kTimeoutSolicitud) as List<dynamic>;
          return filas
              .cast<Map<String, dynamic>>()
              .map(EventoTopStat.desdeJson)
              .toList();
        } on PostgrestException catch (e) {
          throw FallaServidor(TraductorErrores.dePostgres(e));
        } catch (e) {
          TraductorErrores.lanzarInesperado(e);
        }
      });

  /// Asistentes presentes agrupados por día de semana (Lun–Dom).
  Future<List<DatoGrafica>> obtenerAsistenciaDiaSemana(FiltrosEstadisticas f) =>
      conReintentos(() async {
        try {
          final filas = await _supabase
              .rpc(
                'estadisticas_asistencia_dia_semana',
                params: _params(f),
              )
              .timeout(kTimeoutSolicitud) as List<dynamic>;
          return filas
              .cast<Map<String, dynamic>>()
              .map(
                (r) => DatoGrafica(
                  etiqueta: (r['dia'] as String?) ?? '',
                  valor: (r['cantidad'] as num?)?.toDouble() ?? 0,
                  valorSql: (r['dia'] as String?) ?? '',
                ),
              )
              .toList();
        } on PostgrestException catch (e) {
          throw FallaServidor(TraductorErrores.dePostgres(e));
        } catch (e) {
          TraductorErrores.lanzarInesperado(e);
        }
      });

  /// Top 8 organizadores por cantidad de eventos creados, con sus presentes.
  Future<List<DatoCreador>> obtenerEventosPorCreador(FiltrosEstadisticas f) =>
      conReintentos(() async {
        try {
          final filas = await _supabase.rpc(
            'estadisticas_eventos_por_creador',
            params: {..._params(f), 'p_limite': 8},
          ).timeout(kTimeoutSolicitud) as List<dynamic>;
          return filas
              .cast<Map<String, dynamic>>()
              .map(DatoCreador.desdeJson)
              .toList();
        } on PostgrestException catch (e) {
          throw FallaServidor(TraductorErrores.dePostgres(e));
        } catch (e) {
          TraductorErrores.lanzarInesperado(e);
        }
      });

  /// Opciones disponibles para los selectores de filtro (tipos, creadores, tags) en el período.
  Future<OpcionesFiltros> obtenerOpciones(FiltrosEstadisticas f) =>
      conReintentos(() async {
        try {
          final datos = await _supabase.rpc(
            'estadisticas_opciones_filtros',
            params: {
              'p_fecha_inicio': _fecha(f.rango.start),
              'p_fecha_fin': _fecha(f.rango.end),
            },
          ).timeout(kTimeoutSolicitud) as Map<String, dynamic>;
          return OpcionesFiltros.desdeJson(datos);
        } on PostgrestException catch (e) {
          throw FallaServidor(TraductorErrores.dePostgres(e));
        } catch (e) {
          TraductorErrores.lanzarInesperado(e);
        }
      });

  /// Detalle de eventos para drill-down según [dimension] y [valor] seleccionados.
  Future<List<EventoResumido>> obtenerDetalleEventos({
    required FiltrosEstadisticas filtros,
    required String dimension,
    required String valor,
  }) =>
      conReintentos(() async {
        try {
          final filas = await _supabase.rpc(
            'estadisticas_detalle_eventos',
            params: {
              ..._params(filtros),
              'p_dimension': dimension,
              'p_valor': valor,
            },
          ).timeout(kTimeoutSolicitud) as List<dynamic>;
          return filas
              .cast<Map<String, dynamic>>()
              .map(EventoResumido.desdeJson)
              .toList();
        } on PostgrestException catch (e) {
          throw FallaServidor(TraductorErrores.dePostgres(e));
        } catch (e) {
          TraductorErrores.lanzarInesperado(e);
        }
      });

  // ─── Métodos v3 ──────────────────────────────────────────────────────────────

  /// Tasa de asistencia (0–100) por tipo de evento con totales de registros y presentes.
  Future<List<DatoTasaTipo>> obtenerTasaPorTipo(FiltrosEstadisticas f) =>
      conReintentos(() async {
        try {
          final filas = await _supabase
              .rpc(
                'estadisticas_tasa_por_tipo',
                params: _params(f),
              )
              .timeout(kTimeoutSolicitud) as List<dynamic>;
          return filas
              .cast<Map<String, dynamic>>()
              .map(DatoTasaTipo.desdeJson)
              .toList();
        } on PostgrestException catch (e) {
          throw FallaServidor(TraductorErrores.dePostgres(e));
        } catch (e) {
          TraductorErrores.lanzarInesperado(e);
        }
      });

  /// Tendencia mensual: volumen de eventos y tasa de asistencia por mes.
  Future<List<DatoTendenciaDual>> obtenerTendenciaDual(FiltrosEstadisticas f) =>
      conReintentos(() async {
        try {
          final filas = await _supabase
              .rpc(
                'estadisticas_tendencia_dual',
                params: _params(f),
              )
              .timeout(kTimeoutSolicitud) as List<dynamic>;
          return filas
              .cast<Map<String, dynamic>>()
              .map(DatoTendenciaDual.desdeJson)
              .toList();
        } on PostgrestException catch (e) {
          throw FallaServidor(TraductorErrores.dePostgres(e));
        } catch (e) {
          TraductorErrores.lanzarInesperado(e);
        }
      });

  /// Histograma de eventos según rango de asistentes (escala: pequeño, mediano, grande, masivo).
  Future<List<DatoGrafica>> obtenerEscalaEventos(FiltrosEstadisticas f) =>
      conReintentos(() async {
        try {
          final filas = await _supabase
              .rpc(
                'estadisticas_escala_eventos',
                params: _params(f),
              )
              .timeout(kTimeoutSolicitud) as List<dynamic>;
          return filas
              .cast<Map<String, dynamic>>()
              .map(
                (r) => DatoGrafica(
                  etiqueta: (r['rango'] as String?) ?? '',
                  valor: (r['cantidad'] as num?)?.toDouble() ?? 0,
                ),
              )
              .toList();
        } on PostgrestException catch (e) {
          throw FallaServidor(TraductorErrores.dePostgres(e));
        } catch (e) {
          TraductorErrores.lanzarInesperado(e);
        }
      });

  /// Top 10 tags por cantidad de eventos, con tasa de asistencia por tag.
  Future<List<DatoTag>> obtenerTopTags(FiltrosEstadisticas f) =>
      conReintentos(() async {
        try {
          final filas = await _supabase.rpc(
            'estadisticas_top_tags',
            params: {..._params(f), 'p_limite': 10},
          ).timeout(kTimeoutSolicitud) as List<dynamic>;
          return filas
              .cast<Map<String, dynamic>>()
              .map(DatoTag.desdeJson)
              .toList();
        } on PostgrestException catch (e) {
          throw FallaServidor(TraductorErrores.dePostgres(e));
        } catch (e) {
          TraductorErrores.lanzarInesperado(e);
        }
      });

  /// Top 10 usuarios con mayor número de asistencias en el período.
  Future<List<AsistenteFrecuente>> obtenerTopAsistentes(
          FiltrosEstadisticas f) =>
      conReintentos(() async {
        try {
          final filas = await _supabase.rpc(
            'estadisticas_top_asistentes',
            params: {..._params(f), 'p_limite': 10},
          ).timeout(kTimeoutSolicitud) as List<dynamic>;
          return filas
              .cast<Map<String, dynamic>>()
              .map(AsistenteFrecuente.desdeJson)
              .toList();
        } on PostgrestException catch (e) {
          throw FallaServidor(TraductorErrores.dePostgres(e));
        } catch (e) {
          TraductorErrores.lanzarInesperado(e);
        }
      });

  /// Distribución de tipos de evento por mes (para barras apiladas).
  Future<List<ComposicionMes>> obtenerComposicionMensual(
          FiltrosEstadisticas f) =>
      conReintentos(() async {
        try {
          final filas = await _supabase
              .rpc(
                'estadisticas_composicion_mensual',
                params: _params(f),
              )
              .timeout(kTimeoutSolicitud) as List<dynamic>;
          final mapa = <String, Map<String, double>>{};
          for (final r in filas.cast<Map<String, dynamic>>()) {
            final mes = (r['mes'] as String?) ?? '';
            final tipo = (r['tipo_nombre'] as String?) ?? 'Sin tipo';
            final cant = (r['cantidad'] as num?)?.toDouble() ?? 0;
            mapa.putIfAbsent(mes, () => {})[tipo] = cant;
          }
          return mapa.entries
              .map((e) => ComposicionMes(mes: e.key, porTipo: e.value))
              .toList();
        } on PostgrestException catch (e) {
          throw FallaServidor(TraductorErrores.dePostgres(e));
        } catch (e) {
          TraductorErrores.lanzarInesperado(e);
        }
      });

  /// Conteo de eventos por estado operacional (programado, en curso, finalizado, cancelado).
  Future<List<DatoGrafica>> obtenerEstadoEventos(FiltrosEstadisticas f) =>
      conReintentos(() async {
        try {
          final filas = await _supabase
              .rpc(
                'estadisticas_estado_eventos',
                params: _params(f),
              )
              .timeout(kTimeoutSolicitud) as List<dynamic>;
          return filas.cast<Map<String, dynamic>>().map((r) {
            final estatusSql = (r['estatus'] as String?) ?? '';
            return DatoGrafica(
              etiqueta: _traducirEstatusEvento(estatusSql),
              valor: (r['cantidad'] as num?)?.toDouble() ?? 0,
              valorSql: estatusSql,
            );
          }).toList();
        } on PostgrestException catch (e) {
          throw FallaServidor(TraductorErrores.dePostgres(e));
        } catch (e) {
          TraductorErrores.lanzarInesperado(e);
        }
      });

  /// Mapa de calor de entradas registradas cruzando hora del día con día de semana.
  Future<List<DatoHeatmap>> obtenerHeatmapHora(FiltrosEstadisticas f) =>
      conReintentos(() async {
        try {
          final filas = await _supabase
              .rpc(
                'estadisticas_heatmap_hora',
                params: _params(f),
              )
              .timeout(kTimeoutSolicitud) as List<dynamic>;
          return filas
              .cast<Map<String, dynamic>>()
              .map(DatoHeatmap.desdeJson)
              .toList();
        } on PostgrestException catch (e) {
          throw FallaServidor(TraductorErrores.dePostgres(e));
        } catch (e) {
          TraductorErrores.lanzarInesperado(e);
        }
      });

  // ─── Helpers privados ────────────────────────────────────────────────────────

  Map<String, dynamic> _params(FiltrosEstadisticas f) => {
        'p_fecha_inicio': _fecha(f.rango.start),
        'p_fecha_fin': _fecha(f.rango.end),
        'p_tipo_ids': f.tipoIds.isEmpty ? null : f.tipoIds,
        'p_creador_ids': f.creadorIds.isEmpty ? null : f.creadorIds,
        'p_tag_ids': f.tagIds.isEmpty ? null : f.tagIds,
      };

  String _fecha(DateTime d) => d.toIso8601String().substring(0, 10);

  String _traducirEstatus(String e) => switch (e) {
        'presente' => 'Presente',
        'completado' => 'Completado',
        'salio_anticipado' => 'Salió antes',
        'ausente' => 'Ausente',
        'esperado' => 'Esperado',
        _ => e,
      };

  String _traducirEstatusEvento(String e) => switch (e) {
        'programado' => 'Programado',
        'en_curso' => 'En curso',
        'finalizado' => 'Finalizado',
        'cancelado' => 'Cancelado',
        'borrador' => 'Borrador',
        _ => e,
      };
}
