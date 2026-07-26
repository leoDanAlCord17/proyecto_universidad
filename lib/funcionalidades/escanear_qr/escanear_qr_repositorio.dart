import 'package:supabase_flutter/supabase_flutter.dart';

import '../../compartido/asistencia_registro_base.dart';
import '../../compartido/constantes.dart';
import '../../compartido/errores.dart';
import '../../compartido/reintento.dart';
import '../../compartido/traductor_errores.dart';
import '../eventos/evento.dart';

class EscanearQrRepositorio extends AsistenciaRegistroBase {
  const EscanearQrRepositorio(super.supabase);

  /// Obtiene los datos del evento por su UUID.
  Future<Evento> obtenerEvento(String eventoId) => conReintentos(() async {
        try {
          final fila = await supabase
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
          final result = await supabase
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
        if (!esUuidValido(usuarioId)) return null;
        try {
          final fila = await supabase
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
  }) =>
      registrarEntradaBase(
        eventoId: eventoId,
        usuarioId: usuarioId,
        camposExtra: {'entrada_registrada_por': registradoPorId},
      );
}
