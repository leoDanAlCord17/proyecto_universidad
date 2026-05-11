import 'package:supabase_flutter/supabase_flutter.dart';

import '../../compartido/constantes.dart';
import '../../compartido/errores.dart';
import '../../compartido/traductor_errores.dart';
import 'auditoria_evento_modelo.dart';

class AuditoriaEventoRepositorio {
  const AuditoriaEventoRepositorio(this._supabase);

  final SupabaseClient _supabase;

  /// Retorna los últimos 300 eventos ordenados por fecha descendente.
  Future<List<EventoParaAuditoria>> obtenerEventos() async {
    try {
      final filas = await _supabase
          .from(TablasSupabase.eventos)
          .select('id, titulo, estatus, fecha_inicio, hora_inicio')
          .order('fecha_inicio', ascending: false)
          .limit(300) as List<dynamic>;
      return filas
          .cast<Map<String, dynamic>>()
          .map(EventoParaAuditoria.desdeJson)
          .toList();
    } on PostgrestException catch (e) {
      throw FallaServidor(TraductorErrores.dePostgres(e));
    } catch (e) {
      throw FallaInesperada(TraductorErrores.deInesperado(e));
    }
  }

  /// Retorna todos los registros de asistencia de [eventoId] con datos
  /// del asistente, registrador de entrada y registrador de salida.
  Future<List<RegistroAuditoria>> obtenerRegistros(String eventoId) async {
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
          .order('hora_entrada', ascending: true, nullsFirst: false) as List<dynamic>;
      return filas
          .cast<Map<String, dynamic>>()
          .map(RegistroAuditoria.desdeJson)
          .toList();
    } on PostgrestException catch (e) {
      throw FallaServidor(TraductorErrores.dePostgres(e));
    } catch (e) {
      throw FallaInesperada(TraductorErrores.deInesperado(e));
    }
  }
}
