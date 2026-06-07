import 'package:supabase_flutter/supabase_flutter.dart';

import '../../compartido/constantes.dart';
import '../../compartido/errores.dart';
import '../../compartido/reintento.dart';
import '../../compartido/traductor_errores.dart';
import 'tipo_evento_item.dart';

class TiposEventoRepositorio {
  const TiposEventoRepositorio(this._cliente);

  final SupabaseClient _cliente;

  /// Retorna todos los tipos de evento activos.
  Future<List<TipoEventoItem>> obtenerTiposEvento() =>
      conReintentos(() async {
        try {
          final datos = await _cliente
              .from(TablasSupabase.tiposEvento)
              .select()
              .eq('estatus', true)
              .order('nombre')
              .timeout(kTimeoutSolicitud);
          return (datos as List).map((e) => TipoEventoItem.desdeJson(e)).toList();
        } on PostgrestException catch (e) {
          throw FallaServidor(TraductorErrores.dePostgres(e));
        } catch (e) {
          TraductorErrores.lanzarInesperado(e);
        }
      });

  /// Retorna los datos crudos de un tipo de evento por su ID.
  Future<Map<String, dynamic>> obtenerTipoEvento(String id) =>
      conReintentos(() async {
        try {
          return await _cliente
              .from(TablasSupabase.tiposEvento)
              .select()
              .eq('id', id)
              .single()
              .timeout(kTimeoutSolicitud);
        } on PostgrestException catch (e) {
          throw FallaServidor(TraductorErrores.dePostgres(e));
        } catch (e) {
          TraductorErrores.lanzarInesperado(e);
        }
      });

  /// Inserta un nuevo tipo de evento.
  Future<void> crearTipoEvento({
    required String nombre,
    required String descripcion,
  }) async {
    try {
      final usuarioId = await _obtenerUsuarioId();
      await _cliente.from(TablasSupabase.tiposEvento).insert({
        'nombre':      nombre,
        'descripcion': descripcion,
        'estatus':     true,
        'creado_por':  usuarioId,
      });
    } on PostgrestException catch (e) {
      if (e.code == '23505') {
        throw const FallaServidor(
          'Ya existe un tipo de evento activo con ese nombre.',
        );
      }
      throw FallaServidor(TraductorErrores.dePostgres(e));
    } catch (e) {
      TraductorErrores.lanzarInesperado(e);
    }
  }

  /// Actualiza nombre y descripción de un tipo de evento existente.
  Future<void> actualizarTipoEvento({
    required String id,
    required String nombre,
    required String descripcion,
  }) async {
    try {
      final usuarioId = await _obtenerUsuarioId();
      await _cliente.from(TablasSupabase.tiposEvento).update({
        'nombre':          nombre,
        'descripcion':     descripcion,
        'actualizado_por': usuarioId,
        'actualizado_en':  DateTime.now().toUtc().toIso8601String(),
      }).eq('id', id);
    } on PostgrestException catch (e) {
      if (e.code == '23505') {
        throw const FallaServidor(
          'Ya existe un tipo de evento activo con ese nombre.',
        );
      }
      throw FallaServidor(TraductorErrores.dePostgres(e));
    } catch (e) {
      TraductorErrores.lanzarInesperado(e);
    }
  }

  /// Desactiva un tipo de evento sin eliminarlo (soft delete).
  Future<void> desactivarTipoEvento(String id) async {
    try {
      final usuarioId = await _obtenerUsuarioId();
      await _cliente.from(TablasSupabase.tiposEvento).update({
        'estatus':         false,
        'actualizado_por': usuarioId,
        'actualizado_en':  DateTime.now().toUtc().toIso8601String(),
      }).eq('id', id);
    } on PostgrestException catch (e) {
      throw FallaServidor(TraductorErrores.dePostgres(e));
    } catch (e) {
      TraductorErrores.lanzarInesperado(e);
    }
  }

  Future<String?> _obtenerUsuarioId() async {
    final authId = _cliente.auth.currentUser?.id;
    if (authId == null) return null;
    final fila = await _cliente
        .from(TablasSupabase.usuarios)
        .select('id')
        .eq('auth_id', authId)
        .single();
    return fila['id'] as String?;
  }
}
