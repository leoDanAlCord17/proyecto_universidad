import 'package:supabase_flutter/supabase_flutter.dart';

import '../../compartido/constantes.dart';
import '../../compartido/errores.dart';
import '../../compartido/reintento.dart';
import '../../compartido/traductor_errores.dart';
import 'auditoria_evento_modelo.dart';

class AuditoriaEventoRepositorio {
  const AuditoriaEventoRepositorio(this._supabase);

  final SupabaseClient _supabase;

  static const _limite = 20;

  Future<({List<EventoParaAuditoria> eventos, bool hayMas})> obtenerEventos({
    int offset = 0,
    int limite = _limite,
  }) =>
      conReintentos(() async {
        try {
          final filas = await _supabase
              .from(TablasSupabase.eventos)
              .select('id, titulo, estatus, fecha_inicio, hora_inicio')
              .order('fecha_inicio', ascending: false)
              .range(offset, offset + limite - 1)
              .timeout(kTimeoutSolicitud) as List<dynamic>;
          final lista = filas
              .cast<Map<String, dynamic>>()
              .map(EventoParaAuditoria.desdeJson)
              .toList();
          return (eventos: lista, hayMas: lista.length == limite);
        } on PostgrestException catch (e) {
          throw FallaServidor(TraductorErrores.dePostgres(e));
        } catch (e) {
          TraductorErrores.lanzarInesperado(e);
        }
      });

  /// Retorna todos los registros de asistencia de [eventoId] con datos
  /// del asistente, registrador de entrada y registrador de salida.
  Future<List<RegistroAuditoria>> obtenerRegistros(String eventoId) =>
      conReintentos(() async {
        try {
          final filas = await _supabase
              .from(TablasSupabase.asistencia)
              .select(
                'id, usuario_id, estatus, hora_entrada, hora_salida, '
                'visitante_primer_nombre, visitante_primer_apellido, '
                'visitante_contacto, visitante_numero_identificacion, '
                'motivo_salida_anticipada, entrada_registrada_por, salida_registrada_por, '
                'asistente:usuarios!usuario_id(primer_nombre, primer_apellido, url_avatar, numero_identificacion), '
                'reg_entrada:usuarios!entrada_registrada_por(primer_nombre, primer_apellido), '
                'reg_salida:usuarios!salida_registrada_por(primer_nombre, primer_apellido)',
              )
              .eq('evento_id', eventoId)
              .order('hora_entrada', ascending: true, nullsFirst: false)
              .timeout(kTimeoutSolicitud) as List<dynamic>;
          return filas
              .cast<Map<String, dynamic>>()
              .map(RegistroAuditoria.desdeJson)
              .toList();
        } on PostgrestException catch (e) {
          throw FallaServidor(TraductorErrores.dePostgres(e));
        } catch (e) {
          TraductorErrores.lanzarInesperado(e);
        }
      });
}
