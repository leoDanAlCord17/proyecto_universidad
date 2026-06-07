import 'package:supabase_flutter/supabase_flutter.dart';

import '../../compartido/constantes.dart';
import '../../compartido/errores.dart';
import '../../compartido/reintento.dart';
import '../../compartido/traductor_errores.dart';

class CrearTagRepositorio {
  const CrearTagRepositorio(this._supabase);

  final SupabaseClient _supabase;

  /// Retorna true si ya existe un tag con el mismo nombre y tipo.
  /// Excluye [excludeId] de la búsqueda cuando se edita un tag existente.
  Future<bool> existeDuplicado({
    required String nombre,
    required String tipo,
    String? excludeId,
  }) =>
      conReintentos(() async {
        try {
          final resultado = await _supabase
              .from(TablasSupabase.tags)
              .select('id')
              .eq('nombre', nombre)
              .eq('tipo', tipo)
              .timeout(kTimeoutSolicitud);
          final lista = resultado as List;
          if (excludeId == null) return lista.isNotEmpty;
          return lista
              .any((r) => (r as Map<String, dynamic>)['id'] != excludeId);
        } on PostgrestException catch (e) {
          throw FallaServidor(TraductorErrores.dePostgres(e));
        } catch (e) {
          TraductorErrores.lanzarInesperado(e);
        }
      });

  Future<void> crearTag(Map<String, dynamic> datos) async {
    try {
      await _supabase.from(TablasSupabase.tags).insert(datos);
    } on PostgrestException catch (e) {
      throw FallaServidor(TraductorErrores.dePostgres(e));
    } catch (e) {
      TraductorErrores.lanzarInesperado(e);
    }
  }

  Future<Map<String, dynamic>> obtenerTag(String id) => conReintentos(() async {
        try {
          return await _supabase
              .from(TablasSupabase.tags)
              .select('id, nombre, descripcion, tipo')
              .eq('id', id)
              .single()
              .timeout(kTimeoutSolicitud);
        } on PostgrestException catch (e) {
          throw FallaServidor(TraductorErrores.dePostgres(e));
        } catch (e) {
          TraductorErrores.lanzarInesperado(e);
        }
      });

  Future<void> actualizarTag({
    required String id,
    required Map<String, dynamic> datos,
  }) async {
    try {
      await _supabase.from(TablasSupabase.tags).update(datos).eq('id', id);
    } on PostgrestException catch (e) {
      throw FallaServidor(TraductorErrores.dePostgres(e));
    } catch (e) {
      TraductorErrores.lanzarInesperado(e);
    }
  }
}
