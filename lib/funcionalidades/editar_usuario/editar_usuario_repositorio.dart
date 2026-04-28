import 'package:supabase_flutter/supabase_flutter.dart';

import '../../compartido/constantes.dart';
import '../../compartido/errores.dart';
import '../../compartido/traductor_errores.dart';

class EditarUsuarioRepositorio {
  const EditarUsuarioRepositorio(this._supabase);

  final SupabaseClient _supabase;

  /// Retorna los campos editables del usuario identificado por [usuarioId].
  Future<Map<String, dynamic>> obtenerUsuario(String usuarioId) async {
    try {
      return await _supabase
          .from(TablasSupabase.usuarios)
          .select(
            'id, primer_nombre, segundo_nombre, primer_apellido, '
            'segundo_apellido, numero_identificacion, correo, telefono',
          )
          .eq('id', usuarioId)
          .single();
    } on PostgrestException catch (e) {
      throw FallaServidor(TraductorErrores.dePostgres(e));
    } catch (e) {
      throw FallaInesperada(TraductorErrores.deInesperado(e));
    }
  }

  /// Actualiza la información personal del usuario. Los campos opcionales
  /// se envían como [null] cuando vienen vacíos para limpiar el valor en BD.
  Future<void> actualizarUsuario({
    required String  usuarioId,
    required String  primerNombre,
    String?          segundoNombre,
    required String  primerApellido,
    String?          segundoApellido,
    String?          numeroIdentificacion,
    required String  correo,
    String?          telefono,
  }) async {
    try {
      await _supabase
          .from(TablasSupabase.usuarios)
          .update({
            'primer_nombre':         primerNombre,
            'segundo_nombre':        segundoNombre?.isNotEmpty == true ? segundoNombre : null,
            'primer_apellido':       primerApellido,
            'segundo_apellido':      segundoApellido?.isNotEmpty == true ? segundoApellido : null,
            'numero_identificacion': numeroIdentificacion?.isNotEmpty == true ? numeroIdentificacion : null,
            'correo':                correo,
            'telefono':              telefono?.isNotEmpty == true ? telefono : null,
          })
          .eq('id', usuarioId);
    } on PostgrestException catch (e) {
      throw FallaServidor(TraductorErrores.dePostgres(e));
    } catch (e) {
      throw FallaInesperada(TraductorErrores.deInesperado(e));
    }
  }
}
