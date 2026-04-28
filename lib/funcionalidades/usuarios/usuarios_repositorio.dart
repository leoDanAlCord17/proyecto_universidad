import 'package:supabase_flutter/supabase_flutter.dart';

import '../../compartido/constantes.dart';
import '../../compartido/errores.dart';
import '../../compartido/traductor_errores.dart';
import 'usuario_item.dart';

class UsuariosRepositorio {
  const UsuariosRepositorio(this._supabase);

  final SupabaseClient _supabase;

  Future<void> suspenderUsuario(String usuarioId) async {
    try {
      await _supabase
          .from(TablasSupabase.usuarios)
          .update({'estatus': false})
          .eq('id', usuarioId);
    } on PostgrestException catch (e) {
      throw FallaServidor(TraductorErrores.dePostgres(e));
    } catch (e) {
      throw FallaInesperada(TraductorErrores.deInesperado(e));
    }
  }

  /// Retorna todos los usuarios con los campos necesarios para la lista.
  Future<List<UsuarioItem>> obtenerUsuarios() async {
    try {
      final respuesta = await _supabase
          .from(TablasSupabase.usuarios)
          .select('id, primer_nombre, primer_apellido, correo, estatus, numero_identificacion')
          .order('primer_nombre');
      return (respuesta as List)
          .map((json) => UsuarioItem.desdeJson(json as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw FallaServidor(TraductorErrores.dePostgres(e));
    } catch (e) {
      throw FallaInesperada(TraductorErrores.deInesperado(e));
    }
  }
}
