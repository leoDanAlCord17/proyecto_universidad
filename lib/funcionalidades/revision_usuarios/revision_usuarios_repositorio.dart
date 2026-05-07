import 'package:supabase_flutter/supabase_flutter.dart';

import '../../compartido/constantes.dart';
import '../../compartido/errores.dart';
import '../../compartido/traductor_errores.dart';
import 'revision_usuario_item.dart';

class RevisionUsuariosRepositorio {
  RevisionUsuariosRepositorio(this._supabase);

  final SupabaseClient _supabase;

  /// Retorna los usuarios con estatus de aprobación pendiente.
  Future<List<RevisionUsuarioItem>> obtenerPendientes() async {
    try {
      final datos = await _supabase
          .from(TablasSupabase.usuarios)
          .select(
            'id, primer_nombre, segundo_nombre, primer_apellido, segundo_apellido, '
            'correo, numero_identificacion, telefono, creado_en',
          )
          .eq('estatus_aprobacion', EstatusAprobacion.pendiente)
          .order('creado_en');
      return datos.map(RevisionUsuarioItem.desdeJson).toList();
    } on PostgrestException catch (e) {
      throw FallaServidor(TraductorErrores.dePostgres(e));
    } catch (e) {
      throw FallaInesperada(TraductorErrores.deInesperado(e));
    }
  }

  /// Aprueba al usuario cambiando su estatus a aprobado.
  /// Los roles y tags se gestionan desde sus pantallas dedicadas.
  Future<void> aprobar(String usuarioId) async {
    try {
      await _supabase
          .from(TablasSupabase.usuarios)
          .update({'estatus_aprobacion': EstatusAprobacion.aprobado})
          .eq('id', usuarioId);
    } on PostgrestException catch (e) {
      throw FallaServidor(TraductorErrores.dePostgres(e));
    } catch (e) {
      throw FallaInesperada(TraductorErrores.deInesperado(e));
    }
  }

  /// Rechaza la solicitud de un usuario pendiente.
  Future<void> rechazar(String usuarioId) async {
    try {
      await _supabase
          .from(TablasSupabase.usuarios)
          .update({'estatus_aprobacion': EstatusAprobacion.rechazado})
          .eq('id', usuarioId);
    } on PostgrestException catch (e) {
      throw FallaServidor(TraductorErrores.dePostgres(e));
    } catch (e) {
      throw FallaInesperada(TraductorErrores.deInesperado(e));
    }
  }
}
