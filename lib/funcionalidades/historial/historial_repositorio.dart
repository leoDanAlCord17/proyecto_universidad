import 'package:supabase_flutter/supabase_flutter.dart';

import '../../compartido/constantes.dart';
import '../../compartido/errores.dart';
import '../../compartido/traductor_errores.dart';
import 'historial_item.dart';

class HistorialRepositorio {
  HistorialRepositorio(this._supabase);

  final SupabaseClient _supabase;

  /// Retorna el historial de asistencia del usuario, excluyendo
  /// registros con estatus 'esperado' y 'anulado'.
  Future<List<HistorialItem>> obtenerHistorial(String usuarioId) async {
    try {
      final datos = await _supabase
          .from(TablasSupabase.asistencia)
          .select('id, evento_id, estatus, hora_entrada, hora_salida, '
              'eventos(titulo, lugar, fecha_inicio)')
          .eq('usuario_id', usuarioId)
          .neq('estatus', EstatusAsistencia.esperado)
          .neq('estatus', EstatusAsistencia.anulado);

      final items = datos.map(HistorialItem.desdeJson).toList();

      items.sort((a, b) {
        final fa = a.eventoFechaInicio;
        final fb = b.eventoFechaInicio;
        if (fa == null && fb == null) return 0;
        if (fa == null) return 1;
        if (fb == null) return -1;
        return fb.compareTo(fa);
      });

      return items;
    } on PostgrestException catch (e) {
      throw FallaServidor(TraductorErrores.dePostgres(e));
    } catch (e) {
      throw FallaInesperada(TraductorErrores.deInesperado(e));
    }
  }
}
