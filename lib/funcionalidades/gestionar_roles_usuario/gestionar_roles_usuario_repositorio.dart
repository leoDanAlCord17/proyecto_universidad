import 'package:supabase_flutter/supabase_flutter.dart';

import '../../compartido/constantes.dart';
import '../../compartido/errores.dart';
import '../../compartido/traductor_errores.dart';
import 'rol_item.dart';

class GestionarRolesUsuarioRepositorio {
  const GestionarRolesUsuarioRepositorio(this._supabase);

  final SupabaseClient _supabase;

  /// Retorna nombre completo y correo del usuario.
  Future<({String nombre, String correo})> obtenerInfoUsuario(String usuarioId) async {
    try {
      final fila = await _supabase
          .from(TablasSupabase.usuarios)
          .select('primer_nombre, primer_apellido, correo')
          .eq('id', usuarioId)
          .single();
      final nombre = '${fila['primer_nombre']} ${fila['primer_apellido']}';
      return (nombre: nombre, correo: fila['correo'] as String? ?? '');
    } on PostgrestException catch (e) {
      throw FallaServidor(TraductorErrores.dePostgres(e));
    } catch (e) {
      throw FallaInesperada(TraductorErrores.deInesperado(e));
    }
  }

  /// Retorna los roles activos actualmente asignados al usuario.
  Future<List<RolItem>> obtenerRolesUsuario(String usuarioId) async {
    try {
      final datos = await _supabase
          .from(TablasSupabase.usuariosRoles)
          .select('roles(id, nombre, descripcion)')
          .eq('usuario_id', usuarioId)
          .eq('estatus', true);

      final resultado = <RolItem>[];
      for (final fila in datos) {
        final rolData = fila['roles'] as Map<String, dynamic>?;
        if (rolData == null) continue;
        resultado.add(RolItem.desdeJson(rolData));
      }
      return resultado;
    } on PostgrestException catch (e) {
      throw FallaServidor(TraductorErrores.dePostgres(e));
    } catch (e) {
      throw FallaInesperada(TraductorErrores.deInesperado(e));
    }
  }

  /// Retorna todos los roles activos del sistema.
  Future<List<RolItem>> obtenerRolesActivos() async {
    try {
      final datos = await _supabase
          .from(TablasSupabase.roles)
          .select('id, nombre, descripcion')
          .eq('estatus', true)
          .order('nombre');
      return datos.map(RolItem.desdeJson).toList();
    } on PostgrestException catch (e) {
      throw FallaServidor(TraductorErrores.dePostgres(e));
    } catch (e) {
      throw FallaInesperada(TraductorErrores.deInesperado(e));
    }
  }

  /// Inserta un nuevo registro de asignación de rol.
  /// Siempre crea un registro nuevo para preservar trazabilidad.
  Future<void> asignarRol(String usuarioId, String rolId, String? adminId) async {
    try {
      await _supabase.from(TablasSupabase.usuariosRoles).insert({
        'usuario_id': usuarioId,
        'roles_id':   rolId,
        'estatus':    true,
        'creado_por': adminId,
      });
    } on PostgrestException catch (e) {
      throw FallaServidor(TraductorErrores.dePostgres(e));
    } catch (e) {
      throw FallaInesperada(TraductorErrores.deInesperado(e));
    }
  }

  /// Desactiva el registro activo del rol, registrando quién y cuándo lo quitó.
  Future<void> quitarRol(String usuarioId, String rolId, String? adminId) async {
    try {
      await _supabase
          .from(TablasSupabase.usuariosRoles)
          .update({
            'estatus':         false,
            'actualizado_por': adminId,
            'actualizado_en':  DateTime.now().toUtc().toIso8601String(),
          })
          .eq('usuario_id', usuarioId)
          .eq('roles_id',   rolId)
          .eq('estatus',    true);
    } on PostgrestException catch (e) {
      throw FallaServidor(TraductorErrores.dePostgres(e));
    } catch (e) {
      throw FallaInesperada(TraductorErrores.deInesperado(e));
    }
  }
}
