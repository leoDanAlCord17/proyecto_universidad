import 'package:supabase_flutter/supabase_flutter.dart';

import '../../compartido/constantes.dart';
import '../../compartido/errores.dart';
import '../../compartido/traductor_errores.dart';
import 'permiso_opcion.dart';

class CrearRolRepositorio {
  const CrearRolRepositorio(this._supabase);

  final SupabaseClient _supabase;

  Future<List<PermisoOpcion>> obtenerPermisos() async {
    try {
      final res = await _supabase
          .from(TablasSupabase.permisos)
          .select('id, nombre, descripcion')
          .order('nombre');
      return (res as List)
          .map((j) => PermisoOpcion.desdeJson(j as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw FallaServidor(TraductorErrores.dePostgres(e));
    } catch (e) {
      throw FallaInesperada(TraductorErrores.deInesperado(e));
    }
  }

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
      throw FallaInesperada(TraductorErrores.deInesperado(e));
    }
  }

  Future<void> asignarPermisos({
    required String       rolId,
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
      throw FallaInesperada(TraductorErrores.deInesperado(e));
    }
  }

  Future<({Map<String, dynamic> rol, List<String> permisosIds})> obtenerRol(
    String id,
  ) async {
    try {
      final rol = await _supabase
          .from(TablasSupabase.roles)
          .select('id, nombre, descripcion')
          .eq('id', id)
          .single();
      final perms = await _supabase
          .from(TablasSupabase.rolesPermisos)
          .select('permiso_id')
          .eq('rol_id', id)
          .eq('estatus', true);
      final ids = (perms as List).map((r) => r['permiso_id'] as String).toList();
      return (rol: rol, permisosIds: ids);
    } on PostgrestException catch (e) {
      throw FallaServidor(TraductorErrores.dePostgres(e));
    } catch (e) {
      throw FallaInesperada(TraductorErrores.deInesperado(e));
    }
  }

  Future<void> actualizarRol({
    required String              id,
    required Map<String, dynamic> datos,
  }) async {
    try {
      await _supabase.from(TablasSupabase.roles).update(datos).eq('id', id);
    } on PostgrestException catch (e) {
      throw FallaServidor(TraductorErrores.dePostgres(e));
    } catch (e) {
      throw FallaInesperada(TraductorErrores.deInesperado(e));
    }
  }

  Future<void> sincronizarPermisos({
    required String       rolId,
    required List<String> permisosIds,
  }) async {
    try {
      await _supabase
          .from(TablasSupabase.rolesPermisos)
          .delete()
          .eq('rol_id', rolId);
      if (permisosIds.isNotEmpty) {
        final filas = permisosIds
            .map((pid) => {'rol_id': rolId, 'permiso_id': pid, 'estatus': true})
            .toList();
        await _supabase.from(TablasSupabase.rolesPermisos).insert(filas);
      }
    } on PostgrestException catch (e) {
      throw FallaServidor(TraductorErrores.dePostgres(e));
    } catch (e) {
      throw FallaInesperada(TraductorErrores.deInesperado(e));
    }
  }
}
