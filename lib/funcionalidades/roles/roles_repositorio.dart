import 'package:supabase_flutter/supabase_flutter.dart';

import '../../compartido/constantes.dart';
import '../../compartido/errores.dart';
import '../../compartido/traductor_errores.dart';
import 'rol.dart';

class RolesRepositorio {
  const RolesRepositorio(this._supabase);

  final SupabaseClient _supabase;

  Future<List<Rol>> obtenerRoles() async {
    try {
      final respuesta = await _supabase
          .from(TablasSupabase.roles)
          .select('id, nombre, descripcion, es_sistema')
          .order('nombre');

      return (respuesta as List)
          .map((json) => Rol.desdeJson(json as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw FallaServidor(TraductorErrores.dePostgres(e));
    } catch (e) {
      throw FallaInesperada(TraductorErrores.deInesperado(e));
    }
  }

  /// Cuenta cuántos usuarios activos tienen asignado cada rol.
  /// Devuelve un mapa rolId → cantidad. Los roles sin asignaciones no aparecen.
  Future<Map<String, int>> contarUsuariosPorRol() async {
    try {
      final datos = await _supabase
          .from(TablasSupabase.usuariosRoles)
          .select('rol_id')
          .eq('estatus', true);

      final conteo = <String, int>{};
      for (final fila in datos) {
        final rolId = fila['rol_id'] as String;
        conteo[rolId] = (conteo[rolId] ?? 0) + 1;
      }
      return conteo;
    } on PostgrestException catch (e) {
      throw FallaServidor(TraductorErrores.dePostgres(e));
    } catch (e) {
      throw FallaInesperada(TraductorErrores.deInesperado(e));
    }
  }
}
