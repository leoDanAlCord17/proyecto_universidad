import 'package:supabase_flutter/supabase_flutter.dart';

import '../../compartido/constantes.dart';
import '../../compartido/errores.dart';
import '../../compartido/reintento.dart';
import '../../compartido/traductor_errores.dart';
import '../eventos/evento.dart';
import 'asistente_item.dart';

class PanelControlRepositorio {
  const PanelControlRepositorio(this._supabase);

  final SupabaseClient _supabase;

  /// Retorna el evento completo por su ID.
  Future<Evento> obtenerEvento(String eventoId) => conReintentos(() async {
        try {
          final fila = await _supabase
              .from(TablasSupabase.eventos)
              .select()
              .eq('id', eventoId)
              .single()
              .timeout(kTimeoutSolicitud);
          return Evento.desdeJson(fila);
        } on PostgrestException catch (e) {
          throw FallaServidor(TraductorErrores.dePostgres(e));
        } catch (e) {
          TraductorErrores.lanzarInesperado(e);
        }
      });

  /// Retorna los registros reales de asistencia del evento con datos del usuario.
  /// Límite 5 000: los KPIs necesitan el dataset completo; esta cota evita
  /// consultas desbocadas en instalaciones con aforos extraordinariamente grandes.
  Future<List<AsistenteItem>> obtenerAsistentes(String eventoId) =>
      conReintentos(() async {
        try {
          final datos = await _supabase
              .from(TablasSupabase.asistencia)
              .select(
                'id, usuario_id, visitante_primer_nombre, visitante_primer_apellido, '
                'visitante_numero_identificacion, visitante_contacto, estatus, '
                'hora_entrada, hora_salida, '
                'usuarios!usuario_id(primer_nombre, primer_apellido, url_avatar, numero_identificacion), '
                'registrador:usuarios!entrada_registrada_por(primer_nombre, primer_apellido)',
              )
              .eq('evento_id', eventoId)
              .order('creado_en')
              .limit(5000)
              .timeout(kTimeoutSolicitud);
          return datos.map(AsistenteItem.desdeJson).toList();
        } on PostgrestException catch (e) {
          throw FallaServidor(TraductorErrores.dePostgres(e));
        } catch (e) {
          TraductorErrores.lanzarInesperado(e);
        }
      });

  /// Retorna TODOS los usuarios del sistema como ítems sintéticos con
  /// estatus 'esperado'. Se usa para eventos de alcance 'general'.
  Future<List<AsistenteItem>> obtenerTodosUsuarios() => conReintentos(() async {
        try {
          final rows = await _supabase
              .from(TablasSupabase.usuarios)
              .select(
                  'id, primer_nombre, primer_apellido, url_avatar, numero_identificacion')
              .order('primer_apellido', ascending: true)
              .timeout(kTimeoutSolicitud);
          return rows.map<AsistenteItem>(_construirItemDesdeUsuario).toList();
        } on PostgrestException catch (e) {
          throw FallaServidor(TraductorErrores.dePostgres(e));
        } catch (e) {
          TraductorErrores.lanzarInesperado(e);
        }
      });

  /// Retorna TODOS los miembros de los grupos del evento como ítems sintéticos
  /// con estatus 'esperado'. Se usa para eventos de alcance 'dirigido'.
  Future<List<AsistenteItem>> obtenerMiembrosGrupo(String eventoId) =>
      conReintentos(() async {
        try {
          final grupos = await _obtenerGruposTags(eventoId);
          if (grupos.isEmpty) return [];
          final allTagIds = grupos.values.expand((ids) => ids).toSet().toList();
          if (allTagIds.isEmpty) return [];
          final rows = await _consultarUsuariosTags(allTagIds);
          return _construirListaMiembros(rows, grupos);
        } on PostgrestException catch (e) {
          throw FallaServidor(TraductorErrores.dePostgres(e));
        } catch (e) {
          TraductorErrores.lanzarInesperado(e);
        }
      });

  /// Stream en tiempo real de cambios en la tabla asistencia para el evento.
  /// Se usa como disparador para recargar los datos completos con joins.
  Stream<List<Map<String, dynamic>>> streamCambiosAsistencia(String eventoId) {
    return _supabase
        .from(TablasSupabase.asistencia)
        .stream(primaryKey: ['id']).eq('evento_id', eventoId);
  }

  /// Cambia el estatus del evento a 'finalizado'.
  Future<void> cerrarEvento(String eventoId) async {
    try {
      final actualizadoPor = await _resolverUsuarioId();
      await _supabase.from(TablasSupabase.eventos).update({
        'estatus': EstatusEvento.finalizado,
        'actualizado_por': actualizadoPor
      }).eq('id', eventoId);
    } on PostgrestException catch (e) {
      throw FallaServidor(TraductorErrores.dePostgres(e));
    } catch (e) {
      TraductorErrores.lanzarInesperado(e);
    }
  }

