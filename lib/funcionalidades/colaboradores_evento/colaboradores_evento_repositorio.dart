import 'package:supabase_flutter/supabase_flutter.dart';

import '../../compartido/constantes.dart';
import '../../compartido/errores.dart';
import '../../compartido/reintento.dart';
import '../../compartido/traductor_errores.dart';
import 'colaborador_item.dart';

class ColaboradoresEventoRepositorio {
  const ColaboradoresEventoRepositorio(this._supabase);

  final SupabaseClient _supabase;

  /// Retorna los colaboradores activos asignados al evento.
  Future<List<ColaboradorItem>> obtenerColaboradores(String eventoId) =>
      conReintentos(() async {
        try {
          final rolId        = await _rolColaboradorId();
          final asignaciones = await _supabase
              .from(TablasSupabase.eventosUsuariosRoles)
              .select('id, usuario_id, asignado_por')
              .eq('evento_id', eventoId)
              .eq('rol_id', rolId)
              .eq('estatus', true)
              .timeout(kTimeoutSolicitud);
          if (asignaciones.isEmpty) return [];
          final usuarioIds    = asignaciones.map((a) => a['usuario_id'] as String).toList();
          final asignadoPorIds = asignaciones
              .map((a) => a['asignado_por'] as String?)
              .whereType<String>()
              .toSet()
              .toList();
          final todosIds = {...usuarioIds, ...asignadoPorIds}.toList();
          final usuarios = await _supabase
              .from(TablasSupabase.usuarios)
              .select('id, primer_nombre, primer_apellido, url_avatar, numero_identificacion')
              .inFilter('id', todosIds)
              .timeout(kTimeoutSolicitud);
          return _combinarDatos(asignaciones, usuarios);
        } on PostgrestException catch (e) {
          throw FallaServidor(TraductorErrores.dePostgres(e));
        } catch (e) {
          TraductorErrores.lanzarInesperado(e);
        }
      });

  /// Busca usuarios del sistema cuyo nombre o apellido coincida con [query].
  Future<List<UsuarioParaAsignar>> buscarUsuarios(String query) =>
      conReintentos(() async {
        try {
          final q = query.trim();
          if (q.length < 2) return [];
          final qSanitizado = q.length > 100 ? q.substring(0, 100) : q;
          final filas = await _supabase
              .from(TablasSupabase.usuarios)
              .select('id, primer_nombre, primer_apellido, url_avatar, numero_identificacion')
              .or('primer_nombre.ilike.%$qSanitizado%,primer_apellido.ilike.%$qSanitizado%')
              .order('primer_apellido', ascending: true)
              .limit(30)
              .timeout(kTimeoutSolicitud);
          return filas.map(UsuarioParaAsignar.desdeJson).toList();
        } on PostgrestException catch (e) {
          throw FallaServidor(TraductorErrores.dePostgres(e));
        } catch (e) {
          TraductorErrores.lanzarInesperado(e);
        }
      });

  /// Asigna un usuario como colaborador del evento. Si ya existía un registro
  /// inactivo, lo reactiva vía upsert.
  Future<void> asignarColaborador({
    required String eventoId,
    required String usuarioId,
    required String asignadoPorId,
  }) async {
    try {
      final rolId = await _rolColaboradorId();
      await _supabase
          .from(TablasSupabase.eventosUsuariosRoles)
          .upsert(
            {
              'evento_id':    eventoId,
              'usuario_id':   usuarioId,
              'rol_id':       rolId,
              'asignado_por': asignadoPorId,
              'estatus':      true,
            },
            onConflict: 'evento_id,usuario_id,rol_id',
          );
    } on PostgrestException catch (e) {
      throw FallaServidor(TraductorErrores.dePostgres(e));
    } catch (e) {
      TraductorErrores.lanzarInesperado(e);
    }
  }

  /// Desactiva la asignación del colaborador (soft-delete por [asignacionId]).
  Future<void> quitarColaborador(String asignacionId) async {
    try {
      await _supabase
          .from(TablasSupabase.eventosUsuariosRoles)
          .update({'estatus': false})
          .eq('id', asignacionId);
    } on PostgrestException catch (e) {
      throw FallaServidor(TraductorErrores.dePostgres(e));
    } catch (e) {
      TraductorErrores.lanzarInesperado(e);
    }
  }

  // ─── Helpers privados ────────────────────────────────────────────────────────

  Future<String> _rolColaboradorId() async {
    final fila = await _supabase
        .from(TablasSupabase.roles)
        .select('id')
        .eq('nombre', RolesSistema.colaborador)
        .single();
    return fila['id'] as String;
  }

  List<ColaboradorItem> _combinarDatos(
    List<Map<String, dynamic>> asignaciones,
    List<Map<String, dynamic>> usuarios,
  ) {
    final mapaUsuarios = {
      for (final u in usuarios) u['id'] as String: u,
    };
    return asignaciones.map((asig) {
      final uid          = asig['usuario_id'] as String;
      final u            = mapaUsuarios[uid];
      if (u == null) return null;
      final asignadoPorId = asig['asignado_por'] as String?;
      String? asignadoPorNombre;
      if (asignadoPorId != null) {
        final asignador = mapaUsuarios[asignadoPorId];
        if (asignador != null) {
          final n = asignador['primer_nombre']  as String? ?? '';
          final a = asignador['primer_apellido'] as String? ?? '';
          asignadoPorNombre = '$n $a'.trim();
          if (asignadoPorNombre.isEmpty) asignadoPorNombre = null;
        }
      }
      return ColaboradorItem.desdeJson({
        ...u,
        'asignacion_id':      asig['id'] as String,
        'usuario_id':         uid,
        'asignado_por_nombre': asignadoPorNombre,
      });
    }).whereType<ColaboradorItem>().toList();
  }
}
