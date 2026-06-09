import 'package:supabase_flutter/supabase_flutter.dart';

import '../../compartido/constantes.dart';
import '../../compartido/errores.dart';
import '../../compartido/reintento.dart';
import '../../compartido/traductor_errores.dart';
import 'grupo_audiencia.dart';
import 'tag_opcion.dart';
import 'tipo_evento.dart';

class CrearEventoRepositorio {
  const CrearEventoRepositorio(this._cliente);

  final SupabaseClient _cliente;

  /// Retorna los tipos de evento con estatus activo.
  Future<List<TipoEvento>> obtenerTiposEvento() => conReintentos(() async {
        try {
          final datos = await _cliente
              .from(TablasSupabase.tiposEvento)
              .select()
              .eq('estatus', true)
              .timeout(kTimeoutSolicitud);
          return (datos as List).map((e) => TipoEvento.desdeJson(e)).toList();
        } on PostgrestException catch (e) {
          throw FallaServidor(TraductorErrores.dePostgres(e));
        } catch (e) {
          TraductorErrores.lanzarInesperado(e);
        }
      });

  /// Retorna los tags activos (principales y secundarios) — techo de 200 para el picker.
  Future<List<TagOpcion>> obtenerTags() => conReintentos(() async {
        try {
          final datos = await _cliente
              .from(TablasSupabase.tags)
              .select()
              .eq('estatus', true)
              .order('tipo')
              .order('nombre')
              .limit(200)
              .timeout(kTimeoutSolicitud);
          return (datos as List).map((e) => TagOpcion.desdeJson(e)).toList();
        } on PostgrestException catch (e) {
          throw FallaServidor(TraductorErrores.dePostgres(e));
        } catch (e) {
          TraductorErrores.lanzarInesperado(e);
        }
      });

  /// Retorna el valor de max_tags_secundarios_por_usuario desde configuracion_int.
  Future<int> obtenerMaxTagsSecundarios() => conReintentos(() async {
        try {
          final fila = await _cliente
              .from(TablasSupabase.configuracion)
              .select('valor')
              .eq('clave', 'max_tags_secundarios_por_usuario')
              .eq('estatus', true)
              .maybeSingle()
              .timeout(kTimeoutSolicitud);
          return (fila?['valor'] as int?) ?? 3;
        } on PostgrestException catch (e) {
          throw FallaServidor(TraductorErrores.dePostgres(e));
        } catch (e) {
          TraductorErrores.lanzarInesperado(e);
        }
      });

  /// Inserta un nuevo evento y retorna su ID generado.
  Future<String> crearEvento({required Map<String, dynamic> datos}) async {
    try {
      final authId = _cliente.auth.currentUser?.id;
      String? usuarioId;
      if (authId != null) {
        final fila = await _cliente
            .from(TablasSupabase.usuarios)
            .select('id')
            .eq('auth_id', authId)
            .single();
        usuarioId = fila['id'] as String?;
      }

      final respuesta = await _cliente
          .from(TablasSupabase.eventos)
          .insert({
            ...datos,
            'creado_por': usuarioId,
          })
          .select('id')
          .single();
      return respuesta['id'] as String;
    } on PostgrestException catch (e) {
      throw FallaServidor(TraductorErrores.dePostgres(e));
    } catch (e) {
      TraductorErrores.lanzarInesperado(e);
    }
  }

  /// Retorna los datos de un evento.
  Future<Map<String, dynamic>> obtenerEvento(String id) =>
      conReintentos(() async {
        try {
          return await _cliente
              .from(TablasSupabase.eventos)
              .select()
              .eq('id', id)
              .single()
              .timeout(kTimeoutSolicitud);
        } on PostgrestException catch (e) {
          throw FallaServidor(TraductorErrores.dePostgres(e));
        } catch (e) {
          TraductorErrores.lanzarInesperado(e);
        }
      });

  /// Retorna los grupos de audiencia de un evento con sus tags completos.
  Future<List<GrupoAudiencia>> obtenerGruposEvento(String eventoId) =>
      conReintentos(() async {
        try {
          final datos = await _cliente
              .from(TablasSupabase.eventoGruposTags)
              .select('grupo_index, tag_id, tags(id, nombre, tipo)')
              .eq('evento_id', eventoId)
              .timeout(kTimeoutSolicitud);

          final Map<int, TagOpcion> principalesPorGrupo = {};
          final Map<int, List<TagOpcion>> secundariosPorGrupo = {};

          for (final fila in (datos as List).cast<Map<String, dynamic>>()) {
            final grupoIndex = fila['grupo_index'] as int;
            final tagData = fila['tags'] as Map<String, dynamic>?;
            if (tagData == null) continue;
            final tag = TagOpcion.desdeJson(tagData);
            if (tag.tipo == 'principal') {
              principalesPorGrupo[grupoIndex] = tag;
            } else {
              secundariosPorGrupo.putIfAbsent(grupoIndex, () => []).add(tag);
            }
          }

          return principalesPorGrupo.entries
              .map(
                (e) => GrupoAudiencia(
                  grupoIndex: e.key,
                  tagPrincipal: e.value,
                  tagsSecundarios: secundariosPorGrupo[e.key] ?? [],
                ),
              )
              .toList();
        } on PostgrestException catch (e) {
          throw FallaServidor(TraductorErrores.dePostgres(e));
        } catch (e) {
          TraductorErrores.lanzarInesperado(e);
        }
      });

