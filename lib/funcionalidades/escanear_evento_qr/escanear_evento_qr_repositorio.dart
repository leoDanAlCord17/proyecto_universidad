import 'package:supabase_flutter/supabase_flutter.dart';

import '../../compartido/asistencia_registro_base.dart';
import '../../compartido/constantes.dart';
import '../../compartido/errores.dart';
import '../../compartido/reintento.dart';
import '../../compartido/traductor_errores.dart';
import '../eventos/evento.dart';

class EscanearEventoQrRepositorio extends AsistenciaRegistroBase {
  const EscanearEventoQrRepositorio(super.supabase);

  /// Obtiene el evento por su UUID. Retorna null si no existe.
  Future<Evento?> obtenerEvento(String eventoId) => conReintentos(() async {
        try {
          final fila = await supabase
              .from(TablasSupabase.eventos)
              .select()
              .eq('id', eventoId)
              .maybeSingle()
              .timeout(kTimeoutSolicitud);
          return fila == null ? null : Evento.desdeJson(fila);
        } on PostgrestException catch (e) {
          throw FallaServidor(TraductorErrores.dePostgres(e));
        } catch (e) {
          TraductorErrores.lanzarInesperado(e);
        }
      });

  /// Verifica si el usuario satisface al menos un grupo de tags del evento.
  Future<bool> verificarPerteneceAudiencia(String eventoId, String usuarioId) =>
      conReintentos(() async {
        try {
          final filas = await supabase
              .from(TablasSupabase.eventoGruposTags)
              .select('grupo_index, tag_id')
              .eq('evento_id', eventoId)
              .timeout(kTimeoutSolicitud);

          if (filas.isEmpty) return false;

          final mapa = <int, Set<String>>{};
          for (final f in filas) {
            mapa
                .putIfAbsent(f['grupo_index'] as int, () => {})
                .add(f['tag_id'] as String);
          }

          final todosTagIds = mapa.values.expand((s) => s).toSet().toList();
          final userTags = await supabase
              .from(TablasSupabase.usuariosTags)
              .select('tag_id')
              .eq('usuario_id', usuarioId)
              .eq('estatus', true)
              .inFilter('tag_id', todosTagIds)
              .timeout(kTimeoutSolicitud);

          final setTags = userTags.map((f) => f['tag_id'] as String).toSet();
          return mapa.values.any(setTags.containsAll);
        } on PostgrestException catch (e) {
          throw FallaServidor(TraductorErrores.dePostgres(e));
        } catch (e) {
          TraductorErrores.lanzarInesperado(e);
        }
      });

  /// Registra la entrada del usuario en el evento.
  /// Retorna true si fue registrado, false si ya tenía un registro activo.
  Future<bool> registrarEntrada({
    required String eventoId,
    required String usuarioId,
  }) =>
      registrarEntradaBase(eventoId: eventoId, usuarioId: usuarioId);
}
