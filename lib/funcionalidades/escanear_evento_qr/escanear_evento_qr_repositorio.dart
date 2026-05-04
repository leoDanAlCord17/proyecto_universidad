import 'package:supabase_flutter/supabase_flutter.dart';

import '../../compartido/constantes.dart';
import '../../compartido/errores.dart';
import '../../compartido/traductor_errores.dart';
import '../eventos/evento.dart';

class EscanearEventoQrRepositorio {
  const EscanearEventoQrRepositorio(this._supabase);

  final SupabaseClient _supabase;

  static final _regexUuid = RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
  );

  /// Retorna true si el valor tiene formato de UUID válido.
  bool esUuidValido(String valor) => _regexUuid.hasMatch(valor);

  /// Obtiene el evento por su UUID. Retorna null si no existe.
  Future<Evento?> obtenerEvento(String eventoId) async {
    try {
      final fila = await _supabase
          .from(TablasSupabase.eventos)
          .select()
          .eq('id', eventoId)
          .maybeSingle();
      return fila == null ? null : Evento.desdeJson(fila);
    } on PostgrestException catch (e) {
      throw FallaServidor(TraductorErrores.dePostgres(e));
    } catch (e) {
      throw FallaInesperada(TraductorErrores.deInesperado(e));
    }
  }

  /// Verifica si el usuario satisface al menos un grupo de tags del evento.
  Future<bool> verificarPerteneceAudiencia(String eventoId, String usuarioId) async {
    try {
      final filas = await _supabase
          .from(TablasSupabase.eventoGruposTags)
          .select('grupo_index, tag_id')
          .eq('evento_id', eventoId);

      if (filas.isEmpty) return false;

      final mapa = <int, Set<String>>{};
      for (final f in filas) {
        mapa.putIfAbsent(f['grupo_index'] as int, () => {}).add(f['tag_id'] as String);
      }

      final todosTagIds = mapa.values.expand((s) => s).toSet().toList();
      final userTags    = await _supabase
          .from(TablasSupabase.usuariosTags)
          .select('tag_id')
          .eq('usuario_id', usuarioId)
          .eq('estatus', true)
          .inFilter('tag_id', todosTagIds);

      final setTags = userTags.map((f) => f['tag_id'] as String).toSet();
      return mapa.values.any((grupo) => setTags.containsAll(grupo));
    } on PostgrestException catch (e) {
      throw FallaServidor(TraductorErrores.dePostgres(e));
    } catch (e) {
      throw FallaInesperada(TraductorErrores.deInesperado(e));
    }
  }

  /// Registra la entrada del usuario en el evento.
  /// Retorna true si fue registrado, false si ya tenía un registro activo.
  Future<bool> registrarEntrada({
    required String eventoId,
    required String usuarioId,
  }) async {
    try {
      final existing = await _supabase
          .from(TablasSupabase.asistencia)
          .select('id, estatus')
          .eq('evento_id', eventoId)
          .eq('usuario_id', usuarioId)
          .maybeSingle();

      if (existing != null) {
        if ((existing['estatus'] as String?) != EstatusAsistencia.esperado) return false;
        await _actualizarAsistencia(existing['id'] as String);
      } else {
        await _insertarAsistencia(eventoId: eventoId, usuarioId: usuarioId);
      }
      return true;
    } on PostgrestException catch (e) {
      if (e.code == '23505') return false;
      throw FallaServidor(TraductorErrores.dePostgres(e));
    } catch (e) {
      throw FallaInesperada(TraductorErrores.deInesperado(e));
    }
  }

  Future<void> _actualizarAsistencia(String asistenciaId) =>
      _supabase
          .from(TablasSupabase.asistencia)
          .update({
            'estatus':      EstatusAsistencia.presente,
            'hora_entrada': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', asistenciaId);

  Future<void> _insertarAsistencia({
    required String eventoId,
    required String usuarioId,
  }) =>
      _supabase
          .from(TablasSupabase.asistencia)
          .insert({
            'evento_id':    eventoId,
            'usuario_id':   usuarioId,
            'estatus':      EstatusAsistencia.presente,
            'hora_entrada': DateTime.now().toUtc().toIso8601String(),
          });
}
