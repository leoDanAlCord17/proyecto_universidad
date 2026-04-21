import 'package:supabase_flutter/supabase_flutter.dart';

import '../../compartido/constantes.dart';
import '../../compartido/errores.dart';
import 'tag_opcion.dart';
import 'tipo_evento.dart';

class CrearEventoRepositorio {
  const CrearEventoRepositorio(this._cliente);

  final SupabaseClient _cliente;

  /// Retorna los tipos de evento con estatus activo.
  Future<List<TipoEvento>> obtenerTiposEvento() async {
    try {
      final datos = await _cliente
          .from(TablasSupabase.tiposEvento)
          .select()
          .eq('estatus', 'activo');
      return (datos as List).map((e) => TipoEvento.desdeJson(e)).toList();
    } on PostgrestException catch (e) {
      throw FallaServidor(e.message);
    } catch (e) {
      throw FallaInesperada(e.toString());
    }
  }

  /// Retorna los tags activos (principales y secundarios).
  Future<List<TagOpcion>> obtenerTags() async {
    try {
      final datos = await _cliente
          .from(TablasSupabase.tags)
          .select()
          .eq('estatus', true);
      return (datos as List).map((e) => TagOpcion.desdeJson(e)).toList();
    } on PostgrestException catch (e) {
      throw FallaServidor(e.message);
    } catch (e) {
      throw FallaInesperada(e.toString());
    }
  }

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
      throw FallaServidor(e.message);
    } catch (e) {
      throw FallaInesperada(e.toString());
    }
  }

  /// Retorna los datos de un evento y sus tag IDs separados por tipo.
  Future<({
    Map<String, dynamic> evento,
    List<String> tagsPrincipalesIds,
    List<String> tagsSecundariosIds,
  })> obtenerEvento(String id) async {
    try {
      final eventoData = await _cliente
          .from(TablasSupabase.eventos)
          .select()
          .eq('id', id)
          .single();

      final tagsData = await _cliente
          .from(TablasSupabase.eventosTags)
          .select('tag_id, tags(tipo)')
          .eq('evento_id', id)
          .eq('estatus', true);

      final tagsPrincipalesIds = <String>[];
      final tagsSecundariosIds = <String>[];

      for (final fila in tagsData as List) {
        final tagId = fila['tag_id'] as String;
        final tipo  = (fila['tags'] as Map?)?['tipo'] as String?;
        if (tipo == 'principal') {
          tagsPrincipalesIds.add(tagId);
        } else {
          tagsSecundariosIds.add(tagId);
        }
      }

      return (
        evento:              eventoData,
        tagsPrincipalesIds:  tagsPrincipalesIds,
        tagsSecundariosIds:  tagsSecundariosIds,
      );
    } on PostgrestException catch (e) {
      throw FallaServidor(e.message);
    } catch (e) {
      throw FallaInesperada(e.toString());
    }
  }

  /// Actualiza un evento existente.
  Future<void> actualizarEvento({
    required String             id,
    required Map<String, dynamic> datos,
  }) async {
    try {
      await _cliente.from(TablasSupabase.eventos).update(datos).eq('id', id);
    } on PostgrestException catch (e) {
      throw FallaServidor(e.message);
    } catch (e) {
      throw FallaInesperada(e.toString());
    }
  }

  /// Reemplaza todos los tags de un evento (borra los existentes e inserta los nuevos).
  Future<void> actualizarTagsEvento({
    required String       eventoId,
    required List<String> tagIds,
  }) async {
    try {
      await _cliente
          .from(TablasSupabase.eventosTags)
          .delete()
          .eq('evento_id', eventoId);
      if (tagIds.isNotEmpty) {
        final filas = tagIds
            .map((id) => {'evento_id': eventoId, 'tag_id': id, 'estatus': true})
            .toList();
        await _cliente.from(TablasSupabase.eventosTags).insert(filas);
      }
    } on PostgrestException catch (e) {
      throw FallaServidor(e.message);
    } catch (e) {
      throw FallaInesperada(e.toString());
    }
  }

  /// Asocia una lista de tags a un evento existente.
  Future<void> guardarTagsEvento({
    required String       eventoId,
    required List<String> tagIds,
  }) async {
    try {
      final filas = tagIds
          .map((id) => {'evento_id': eventoId, 'tag_id': id, 'estatus': true})
          .toList();
      await _cliente.from(TablasSupabase.eventosTags).insert(filas);
    } on PostgrestException catch (e) {
      throw FallaServidor(e.message);
    } catch (e) {
      throw FallaInesperada(e.toString());
    }
  }
}
