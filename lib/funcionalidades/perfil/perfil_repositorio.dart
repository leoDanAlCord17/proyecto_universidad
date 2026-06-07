import 'dart:async';
import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../compartido/cache_local.dart';
import '../../compartido/constantes.dart';
import '../../compartido/errores.dart';
import '../../compartido/reintento.dart';
import '../../compartido/traductor_errores.dart';

class PerfilRepositorio {

  PerfilRepositorio(this._supabase);
  final SupabaseClient _supabase;

  static const _claveTags = 'perfil_tags';

  /// Obtiene el tag principal y los tags secundarios activos del usuario.
  /// Guarda el resultado en caché local para uso offline.
  Future<({String? tagPrincipal, List<String> tagsSecundarios})> obtenerTags(
    String usuarioId,
  ) =>
      conReintentos(() async {
        try {
          final datos = await _supabase
              .from(TablasSupabase.usuariosTags)
              .select('tags(nombre, tipo)')
              .eq('usuario_id', usuarioId)
              .eq('estatus', true)
              .timeout(kTimeoutSolicitud);

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

          unawaited(
            CacheLocal.guardar(
              '${_claveTags}_$usuarioId',
              jsonEncode({'tagPrincipal': tagPrincipal, 'tagsSecundarios': tagsSecundarios}),
            ),
          );

          return (tagPrincipal: tagPrincipal, tagsSecundarios: tagsSecundarios);
        } on PostgrestException catch (e) {
          throw FallaServidor(TraductorErrores.dePostgres(e));
        } catch (e) {
          TraductorErrores.lanzarInesperado(e);
        }
      });

  /// Lee los tags del usuario desde caché local. Devuelve null si no hay caché.
  ({String? tagPrincipal, List<String> tagsSecundarios})? obtenerTagsDesdeCache(
    String usuarioId,
  ) {
    final json = CacheLocal.leer('${_claveTags}_$usuarioId');
    if (json == null) return null;
    try {
      final mapa           = jsonDecode(json) as Map<String, dynamic>;
      final tagsSecundarios = (mapa['tagsSecundarios'] as List<dynamic>)
          .map((e) => e as String)
          .toList();
      return (
        tagPrincipal:    mapa['tagPrincipal'] as String?,
        tagsSecundarios: tagsSecundarios,
      );
    } catch (_) {
      return null;
    }
  }

  /// Retorna true si la configuración permite al usuario editar su perfil.
  /// Devuelve false ante cualquier error (seguro por defecto).
  Future<bool> obtenerPuedeEditarPerfil() =>
      conReintentos(() async {
        try {
          final fila = await _supabase
              .from(TablasSupabase.configuracion)
              .select('valor')
              .eq('clave', 'usuario_editar_perfil')
              .eq('estatus', true)
              .maybeSingle()
              .timeout(kTimeoutSolicitud);
          return (fila?['valor'] as int?) == 1;
        } on PostgrestException catch (_) {
          return false;
        } catch (_) {
          return false;
        }
      });

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
      TraductorErrores.lanzarInesperado(e);
    }
  }
}
