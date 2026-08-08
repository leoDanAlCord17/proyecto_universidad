import 'package:supabase_flutter/supabase_flutter.dart';

import '../../compartido/constantes.dart';
import '../../compartido/errores.dart';
import '../../compartido/reintento.dart';
import '../../compartido/traductor_errores.dart';
import 'configuracion_item.dart';

class ConfiguracionGeneralRepositorio {
  const ConfiguracionGeneralRepositorio(this._supabase);

  final SupabaseClient _supabase;

  Future<List<ConfiguracionItem>> obtenerTodas() => conReintentos(() async {
        try {
          final filas = await _supabase
              .from(TablasSupabase.configuracion)
              .select()
              .order('modulo')
              .order('clave')
              .timeout(kTimeoutSolicitud);
          return (filas as List)
              .map((json) =>
                  ConfiguracionItem.desdeJson(json as Map<String, dynamic>))
              .toList();
        } on PostgrestException catch (e) {
          throw FallaServidor(TraductorErrores.dePostgres(e));
        } catch (e) {
          TraductorErrores.lanzarInesperado(e);
        }
      });

  Future<void> actualizarValor(String id, int nuevoValor) async {
    try {
      await _supabase
          .from(TablasSupabase.configuracion)
          .update({'valor': nuevoValor}).eq('id', id);
    } on PostgrestException catch (e) {
      throw FallaServidor(TraductorErrores.dePostgres(e));
    } catch (e) {
      TraductorErrores.lanzarInesperado(e);
    }
  }
}
