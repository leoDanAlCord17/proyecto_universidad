import 'package:supabase_flutter/supabase_flutter.dart';

import '../../compartido/constantes.dart';
import '../../compartido/errores.dart';
import '../../compartido/reintento.dart';
import '../../compartido/traductor_errores.dart';
import 'historial_item.dart';

class HistorialRepositorio {
  HistorialRepositorio(this._supabase);

  final SupabaseClient _supabase;

  static const _limite = 20;

  /// Retorna una página de historial del usuario, ordenada por fecha del evento
  /// descendente. El campo [hayMas] indica si existen más registros después del offset.
  Future<({List<HistorialItem> items, bool hayMas})> obtenerHistorial(
    String usuarioId, {
    int offset = 0,
    int limite = _limite,
  }) =>
      conReintentos(() async {
        try {
          final datos = await _supabase
              .from(TablasSupabase.asistencia)
              .select('id, evento_id, estatus, hora_entrada, hora_salida, '
                  'eventos(titulo, lugar, fecha_inicio)')
              .eq('usuario_id', usuarioId)
              .neq('estatus', EstatusAsistencia.esperado)
              .neq('estatus', EstatusAsistencia.anulado)
              .order('fecha_inicio', ascending: false, referencedTable: 'eventos')
              .order('id', ascending: false)
              .range(offset, offset + limite - 1)
              .timeout(kTimeoutSolicitud);

          final items = datos.map(HistorialItem.desdeJson).toList();
          return (items: items, hayMas: items.length >= limite);
        } on PostgrestException catch (e) {
          throw FallaServidor(TraductorErrores.dePostgres(e));
        } catch (e) {
          TraductorErrores.lanzarInesperado(e);
        }
      });
}
