import 'package:supabase_flutter/supabase_flutter.dart';

import '../../compartido/constantes.dart';
import '../../compartido/errores.dart';
import '../../compartido/traductor_errores.dart';

class CrearTagRepositorio {
  const CrearTagRepositorio(this._supabase);

  final SupabaseClient _supabase;

  /// Retorna true si ya existe un tag con el mismo nombre y tipo.
  /// Excluye [excludeId] de la búsqueda cuando se edita un tag existente.
  Future<bool> existeDuplicado({
    required String nombre,
    required String tipo,
    String?         excludeId,
  }) async {
    try {
      final resultado = await _supabase
          .from(TablasSupabase.tags)
          .select('id')
          .eq('nombre', nombre)
          .eq('tipo', tipo);
      final lista = resultado as List;
      if (excludeId == null) return lista.isNotEmpty;
      return lista.any((r) => (r as Map<String, dynamic>)['id'] != excludeId);
    } on PostgrestException catch (e) {
      throw FallaServidor(TraductorErrores.dePostgres(e));
    } catch (e) {
      throw FallaInesperada(TraductorErrores.deInesperado(e));
    }
  }

  Future<void> crearTag(Map<String, dynamic> datos) async {
    try {
      await _supabase.from(TablasSupabase.tags).insert(datos);
    } on PostgrestException catch (e) {
      throw FallaServidor(TraductorErrores.dePostgres(e));
    } catch (e) {
      throw FallaInesperada(TraductorErrores.deInesperado(e));
    }
  }

  Future<Map<String, dynamic>> obtenerTag(String id) async {
    try {
      return await _supabase
          .from(TablasSupabase.tags)
          .select('id, nombre, descripcion, tipo')
          .eq('id', id)
          .single();
    } on PostgrestException catch (e) {
      throw FallaServidor(TraductorErrores.dePostgres(e));
    } catch (e) {
      throw FallaInesperada(TraductorErrores.deInesperado(e));
    }
  }

  Future<void> actualizarTag({
    required String              id,
    required Map<String, dynamic> datos,
  }) async {
    try {
      await _supabase.from(TablasSupabase.tags).update(datos).eq('id', id);
    } on PostgrestException catch (e) {
      throw FallaServidor(TraductorErrores.dePostgres(e));
    } catch (e) {
      throw FallaInesperada(TraductorErrores.deInesperado(e));
    }
  }
}
