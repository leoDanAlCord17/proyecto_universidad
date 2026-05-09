import 'package:supabase_flutter/supabase_flutter.dart';

import '../../compartido/constantes.dart';
import '../../compartido/errores.dart';
import '../../compartido/traductor_errores.dart';
import 'evento_en_curso.dart';

class EventosEnCursoRepositorio {
  const EventosEnCursoRepositorio(this._supabase);

  final SupabaseClient _supabase;

  /// Retorna todos los eventos con estatus 'en_curso'.
  /// TODO: filtrar por participación del usuario cuando los permisos estén definidos.
  Future<List<EventoEnCurso>> obtenerEventosEnCurso(String usuarioId) async {
    try {
      final rows = await _supabase
          .from(TablasSupabase.eventos)
          .select(
            'id, titulo, lugar, hora_inicio, hora_fin, '
            'permite_qr_evento, permite_qr_usuario, '
            'permite_foraneos, modo_registro',
          )
          .eq('estatus', EstatusEvento.enCurso);

      return rows.map(EventoEnCurso.desdeJson).toList();
    } on PostgrestException catch (e) {
      throw FallaServidor(TraductorErrores.dePostgres(e));
    } catch (e) {
      throw FallaInesperada(TraductorErrores.deInesperado(e));
    }
  }

  /// Inserta un registro de asistencia para un visitante foráneo (sin cuenta).
  Future<void> registrarForaneo({
    required String eventoId,
    required String primerNombre,
    required String primerApellido,
    required String cedula,
    String? contacto,
  }) async {
    try {
      await _supabase
          .from(TablasSupabase.asistencia)
          .insert({
            'evento_id':                      eventoId,
            'visitante_primer_nombre':         primerNombre,
            'visitante_primer_apellido':       primerApellido,
            'visitante_numero_identificacion': cedula,
            'visitante_contacto':              contacto?.trim().isNotEmpty == true ? contacto!.trim() : null,
            'estatus':                         EstatusAsistencia.presente,
            'hora_entrada':                    DateTime.now().toUtc().toIso8601String(),
            'entrada_registrada_por':          _supabase.auth.currentUser?.id,
          });
    } on PostgrestException catch (e) {
      throw FallaServidor(TraductorErrores.dePostgres(e));
    } catch (e) {
      throw FallaInesperada(TraductorErrores.deInesperado(e));
    }
  }

  /// Stream en tiempo real de los registros de asistencia de un evento.
  Stream<List<Map<String, dynamic>>> streamAsistencia(String eventoId) =>
      _supabase
          .from(TablasSupabase.asistencia)
          .stream(primaryKey: ['id'])
          .eq('evento_id', eventoId);
}
