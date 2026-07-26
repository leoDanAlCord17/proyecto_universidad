import 'package:supabase_flutter/supabase_flutter.dart';

import 'constantes.dart';
import 'errores.dart';
import 'traductor_errores.dart';

/// Lógica común a los repositorios que registran asistencia a partir de un
/// QR escaneado (`EscanearQrRepositorio`, panel-driven; y
/// `EscanearEventoQrRepositorio`, autoescaneo del propio usuario). Antes
/// ambos repositorios duplicaban ~85% del código: la misma validación de
/// UUID y el mismo flujo de "buscar fila existente → actualizar a presente
/// o insertar → tratar Postgres 23505 como ya-registrado".
abstract class AsistenciaRegistroBase {
  const AsistenciaRegistroBase(this.supabase);

  final SupabaseClient supabase;

  static final RegExp _regexUuid = RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
  );

  /// Retorna true si [valor] tiene formato de UUID válido.
  bool esUuidValido(String valor) => _regexUuid.hasMatch(valor);

  /// Registra la entrada de [usuarioId] en [eventoId]: si ya existe una fila
  /// de asistencia en estatus `esperado` la actualiza a `presente`; si no
  /// existe fila, inserta una nueva.
  ///
  /// [camposExtra] se mezcla en el payload de update/insert — por ejemplo
  /// `entrada_registrada_por` cuando el registro lo hace un administrador
  /// desde el panel en lugar del autoescaneo del propio usuario.
  ///
  /// Retorna `false` (sin lanzar) tanto si ya había un registro activo como
  /// si una carrera concurrente produjo un duplicado (Postgres `23505`) —
  /// ambos casos significan "ya estaba registrado", no un error real.
  Future<bool> registrarEntradaBase({
    required String eventoId,
    required String usuarioId,
    Map<String, dynamic> camposExtra = const {},
  }) async {
    try {
      final existente = await supabase
          .from(TablasSupabase.asistencia)
          .select('id, estatus')
          .eq('evento_id', eventoId)
          .eq('usuario_id', usuarioId)
          .maybeSingle();

      if (existente != null) {
        if ((existente['estatus'] as String?) != EstatusAsistencia.esperado) {
          return false;
        }
        await _actualizarAsistencia(existente['id'] as String, camposExtra);
      } else {
        await _insertarAsistencia(
          eventoId: eventoId,
          usuarioId: usuarioId,
          camposExtra: camposExtra,
        );
      }
      return true;
    } on PostgrestException catch (e) {
      if (e.code == '23505') return false;
      throw FallaServidor(TraductorErrores.dePostgres(e));
    } catch (e) {
      TraductorErrores.lanzarInesperado(e);
    }
  }

  Future<void> _actualizarAsistencia(
    String asistenciaId,
    Map<String, dynamic> camposExtra,
  ) =>
      supabase.from(TablasSupabase.asistencia).update({
        'estatus': EstatusAsistencia.presente,
        'hora_entrada': DateTime.now().toUtc().toIso8601String(),
        ...camposExtra,
      }).eq('id', asistenciaId);

  Future<void> _insertarAsistencia({
    required String eventoId,
    required String usuarioId,
    required Map<String, dynamic> camposExtra,
  }) =>
      supabase.from(TablasSupabase.asistencia).insert({
        'evento_id': eventoId,
        'usuario_id': usuarioId,
        'estatus': EstatusAsistencia.presente,
        'hora_entrada': DateTime.now().toUtc().toIso8601String(),
        ...camposExtra,
      });
}
