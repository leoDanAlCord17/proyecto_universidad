import 'package:supabase_flutter/supabase_flutter.dart';

import '../../compartido/constantes.dart';
import '../../compartido/errores.dart';
import '../../compartido/reintento.dart';
import '../../compartido/traductor_errores.dart';
import 'rol.dart';

class RolesRepositorio {
  const RolesRepositorio(this._supabase);

  final SupabaseClient _supabase;

  static const _limite = 20;

  Future<({List<Rol> roles, bool hayMas})> obtenerRoles({
    int offset = 0,
    int limite = _limite,
  }) =>
      conReintentos(() async {
        try {
          final respuesta = await _supabase
              .from(TablasSupabase.roles)
              .select('id, nombre, descripcion, es_sistema')
              .order('nombre')
              .range(offset, offset + limite - 1)
              .timeout(kTimeoutSolicitud);

          final roles = (respuesta as List)
              .map((json) => Rol.desdeJson(json as Map<String, dynamic>))
              .toList();
          return (roles: roles, hayMas: roles.length >= limite);
        } on PostgrestException catch (e) {
          throw FallaServidor(TraductorErrores.dePostgres(e));
        } catch (e) {
          TraductorErrores.lanzarInesperado(e);
        }
      });

  /// Cuenta cuántos usuarios activos tienen asignado cada rol.
  /// Devuelve un mapa rolId → cantidad. Los roles sin asignaciones no aparecen.
  Future<Map<String, int>> contarUsuariosPorRol() =>
      conReintentos(() async {
        try {
          final datos = await _supabase
              .from(TablasSupabase.usuariosRoles)
              .select('rol_id')
              .eq('estatus', true)
              .timeout(kTimeoutSolicitud);

          final conteo = <String, int>{};
          for (final fila in datos) {
            final rolId = fila['rol_id'] as String;
            conteo[rolId] = (conteo[rolId] ?? 0) + 1;
          }
          return conteo;
        } on PostgrestException catch (e) {
          throw FallaServidor(TraductorErrores.dePostgres(e));
        } catch (e) {
          TraductorErrores.lanzarInesperado(e);
        }
      });
}
