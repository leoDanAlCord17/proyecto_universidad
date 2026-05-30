import 'package:supabase_flutter/supabase_flutter.dart';

import '../../compartido/constantes.dart';
import '../../compartido/errores.dart';
import '../../compartido/traductor_errores.dart';
import 'evento.dart';

class EventosRepositorio {
  const EventosRepositorio(this._supabase);

  final SupabaseClient _supabase;

  /// Retorna todos los eventos en curso y programados con sus grupos de audiencia,
  /// ordenados por fecha de inicio ascendente.
  Future<List<EventoConGrupos>> obtenerEventosConGrupos() async {
    try {
      final datos = await _supabase
          .from(TablasSupabase.eventos)
          .select('*, evento_grupos_tags(grupo_index, tag_id, tags(tipo, nombre))')
          .inFilter('estatus', [EstatusEvento.enCurso, EstatusEvento.programado])
          .order('fecha_inicio', ascending: true);

      return datos.map<EventoConGrupos>(EventoConGrupos.desdeJson).toList();
    } on PostgrestException catch (e) {
      throw FallaServidor(TraductorErrores.dePostgres(e));
    } catch (e) {
      throw FallaInesperada(TraductorErrores.deInesperado(e));
    }
  }

  /// Retorna cuántos eventos con estatus "borrador" tiene el usuario.
  Future<int> contarBorradores(String usuarioId) async {
    try {
      final datos = await _supabase
          .from(TablasSupabase.eventos)
          .select('id')
          .eq('estatus', EstatusEvento.borrador)
          .eq('creado_por', usuarioId);
      return datos.length;
    } on PostgrestException catch (e) {
      throw FallaServidor(TraductorErrores.dePostgres(e));
    } catch (e) {
      throw FallaInesperada(TraductorErrores.deInesperado(e));
    }
  }

  /// Retorna un mapa [eventoId → cantidad] de asistentes presentes/completados
  /// para los eventos dados. Solo relevante para eventos en curso.
  Future<Map<String, int>> obtenerConteoPresentesPorEvento(
    List<String> eventoIds,
  ) async {
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
          ]);
      final conteos = <String, int>{};
      for (final fila in filas) {
        final id = fila['evento_id'] as String;
        conteos[id] = (conteos[id] ?? 0) + 1;
      }
      return conteos;
    } on PostgrestException catch (e) {
      throw FallaServidor(TraductorErrores.dePostgres(e));
    } catch (e) {
      throw FallaInesperada(TraductorErrores.deInesperado(e));
    }
  }

  /// Retorna el tag principal y los tags secundarios activos del usuario.
  Future<({String? tagPrincipalId, List<String> tagsSecundariosIds})>
      obtenerTagsUsuario(String usuarioId) async {
    try {
      final datos = await _supabase
          .from(TablasSupabase.usuariosTags)
          .select('tag_id, tags(tipo)')
          .eq('usuario_id', usuarioId)
          .eq('estatus', true);

      String?      tagPrincipalId;
      final        tagsSecundariosIds = <String>[];

      for (final fila in datos) {
        final tagId = fila['tag_id'] as String;
        final tipo  = (fila['tags'] as Map<String, dynamic>?)?['tipo'] as String?;
        if (tipo == 'principal') {
          tagPrincipalId = tagId;
        } else {
          tagsSecundariosIds.add(tagId);
        }
      }

      return (
        tagPrincipalId:     tagPrincipalId,
        tagsSecundariosIds: tagsSecundariosIds,
      );
    } on PostgrestException catch (e) {
      throw FallaServidor(TraductorErrores.dePostgres(e));
    } catch (e) {
      throw FallaInesperada(TraductorErrores.deInesperado(e));
    }
  }
}
