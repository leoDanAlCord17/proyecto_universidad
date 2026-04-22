import 'package:supabase_flutter/supabase_flutter.dart';

import '../../compartido/constantes.dart';
import '../../compartido/errores.dart';
import '../../compartido/traductor_errores.dart';
import 'tag.dart';

class TagsRepositorio {
  const TagsRepositorio(this._supabase);

  final SupabaseClient _supabase;

  Future<List<Tag>> obtenerTags() async {
    try {
      final respuesta = await _supabase
          .from(TablasSupabase.tags)
          .select('id, nombre, tipo, estatus, descripcion, usuarios_tags(count)')
          .eq('usuarios_tags.estatus', true)
          .order('nombre');

      return (respuesta as List)
          .map((json) => Tag.desdeJson(json as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw FallaServidor(TraductorErrores.dePostgres(e));
    } catch (e) {
      throw FallaInesperada(TraductorErrores.deInesperado(e));
    }
  }

  Future<void> activarTag(String id) async {
    try {
      await _supabase
          .from(TablasSupabase.tags)
          .update({'estatus': true})
          .eq('id', id);
    } on PostgrestException catch (e) {
      throw FallaServidor(TraductorErrores.dePostgres(e));
    } catch (e) {
      throw FallaInesperada(TraductorErrores.deInesperado(e));
    }
  }

  /// Desactiva primero las asignaciones y luego el tag.
  /// Si falla el primer paso, nada cambia. Si falla el segundo,
  /// las asignaciones ya están desactivadas — estado recuperable con reintentar.
  Future<void> desactivarTag(String id) async {
    try {
      await _supabase
          .from(TablasSupabase.usuariosTags)
          .update({'estatus': false})
          .eq('tag_id', id);
      await _supabase
          .from(TablasSupabase.tags)
          .update({'estatus': false})
          .eq('id', id);
    } on PostgrestException catch (e) {
      throw FallaServidor(TraductorErrores.dePostgres(e));
    } catch (e) {
      throw FallaInesperada(TraductorErrores.deInesperado(e));
    }
  }
}
