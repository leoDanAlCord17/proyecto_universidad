import 'package:supabase_flutter/supabase_flutter.dart';

import '../../compartido/constantes.dart';
import '../../compartido/errores.dart';
import '../../compartido/reintento.dart';
import '../../compartido/traductor_errores.dart';
import '../eventos/evento.dart';

class EscanearQrRepositorio {
  const EscanearQrRepositorio(this._supabase);

  final SupabaseClient _supabase;

  static final _regexUuid = RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
  );

  /// Obtiene los datos del evento por su UUID.
  Future<Evento> obtenerEvento(String eventoId) => conReintentos(() async {
        try {
          final fila = await _supabase
              .from(TablasSupabase.eventos)
              .select()
              .eq('id', eventoId)
              .single()
              .timeout(kTimeoutSolicitud);
          return Evento.desdeJson(fila);
        } on PostgrestException catch (e) {
          throw FallaServidor(TraductorErrores.dePostgres(e));
        } catch (e) {
          TraductorErrores.lanzarInesperado(e);
        }
      });

  /// Cuenta asistentes con estatus activo en el evento.
  Future<int> contarPresentes(String eventoId) => conReintentos(() async {
        try {
          final result = await _supabase
              .from(TablasSupabase.asistencia)
              .select('id')
              .eq('evento_id', eventoId)
              .inFilter('estatus', [
            EstatusAsistencia.presente,
            EstatusAsistencia.completado,
            EstatusAsistencia.salioAnticipado,
          ]).timeout(kTimeoutSolicitud);
          return result.length;
        } on PostgrestException catch (_) {
          return 0;
        } catch (_) {
          return 0;
        }
      });

  /// Busca un usuario activo por su UUID. Retorna null si no existe o no es válido.
  Future<Map<String, dynamic>?> buscarUsuario(String usuarioId) =>
      conReintentos(() async {
        if (!_regexUuid.hasMatch(usuarioId)) return null;
        try {
          final fila = await _supabase
              .from(TablasSupabase.usuarios)
              .select(
                'primer_nombre, primer_apellido, numero_identificacion, '
                'usuarios_roles!usuarios_roles_usuario_id_fkey(roles(nombre))',
              )
              .eq('id', usuarioId)
              .eq('estatus', true)
              .maybeSingle()
              .timeout(kTimeoutSolicitud);
          return fila;
        } on PostgrestException catch (e) {
          throw FallaServidor(TraductorErrores.dePostgres(e));
        } catch (e) {
          TraductorErrores.lanzarInesperado(e);
        }
      });

  /// Registra la entrada del usuario para el evento.
  /// Retorna true si fue registrado, false si ya estaba registrado.
  Future<bool> registrarEntrada({
    required String eventoId,
    required String usuarioId,
    String? registradoPorId,
  }) async {
    try {
      final existing = await _supabase
          .from(TablasSupabase.asistencia)
          .select('id, estatus')
          .eq('evento_id', eventoId)
          .eq('usuario_id', usuarioId)
          .maybeSingle();

      if (existing != null) {
        if ((existing['estatus'] as String?) != EstatusAsistencia.esperado)
          return false;
        await _actualizarAsistencia(existing['id'] as String, registradoPorId);
      } else {
        await _insertarAsistencia(
          eventoId: eventoId,
          usuarioId: usuarioId,
          registradoPorId: registradoPorId,
        );
      }
      return true;
    } on PostgrestException catch (e) {
      if (e.code == '23505') return false;
      throw FallaServidor(TraductorErrores.dePostgres(e));
    } catch (e) {
      TraductorErrores.lanzarInesperado(e);
    }
  }

  Future<void> _actualizarAsistencia(
          String asistenciaId, String? registradoPorId) =>
      _supabase.from(TablasSupabase.asistencia).update({
        'estatus': EstatusAsistencia.presente,
        'hora_entrada': DateTime.now().toUtc().toIso8601String(),
        'entrada_registrada_por': registradoPorId,
      }).eq('id', asistenciaId);

  Future<void> _insertarAsistencia({
    required String eventoId,
    required String usuarioId,
    required String? registradoPorId,
  }) =>
      _supabase.from(TablasSupabase.asistencia).insert({
        'evento_id': eventoId,
        'usuario_id': usuarioId,
        'estatus': EstatusAsistencia.presente,
        'hora_entrada': DateTime.now().toUtc().toIso8601String(),
        'entrada_registrada_por': registradoPorId,
      });
}
