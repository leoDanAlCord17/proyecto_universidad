import 'package:supabase_flutter/supabase_flutter.dart';

import '../../compartido/constantes.dart';
import '../../compartido/errores.dart';
import '../../compartido/reintento.dart';
import '../../compartido/traductor_errores.dart';
import 'permiso_opcion.dart';

class CrearRolRepositorio {
  const CrearRolRepositorio(this._supabase);

  final SupabaseClient _supabase;

  Future<List<PermisoOpcion>> obtenerPermisos() => conReintentos(() async {
        try {
          final res = await _supabase
              .from(TablasSupabase.permisos)
              .select('id, nombre, descripcion')
              .eq('estatus', true)
              .order('nombre')
              .timeout(kTimeoutSolicitud);
          return (res as List)
              .map((j) => PermisoOpcion.desdeJson(j as Map<String, dynamic>))
              .toList();
        } on PostgrestException catch (e) {
          throw FallaServidor(TraductorErrores.dePostgres(e));
        } catch (e) {
          TraductorErrores.lanzarInesperado(e);
        }
      });

  Future<String> crearRol({required Map<String, dynamic> datos}) async {
    try {
      final res = await _supabase
          .from(TablasSupabase.roles)
          .insert(datos)
          .select('id')
          .single();
      return res['id'] as String;
    } on PostgrestException catch (e) {
      throw FallaServidor(TraductorErrores.dePostgres(e));
    } catch (e) {
      TraductorErrores.lanzarInesperado(e);
    }
  }

  Future<void> asignarPermisos({
    required String rolId,
    required List<String> permisosIds,
  }) async {
    try {
      final filas = permisosIds
          .map((pid) => {'rol_id': rolId, 'permiso_id': pid, 'estatus': true})
          .toList();
      await _supabase.from(TablasSupabase.rolesPermisos).insert(filas);
    } on PostgrestException catch (e) {
      throw FallaServidor(TraductorErrores.dePostgres(e));
    } catch (e) {
      TraductorErrores.lanzarInesperado(e);
    }
  }

  Future<({Map<String, dynamic> rol, List<String> permisosIds})> obtenerRol(
    String id,
  ) =>
      conReintentos(() async {
        try {
          final rol = await _supabase
              .from(TablasSupabase.roles)
              .select('id, nombre, descripcion')
              .eq('id', id)
              .single()
              .timeout(kTimeoutSolicitud);
          final perms = await _supabase
              .from(TablasSupabase.rolesPermisos)
              .select('permiso_id')
              .eq('rol_id', id)
              .eq('estatus', true)
              .timeout(kTimeoutSolicitud);
          final ids = (perms as List)
              .cast<Map<String, dynamic>>()
              .map((r) => r['permiso_id'] as String)
              .toList();
          return (rol: rol, permisosIds: ids);
        } on PostgrestException catch (e) {
          throw FallaServidor(TraductorErrores.dePostgres(e));
        } catch (e) {
          TraductorErrores.lanzarInesperado(e);
        }
      });

  Future<void> actualizarRol({
    required String id,
    required Map<String, dynamic> datos,
  }) async {
    try {
      final actualizadoPor = await _resolverUsuarioId();
      await _supabase
          .from(TablasSupabase.roles)
          .update({...datos, 'actualizado_por': actualizadoPor}).eq('id', id);
    } on PostgrestException catch (e) {
      throw FallaServidor(TraductorErrores.dePostgres(e));
    } catch (e) {
      TraductorErrores.lanzarInesperado(e);
    }
  }

  /// Sincroniza permisos usando diff: solo elimina los removidos e inserta los nuevos.
  /// Evita borrar todo y reinsertar, que deja el rol sin permisos si el insert falla.
  Future<void> sincronizarPermisos({
    required String rolId,
    required List<String> nuevosIds,
    required List<String> anterioresIds,
  }) async {
    try {
      final aDesactivar =
          anterioresIds.where((id) => !nuevosIds.contains(id)).toList();
      final aActivar =
          nuevosIds.where((id) => !anterioresIds.contains(id)).toList();

      if (aDesactivar.isNotEmpty) {
        final actualizadoPor = await _resolverUsuarioId();
        await _supabase
            .from(TablasSupabase.rolesPermisos)
            .update({'estatus': false, 'actualizado_por': actualizadoPor})
            .eq('rol_id', rolId)
            .inFilter('permiso_id', aDesactivar);
      }
      if (aActivar.isNotEmpty) {
        final filas = aActivar
            .map((pid) => {'rol_id': rolId, 'permiso_id': pid, 'estatus': true})
            .toList();
        await _supabase
            .from(TablasSupabase.rolesPermisos)
            .upsert(filas, onConflict: 'rol_id,permiso_id');
      }
    } on PostgrestException catch (e) {
      throw FallaServidor(TraductorErrores.dePostgres(e));
    } catch (e) {
      TraductorErrores.lanzarInesperado(e);
    }
  }

  Future<String?> _resolverUsuarioId() async {
    final authId = _supabase.auth.currentUser?.id;
    if (authId == null) return null;
    final fila = await _supabase
        .from(TablasSupabase.usuarios)
        .select('id')
        .eq('auth_id', authId)
        .maybeSingle();
    return fila?['id'] as String?;
  }
}
