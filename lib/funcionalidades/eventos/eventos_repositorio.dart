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
