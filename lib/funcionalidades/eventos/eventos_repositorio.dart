import 'dart:async';
import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../compartido/cache_local.dart';
import '../../compartido/constantes.dart';
import '../../compartido/errores.dart';
import '../../compartido/reintento.dart';
import '../../compartido/traductor_errores.dart';
import 'evento.dart';

class EventosRepositorio {
  const EventosRepositorio(this._supabase);

  final SupabaseClient _supabase;

  static const _claveCacheBase = 'eventos_con_grupos';

  // Namespaced por usuario: en un dispositivo compartido (tablet de control
  // de acceso, recepción), evita que los eventos cacheados de un usuario
  // queden visibles para otro dentro del TTL de la caché.
  String _claveCache(String usuarioId) => '${_claveCacheBase}_$usuarioId';

  /// Retorna todos los eventos en curso y programados con sus grupos de audiencia,
  /// ordenados por fecha de inicio ascendente.
  /// Guarda la respuesta cruda en caché local para uso offline.
  Future<List<EventoConGrupos>> obtenerEventosConGrupos({
    required String usuarioId,
  }) =>
      conReintentos(() async {
        try {
          final datos = await _supabase
              .from(TablasSupabase.eventos)
              .select(
                  '*, evento_grupos_tags(grupo_index, tag_id, tags(tipo, nombre))')
              .inFilter(
                  'estatus', [EstatusEvento.enCurso, EstatusEvento.programado])
              .order('fecha_inicio', ascending: true)
              .timeout(kTimeoutSolicitud);

          unawaited(
            CacheLocal.guardar(_claveCache(usuarioId), jsonEncode(datos)),
          );

          return datos.map<EventoConGrupos>(EventoConGrupos.desdeJson).toList();
        } on PostgrestException catch (e) {
          throw FallaServidor(TraductorErrores.dePostgres(e));
        } catch (e) {
          TraductorErrores.lanzarInesperado(e);
        }
      });

  /// Lee los eventos desde caché local (IndexedDB en web, Hive en móvil).
  /// Devuelve null si no hay caché disponible o si el JSON está corrupto.
  List<EventoConGrupos>? obtenerEventosConGruposDesdeCache(String usuarioId) {
    final json = CacheLocal.leer(_claveCache(usuarioId));
    if (json == null) return null;
    try {
      final lista = jsonDecode(json) as List<dynamic>;
      return lista
          .map<EventoConGrupos>(
            (e) => EventoConGrupos.desdeJson(e as Map<String, dynamic>),
          )
          .toList();
    } catch (_) {
      return null;
    }
  }

  /// Retorna cuántos eventos con estatus "borrador" tiene el usuario.
  Future<int> contarBorradores(String usuarioId) => conReintentos(() async {
        try {
          final datos = await _supabase
              .from(TablasSupabase.eventos)
              .select('id')
              .eq('estatus', EstatusEvento.borrador)
              .eq('creado_por', usuarioId)
              .timeout(kTimeoutSolicitud);
          return datos.length;
        } on PostgrestException catch (e) {
          throw FallaServidor(TraductorErrores.dePostgres(e));
        } catch (e) {
          TraductorErrores.lanzarInesperado(e);
        }
      });

  /// Retorna un mapa [eventoId → cantidad] de asistentes presentes/completados
  /// para los eventos dados. Solo relevante para eventos en curso.
  Future<Map<String, int>> obtenerConteoPresentesPorEvento(
    List<String> eventoIds,
  ) =>
      conReintentos(() async {
        if (eventoIds.isEmpty) return {};
        try {
          final filas = await _supabase
              .from(TablasSupabase.asistencia)
              .select('evento_id')
              .inFilter('evento_id', eventoIds)
              .inFilter('estatus', [
            EstatusAsistencia.presente,
            EstatusAsistencia.completado,
            EstatusAsistencia.salioAnticipado,
          ]).timeout(kTimeoutSolicitud);
          final conteos = <String, int>{};
          for (final fila in filas) {
            final id = fila['evento_id'] as String;
            conteos[id] = (conteos[id] ?? 0) + 1;
          }
          return conteos;
        } on PostgrestException catch (e) {
          throw FallaServidor(TraductorErrores.dePostgres(e));
        } catch (e) {
          TraductorErrores.lanzarInesperado(e);
        }
      });

  /// Retorna el tag principal y los tags secundarios activos del usuario.
  Future<({String? tagPrincipalId, List<String> tagsSecundariosIds})>
      obtenerTagsUsuario(String usuarioId) => conReintentos(() async {
            try {
              final datos = await _supabase
                  .from(TablasSupabase.usuariosTags)
                  .select('tag_id, tags(tipo)')
                  .eq('usuario_id', usuarioId)
                  .eq('estatus', true)
                  .timeout(kTimeoutSolicitud);

              String? tagPrincipalId;
              final tagsSecundariosIds = <String>[];

              for (final fila in datos) {
                final tagId = fila['tag_id'] as String;
                final tipo =
                    (fila['tags'] as Map<String, dynamic>?)?['tipo'] as String?;
                if (tipo == 'principal') {
                  tagPrincipalId = tagId;
                } else {
                  tagsSecundariosIds.add(tagId);
                }
              }

              return (
                tagPrincipalId: tagPrincipalId,
                tagsSecundariosIds: tagsSecundariosIds,
              );
            } on PostgrestException catch (e) {
              throw FallaServidor(TraductorErrores.dePostgres(e));
            } catch (e) {
              TraductorErrores.lanzarInesperado(e);
            }
          });
}
