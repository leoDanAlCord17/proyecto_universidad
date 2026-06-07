import 'package:supabase_flutter/supabase_flutter.dart';

import '../../compartido/constantes.dart';
import '../../compartido/errores.dart';
import '../../compartido/reintento.dart';
import '../../compartido/traductor_errores.dart';
import 'borrador_evento.dart';

class BorradoresRepositorio {
  const BorradoresRepositorio(this._cliente);

  final SupabaseClient _cliente;

  static const _limite = 20;

  Future<({List<BorradorEvento> borradores, bool hayMas})> obtenerBorradores(
    String usuarioId, {
    int offset = 0,
    int limite = _limite,
  }) =>
      conReintentos(() async {
        try {
          final datos = await _cliente
              .from(TablasSupabase.eventos)
              .select()
              .eq('estatus', EstatusEvento.borrador)
              .eq('creado_por', usuarioId)
              .order('fecha_inicio', ascending: false)
              .range(offset, offset + limite - 1)
              .timeout(kTimeoutSolicitud);
          final borradores = (datos as List)
              .map((e) => BorradorEvento.desdeJson(e as Map<String, dynamic>))
              .toList();
          return (borradores: borradores, hayMas: borradores.length >= limite);
        } on PostgrestException catch (e) {
          throw FallaServidor(TraductorErrores.dePostgres(e));
        } catch (e) {
          TraductorErrores.lanzarInesperado(e);
        }
      });

  Future<void> publicarEvento(String eventoId) async {
    try {
      final actualizadoPor = await _resolverUsuarioId();
      await _cliente.from(TablasSupabase.eventos).update({
        'estatus': EstatusEvento.programado,
        'actualizado_por': actualizadoPor
      }).eq('id', eventoId);
    } on PostgrestException catch (e) {
      throw FallaServidor(TraductorErrores.dePostgres(e));
    } catch (e) {
      TraductorErrores.lanzarInesperado(e);
    }
  }

  Future<String?> _resolverUsuarioId() async {
    final authId = _cliente.auth.currentUser?.id;
    if (authId == null) return null;
    final fila = await _cliente
        .from(TablasSupabase.usuarios)
        .select('id')
        .eq('auth_id', authId)
        .maybeSingle();
    return fila?['id'] as String?;
  }
}
