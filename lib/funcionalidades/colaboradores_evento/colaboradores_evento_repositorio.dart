import 'package:supabase_flutter/supabase_flutter.dart';

import '../../compartido/constantes.dart';
import '../../compartido/errores.dart';
import '../../compartido/traductor_errores.dart';
import 'colaborador_item.dart';

class ColaboradoresEventoRepositorio {
  const ColaboradoresEventoRepositorio(this._supabase);

  final SupabaseClient _supabase;

  /// Retorna los colaboradores activos asignados al evento.
  Future<List<ColaboradorItem>> obtenerColaboradores(String eventoId) async {
    try {
      final rolId        = await _rolColaboradorId();
      final asignaciones = await _supabase
          .from(TablasSupabase.eventosUsuariosRoles)
          .select('id, usuario_id')
          .eq('evento_id', eventoId)
          .eq('rol_id', rolId)
          .eq('estatus', true);
      if (asignaciones.isEmpty) return [];
      final usuarioIds = asignaciones.map((a) => a['usuario_id'] as String).toList();
      final usuarios   = await _supabase
          .from(TablasSupabase.usuarios)
          .select('id, primer_nombre, primer_apellido, url_avatar, numero_identificacion')
          .inFilter('id', usuarioIds);
      return _combinarDatos(asignaciones, usuarios);
    } on PostgrestException catch (e) {
      throw FallaServidor(TraductorErrores.dePostgres(e));
    } catch (e) {
      throw FallaInesperada(TraductorErrores.deInesperado(e));
    }
  }

  /// Busca usuarios del sistema cuyo nombre o apellido coincida con [query].
  Future<List<UsuarioParaAsignar>> buscarUsuarios(String query) async {
    try {
      final q = query.trim();
      if (q.length < 2) return [];
      final qSanitizado = q.length > 100 ? q.substring(0, 100) : q;
      final filas = await _supabase
          .from(TablasSupabase.usuarios)
          .select('id, primer_nombre, primer_apellido, url_avatar, numero_identificacion')
          .or('primer_nombre.ilike.%$qSanitizado%,primer_apellido.ilike.%$qSanitizado%')
          .order('primer_apellido', ascending: true)
          .limit(30);
      return filas.map(UsuarioParaAsignar.desdeJson).toList();
    } on PostgrestException catch (e) {
      throw FallaServidor(TraductorErrores.dePostgres(e));
    } catch (e) {
      throw FallaInesperada(TraductorErrores.deInesperado(e));
    }
  }

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
      throw FallaInesperada(TraductorErrores.deInesperado(e));
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
      throw FallaInesperada(TraductorErrores.deInesperado(e));
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
    final mapaAsig = {
      for (final asig in asignaciones)
        asig['usuario_id'] as String: asig['id'] as String,
    };
    return usuarios.map((u) {
      final uid = u['id'] as String;
      return ColaboradorItem.desdeJson({
        ...u, 'asignacion_id': mapaAsig[uid]!, 'usuario_id': uid,
      });
    }).toList();
  }
}
