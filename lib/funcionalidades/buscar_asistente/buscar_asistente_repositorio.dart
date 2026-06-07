import 'package:supabase_flutter/supabase_flutter.dart';

import '../../compartido/constantes.dart';
import '../../compartido/errores.dart';
import '../../compartido/reintento.dart';
import '../../compartido/traductor_errores.dart';
import '../eventos/evento.dart';

class BuscarAsistenteRepositorio {
  const BuscarAsistenteRepositorio(this._supabase);

  final SupabaseClient _supabase;

  /// Retorna el evento completo por su ID.
  Future<Evento> obtenerEvento(String eventoId) =>
      conReintentos(() async {
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

  /// Stream en tiempo real de todos los registros de asistencia del evento.
  Stream<List<Map<String, dynamic>>> streamAsistencia(String eventoId) {
    return _supabase
        .from(TablasSupabase.asistencia)
        .stream(primaryKey: ['id'])
        .eq('evento_id', eventoId);
  }

  /// Busca usuarios del sistema cuyo nombre o apellido coincida con [query].
  Future<List<Map<String, dynamic>>> buscarUsuarios(String query) =>
      conReintentos(() async {
        try {
          final q = query.trim();
          // Mínimo 2 caracteres para evitar escaneos completos de la tabla.
          // Máximo 100 caracteres para prevenir abuso de la query.
          if (q.length < 2) return [];
          final qSanitizado = q.length > 100 ? q.substring(0, 100) : q;
          final rows = await _supabase
              .from(TablasSupabase.usuarios)
              .select('id, primer_nombre, primer_apellido, url_avatar, numero_identificacion')
              .or('primer_nombre.ilike.%$qSanitizado%,primer_apellido.ilike.%$qSanitizado%')
              .order('primer_apellido', ascending: true)
              .limit(30)
              .timeout(kTimeoutSolicitud);
          return List<Map<String, dynamic>>.from(rows);
        } on PostgrestException catch (e) {
          throw FallaServidor(TraductorErrores.dePostgres(e));
        } catch (e) {
          TraductorErrores.lanzarInesperado(e);
        }
      });

  /// Registra la entrada de un usuario del sistema.
  /// Si [asistenciaId] no es null actualiza el registro esperado existente;
  /// de lo contrario inserta uno nuevo.
  Future<void> registrarEntrada({
    required String  eventoId,
    required String  usuarioId,
    String?          asistenciaId,
    String?          registradoPorId,
  }) async {
    try {
      final datos = <String, dynamic>{
        'estatus':                EstatusAsistencia.presente,
        'hora_entrada':           DateTime.now().toUtc().toIso8601String(),
        'entrada_registrada_por': registradoPorId,
      };
      if (asistenciaId != null) {
        await _supabase
            .from(TablasSupabase.asistencia)
            .update(datos)
            .eq('id', asistenciaId);
      } else {
        datos['evento_id']  = eventoId;
        datos['usuario_id'] = usuarioId;
        await _supabase.from(TablasSupabase.asistencia).insert(datos);
      }
    } on PostgrestException catch (e) {
      if (e.code == '23505') return; // ya registrado — idempotente, no es un error
      throw FallaServidor(TraductorErrores.dePostgres(e));
    } catch (e) {
      TraductorErrores.lanzarInesperado(e);
    }
  }

  /// Retorna un mapa id→nombreCompleto para los IDs dados.
  Future<Map<String, String>> resolverNombresUsuarios(List<String> ids) =>
      conReintentos(() async {
        if (ids.isEmpty) return {};
        try {
          final filas = await _supabase
              .from(TablasSupabase.usuarios)
              .select('id, primer_nombre, primer_apellido')
              .inFilter('id', ids)
              .timeout(kTimeoutSolicitud);
          return {
            for (final f in filas)
              f['id'] as String:
                '${f['primer_nombre'] ?? ''} ${f['primer_apellido'] ?? ''}'.trim(),
          };
        } on PostgrestException catch (e) {
          throw FallaServidor(TraductorErrores.dePostgres(e));
        } catch (e) {
          TraductorErrores.lanzarInesperado(e);
        }
      });

  /// Marca la salida de un asistente (normal o anticipada).
  Future<void> marcarSalida({
    required String asistenciaId,
    required bool   esAnticipada,
    String?         motivo,
    String?         registradoPorId,
  }) async {
    try {
      final datos = <String, dynamic>{
        'hora_salida':           DateTime.now().toUtc().toIso8601String(),
        'salida_registrada_por': registradoPorId,
      };
      if (esAnticipada) {
        datos['estatus']                  = EstatusAsistencia.salioAnticipado;
        datos['motivo_salida_anticipada'] = motivo;
      } else {
        datos['estatus'] = EstatusAsistencia.completado;
      }
      await _supabase
          .from(TablasSupabase.asistencia)
          .update(datos)
          .eq('id', asistenciaId);
    } on PostgrestException catch (e) {
      throw FallaServidor(TraductorErrores.dePostgres(e));
    } catch (e) {
      TraductorErrores.lanzarInesperado(e);
    }
  }
}