  /// Inserta un registro de asistencia para un visitante foráneo (sin cuenta).
  Future<void> registrarForaneo({
    required String eventoId,
    required String primerNombre,
    required String primerApellido,
    String? cedula,
    String? contacto,
    String? registradoPorId,
  }) async {
    try {
      await _supabase.from(TablasSupabase.asistencia).insert({
        'evento_id': eventoId,
        'visitante_primer_nombre': primerNombre,
        'visitante_primer_apellido': primerApellido,
        'visitante_numero_identificacion': _textoOpcional(cedula),
        'visitante_contacto': _textoOpcional(contacto),
        'estatus': EstatusAsistencia.presente,
        'hora_entrada': DateTime.now().toUtc().toIso8601String(),
        'entrada_registrada_por': registradoPorId,
      });
    } on PostgrestException catch (e) {
      throw FallaServidor(TraductorErrores.dePostgres(e));
    } catch (e) {
      TraductorErrores.lanzarInesperado(e);
    }
  }

  String? _textoOpcional(String? valor) {
    final v = valor?.trim();
    return (v != null && v.isNotEmpty) ? v : null;
  }

  /// Marca como 'ausente' todos los registros 'esperado' del evento.
  Future<void> marcarAusentesAuto(String eventoId) async {
    try {
      await _supabase
          .from(TablasSupabase.asistencia)
          .update({
            'estatus': EstatusAsistencia.ausente,
            'actualizado_en': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('evento_id', eventoId)
          .eq('estatus', EstatusAsistencia.esperado);
    } on PostgrestException catch (e) {
      throw FallaServidor(TraductorErrores.dePostgres(e));
    } catch (e) {
      TraductorErrores.lanzarInesperado(e);
    }
  }

  // ─── Helpers privados ────────────────────────────────────────────────────────

  Future<Map<int, List<String>>> _obtenerGruposTags(String eventoId) async {
    final rows = await _supabase
        .from(TablasSupabase.eventoGruposTags)
        .select('grupo_index, tag_id')
        .eq('evento_id', eventoId);
    final grupos = <int, List<String>>{};
    for (final row in rows) {
      final idx = row['grupo_index'] as int;
      grupos.putIfAbsent(idx, () => []).add(row['tag_id'] as String);
    }
    return grupos;
  }

  Future<List<Map<String, dynamic>>> _consultarUsuariosTags(
    List<String> tagIds,
  ) async {
    final rows = await _supabase
        .from(TablasSupabase.usuariosTags)
        .select(
          'usuario_id, tag_id, '
          'usuarios!usuario_id(primer_nombre, primer_apellido, url_avatar, numero_identificacion)',
        )
        .inFilter('tag_id', tagIds)
        .eq('estatus', true);
    return List<Map<String, dynamic>>.from(rows);
  }

  List<AsistenteItem> _construirListaMiembros(
    List<Map<String, dynamic>> rows,
    Map<int, List<String>> grupos,
  ) {
    final tagsPorUsuario = <String, Set<String>>{};
    final datosUsuario = <String, Map<String, dynamic>>{};
    for (final row in rows) {
      final userId = row['usuario_id'] as String;
      final tagId = row['tag_id'] as String;
      tagsPorUsuario.putIfAbsent(userId, () => {}).add(tagId);
      datosUsuario.putIfAbsent(
        userId,
        () => row['usuarios'] as Map<String, dynamic>? ?? {},
      );
    }
    final resultado = <AsistenteItem>[];
    for (final entry in tagsPorUsuario.entries) {
      final coincide = grupos.values.any(
        entry.value.containsAll,
      );
      if (!coincide) continue;
      resultado
          .add(_construirItemEsperado(entry.key, datosUsuario[entry.key]!));
    }
    return resultado;
  }

  AsistenteItem _construirItemEsperado(
    String userId,
    Map<String, dynamic> datosUsuario,
  ) {
    return AsistenteItem.desdeJson(
      {
        'id': userId,
        'usuario_id': userId,
        'estatus': EstatusAsistencia.esperado,
        'hora_entrada': null,
        'visitante_primer_nombre': null,
        'visitante_primer_apellido': null,
        'visitante_contacto': null,
        'usuarios': datosUsuario,
      },
      eraEsperado: true,
    );
  }

  Future<String?> _resolverUsuarioId() async {
    final authId = _supabase.auth.currentUser?.id;
    if (authId == null) return null;
    final fila = await _supabase
        .from(TablasSupabase.usuarios)
        .select('id')
        .eq('auth_id', authId)
        .maybeSingle();
    return fila?['id'] as String?;
  }

  AsistenteItem _construirItemDesdeUsuario(Map<String, dynamic> row) {
    return AsistenteItem.desdeJson({
      'id': row['id'],
      'usuario_id': row['id'],
      'estatus': EstatusAsistencia.esperado,
      'hora_entrada': null,
      'visitante_primer_nombre': null,
      'visitante_primer_apellido': null,
      'visitante_contacto': null,
      'usuarios': {
        'primer_nombre': row['primer_nombre'],
        'primer_apellido': row['primer_apellido'],
        'url_avatar': row['url_avatar'],
        'numero_identificacion': row['numero_identificacion'],
      },
    });
  }
}
