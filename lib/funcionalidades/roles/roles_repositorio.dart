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
}