  /// Actualiza un evento existente.
  Future<void> actualizarEvento({
    required String id,
    required Map<String, dynamic> datos,
  }) async {
    try {
      final actualizadoPor = await _resolverUsuarioId();
      await _cliente
          .from(TablasSupabase.eventos)
          .update({...datos, 'actualizado_por': actualizadoPor}).eq('id', id);
    } on PostgrestException catch (e) {
      throw FallaServidor(TraductorErrores.dePostgres(e));
    } catch (e) {
      TraductorErrores.lanzarInesperado(e);
    }
  }

  /// Inserta los grupos de audiencia de un evento nuevo.
  Future<void> guardarGruposEvento({
    required String eventoId,
    required List<GrupoAudiencia> grupos,
  }) async {
    try {
      final filas = _construirFilasGrupos(eventoId, grupos);
      if (filas.isNotEmpty) {
        await _cliente.from(TablasSupabase.eventoGruposTags).insert(filas);
      }
    } on PostgrestException catch (e) {
      throw FallaServidor(TraductorErrores.dePostgres(e));
    } catch (e) {
      TraductorErrores.lanzarInesperado(e);
    }
  }

  /// Reemplaza todos los grupos de audiencia de un evento existente.
  Future<void> actualizarGruposEvento({
    required String eventoId,
    required List<GrupoAudiencia> grupos,
  }) async {
    try {
      await _cliente
          .from(TablasSupabase.eventoGruposTags)
          .delete()
          .eq('evento_id', eventoId);
      final filas = _construirFilasGrupos(eventoId, grupos);
      if (filas.isNotEmpty) {
        await _cliente.from(TablasSupabase.eventoGruposTags).insert(filas);
      }
    } on PostgrestException catch (e) {
      throw FallaServidor(TraductorErrores.dePostgres(e));
    } catch (e) {
      TraductorErrores.lanzarInesperado(e);
    }
  }

  /// Retorna los IDs de usuarios cuya audiencia coincide con los grupos del evento.
  /// Usado para notificar al publicar un evento dirigido (N8).
  Future<List<String>> obtenerUsuariosIdsDirigidos(String eventoId) =>
      conReintentos(() async {
        try {
          final grupoRows = await _cliente
              .from(TablasSupabase.eventoGruposTags)
              .select('grupo_index, tag_id')
              .eq('evento_id', eventoId)
              .timeout(kTimeoutSolicitud);
          if ((grupoRows as List).isEmpty) return <String>[];

          final grupos = <int, List<String>>{};
          for (final row in (grupoRows).cast<Map<String, dynamic>>()) {
            final idx = row['grupo_index'] as int;
            grupos.putIfAbsent(idx, () => []).add(row['tag_id'] as String);
          }

          final allTagIds = grupos.values.expand((ids) => ids).toSet().toList();
          final userTagRows = await _cliente
              .from(TablasSupabase.usuariosTags)
              .select('usuario_id, tag_id')
              .inFilter('tag_id', allTagIds)
              .eq('estatus', true)
              .timeout(kTimeoutSolicitud);

          final tagsPorUsuario = <String, Set<String>>{};
          for (final row
              in (userTagRows as List).cast<Map<String, dynamic>>()) {
            final userId = row['usuario_id'] as String;
            final tagId = row['tag_id'] as String;
            tagsPorUsuario.putIfAbsent(userId, () => {}).add(tagId);
          }

          return tagsPorUsuario.entries
              .where((e) => grupos.values.any(e.value.containsAll))
              .map((e) => e.key)
              .toList();
        } on PostgrestException catch (e) {
          throw FallaServidor(TraductorErrores.dePostgres(e));
        } catch (e) {
          TraductorErrores.lanzarInesperado(e);
        }
      });

  List<Map<String, dynamic>> _construirFilasGrupos(
    String eventoId,
    List<GrupoAudiencia> grupos,
  ) {
    final filas = <Map<String, dynamic>>[];
    for (final grupo in grupos) {
      filas.add({
        'evento_id': eventoId,
        'grupo_index': grupo.grupoIndex,
        'tag_id': grupo.tagPrincipal.id,
      });
      for (final sec in grupo.tagsSecundarios) {
        filas.add({
          'evento_id': eventoId,
          'grupo_index': grupo.grupoIndex,
          'tag_id': sec.id,
        });
      }
    }
    return filas;
  }

  Future<String?> _resolverUsuarioId() async {
    final authId = _cliente.auth.currentUser?.id;
    if (authId == null) return null;
    final fila = await _cliente
        .from(TablasSupabase.usuarios)
        .select('id')
        .eq('auth_id', authId)
        .maybeSingle();
    return fila?['id'] as String?;
  }
}
