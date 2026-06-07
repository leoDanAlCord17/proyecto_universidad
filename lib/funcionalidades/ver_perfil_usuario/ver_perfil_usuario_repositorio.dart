import 'package:supabase_flutter/supabase_flutter.dart';

import '../../compartido/constantes.dart';
import '../../compartido/errores.dart';
import '../../compartido/reintento.dart';
import '../../compartido/traductor_errores.dart';
import 'perfil_completo_usuario.dart';

class VerPerfilUsuarioRepositorio {
  const VerPerfilUsuarioRepositorio(this._supabase);

  final SupabaseClient _supabase;

  /// Retorna el perfil completo del usuario incluyendo sus tags activos.
  Future<PerfilCompletoUsuario> obtenerPerfilCompleto(String usuarioId) =>
      conReintentos(() async {
        try {
          final fila = await _supabase
              .from(TablasSupabase.usuarios)
              .select(
                'id, primer_nombre, segundo_nombre, primer_apellido, segundo_apellido, '
                'numero_identificacion, correo, telefono, estatus, creado_en',
              )
              .eq('id', usuarioId)
              .single()
              .timeout(kTimeoutSolicitud);

          final tagsDatos = await _supabase
              .from(TablasSupabase.usuariosTags)
              .select('tags(id, nombre, tipo)')
              .eq('usuario_id', usuarioId)
              .eq('estatus', true)
              .timeout(kTimeoutSolicitud);

          final (tagPrincipal, secundarios) = _mapearTags(tagsDatos);

          return PerfilCompletoUsuario(
            id: fila['id'] as String,
            primerNombre: fila['primer_nombre'] as String? ?? '',
            segundoNombre: fila['segundo_nombre'] as String?,
            primerApellido: fila['primer_apellido'] as String? ?? '',
            segundoApellido: fila['segundo_apellido'] as String?,
            numeroIdentificacion: fila['numero_identificacion'] as String?,
            correo: fila['correo'] as String? ?? '',
            telefono: fila['telefono'] as String?,
            estatus: (fila['estatus'] as bool?) ?? true,
            creadoEn: fila['creado_en'] != null
                ? DateTime.parse(fila['creado_en'] as String)
                : null,
            tagPrincipalNombre: tagPrincipal,
            tagsSecundariosNombres: secundarios,
          );
        } on PostgrestException catch (e) {
          throw FallaServidor(TraductorErrores.dePostgres(e));
        } catch (e) {
          TraductorErrores.lanzarInesperado(e);
        }
      });

  (String? tagPrincipal, List<String> secundarios) _mapearTags(
      List<Map<String, dynamic>> datos) {
    String? tagPrincipal;
    final secundarios = <String>[];

    for (final fila in datos) {
      final tagData = fila['tags'] as Map<String, dynamic>?;
      if (tagData == null) continue;
      final tipo = tagData['tipo'] as String? ?? '';
      final nombre = tagData['nombre'] as String? ?? '';
      if (tipo == 'principal') {
        tagPrincipal = nombre;
      } else {
        secundarios.add(nombre);
      }
    }
    return (tagPrincipal, secundarios);
  }
}
