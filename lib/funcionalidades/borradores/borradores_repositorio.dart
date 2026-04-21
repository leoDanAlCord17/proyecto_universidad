import 'package:supabase_flutter/supabase_flutter.dart';

import '../../compartido/constantes.dart';
import '../../compartido/errores.dart';
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
      throw FallaServidor(e.message);
    } catch (e) {
      throw FallaInesperada(e.toString());
    }
  }

  Future<void> publicarEvento(String eventoId) async {
    try {
      await _cliente
          .from(TablasSupabase.eventos)
          .update({'estatus': EstatusEvento.programado})
          .eq('id', eventoId);
    } on PostgrestException catch (e) {
      throw FallaServidor(e.message);
    } catch (e) {
      throw FallaInesperada(e.toString());
    }
  }
}
