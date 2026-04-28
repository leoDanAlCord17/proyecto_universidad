import 'package:supabase_flutter/supabase_flutter.dart';

import '../../compartido/constantes.dart';
import '../../compartido/errores.dart';
import '../../compartido/traductor_errores.dart';
import 'tag_item.dart';

class GestionarTagsUsuarioRepositorio {
  const GestionarTagsUsuarioRepositorio(this._supabase);

  final SupabaseClient _supabase;

  /// Retorna nombre completo y correo del usuario.
  Future<({String nombre, String correo})> obtenerInfoUsuario(String usuarioId) async {
    try {
      final fila = await _supabase
          .from(TablasSupabase.usuarios)
          .select('primer_nombre, primer_apellido, correo')
          .eq('id', usuarioId)
          .single();
      final nombre = '${fila['primer_nombre']} ${fila['primer_apellido']}';
      return (nombre: nombre, correo: fila['correo'] as String? ?? '');
    } on PostgrestException catch (e) {
      throw FallaServidor(TraductorErrores.dePostgres(e));
    } catch (e) {
      throw FallaInesperada(TraductorErrores.deInesperado(e));
    }
  }

  /// Retorna los tags actualmente activos del usuario separados por tipo.
  Future<({TagItem? tagPrincipal, List<TagItem> tagsSecundarios})> obtenerTagsUsuario(
    String usuarioId,
  ) async {
    try {
      final datos = await _supabase
          .from(TablasSupabase.usuariosTags)
          .select('tags(id, nombre, tipo)')
          .eq('usuario_id', usuarioId)
          .eq('estatus', true);

      TagItem?      principal;
      final         secundarios  = <TagItem>[];

      for (final fila in datos) {
        final tagData = fila['tags'] as Map<String, dynamic>?;
        if (tagData == null) continue;
        final tag = TagItem.desdeJson(tagData);
        if (tag.esPrincipal) {
          principal = tag;
        } else {
          secundarios.add(tag);
        }
      }
      return (tagPrincipal: principal, tagsSecundarios: secundarios);
    } on PostgrestException catch (e) {
      throw FallaServidor(TraductorErrores.dePostgres(e));
    } catch (e) {
      throw FallaInesperada(TraductorErrores.deInesperado(e));
    }
  }

  /// Retorna todos los tags activos del sistema.
  Future<List<TagItem>> obtenerTagsActivos() async {
    try {
      final datos = await _supabase
          .from(TablasSupabase.tags)
          .select('id, nombre, tipo')
          .eq('estatus', true)
          .order('nombre');
      return datos.map(TagItem.desdeJson).toList();
    } on PostgrestException catch (e) {
      throw FallaServidor(TraductorErrores.dePostgres(e));
    } catch (e) {
      throw FallaInesperada(TraductorErrores.deInesperado(e));
    }
  }

  /// Retorna el límite de tags secundarios por usuario desde configuracion_int.
  Future<int> obtenerMaxTagsSecundarios() async {
    try {
      final fila = await _supabase
          .from(TablasSupabase.configuracionInt)
          .select('valor')
          .eq('clave', 'max_tags_secundarios_por_usuario')
          .maybeSingle();
      return (fila?['valor'] as int?) ?? 3;
    } on PostgrestException catch (e) {
      throw FallaServidor(TraductorErrores.dePostgres(e));
    } catch (e) {
      throw FallaInesperada(TraductorErrores.deInesperado(e));
    }
  }

  /// Inserta un nuevo registro de asignación de tag.
  /// Siempre crea un registro nuevo para preservar trazabilidad.
  Future<void> asignarTag(String usuarioId, String tagId, String? adminId) async {
    try {
      await _supabase.from(TablasSupabase.usuariosTags).insert({
        'usuario_id':   usuarioId,
        'tag_id':       tagId,
        'estatus':      true,
        'asignado_por': adminId,
      });
    } on PostgrestException catch (e) {
      throw FallaServidor(TraductorErrores.dePostgres(e));
    } catch (e) {
      throw FallaInesperada(TraductorErrores.deInesperado(e));
    }
  }

  /// Desactiva el registro activo del tag, registrando quién y cuándo lo quitó.
  Future<void> quitarTag(String usuarioId, String tagId, String? adminId) async {
    try {
      await _supabase
          .from(TablasSupabase.usuariosTags)
          .update({
            'estatus':         false,
            'actualizado_por': adminId,
            'actualizado_en':  DateTime.now().toUtc().toIso8601String(),
          })
          .eq('usuario_id', usuarioId)
          .eq('tag_id',     tagId)
          .eq('estatus',    true);
    } on PostgrestException catch (e) {
      throw FallaServidor(TraductorErrores.dePostgres(e));
    } catch (e) {
      throw FallaInesperada(TraductorErrores.deInesperado(e));
    }
  }
}
