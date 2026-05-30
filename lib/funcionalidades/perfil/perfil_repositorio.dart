import 'package:supabase_flutter/supabase_flutter.dart';

import '../../compartido/constantes.dart';
import '../../compartido/errores.dart';
import '../../compartido/traductor_errores.dart';

class PerfilRepositorio {

  PerfilRepositorio(this._supabase);
  final SupabaseClient _supabase;

  /// Obtiene el tag principal y los tags secundarios activos del usuario.
  Future<({String? tagPrincipal, List<String> tagsSecundarios})> obtenerTags(
    String usuarioId,
  ) async {
    try {
      final datos = await _supabase
          .from(TablasSupabase.usuariosTags)
          .select('tags(nombre, tipo)')
          .eq('usuario_id', usuarioId)
          .eq('estatus', true);

      String? tagPrincipal;
      final tagsSecundarios = <String>[];

      for (final fila in datos) {
        final tag    = fila['tags'] as Map<String, dynamic>;
        final nombre = tag['nombre'] as String;
        final tipo   = tag['tipo']   as String;
        if (tipo == 'principal') {
          tagPrincipal = nombre;
        } else {
          tagsSecundarios.add(nombre);
        }
      }

      return (tagPrincipal: tagPrincipal, tagsSecundarios: tagsSecundarios);
    } on PostgrestException catch (e) {
      throw FallaServidor(TraductorErrores.dePostgres(e));
    } catch (e) {
      throw FallaInesperada(TraductorErrores.deInesperado(e));
    }
  }

  /// Retorna true si la configuración permite al usuario editar su perfil.
  /// Devuelve false ante cualquier error (seguro por defecto).
  Future<bool> obtenerPuedeEditarPerfil() async {
    try {
      final fila = await _supabase
          .from(TablasSupabase.configuracion)
          .select('valor')
          .eq('clave', 'usuario_editar_perfil')
          .eq('estatus', true)
          .maybeSingle();
      return (fila?['valor'] as int?) == 1;
    } on PostgrestException catch (_) {
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Actualiza los datos personales del usuario en la tabla usuarios.
  Future<void> actualizarPerfil({
    required String               usuarioId,
    required Map<String, dynamic> datos,
  }) async {
    try {
      await _supabase
          .from(TablasSupabase.usuarios)
          .update(datos)
          .eq('id', usuarioId);
    } on PostgrestException catch (e) {
      throw FallaServidor(TraductorErrores.dePostgres(e));
    } catch (e) {
      throw FallaInesperada(TraductorErrores.deInesperado(e));
    }
  }
}
