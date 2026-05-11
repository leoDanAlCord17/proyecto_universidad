import 'package:supabase_flutter/supabase_flutter.dart';

import '../../compartido/constantes.dart';
import '../../compartido/errores.dart';
import '../../compartido/traductor_errores.dart';
import 'borrador_evento.dart';

class BorradoresRepositorio {
  const BorradoresRepositorio(this._cliente);

  final SupabaseClient _cliente;

  Future<List<BorradorEvento>> obtenerBorradores(String usuarioId) async {
    try {
      final datos = await _cliente
          .from(TablasSupabase.eventos)
          .select()
          .eq('estatus', EstatusEvento.borrador)
          .eq('creado_por', usuarioId)
          .order('fecha_inicio', ascending: false);
      return (datos as List)
          .map((e) => BorradorEvento.desdeJson(e as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw FallaServidor(TraductorErrores.dePostgres(e));
    } catch (e) {
      throw FallaInesperada(TraductorErrores.deInesperado(e));
    }
  }

  Future<void> publicarEvento(String eventoId) async {
    try {
      final actualizadoPor = await _resolverUsuarioId();
      await _cliente
          .from(TablasSupabase.eventos)
          .update({'estatus': EstatusEvento.programado, 'actualizado_por': actualizadoPor})
          .eq('id', eventoId);
    } on PostgrestException catch (e) {
      throw FallaServidor(TraductorErrores.dePostgres(e));
    } catch (e) {
      throw FallaInesperada(TraductorErrores.deInesperado(e));
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
