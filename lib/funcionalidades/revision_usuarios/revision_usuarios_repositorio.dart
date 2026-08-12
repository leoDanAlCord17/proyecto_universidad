import 'package:supabase_flutter/supabase_flutter.dart';

import '../../compartido/constantes.dart';
import '../../compartido/errores.dart';
import '../../compartido/reintento.dart';
import '../../compartido/traductor_errores.dart';
import 'revision_usuario_item.dart';

class RevisionUsuariosRepositorio {
  RevisionUsuariosRepositorio(this._supabase);

  final SupabaseClient _supabase;

  static const _limite = 20;

  /// Retorna una página de usuarios pendientes de aprobación.
  Future<({List<RevisionUsuarioItem> usuarios, bool hayMas})>
      obtenerPendientes({
    int offset = 0,
    int limite = _limite,
  }) =>
          conReintentos(() async {
            try {
              final datos = await _supabase
                  .from(TablasSupabase.usuarios)
                  .select(
                    'id, primer_nombre, segundo_nombre, primer_apellido, segundo_apellido, '
                    'correo, numero_identificacion, telefono, creado_en',
                  )
                  .eq('estatus_aprobacion', EstatusAprobacion.pendiente)
                  .order('creado_en')
                  .range(offset, offset + limite - 1)
                  .timeout(kTimeoutSolicitud);
              final usuarios =
                  datos.map(RevisionUsuarioItem.desdeJson).toList();
              return (usuarios: usuarios, hayMas: usuarios.length >= limite);
            } on PostgrestException catch (e) {
              throw FallaServidor(TraductorErrores.dePostgres(e));
            } catch (e) {
              TraductorErrores.lanzarInesperado(e);
            }
          });

  /// Aprueba al usuario cambiando su estatus a aprobado.
  /// Los roles y tags se gestionan desde sus pantallas dedicadas.
  Future<void> aprobar(String usuarioId) async {
    try {
      await _supabase
          .from(TablasSupabase.usuarios)
          .update({'estatus_aprobacion': EstatusAprobacion.aprobado}).eq(
              'id', usuarioId);
    } on PostgrestException catch (e) {
      throw FallaServidor(TraductorErrores.dePostgres(e));
    } catch (e) {
      TraductorErrores.lanzarInesperado(e);
    }
  }

  /// Rechaza la solicitud de un usuario pendiente.
  ///
  /// También marca `estatus: false` — la tabla tiene una restricción
  /// (`usuarios_estatus_coherente`) que impide que un usuario quede
  /// simultáneamente activo y rechazado. Sin esto, la actualización viola
  /// la restricción y Postgres la rechaza con un error.
  Future<void> rechazar(String usuarioId) async {
    try {
      await _supabase.from(TablasSupabase.usuarios).update({
        'estatus_aprobacion': EstatusAprobacion.rechazado,
        'estatus': false,
      }).eq('id', usuarioId);
    } on PostgrestException catch (e) {
      throw FallaServidor(TraductorErrores.dePostgres(e));
    } catch (e) {
      TraductorErrores.lanzarInesperado(e);
    }
  }
}
