import 'package:supabase_flutter/supabase_flutter.dart';

import '../../compartido/constantes.dart';
import '../../compartido/errores.dart';
import '../../compartido/traductor_errores.dart';
import 'permiso.dart';

class PermisosRepositorio {
  const PermisosRepositorio(this._supabase);

  final SupabaseClient _supabase;

  Future<List<Permiso>> obtenerPermisos() async {
    try {
      final respuesta = await _supabase
          .from(TablasSupabase.permisos)
          .select('id, nombre, descripcion')
          .eq('estatus', true)
          .order('nombre');

      return (respuesta as List)
          .map((json) => Permiso.desdeJson(json as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw FallaServidor(TraductorErrores.dePostgres(e));
    } catch (e) {
      throw FallaInesperada(TraductorErrores.deInesperado(e));
    }
  }
}
