import 'package:supabase_flutter/supabase_flutter.dart';

import '../../compartido/constantes.dart';
import '../../compartido/errores.dart';
import '../../compartido/reintento.dart';
import '../../compartido/traductor_errores.dart';
import 'usuario_item.dart';

class UsuariosRepositorio {
  const UsuariosRepositorio(this._supabase);

  final SupabaseClient _supabase;

  Future<void> suspenderUsuario(String usuarioId) async {
    try {
      await _supabase
          .from(TablasSupabase.usuarios)
          .update({'estatus': false}).eq('id', usuarioId);
    } on PostgrestException catch (e) {
      throw FallaServidor(TraductorErrores.dePostgres(e));
    } catch (e) {
      TraductorErrores.lanzarInesperado(e);
    }
  }

  static const _limite = 20;

  Future<({List<UsuarioItem> usuarios, bool hayMas})> obtenerUsuarios({
    int offset = 0,
    int limite = _limite,
  }) =>
      conReintentos(() async {
        try {
          final respuesta = await _supabase
              .from(TablasSupabase.usuarios)
              .select(
                  'id, primer_nombre, primer_apellido, correo, estatus, numero_identificacion, url_avatar')
              .order('primer_nombre')
              .range(offset, offset + limite - 1)
              .timeout(kTimeoutSolicitud);
          final lista = (respuesta as List)
              .map(
                  (json) => UsuarioItem.desdeJson(json as Map<String, dynamic>))
              .toList();
          return (usuarios: lista, hayMas: lista.length == limite);
        } on PostgrestException catch (e) {
          throw FallaServidor(TraductorErrores.dePostgres(e));
        } catch (e) {
          TraductorErrores.lanzarInesperado(e);
        }
      });

  // ── Métodos para acciones en lote ──────────────────────────────────────────

  /// Retorna roles activos del sistema para el selector de asignación en lote.
  Future<List<({String id, String nombre})>> obtenerRolesActivos() =>
      conReintentos(() async {
        try {
          final datos = await _supabase
              .from(TablasSupabase.roles)
              .select('id, nombre')
              .eq('estatus', true)
              .order('nombre')
              .timeout(kTimeoutSolicitud);
          return datos
              .map<({String id, String nombre})>(
                (r) => (id: r['id'] as String, nombre: r['nombre'] as String),
              )
              .toList();
        } on PostgrestException catch (e) {
          throw FallaServidor(TraductorErrores.dePostgres(e));
        } catch (e) {
          TraductorErrores.lanzarInesperado(e);
        }
      });

  /// Retorna tags activos del sistema para el selector de asignación en lote.
  Future<List<({String id, String nombre, String tipo})>>
      obtenerTagsActivos() => conReintentos(() async {
            try {
              final datos = await _supabase
                  .from(TablasSupabase.tags)
                  .select('id, nombre, tipo')
                  .eq('estatus', true)
                  .order('nombre')
                  .timeout(kTimeoutSolicitud);
              return datos
                  .map<({String id, String nombre, String tipo})>(
                    (t) => (
                      id: t['id'] as String,
                      nombre: t['nombre'] as String,
                      tipo: t['tipo'] as String? ?? '',
                    ),
                  )
                  .toList();
            } on PostgrestException catch (e) {
              throw FallaServidor(TraductorErrores.dePostgres(e));
            } catch (e) {
              TraductorErrores.lanzarInesperado(e);
            }
          });

  /// Asigna el mismo rol a múltiples usuarios (upsert para no duplicar).
  Future<void> asignarRolLote(
    List<String> usuarioIds,
    String rolId,
    String adminId,
  ) async {
    try {
      final registros = usuarioIds
          .map(
            (uid) => {
              'usuario_id': uid,
              'rol_id': rolId,
              'estatus': true,
              'creado_por': adminId,
            },
          )
          .toList();
      await _supabase.from(TablasSupabase.usuariosRoles).upsert(
            registros,
            onConflict: 'usuario_id,rol_id',
          );
    } on PostgrestException catch (e) {
      throw FallaServidor(TraductorErrores.dePostgres(e));
    } catch (e) {
      TraductorErrores.lanzarInesperado(e);
    }
  }

  /// Asigna el mismo tag a múltiples usuarios (insert; sin deactivar previos).
  Future<void> asignarTagLote(
    List<String> usuarioIds,
    String tagId,
    String adminId,
  ) async {
    try {
      final registros = usuarioIds
          .map(
            (uid) => {
              'usuario_id': uid,
              'tag_id': tagId,
              'estatus': true,
              'creado_por': adminId,
            },
          )
          .toList();
      await _supabase.from(TablasSupabase.usuariosTags).insert(registros);
    } on PostgrestException catch (e) {
      throw FallaServidor(TraductorErrores.dePostgres(e));
    } catch (e) {
      TraductorErrores.lanzarInesperado(e);
    }
  }

  /// Suspende múltiples usuarios en una sola operación.
  Future<void> suspenderLote(List<String> usuarioIds) async {
    try {
      await _supabase
          .from(TablasSupabase.usuarios)
          .update({'estatus': false}).inFilter('id', usuarioIds);
    } on PostgrestException catch (e) {
      throw FallaServidor(TraductorErrores.dePostgres(e));
    } catch (e) {
      TraductorErrores.lanzarInesperado(e);
    }
  }
}
